import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device/device_location_service.dart';
import '../../data/device/network_connectivity_service.dart';
import '../../domain/entities/demo_location_seed.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/value_objects/availability_context.dart';
import 'app_bootstrap.dart';
import 'profile_controller.dart';
import 'recommendations_provider.dart';

class ShoppingLocationState {
  const ShoppingLocationState({
    required this.apiConfigured,
    this.loading = false,
    this.location,
    this.error,
    this.lastQuery,
  });

  final bool apiConfigured;
  final bool loading;
  final SearchLocation? location;
  final String? error;
  final String? lastQuery;

  ShoppingLocationState copyWith({
    bool? apiConfigured,
    bool? loading,
    SearchLocation? location,
    bool clearLocation = false,
    String? error,
    bool clearError = false,
    String? lastQuery,
    bool clearLastQuery = false,
  }) {
    return ShoppingLocationState(
      apiConfigured: apiConfigured ?? this.apiConfigured,
      loading: loading ?? this.loading,
      location: clearLocation ? null : location ?? this.location,
      error: clearError ? null : error ?? this.error,
      lastQuery: clearLastQuery ? null : lastQuery ?? this.lastQuery,
    );
  }
}

enum StoreAvailabilityMode { offline, searching, online }

enum StoreAvailabilityFallbackReason {
  apiUnavailable,
  noInternet,
  noLocation,
  noStoresFound,
  searchFailed,
}

class StoreAvailabilityModeState {
  const StoreAvailabilityModeState({
    required this.mode,
    required this.apiConfigured,
    required this.hasInternet,
    this.location,
    this.nearbyStores = const [],
    this.fallbackReason,
    this.lookupError,
  });

  final StoreAvailabilityMode mode;
  final bool apiConfigured;
  final bool hasInternet;
  final SearchLocation? location;
  final List<NearbyStore> nearbyStores;
  final StoreAvailabilityFallbackReason? fallbackReason;
  final String? lookupError;

  bool get isOffline => mode == StoreAvailabilityMode.offline;
  bool get isSearching => mode == StoreAvailabilityMode.searching;
  bool get isOnline => mode == StoreAvailabilityMode.online;
  bool get hasLocation => location != null;
  bool get shouldShowOfflineBanner =>
      isOffline &&
      (fallbackReason == StoreAvailabilityFallbackReason.apiUnavailable ||
          fallbackReason == StoreAvailabilityFallbackReason.noInternet);
  bool get usingDeviceLocation =>
      location != null &&
      location!.kind == SearchLocationKind.device &&
      location!.isLive;
}

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return const DeviceLocationService();
});

final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>(
  (ref) {
    return NetworkConnectivityService();
  },
);

final hasInternetConnectionProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkConnectivityServiceProvider).watchIsOnline();
});

final shoppingLocationControllerProvider =
    StateNotifierProvider<ShoppingLocationController, ShoppingLocationState>((
      ref,
    ) {
      return ShoppingLocationController(ref);
    });

final shoppingLocationStateProvider = Provider<ShoppingLocationState>((ref) {
  return ref.watch(shoppingLocationControllerProvider);
});

class ShoppingLocationController extends StateNotifier<ShoppingLocationState> {
  ShoppingLocationController(this._ref)
    : super(const ShoppingLocationState(apiConfigured: true)) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final bootstrap = await _ref.read(appBootstrapProvider.future);
    state = state.copyWith(
      apiConfigured: bootstrap.storeLocatorRepository.isConfigured,
      loading: false,
      clearError: true,
    );
    if (!bootstrap.storeLocatorRepository.isConfigured) {
      return;
    }

