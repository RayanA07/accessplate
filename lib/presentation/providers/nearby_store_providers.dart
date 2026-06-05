import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/build_meal_shopping_plan_use_case.dart';
import '../../data/device/device_location_service.dart';
import '../../data/device/network_connectivity_service.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/demo_location_seed.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';
import 'app_bootstrap.dart';
import 'demo_meals_store_data.dart';
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
    return useDeviceLocationWithFallback();
  }

  Future<void> useDeviceLocationWithFallback({
    bool fallbackToDefaultOnFailure = false,
  }) async {
    if (!state.apiConfigured) {
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
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
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
      state = state.copyWith(
        loading: false,
        error: 'Device location failed: $error',
      );
    }
  }

  Future<void> search(
    String query, {
    bool persistZip = true,
    bool fallbackToDefaultOnFailure = false,
  }) async {
    if (!state.apiConfigured) {
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
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
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      if (fallbackToDefaultOnFailure) {
        useDefaultFallback();
        return;
      }
      state = state.copyWith(
        loading: false,
        error: 'Location search failed: $error',
      );
    }
  }

  void useDefaultFallback({bool clearLastQuery = true}) {
    state = state.copyWith(
      loading: false,
      location: demoSeedLocation,
      clearLastQuery: clearLastQuery,
      clearError: true,
    );
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
  final locationState = ref.watch(shoppingLocationControllerProvider);
  if (!locationState.apiConfigured || locationState.location == null) {
    return const [];
  }

  final bootstrap = await ref.watch(appBootstrapProvider.future);
  final profile = await ref.watch(profileControllerProvider.future);
  final origin = locationState.location!;
  final cachedLookup = profile.constraints.cachedNearbyStoreLookup;
  final hasInternet = ref.watch(hasInternetConnectionProvider).value ?? true;
  final cachedStores = _cachedStoresFor(
    cachedLookup: cachedLookup,
    origin: origin,
    categories: profile.constraints.feasibility.availability,
  );
  if (!hasInternet && cachedStores.isNotEmpty) {
    return cachedStores;
  }

  try {
    return _loadNearbyStores(
      ref: ref,
      bootstrap: bootstrap,
      profile: profile,
      origin: origin,
    );
  } catch (error) {
    if (cachedStores.isNotEmpty) {
      return cachedStores;
    }
    if (isDemoSeedLocation(origin)) {
      return const [];
    }

    ref.read(shoppingLocationControllerProvider.notifier).useDefaultFallback();
    if (!hasInternet) {
      return const [];
    }

    final fallbackCachedStores = _cachedStoresFor(
      cachedLookup: profile.constraints.cachedNearbyStoreLookup,
      origin: demoSeedLocation,
      categories: profile.constraints.feasibility.availability,
    );
    if (fallbackCachedStores.isNotEmpty) {
      return fallbackCachedStores;
    }

    try {
      return await _loadNearbyStores(
        ref: ref,
        bootstrap: bootstrap,
        profile: profile,
        origin: demoSeedLocation,
      );
    } catch (_) {
      return const [];
    }
  }
});

final storeAvailabilityModeProvider = Provider<StoreAvailabilityModeState>((
  ref,
) {
  return const StoreAvailabilityModeState(
    mode: StoreAvailabilityMode.online,
    apiConfigured: true,
    hasInternet: true,
    location: demoMealsLocation,
    nearbyStores: demoMealsNearbyStores,
  );
});

final mealShoppingSummariesProvider =
    FutureProvider<Map<int, MealShoppingPlan>>((ref) async {
      final bootstrap = await ref.watch(appBootstrapProvider.future);
      final profile = await ref.watch(profileControllerProvider.future);
      final recommendations = await ref.watch(recommendationsProvider.future);

      final plans = <int, MealShoppingPlan>{};
      for (final recommendation in recommendations.recommendations) {
        final plan = _buildDemoMealShoppingPlan(
          buildMealShoppingPlanUseCase: bootstrap.buildMealShoppingPlanUseCase,
          food: recommendation.food,
          constraints: profile.constraints,
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
      final summaries = await ref.watch(mealShoppingSummariesProvider.future);
      return summaries;
    });

final liveMealShoppingPlanProvider =
    FutureProvider.family<MealShoppingPlan?, int>((ref, foodId) async {
      final summaries = await ref.watch(mealShoppingSummariesProvider.future);
      return summaries[foodId];
    });

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

MealShoppingPlan _buildDemoMealShoppingPlan({
  required BuildMealShoppingPlanUseCase buildMealShoppingPlanUseCase,
  required Food food,
  required UserConstraints constraints,
}) {
  final context = _demoStoreContextFor(food, constraints);
  final candidateStores = demoMealsStoresForContext(context);
  final basePlan = buildMealShoppingPlanUseCase.buildSummary(
    food: food,
    constraints: constraints,
    nearbyStores: candidateStores,
  );
  final chosenStore =
      basePlan.chosenStore ??
      (candidateStores.isEmpty ? null : candidateStores.first);
  final backupStores = chosenStore == null
      ? const <NearbyStore>[]
      : candidateStores
            .where((store) => store.placeId != chosenStore.placeId)
            .take(2)
            .toList(growable: false);

  return basePlan.copyWith(
    chosenStore: chosenStore,
    backupStores: backupStores,
    candidateStores: candidateStores,
    liveLookupAttempted: true,
    storeStatusNote: chosenStore == null ? basePlan.storeStatusNote : null,
    merchantAlternatives: const <NearbyStore>[],
  );
}

AvailabilityContext _demoStoreContextFor(
  Food food,
  UserConstraints constraints,
) {
  final enabled = food.availability.intersection(
    constraints.feasibility.availability,
  );
  if (food.isMerchantSpecific ||
      (enabled.contains(AvailabilityContext.fastFood) && enabled.length == 1)) {
    return AvailabilityContext.fastFood;
  }

  for (final context in const [
    AvailabilityContext.grocery,
    AvailabilityContext.convenience,
    AvailabilityContext.dollarStore,
    AvailabilityContext.fastFood,
  ]) {
    if (enabled.contains(context)) {
      return context;
    }
  }

  if (enabled.contains(AvailabilityContext.foodPantry)) {
    return AvailabilityContext.grocery;
  }
  return AvailabilityContext.grocery;
}

Future<List<NearbyStore>> _loadNearbyStores({
  required Ref ref,
  required AppBootstrap bootstrap,
  required UserProfile profile,
  required SearchLocation origin,
}) async {
  final stores = await bootstrap.searchNearbyStoresUseCase
      .execute(
        origin: origin,
        categories: profile.constraints.feasibility.availability,
        transportationMode: profile.constraints.access.transportation,
        maxTravelMinutes: profile.constraints.access.maxTravelMinutes,
      )
      .timeout(_nearbyStoreLookupTimeout);
  await ref
      .read(profileControllerProvider.notifier)
      .updateNearbyStoreCache(
        CachedNearbyStoreLookup(
          origin: origin,
          stores: stores,
          cachedAt: DateTime.now().toUtc(),
        ),
      );
  return stores;
}

const _nearbyStoreLookupTimeout = Duration(seconds: 8);
