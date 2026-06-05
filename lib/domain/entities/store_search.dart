import 'grocery.dart';
import '../value_objects/availability_context.dart';

enum SearchLocationKind { device, address, zipCentroid }

enum DataVerification { live, approximate, unavailable }

enum TravelMetricSource { liveRoute, straightLineApproximate, unavailable }

SearchLocationKind _searchLocationKindFromCode(String? code) {
  return SearchLocationKind.values.firstWhere(
    (value) => value.name == code,
    orElse: () => SearchLocationKind.address,
  );
}

DataVerification _dataVerificationFromCode(String? code) {
  return DataVerification.values.firstWhere(
    (value) => value.name == code,
    orElse: () => DataVerification.unavailable,
  );
}

TravelMetricSource _travelMetricSourceFromCode(String? code) {
  return TravelMetricSource.values.firstWhere(
    (value) => value.name == code,
    orElse: () => TravelMetricSource.unavailable,
  );
}

class SearchLocation {
  const SearchLocation({
    required this.kind,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.verification,
    this.postalCode,
    this.query,
    this.detail,
  });

  final SearchLocationKind kind;
  final String label;
  final double latitude;
  final double longitude;
  final DataVerification verification;
  final String? postalCode;
  final String? query;
  final String? detail;

  bool get isApproximate => verification == DataVerification.approximate;
  bool get isLive => verification == DataVerification.live;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'verification': verification.name,
      'postalCode': postalCode,
      'query': query,
      'detail': detail,
    };
  }

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      kind: _searchLocationKindFromCode(json['kind'] as String?),
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      verification: _dataVerificationFromCode(json['verification'] as String?),
      postalCode: json['postalCode'] as String?,
      query: json['query'] as String?,
      detail: json['detail'] as String?,
    );
  }
}

class TravelMetric {
  const TravelMetric({
    required this.source,
    this.distanceMiles,
    this.durationMinutes,
  });

  final TravelMetricSource source;
  final double? distanceMiles;
  final int? durationMinutes;

  bool get isLive => source == TravelMetricSource.liveRoute;
  bool get isApproximate =>
      source == TravelMetricSource.straightLineApproximate;

  Map<String, dynamic> toJson() {
    return {
      'source': source.name,
      'distanceMiles': distanceMiles,
      'durationMinutes': durationMinutes,
    };
  }

  factory TravelMetric.fromJson(Map<String, dynamic> json) {
    return TravelMetric(
      source: _travelMetricSourceFromCode(json['source'] as String?),
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );
  }
}

class NearbyStore {
  const NearbyStore({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.discoveryVerification,
    required this.travelMetric,
    this.primaryCategory,
    this.linkedGroceryStore,
    this.phoneNumber,
    this.brandKey,
  });

  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final Set<AvailabilityContext> categories;
  final AvailabilityContext? primaryCategory;
  final DataVerification discoveryVerification;
  final TravelMetric travelMetric;
  final GroceryStore? linkedGroceryStore;
  final String? phoneNumber;

  /// Normalized merchant brand key (e.g. `taco_bell`) resolved from the store's
  /// OSM `brand`/`operator`/`name` tags, or `null` if the store could not be
  /// confidently tied to a known chain. Used to verify that a brand-specific
  /// meal is matched only to a store of the same brand.
  final String? brandKey;

  bool supportsCategory(AvailabilityContext context) {
    return categories.contains(context);
  }

  /// Whether this store is the exact merchant required by a brand-specific meal.
  bool matchesMerchant(String? requiredBrandKey) {
    return requiredBrandKey != null && brandKey == requiredBrandKey;
  }

  NearbyStore copyWith({
    Set<AvailabilityContext>? categories,
    AvailabilityContext? primaryCategory,
    DataVerification? discoveryVerification,
    TravelMetric? travelMetric,
    GroceryStore? linkedGroceryStore,
    bool clearLinkedGroceryStore = false,
    String? phoneNumber,
    String? brandKey,
  }) {
    return NearbyStore(
      placeId: placeId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      categories: categories ?? this.categories,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      discoveryVerification:
          discoveryVerification ?? this.discoveryVerification,
      travelMetric: travelMetric ?? this.travelMetric,
      linkedGroceryStore: clearLinkedGroceryStore
          ? null
          : linkedGroceryStore ?? this.linkedGroceryStore,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      brandKey: brandKey ?? this.brandKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categories.map((value) => value.code).toList(),
      'primaryCategory': primaryCategory?.code,
      'discoveryVerification': discoveryVerification.name,
      'travelMetric': travelMetric.toJson(),
      'linkedGroceryStore': linkedGroceryStore?.toJson(),
      'phoneNumber': phoneNumber,
      'brandKey': brandKey,
    };
  }