    final profile = await _ref.read(profileControllerProvider.future);
    final postalCode = resolvedAccessPostalCode(
      profile.constraints.access.postalCode,
    );
    final cachedLookup = profile.constraints.cachedNearbyStoreLookup;
    if (cachedLookup != null &&
        (cachedLookup.origin.postalCode == null ||
            cachedLookup.origin.postalCode == postalCode)) {
      state = state.copyWith(
        loading: false,
        location: cachedLookup.origin,
        lastQuery: cachedLookup.origin.query ?? cachedLookup.origin.label,
        clearError: true,
      );
      return;
    }
    final seededLocation = seededSearchLocationForPostalCode(postalCode);
    if (seededLocation != null) {
      state = state.copyWith(
        loading: false,
        location: seededLocation,
        lastQuery: seededLocation.query ?? seededLocation.label,
        clearError: true,
      );
      if (postalCode != profile.constraints.access.postalCode) {
        await _ref
            .read(profileControllerProvider.notifier)
            .updatePostalCode(postalCode);
      }
      return;
    }

    if (postalCode.length == 5) {
      await search(postalCode, persistZip: false);
      return;
    }

    // No cached origin and no usable saved ZIP yet: fall back to the bundled
    // Chicago 60651 demo origin so nearby search has a real, consistent
    // starting point instead of whatever the device/emulator defaults to
    // (e.g. Mountain View 94043).
    state = state.copyWith(
      loading: false,
      location: demoSeedLocation,
      clearLastQuery: true,
      clearError: true,
    );
  }

  Future<void> useDeviceLocation() async {
    if (!state.apiConfigured) {
      state = state.copyWith(
        error: 'Nearby store search is unavailable right now.',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final fix = await _ref
          .read(deviceLocationServiceProvider)
          .determineCurrentLocation();
      final bootstrap = await _ref.read(appBootstrapProvider.future);
      final location = await bootstrap.storeLocatorRepository
          .reverseGeocodeDeviceLocation(fix);
      // Device location drives search from the resolved coordinates and shows a
      // readable label, but must not prefill the typed-query field (especially
      // not with raw lat/lng).
      state = state.copyWith(
        loading: false,
        location: location,
        clearLastQuery: true,
        clearError: true,
      );
    } on StoreSearchException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: 'Device location failed: $error',
      );
    }
  }

  Future<void> search(String query, {bool persistZip = true}) async {
    if (!state.apiConfigured) {
      state = state.copyWith(
        error: 'Nearby store search is unavailable right now.',
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
      lastQuery: query.trim(),
    );
    try {
      final bootstrap = await _ref.read(appBootstrapProvider.future);
      final location = await bootstrap.storeLocatorRepository.geocodeQuery(
        query,
      );
      state = state.copyWith(
        loading: false,
        location: location,
        clearError: true,
      );
      if (persistZip && location.postalCode?.length == 5) {
        await _ref
            .read(profileControllerProvider.notifier)
            .updatePostalCode(location.postalCode!);
      }
    } on StoreSearchException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: 'Location search failed: $error',
      );
    }
  }

  Future<void> clear() async {
    state = state.copyWith(
      clearLocation: true,
      clearError: true,
      clearLastQuery: true,
      loading: false,
    );
    await _ref
        .read(profileControllerProvider.notifier)
        .updateNearbyStoreCache(null);
  }
}

final nearbyStoresProvider = FutureProvider<List<NearbyStore>>((ref) async {
  return _hardcodedDemoStores;
});

final storeAvailabilityModeProvider = Provider<StoreAvailabilityModeState>((
  ref,
) {
  return const StoreAvailabilityModeState(
    mode: StoreAvailabilityMode.online,
    apiConfigured: true,
    hasInternet: true,
    location: demoSeedLocation,
    nearbyStores: _hardcodedDemoStores,
  );
});

