import '../entities/store_search.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/transportation_mode.dart';

abstract class StoreLocatorRepository {
  bool get isConfigured;

  Future<SearchLocation> geocodeQuery(String query);

  Future<SearchLocation> reverseGeocodeDeviceLocation(DeviceLocationFix fix);

  Future<List<NearbyStore>> searchNearbyStores({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    int limitPerCategory = 4,
  });

  Future<Map<String, TravelMetric>> computeTravelMetrics({
    required SearchLocation origin,
    required Iterable<NearbyStore> stores,
    required TransportationMode transportationMode,
  });
}
