import 'grocery.dart';
import '../value_objects/availability_context.dart';

enum SearchLocationKind { device, address, zipCentroid }

enum DataVerification { live, approximate, unavailable }

enum TravelMetricSource { liveRoute, straightLineApproximate, unavailable }

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

  bool supportsCategory(AvailabilityContext context) {
    return categories.contains(context);
  }

  NearbyStore copyWith({
    Set<AvailabilityContext>? categories,
    AvailabilityContext? primaryCategory,
    DataVerification? discoveryVerification,
    TravelMetric? travelMetric,
    GroceryStore? linkedGroceryStore,
    bool clearLinkedGroceryStore = false,
    String? phoneNumber,
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

class StoreSearchException implements Exception {
  const StoreSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
