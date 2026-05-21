import 'dart:convert';

import 'package:access_plate/data/remote/grocery_api_config.dart';
import 'package:access_plate/data/remote/kroger_catalog_repository.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int tokenCalls;
  late GroceryApiConfig config;

  setUp(() {
    tokenCalls = 0;
    config = const GroceryApiConfig(
      clientId: 'client-id',
      clientSecret: 'client-secret',
      scopes: 'product.compact',
      apiBaseUrl: 'https://example.test/v1',
      tokenUrl: 'https://example.test/token',
    );
  });

  test('maps store search results', () async {
    final repository = KrogerCatalogRepository(
      config: config,
      httpClient: MockClient((request) async {
        if (request.url.path == '/token') {
          tokenCalls += 1;
          return http.Response(
            jsonEncode({'access_token': 'abc123', 'expires_in': 3600}),
            200,
          );
        }
        expect(request.url.path, '/v1/locations');
        expect(request.url.queryParameters['filter.zipCode.near'], '45238');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'locationId': '01400477',
                'name': 'Kroger Delhi',
                'phone': '513-451-7050',
                'address': {
                  'addressLine1': '5080 Delhi Pike',
                  'city': 'Cincinnati',
                  'state': 'OH',
                  'zipCode': '45238',
                },
                'distance': 3.4,
              },
            ],
          }),
          200,
        );
      }),
    );

    final stores = await repository.searchStores(postalCode: '45238');

    expect(tokenCalls, 1);
    expect(stores, hasLength(1));
    expect(stores.first.locationId, '01400477');
    expect(stores.first.addressLine1, '5080 Delhi Pike');
    expect(stores.first.distanceMiles, 3.4);
  });

  test('maps product search results and reuses cached auth token', () async {
    final repository = KrogerCatalogRepository(
      config: config,
      httpClient: MockClient((request) async {
        if (request.url.path == '/token') {
          tokenCalls += 1;
          return http.Response(
            jsonEncode({'access_token': 'abc123', 'expires_in': 3600}),
            200,
          );
        }

        if (request.url.path == '/v1/locations') {
          return http.Response(jsonEncode({'data': []}), 200);
        }

        expect(request.url.path, '/v1/products');
        expect(request.url.queryParameters['filter.term'], 'yogurt');
        expect(request.url.queryParameters['filter.locationId'], '01400477');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'productId': '0001111041700',
                'description': 'Kroger Carbmaster Yogurt',
                'brand': 'Kroger',
                'aisleLocations': [
                  {'description': 'Dairy', 'number': '5'},
                ],
                'items': [
                  {
                    'size': '5.3 oz',
                    'price': {'regular': 0.99, 'promo': 0.79},
                    'fulfillment': {'inStore': true},
                  },
                  {
                    'size': '5.3 oz',
                    'price': {'regular': 1.19},
                    'fulfillment': {'inStore': true},
                  },
                ],
              },
            ],
          }),
          200,
        );
      }),
    );

    await repository.searchStores(postalCode: '45238');
    final products = await repository.searchProducts(
      store: const GroceryStore(
        retailer: GroceryRetailer.kroger,
        locationId: '01400477',
        name: 'Kroger Delhi',
        addressLine1: '5080 Delhi Pike',
        city: 'Cincinnati',
        state: 'OH',
        postalCode: '45238',
      ),
      term: 'yogurt',
    );

    expect(tokenCalls, 1);
    expect(products, hasLength(1));
    expect(products.first.brand, 'Kroger');
    expect(products.first.effectivePrice, 0.79);
    expect(products.first.aisle, 'Dairy (5)');
  });
}
