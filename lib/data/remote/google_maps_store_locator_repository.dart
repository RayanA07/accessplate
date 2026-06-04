import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../domain/entities/store_search.dart';
import '../../domain/repositories/store_locator_repository.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/transportation_mode.dart';
import 'google_maps_api_config.dart';

class GoogleMapsStoreLocatorRepository implements StoreLocatorRepository {
  GoogleMapsStoreLocatorRepository({
    required GoogleMapsApiConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client();

  final GoogleMapsApiConfig _config;
  final http.Client _httpClient;

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<SearchLocation> geocodeQuery(String query) async {
    _requireConfiguration();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const StoreSearchException('Enter an address or ZIP code.');
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final zipOnly = digits.length == 5 && trimmed == digits;
    final uri = zipOnly
        ? Uri.parse(
            '${_config.geocodingBaseUrl}/geocode/address',
          ).replace(
            queryParameters: {
              'address.postalCode': digits,
              'key': _config.apiKey,
            },
          )
        : Uri.parse(
            '${_config.geocodingBaseUrl}/geocode/address/${Uri.encodeComponent(trimmed)}',
          ).replace(
            queryParameters: {'key': _config.apiKey},
          );

    final payload = await _getJson(uri);
    final results = payload['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) {
      throw const StoreSearchException(
        'No map location could be verified for that search.',
      );
    }

    final result = Map<String, dynamic>.from(results.first as Map);
    final location = Map<String, dynamic>.from(
      result['location'] as Map? ?? const {},
    );
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const StoreSearchException(
        'Map lookup returned no coordinates for that search.',
      );
    }

    return SearchLocation(
      kind: zipOnly ? SearchLocationKind.zipCentroid : SearchLocationKind.address,
      label: zipOnly
          ? 'ZIP $digits'
          : result['formattedAddress'] as String? ?? trimmed,
      latitude: latitude,
      longitude: longitude,
      verification: zipOnly ? DataVerification.approximate : DataVerification.live,
      postalCode: _postalCodeFromResult(result) ?? (zipOnly ? digits : null),
      query: trimmed,
      detail: zipOnly
          ? 'Approximate ZIP centroid from Google Geocoding'
          : 'Live geocoded address from Google Geocoding',
    );
  }

  @override
  Future<SearchLocation> reverseGeocodeDeviceLocation(
    DeviceLocationFix fix,
  ) async {
    _requireConfiguration();
    final uri = Uri.parse(
      '${_config.geocodingBaseUrl}/geocode/location/${fix.latitude},${fix.longitude}',
    ).replace(queryParameters: {'key': _config.apiKey});
    final payload = await _getJson(uri);
    final results = payload['results'] as List<dynamic>? ?? const [];
    final result = results.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(results.first as Map);

    return SearchLocation(
      kind: SearchLocationKind.device,
      label:
          result['formattedAddress'] as String? ??
          'Current device location',
      latitude: fix.latitude,
      longitude: fix.longitude,
      verification: fix.isPrecise
          ? DataVerification.live
          : DataVerification.approximate,
      postalCode: _postalCodeFromResult(result),
      detail: fix.isPrecise
          ? 'Live device location'
          : 'Approximate device location',
    );
  }

  @override
  Future<List<NearbyStore>> searchNearbyStores({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    int limitPerCategory = 4,
  }) async {
    _requireConfiguration();
    final merged = <String, NearbyStore>{};

    for (final category in categories) {
      final uri = Uri.parse('${_config.placesBaseUrl}/places:searchText');
      final response = await _httpClient.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'X-Goog-Api-Key': _config.apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.primaryTypeDisplayName',
        },
        body: jsonEncode({
          'textQuery': _textQueryFor(category),
          'maxResultCount': limitPerCategory,
          'locationBias': {
            'circle': {
              'center': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
              'radius': radiusMeters.toDouble(),
            },
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StoreSearchException(
          'Nearby store search failed (${response.statusCode}).',
        );
      }

      final payload = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final places = payload['places'] as List<dynamic>? ?? const [];
      for (final row in places) {
        final place = Map<String, dynamic>.from(row as Map);
        final id = place['id'] as String?;
        final displayName = place['displayName'] is Map
            ? Map<String, dynamic>.from(place['displayName'] as Map)
            : const <String, dynamic>{};
        final location = place['location'] is Map
            ? Map<String, dynamic>.from(place['location'] as Map)
            : const <String, dynamic>{};
        final latitude = (location['latitude'] as num?)?.toDouble();
        final longitude = (location['longitude'] as num?)?.toDouble();
        if (id == null || latitude == null || longitude == null) {
          continue;
        }

        final distanceMiles = _straightLineMiles(
          origin.latitude,
          origin.longitude,
          latitude,
          longitude,
        );
        final existing = merged[id];
        final nextCategories = {
          ...?existing?.categories,
          category,
        };
        final nextPrimary = existing?.primaryCategory ?? category;
        merged[id] = NearbyStore(
          placeId: id,
          name: displayName['text'] as String? ?? 'Nearby store',
          address: place['formattedAddress'] as String? ?? '',
          latitude: latitude,
          longitude: longitude,
          categories: nextCategories,
          primaryCategory: nextPrimary,
          discoveryVerification: DataVerification.live,
          travelMetric: existing?.travelMetric ??
              TravelMetric(
                source: TravelMetricSource.straightLineApproximate,
                distanceMiles: distanceMiles,
              ),
        );
      }
    }

    final stores = merged.values.toList(growable: false);
    stores.sort((left, right) {
      final leftMiles = left.travelMetric.distanceMiles ?? double.infinity;
      final rightMiles = right.travelMetric.distanceMiles ?? double.infinity;
      final byDistance = leftMiles.compareTo(rightMiles);
      if (byDistance != 0) {
        return byDistance;
      }
      return left.name.compareTo(right.name);
    });
    return stores;
  }

  @override
  Future<Map<String, TravelMetric>> computeTravelMetrics({
    required SearchLocation origin,
    required Iterable<NearbyStore> stores,
    required TransportationMode transportationMode,
  }) async {
    _requireConfiguration();
    final destinations = stores.toList(growable: false);
    if (destinations.isEmpty) {
      return const {};
    }

    final response = await _httpClient.post(
      Uri.parse('${_config.routesBaseUrl}/distanceMatrix/v2:computeRouteMatrix'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Goog-Api-Key': _config.apiKey,
        'X-Goog-FieldMask':
            'originIndex,destinationIndex,status,condition,distanceMeters,duration',
      },
      body: jsonEncode({
        'origins': [
          {
            'waypoint': {
              'location': {
                'latLng': {
                  'latitude': origin.latitude,
                  'longitude': origin.longitude,
                },
              },
            },
          },
        ],
        'destinations': [
          for (final store in destinations)
            {
              'waypoint': {
                'location': {
                  'latLng': {
                    'latitude': store.latitude,
                    'longitude': store.longitude,
                  },
                },
              },
            },
        ],
        'travelMode': _travelModeFor(transportationMode),
        if (transportationMode == TransportationMode.car)
          'routingPreference': 'TRAFFIC_AWARE'
        else if (transportationMode == TransportationMode.walk ||
            transportationMode == TransportationMode.limited)
          'routingPreference': 'TRAFFIC_UNAWARE',
        'units': 'IMPERIAL',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const {};
    }

    final rows = jsonDecode(response.body) as List<dynamic>;
    final metrics = <String, TravelMetric>{};
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final destinationIndex = (map['destinationIndex'] as num?)?.toInt();
      if (destinationIndex == null ||
          destinationIndex < 0 ||
          destinationIndex >= destinations.length) {
        continue;
      }
      if ((map['condition'] as String?) != 'ROUTE_EXISTS') {
        continue;
      }

      final distanceMeters = (map['distanceMeters'] as num?)?.toDouble();
      final durationRaw = map['duration'] as String?;
      metrics[destinations[destinationIndex].placeId] = TravelMetric(
        source: TravelMetricSource.liveRoute,
        distanceMiles: distanceMeters == null ? null : distanceMeters / 1609.344,
        durationMinutes: _parseDurationMinutes(durationRaw),
      );
    }
    return metrics;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(
      uri,
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        'X-Goog-Api-Key': _config.apiKey,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoreSearchException(
        'Map lookup failed (${response.statusCode}).',
      );
    }
    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  int? _parseDurationMinutes(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final seconds = double.tryParse(raw.replaceAll('s', ''));
    if (seconds == null) {
      return null;
    }
    return math.max(1, (seconds / 60).round());
  }

  String? _postalCodeFromResult(Map<String, dynamic> result) {
    final formatted = result['formattedAddress'] as String?;
    final match = RegExp(r'\b(\d{5})(?:-\d{4})?\b').firstMatch(formatted ?? '');
    return match?.group(1);
  }

  String _textQueryFor(AvailabilityContext category) {
    return switch (category) {
      AvailabilityContext.grocery => 'grocery store',
      AvailabilityContext.convenience => 'convenience store',
      AvailabilityContext.fastFood => 'fast food restaurant',
      AvailabilityContext.foodPantry => 'food pantry',
      AvailabilityContext.dollarStore => 'dollar store',
    };
  }

  String _travelModeFor(TransportationMode mode) {
    return switch (mode) {
      TransportationMode.car => 'DRIVE',
      TransportationMode.transit => 'TRANSIT',
      TransportationMode.walk => 'WALK',
      TransportationMode.limited => 'WALK',
    };
  }

  double _straightLineMiles(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusMiles = 3958.7613;
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRadians(double value) => value * (math.pi / 180);

  void _requireConfiguration() {
    if (!isConfigured) {
      throw const StoreSearchException(
        'Google Maps APIs are not configured for this build.',
      );
    }
  }
}