  factory NearbyStore.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>? ?? const [])
        .map((value) => AvailabilityContext.fromCode(value.toString()))
        .toSet();
    return NearbyStore(
      placeId: json['placeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      categories: categories,
      primaryCategory: json['primaryCategory'] == null
          ? null
          : AvailabilityContext.fromCode(json['primaryCategory'] as String),
      discoveryVerification: _dataVerificationFromCode(
        json['discoveryVerification'] as String?,
      ),
      travelMetric: TravelMetric.fromJson(
        Map<String, dynamic>.from(json['travelMetric'] as Map? ?? const {}),
      ),
      linkedGroceryStore: json['linkedGroceryStore'] is Map
          ? GroceryStore.fromJson(
              Map<String, dynamic>.from(json['linkedGroceryStore'] as Map),
            )
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      brandKey: json['brandKey'] as String?,
    );
  }
}

class DeviceLocationFix {
  const DeviceLocationFix({
    required this.latitude,
    required this.longitude,
    required this.isPrecise,
  });

  final double latitude;
  final double longitude;
  final bool isPrecise;
}

class CachedNearbyStoreLookup {
  const CachedNearbyStoreLookup({
    required this.origin,
    required this.stores,
    required this.cachedAt,
  });

  final SearchLocation origin;
  final List<NearbyStore> stores;
  final DateTime cachedAt;

  Map<String, dynamic> toJson() {
    return {
      'origin': origin.toJson(),
      'stores': stores.map((store) => store.toJson()).toList(),
      'cachedAt': cachedAt.toUtc().toIso8601String(),
    };
  }

  static CachedNearbyStoreLookup? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final originRaw = json['origin'];
    if (originRaw is! Map) {
      return null;
    }
    final cachedAtRaw = json['cachedAt'] as String?;
    final cachedAt = cachedAtRaw == null
        ? null
        : DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) {
      return null;
    }
    final stores = (json['stores'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => NearbyStore.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return CachedNearbyStoreLookup(
      origin: SearchLocation.fromJson(Map<String, dynamic>.from(originRaw)),
      stores: stores,
      cachedAt: cachedAt,
    );
  }

  bool matchesOrigin(SearchLocation other) {
    final cachedPostalCode = origin.postalCode?.trim();
    final otherPostalCode = other.postalCode?.trim();
    if (cachedPostalCode?.length == 5 && otherPostalCode?.length == 5) {
      return cachedPostalCode == otherPostalCode;
    }

    final cachedQuery = (origin.query ?? origin.label).trim().toLowerCase();
    final otherQuery = (other.query ?? other.label).trim().toLowerCase();
    if (cachedQuery.isNotEmpty && otherQuery.isNotEmpty) {
      return cachedQuery == otherQuery;
    }

    return (origin.latitude - other.latitude).abs() < 0.01 &&
        (origin.longitude - other.longitude).abs() < 0.01;
  }

  bool samePayload(CachedNearbyStoreLookup other) {
    if (!matchesOrigin(other.origin) || stores.length != other.stores.length) {
      return false;
    }

    for (var index = 0; index < stores.length; index++) {
      final currentStore = stores[index];
      final nextStore = other.stores[index];
      if (currentStore.placeId != nextStore.placeId ||
          currentStore.name != nextStore.name ||
          currentStore.address != nextStore.address ||
          currentStore.categories.length != nextStore.categories.length ||
          !currentStore.categories.containsAll(nextStore.categories) ||
          currentStore.primaryCategory != nextStore.primaryCategory ||
          currentStore.discoveryVerification !=
              nextStore.discoveryVerification ||
          currentStore.travelMetric.source != nextStore.travelMetric.source ||
          currentStore.travelMetric.distanceMiles !=
              nextStore.travelMetric.distanceMiles ||
          currentStore.travelMetric.durationMinutes !=
              nextStore.travelMetric.durationMinutes ||
          currentStore.phoneNumber != nextStore.phoneNumber ||
          currentStore.brandKey != nextStore.brandKey ||
          currentStore.linkedGroceryStore?.locationId !=
              nextStore.linkedGroceryStore?.locationId) {
        return false;
      }
    }

    return true;
  }
}

class StoreSearchException implements Exception {
  const StoreSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