final mealShoppingSummariesProvider =
    FutureProvider<Map<int, MealShoppingPlan>>((ref) async {
      final bootstrap = await ref.watch(appBootstrapProvider.future);
      final profile = await ref.watch(profileControllerProvider.future);
      final recommendations = await ref.watch(recommendationsProvider.future);
      List<NearbyStore> nearbyStores;
      try {
        nearbyStores = await ref.watch(nearbyStoresProvider.future);
      } catch (_) {
        nearbyStores = const <NearbyStore>[];
      }
      final availabilityMode = ref.read(storeAvailabilityModeProvider);
      final usableNearbyStores = availabilityMode.isOnline
          ? nearbyStores
          : const <NearbyStore>[];

      final plans = <int, MealShoppingPlan>{};
      for (final recommendation in recommendations.recommendations) {
        final plan = bootstrap.buildMealShoppingPlanUseCase.buildSummary(
          food: recommendation.food,
          constraints: profile.constraints,
          nearbyStores: usableNearbyStores,
        );
        plans[recommendation.food.id] = plan;
      }
      return plans;
    });

final mealShoppingSummaryProvider = Provider.family<MealShoppingPlan?, int>((
  ref,
  foodId,
) {
  final summaries = ref.watch(mealShoppingSummariesProvider).valueOrNull;
  return summaries?[foodId];
});

final prefetchedLiveMealShoppingPlansProvider =
    FutureProvider<Map<int, MealShoppingPlan>>((ref) async {
      final bootstrap = await ref.watch(appBootstrapProvider.future);
      final recommendations = await ref.watch(recommendationsProvider.future);
      final summaries = await ref.watch(mealShoppingSummariesProvider.future);

      final plans = <int, MealShoppingPlan>{};
      for (final recommendation in recommendations.recommendations.take(
        _prefetchedMealPlanCount,
      )) {
        final basePlan = summaries[recommendation.food.id];
        if (basePlan == null) {
          continue;
        }
        final enriched = await bootstrap.buildMealShoppingPlanUseCase
            .enrichWithLiveProducts(basePlan);
        plans[recommendation.food.id] = enriched;
      }
      return plans;
    });

final liveMealShoppingPlanProvider =
    FutureProvider.family<MealShoppingPlan?, int>((ref, foodId) async {
      final bootstrap = await ref.watch(appBootstrapProvider.future);
      final summaries = await ref.watch(mealShoppingSummariesProvider.future);
      final basePlan = summaries[foodId];
      if (basePlan == null) {
        return null;
      }
      return bootstrap.buildMealShoppingPlanUseCase.enrichWithLiveProducts(
        basePlan,
      );
    });

const _prefetchedMealPlanCount = 3;

List<NearbyStore> _cachedStoresFor({
  required CachedNearbyStoreLookup? cachedLookup,
  required SearchLocation origin,
  required Set<AvailabilityContext> categories,
}) {
  if (cachedLookup == null || !cachedLookup.matchesOrigin(origin)) {
    return const [];
  }

  return cachedLookup.stores
      .where((store) => categories.any(store.supportsCategory))
      .toList(growable: false);
}

String? _errorMessageFor(Object? error) {
  if (error == null) {
    return null;
  }
  return error.toString();
}

const _hardcodedDemoStores = <NearbyStore>[
  NearbyStore(
    placeId: 'demo_mcdonalds',
    name: "McDonald's",
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.fastFood},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.2,
    ),
  ),
  NearbyStore(
    placeId: 'demo_dollar_general',
    name: 'Dollar General',
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.dollarStore},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.4,
    ),
  ),
  NearbyStore(
    placeId: 'demo_family_dollar',
    name: 'Family Dollar',
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.dollarStore},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.5,
    ),
  ),
  NearbyStore(
    placeId: 'demo_aldi',
    name: 'Aldi',
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.grocery},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.7,
    ),
  ),
  NearbyStore(
    placeId: 'demo_popeyes',
    name: 'Popeyes',
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.fastFood},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.3,
    ),
  ),
  NearbyStore(
    placeId: 'demo_7eleven',
    name: '7-Eleven',
    address: '3758 W Madison St, Chicago, IL 60624',
    latitude: 41.8798,
    longitude: -87.7272,
    categories: {AvailabilityContext.convenience},
    discoveryVerification: DataVerification.approximate,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 0.1,
    ),
  ),
];
