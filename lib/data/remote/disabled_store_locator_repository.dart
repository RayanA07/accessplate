import '../../domain/entities/store_search.dart';
import '../../domain/repositories/store_locator_repository.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/transportation_mode.dart';

class DisabledStoreLocatorRepository implements StoreLocatorRepository {
  const DisabledStoreLocatorRepository();

  @override
  bool get isConfigured => false;

  @override
  Future<Map<String, TravelMetric>> computeTravelMetrics({
    required SearchLocation origin,
    required Iterable<NearbyStore> stores,
    required TransportationMode transportationMode,
  }) async {
    return const {};
  }

  @override
  Future<SearchLocation> geocodeQuery(String query) async {
    throw const StoreSearchException(
      'Live nearby-store search is not configured for this build.',
    );
  }

  @override
  Future<SearchLocation> reverseGeocodeDeviceLocation(
    DeviceLocationFix fix,
  ) async {
    throw const StoreSearchException(
      'Live nearby-store search is not configured for this build.',
    );
  }

  @override
  Future<List<NearbyStore>> searchNearbyStores({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required int radiusMeters,
    int limitPerCategory = 4,
  }) async {
    return const [];
  }
}
