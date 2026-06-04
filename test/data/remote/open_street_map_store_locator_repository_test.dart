import 'dart:convert';

import 'package:access_plate/data/remote/open_street_map_api_config.dart';
import 'package:access_plate/data/remote/open_street_map_store_locator_repository.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = OpenStreetMapApiConfig(
    nominatimBaseUrl: 'https://osm.test',
    overpassBaseUrl: 'https://overpass.test/api/interpreter',
    userAgent: 'AccessPlate test',
  );

  test('maps manual address lookup through Nominatim', () async {
    final repository = OpenStreetMapStoreLocatorRepository(
      config: config,
      httpClient: MockClient((request) async {
        expect(request.url.toString(), contains('/search'));
        expect(request.url.queryParameters['q'], '123 Main St, Cincinnati, OH');
        return http.Response(
          jsonEncode([
            {
              'lat': '39.1031',
              'lon': '-84.5120',
              'display_name':
                  '123 Main St, Cincinnati, Hamilton County, Ohio, 45202, United States',
              'address': {'postcode': '45202-1234'},
            },
          ]),
          200,
        );
      }),
    );

    final result = await repository.geocodeQuery('123 Main St, Cincinnati, OH');

    expect(result.kind, SearchLocationKind.address);
    expect(result.verification, DataVerification.live);
    expect(result.postalCode, '45202');
    expect(result.label, contains('123 Main St'));
  });

  test('maps ZIP lookup as approximate area search', () async {
    final repository = OpenStreetMapStoreLocatorRepository(
      config: config,
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['postalcode'], '45202');
        expect(request.url.queryParameters['countrycodes'], 'us');
        return http.Response(
          jsonEncode([
            {
              'lat': '39.1084',
              'lon': '-84.5106',
              'display_name':
                  'Cincinnati, Hamilton County, Ohio, 45202, United States',
              'address': {'postcode': '45202'},
            },
          ]),
          200,
        );
      }),
    );

    final result = await repository.geocodeQuery('45202');

    expect(result.kind, SearchLocationKind.zipCentroid);
    expect(result.verification, DataVerification.approximate);
    expect(result.label, 'ZIP 45202 area');
    expect(result.detail, contains('Approximate ZIP area'));
  });

  test('maps nearby store discovery from Overpass into approximate distances', () async {
    final repository = OpenStreetMapStoreLocatorRepository(
      config: config,
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'https://overpass.test/api/interpreter');
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 39.1035,
                'lon': -84.5112,
                'tags': {
                  'name': 'Kroger',
                  'shop': 'supermarket',
                  'addr:housenumber': '100',
                  'addr:street': 'Elm St',
                  'addr:city': 'Cincinnati',
                  'addr:state': 'OH',
                  'addr:postcode': '45202',
                },
              },
              {
                'type': 'node',
                'id': 2,
                'lat': 39.1012,
                'lon': -84.5135,
                'tags': {
                  'brand': 'Dollar General',
                  'shop': 'variety_store',
                },
              },
              {
                'type': 'node',
                'id': 3,
                'lat': 39.1008,
                'lon': -84.5142,
                'tags': {
                  'name': 'Fast Burger',
                  'amenity': 'fast_food',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final stores = await repository.searchNearbyStores(
      origin: const SearchLocation(
        kind: SearchLocationKind.address,
        label: 'Demo origin',
        latitude: 39.1031,
        longitude: -84.5120,
        verification: DataVerification.live,
        postalCode: '45202',
      ),
      categories: const {
        AvailabilityContext.grocery,
        AvailabilityContext.dollarStore,
        AvailabilityContext.fastFood,
      },
      radiusMeters: 2000,
    );

    expect(stores, hasLength(3));
    expect(stores.first.name, 'Kroger');
    expect(stores.first.travelMetric.source, TravelMetricSource.straightLineApproximate);
    expect(stores.first.travelMetric.durationMinutes, isNull);
    expect(stores.first.address, contains('Elm St'));
    expect(
      stores.map((store) => store.primaryCategory),
      containsAll(<AvailabilityContext?>[
        AvailabilityContext.grocery,
        AvailabilityContext.dollarStore,
        AvailabilityContext.fastFood,
      ]),
    );
  });
}
