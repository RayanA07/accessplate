import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../domain/entities/store_search.dart';
import '../../domain/repositories/store_locator_repository.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/merchant_brand.dart';
import '../../domain/value_objects/transportation_mode.dart';
import 'open_street_map_api_config.dart';

class OpenStreetMapStoreLocatorRepository implements StoreLocatorRepository {
  OpenStreetMapStoreLocatorRepository({
    required OpenStreetMapApiConfig config,
    http.Client? httpClient,
    MerchantBrandCatalog merchantBrandCatalog = MerchantBrandCatalog.defaults,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _merchantBrandCatalog = merchantBrandCatalog;

  final OpenStreetMapApiConfig _config;
  final http.Client _httpClient;
  final MerchantBrandCatalog _merchantBrandCatalog;

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<SearchLocation> geocodeQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const StoreSearchException('Enter an address or ZIP code.');
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final zipOnly = digits.length == 5 && trimmed == digits;
    final uri = Uri.parse('${_config.nominatimBaseUrl}/search').replace(
      queryParameters: {
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '1',
        'countrycodes': 'us',
        if (zipOnly) 'postalcode': digits else 'q': trimmed,
      },
    );

    final payload = await _getJsonList(
      uri,
      failureMessage: 'Location search failed',
    );
    if (payload.isEmpty) {
      throw const StoreSearchException(
        'No map location could be verified for that search.',
      );
    }

    final result = Map<String, dynamic>.from(payload.first as Map);
    final latitude = double.tryParse(result['lat']?.toString() ?? '');
    final longitude = double.tryParse(result['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      throw const StoreSearchException(
        'Map lookup returned no coordinates for that search.',
      );
    }

    final address = _addressMap(result['address']);
    final postalCode =
        _normalizePostalCode(address['postcode']?.toString()) ??
        (zipOnly ? digits : null);

    return SearchLocation(
      kind: zipOnly
          ? SearchLocationKind.zipCentroid
          : SearchLocationKind.address,
      label: zipOnly
          ? 'ZIP $digits area'
          : result['display_name'] as String? ?? trimmed,
      latitude: latitude,
      longitude: longitude,
      verification: zipOnly
          ? DataVerification.approximate
          : DataVerification.live,
      postalCode: postalCode,
      query: trimmed,
      detail: zipOnly
          ? 'Approximate ZIP area from OpenStreetMap Nominatim'
          : 'Address match from OpenStreetMap Nominatim',
    );
  }

  @override
  Future<SearchLocation> reverseGeocodeDeviceLocation(
    DeviceLocationFix fix,
  ) async {
    final verification = fix.isPrecise
        ? DataVerification.live
        : DataVerification.approximate;
    final fallbackLabel = fix.isPrecise
        ? 'Current location'
        : 'Approximate current location';

    // Resolve a human-readable label from the device coordinates. The raw
    // lat/lng is NEVER placed in `query` (which feeds the visible search field);
    // searching always uses the coordinates on this object. If labeling fails
    // (offline / rate limited), fall back to a generic label but keep the real
    // coordinates so nearby search still works.
    String label = fallbackLabel;
    String? postalCode;
    String detail = fix.isPrecise
        ? 'Device GPS fix'
        : 'Approximate device GPS fix';
    try {
      final uri = Uri.parse('${_config.nominatimBaseUrl}/reverse').replace(
        queryParameters: {
          'format': 'jsonv2',
          'addressdetails': '1',
          'zoom': '16',
          'lat': fix.latitude.toString(),
          'lon': fix.longitude.toString(),
        },
      );
      final response = await _httpClient
          .get(uri, headers: _headers())
          .timeout(_nominatimTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = Map<String, dynamic>.from(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        final address = _addressMap(result['address']);
        final resolvedLabel =
            _shortAreaLabel(address) ??
            _firstSegment(result['display_name']?.toString());
        if (resolvedLabel != null && resolvedLabel.isNotEmpty) {
          label = resolvedLabel;
          detail = fix.isPrecise
              ? 'Reverse geocoded from device GPS via OpenStreetMap Nominatim'
              : 'Approximate area reverse geocoded via OpenStreetMap Nominatim';
        }
        postalCode = _normalizePostalCode(address['postcode']?.toString());
      }
    } catch (_) {
      // Keep the generic fallback label; coordinates remain valid for search.
    }

    return SearchLocation(
      kind: SearchLocationKind.device,
      label: label,
      latitude: fix.latitude,
      longitude: fix.longitude,
      verification: verification,
      postalCode: postalCode,
      // Intentionally null: device location must not prefill the typed-query
      // field with raw coordinates.
      query: null,
      detail: detail,
    );
  }

  /// Builds a concise "City, ST 12345" style label from a Nominatim address map.
  String? _shortAreaLabel(Map<String, dynamic> address) {
    final city =
        (address['city'] ??
                address['town'] ??
                address['village'] ??
                address['hamlet'] ??
                address['suburb'] ??
                address['neighbourhood'])
            ?.toString()
            .trim();
    final state = address['state']?.toString().trim();
    final postcode = _normalizePostalCode(address['postcode']?.toString());

    final cityState = [
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
    ].join(', ');
    final pieces = [if (cityState.isNotEmpty) cityState, ?postcode];
    if (pieces.isEmpty) {
      return null;
    }
    return pieces.join(' ');
  }

  String? _firstSegment(String? displayName) {
    if (displayName == null) {
      return null;
    }
    final segment = displayName.split(',').first.trim();
    return segment.isEmpty ? null : segment;
  }

  @override
  Future<List<NearbyStore>> searchNearbyStores({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    int limitPerCategory = 4,
  }) async {
    if (categories.isEmpty) {
      return const [];
    }

    Object? primaryError;
    try {
      final query = _buildOverpassQuery(
        origin: origin,
        categories: categories,
        radiusMeters: radiusMeters,
        limitPerCategory: limitPerCategory,
      );
      final response = await _httpClient
          .post(
            Uri.parse(_config.overpassBaseUrl),
            headers: _headers(
              contentType: 'application/x-www-form-urlencoded; charset=utf-8',
            ),
            body: {'data': query},
          )
          .timeout(_overpassTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StoreSearchException(
          'Nearby store search failed (${response.statusCode}).',
        );
      }

      final payload = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final stores = _storesFromOverpassElements(
        origin: origin,
        categories: categories,
        elements: payload['elements'] as List<dynamic>? ?? const [],
      );
      if (stores.isNotEmpty) {
        return stores;
      }
    } catch (error) {
      primaryError = error;
    }

    try {
      final fallbackStores = await _searchNearbyStoresWithNominatimFallback(
        origin: origin,
        categories: categories,
        radiusMeters: radiusMeters,
        limitPerCategory: limitPerCategory,
      );
      if (fallbackStores.isNotEmpty) {
        return fallbackStores;
      }
    } catch (_) {
      if (primaryError == null) {
        return const [];
      }
    }

    if (primaryError is StoreSearchException) {
      throw primaryError;
    }
    if (primaryError is TimeoutException) {
      throw const StoreSearchException(
        'Nearby store search timed out before stores could be verified.',
      );
    }
    if (primaryError is SocketException) {
      throw const StoreSearchException(
        'Nearby store search could not reach the map service.',
      );
    }
    if (primaryError != null) {
      throw StoreSearchException('Nearby store search failed: $primaryError');
    }

    throw const StoreSearchException(
      'No nearby stores matched the current live search.',
    );
  }

  @override
  Future<Map<String, TravelMetric>> computeTravelMetrics({
    required SearchLocation origin,
    required Iterable<NearbyStore> stores,
    required TransportationMode transportationMode,
  }) async {
    // The public OpenStreetMap prototype path has no routing engine, so no live
    // drive/walk times are available. Returning an empty map keeps each store's
    // straight-line distance, which is explicitly surfaced as "approximate" in
    // the UI — we never imply a live route we did not compute.
    return const {};
  }

  Future<List<dynamic>> _getJsonList(
    Uri uri, {
    required String failureMessage,
  }) async {
    final response = await _httpClient
        .get(uri, headers: _headers())
        .timeout(_nominatimTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpFailure(
        failureMessage: failureMessage,
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  StoreSearchException _httpFailure({
    required String failureMessage,
    required int statusCode,
  }) {
    if (statusCode == 429) {
      return switch (failureMessage) {
        'Location search failed' => const StoreSearchException(
          'Location search is temporarily busy. Try again in a moment.',
        ),
        'Nearby store search fallback failed' => const StoreSearchException(
          'Nearby store lookup fallback is temporarily busy.',
        ),
        'Device location lookup failed' => const StoreSearchException(
          'Current location labeling is temporarily unavailable.',
        ),
        _ => StoreSearchException('$failureMessage (429).'),
      };
    }

    return StoreSearchException('$failureMessage ($statusCode).');
  }

  Map<String, String> _headers({String? contentType}) {
    return {
      HttpHeaders.userAgentHeader: _config.userAgent,
      HttpHeaders.acceptHeader: 'application/json',
      ...?contentType == null
          ? null
          : {HttpHeaders.contentTypeHeader: contentType},
    };
  }

  Map<String, dynamic> _addressMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  _LatLng? _coordinatesFor(Map<String, dynamic> element) {
    final center = _addressMap(element['center']);
    final latitude =
        (element['lat'] as num?)?.toDouble() ??
        (center['lat'] as num?)?.toDouble();
    final longitude =
        (element['lon'] as num?)?.toDouble() ??
        (center['lon'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return null;
    }
    return _LatLng(latitude, longitude);
  }

  /// Resolves a known chain brand key from a store's OSM tags. `brand`/
  /// `operator` are canonical chain identifiers, so they take priority over the
  /// free-form `name`. Returns `null` when no known chain is confidently
  /// recognized.
  String? _brandKeyFromTags(Map<String, dynamic> tags) {
    for (final tag in const ['brand', 'operator', 'name']) {
      final value = tags[tag]?.toString();
      final key = _merchantBrandCatalog.matchKey(value);
      if (key != null) {
        return key;
      }
    }
    return null;
  }

  Set<AvailabilityContext> _categoriesFor(Map<String, dynamic> tags) {
    final categories = <AvailabilityContext>{};
    final shop = _normalize(tags['shop']?.toString() ?? '');
    final amenity = _normalize(tags['amenity']?.toString() ?? '');
    final socialFacility = _normalize(
      tags['social_facility']?.toString() ?? '',
    );
    final combined = _normalize(
      [
        tags['name'],
        tags['brand'],
        tags['operator'],
        tags['description'],
      ].whereType<Object>().join(' '),
    );

    if (shop == 'supermarket' || shop == 'grocery') {
      categories.add(AvailabilityContext.grocery);
    }
    if (shop == 'convenience') {
      categories.add(AvailabilityContext.convenience);
    }
    if (amenity == 'fast food') {
      categories.add(AvailabilityContext.fastFood);
    }
    if (_isDollarStore(shop, combined)) {
      categories.add(AvailabilityContext.dollarStore);
    }
    if (_isFoodPantry(amenity, socialFacility, combined)) {
      categories.add(AvailabilityContext.foodPantry);
    }

    return categories;
  }

  bool _isDollarStore(String shop, String combined) {
    if (shop == 'variety store' || shop == 'discount') {
      return true;
    }
    return _dollarStoreTerms.any(combined.contains);
  }

  bool _isFoodPantry(String amenity, String socialFacility, String combined) {
    if (socialFacility == 'food bank' || socialFacility == 'food pantry') {
      return true;
    }
    if (amenity == 'food bank') {
      return true;
    }
    return combined.contains('food pantry') ||
        combined.contains('food bank') ||
        combined.contains('pantry');
  }

  AvailabilityContext _primaryCategory(Set<AvailabilityContext> categories) {
    for (final category in _categoryPriority) {
      if (categories.contains(category)) {
        return category;
      }
    }
    return categories.first;
  }

  String _storeName(
    Map<String, dynamic> tags,
    Set<AvailabilityContext> categories,
  ) {
    final name = tags['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final brand = tags['brand']?.toString().trim();
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }
    final category = _primaryCategory(categories);
    return switch (category) {
      AvailabilityContext.grocery => 'Nearby grocery store',
      AvailabilityContext.convenience => 'Nearby convenience store',
      AvailabilityContext.dollarStore => 'Nearby dollar store',
      AvailabilityContext.foodPantry => 'Nearby food pantry',
      AvailabilityContext.fastFood => 'Nearby fast-food location',
    };
  }

  String _addressFromTags(Map<String, dynamic> tags) {
    final full = tags['addr:full']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full;
    }

    final line1 = [
      tags['addr:housenumber']?.toString().trim(),
      tags['addr:street']?.toString().trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    final line2 = [
      tags['addr:city']?.toString().trim(),
      tags['addr:state']?.toString().trim(),
      _normalizePostalCode(tags['addr:postcode']?.toString()),
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    final pieces = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
    ];
    if (pieces.isEmpty) {
      return 'Address unavailable';
    }
    return pieces.join(', ');
  }

  String? _normalizePostalCode(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = RegExp(r'\b(\d{5})(?:-\d{4})?\b').firstMatch(raw);
    return match?.group(1);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildOverpassQuery({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    required int limitPerCategory,
  }) {
    final fragments = <String>[
      for (final category in categories)
        ..._queryFragmentsFor(
          category,
          origin.latitude,
          origin.longitude,
          radiusMeters,
          limitPerCategory,
        ),
    ];
    return '''
[out:json][timeout:8];
(
${fragments.join('\n')}
);
out center tags;
''';
  }

  List<NearbyStore> _storesFromOverpassElements({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required List<dynamic> elements,
  }) {
    final merged = <String, NearbyStore>{};

    for (final row in elements) {
      final element = Map<String, dynamic>.from(row as Map);
      final tags = _addressMap(element['tags']);
      final matchedCategories = _categoriesFor(tags).intersection(categories);
      if (matchedCategories.isEmpty) {
        continue;
      }

      final coordinates = _coordinatesFor(element);
      if (coordinates == null) {
        continue;
      }

      final placeId = '${element['type'] ?? 'element'}:${element['id'] ?? ''}';
      if (placeId == 'element:') {
        continue;
      }

      final distanceMiles = _straightLineMiles(
        origin.latitude,
        origin.longitude,
        coordinates.latitude,
        coordinates.longitude,
      );
      final existing = merged[placeId];
      final storeCategories = {...?existing?.categories, ...matchedCategories};
      merged[placeId] = NearbyStore(
        placeId: placeId,
        name: _storeName(tags, storeCategories),
        address: _addressFromTags(tags),
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        categories: storeCategories,
        primaryCategory:
            existing?.primaryCategory ?? _primaryCategory(storeCategories),
        discoveryVerification: DataVerification.live,
        travelMetric: TravelMetric(
          source: TravelMetricSource.straightLineApproximate,
          distanceMiles: distanceMiles,
        ),
        phoneNumber:
            tags['phone']?.toString() ?? tags['contact:phone']?.toString(),
        brandKey: existing?.brandKey ?? _brandKeyFromTags(tags),
      );
    }

    final stores = merged.values.toList(growable: false);
    stores.sort(_sortStoresByDistanceThenName);
    return _dedupeStores(stores);
  }

  Future<List<NearbyStore>> _searchNearbyStoresWithNominatimFallback({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    required int limitPerCategory,
  }) async {
    final merged = <String, NearbyStore>{};
    final viewbox = _viewboxFor(origin, radiusMeters);

    for (final category in categories) {
      for (final phrase in _fallbackQueriesFor(category)) {
        final uri = Uri.parse('${_config.nominatimBaseUrl}/search').replace(
          queryParameters: {
            'format': 'jsonv2',
            'addressdetails': '1',
            'limit': limitPerCategory.toString(),
            'countrycodes': 'us',
            'q': phrase,
            'viewbox': viewbox,
            'bounded': '1',
          },
        );

        final payload = await _getJsonList(
          uri,
          failureMessage: 'Nearby store search fallback failed',
        );
        for (final row in payload) {
          final result = Map<String, dynamic>.from(row as Map);
          final latitude = double.tryParse(result['lat']?.toString() ?? '');
          final longitude = double.tryParse(result['lon']?.toString() ?? '');
          if (latitude == null || longitude == null) {
            continue;
          }

          final placeId = _nominatimPlaceId(result);
          if (placeId == null) {
            continue;
          }

          final existing = merged[placeId];
          final storeCategories = {...?existing?.categories, category};
          merged[placeId] = NearbyStore(
            placeId: placeId,
            name: _storeNameFromSearchResult(result, category),
            address: _addressFromSearchResult(result),
            latitude: latitude,
            longitude: longitude,
            categories: storeCategories,
            primaryCategory:
                existing?.primaryCategory ?? _primaryCategory(storeCategories),
            discoveryVerification: DataVerification.live,
            travelMetric: TravelMetric(
              source: TravelMetricSource.straightLineApproximate,
              distanceMiles: _straightLineMiles(
                origin.latitude,
                origin.longitude,
                latitude,
                longitude,
              ),
            ),
            brandKey:
                existing?.brandKey ??
                _merchantBrandCatalog.matchKey(
                  result['name']?.toString() ??
                      result['display_name']?.toString(),
                ),
          );
        }
      }
    }

    final stores = merged.values.toList(growable: false);
    stores.sort(_sortStoresByDistanceThenName);
    return _dedupeStores(stores);
  }

  List<String> _fallbackQueriesFor(AvailabilityContext category) {
    return switch (category) {
      AvailabilityContext.grocery => const ['supermarket', 'grocery store'],
      AvailabilityContext.convenience => const ['convenience store'],
      AvailabilityContext.dollarStore => const [
        'Dollar General',
        'Family Dollar',
        'Dollar Tree',
      ],
      AvailabilityContext.foodPantry => const ['food pantry', 'food bank'],
      AvailabilityContext.fastFood => const ['fast food'],
    };
  }

  String _viewboxFor(SearchLocation origin, int radiusMeters) {
    final latDelta = radiusMeters / 111320.0;
    final lngDelta =
        radiusMeters /
        (111320.0 *
            math.cos(_toRadians(origin.latitude)).abs().clamp(0.2, 1.0));
    final left = origin.longitude - lngDelta;
    final right = origin.longitude + lngDelta;
    final top = origin.latitude + latDelta;
    final bottom = origin.latitude - latDelta;
    return '$left,$top,$right,$bottom';
  }

  String? _nominatimPlaceId(Map<String, dynamic> result) {
    final osmType = result['osm_type']?.toString();
    final osmId = result['osm_id']?.toString();
    if (osmType == null || osmType.isEmpty || osmId == null || osmId.isEmpty) {
      return null;
    }
    return '$osmType:$osmId';
  }

  String _storeNameFromSearchResult(
    Map<String, dynamic> result,
    AvailabilityContext category,
  ) {
    final explicitName = result['name']?.toString().trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final displayName = result['display_name']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      final firstSegment = displayName.split(',').first.trim();
      if (firstSegment.isNotEmpty) {
        return firstSegment;
      }
    }

    return switch (category) {
      AvailabilityContext.grocery => 'Nearby grocery store',
      AvailabilityContext.convenience => 'Nearby convenience store',
      AvailabilityContext.dollarStore => 'Nearby dollar store',
      AvailabilityContext.foodPantry => 'Nearby food pantry',
      AvailabilityContext.fastFood => 'Nearby fast-food location',
    };
  }

  String _addressFromSearchResult(Map<String, dynamic> result) {
    final address = _addressMap(result['address']);
    final formatted = _addressFromTags({
      'addr:housenumber': address['house_number'],
      'addr:street':
          address['road'] ?? address['street'] ?? address['pedestrian'],
      'addr:city':
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['hamlet'],
      'addr:state': address['state'],
      'addr:postcode': address['postcode'],
    });
    if (formatted != 'Address unavailable') {
      return formatted;
    }
    return result['display_name']?.toString() ?? 'Address unavailable';
  }

  /// Removes duplicate listings for the same store. Distinct OSM elements
  /// (e.g. a node and a building polygon, or two imports of one 7-Eleven) can
  /// share an identical name and distance; those must not appear twice. The
  /// list is already distance-sorted, so the nearest/first instance is kept.
  List<NearbyStore> _dedupeStores(List<NearbyStore> stores) {
    final seen = <String>{};
    final result = <NearbyStore>[];
    for (final store in stores) {
      final miles = store.travelMetric.distanceMiles;
      final distanceKey = miles == null
          ? 'na'
          : (miles * 10).round().toString();
      final key = '${_normalize(store.name)}|$distanceKey';
      if (seen.add(key)) {
        result.add(store);
      }
    }
    return result;
  }

  int _sortStoresByDistanceThenName(NearbyStore left, NearbyStore right) {
    final leftMiles = left.travelMetric.distanceMiles ?? double.infinity;
    final rightMiles = right.travelMetric.distanceMiles ?? double.infinity;
    final byDistance = leftMiles.compareTo(rightMiles);
    if (byDistance != 0) {
      return byDistance;
    }
    return left.name.compareTo(right.name);
  }

  List<String> _queryFragmentsFor(
    AvailabilityContext category,
    double latitude,
    double longitude,
    int radiusMeters,
    int limitPerCategory,
  ) {
    final around = '(around:$radiusMeters,$latitude,$longitude)';
    return switch (category) {
      AvailabilityContext.grocery => [
        'nwr["shop"="supermarket"]$around;',
        'nwr["shop"="grocery"]$around;',
      ],
      AvailabilityContext.convenience => ['nwr["shop"="convenience"]$around;'],
      AvailabilityContext.dollarStore => [
        'nwr["shop"="variety_store"]$around;',
        'nwr["shop"="discount"]$around;',
        'nwr["name"~"$_dollarStorePattern",i]$around;',
        'nwr["brand"~"$_dollarStorePattern",i]$around;',
      ],
      AvailabilityContext.foodPantry => [
        'nwr["amenity"="food_bank"]$around;',
        'nwr["amenity"="social_facility"]["social_facility"~"food_bank|food_pantry",i]$around;',
        'nwr["social_facility"~"food_bank|food_pantry",i]$around;',
        'nwr["name"~"food pantry|food bank",i]$around;',
      ],
      AvailabilityContext.fastFood => ['nwr["amenity"="fast_food"]$around;'],
    }.take(limitPerCategory).toList(growable: false);
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
}

class _LatLng {
  const _LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

const _categoryPriority = <AvailabilityContext>[
  AvailabilityContext.grocery,
  AvailabilityContext.convenience,
  AvailabilityContext.dollarStore,
  AvailabilityContext.foodPantry,
  AvailabilityContext.fastFood,
];

const _dollarStorePattern =
    r'dollar general|family dollar|dollar tree|99 cents only|five below';

const _dollarStoreTerms = <String>[
  'dollar general',
  'family dollar',
  'dollar tree',
  '99 cents only',
  'five below',
];

const _overpassTimeout = Duration(seconds: 8);
const _nominatimTimeout = Duration(seconds: 8);
