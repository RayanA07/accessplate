import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device/device_location_service.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
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
  }) {
    return ShoppingLocationState(
      apiConfigured: apiConfigured ?? this.apiConfigured,
      loading: loading ?? this.loading,
      location: clearLocation ? null : location ?? this.location,
      error: clearError ? null : error ?? this.error,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return const DeviceLocationService();
});

final shoppingLocationControllerProvider = StateNotifierProvider<
  ShoppingLocationController,
  ShoppingLocationState
>((ref) {
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
    final postalCode = profile.constraints.access.postalCode.trim();
    if (postalCode.length == 5) {
      await search(postalCode, persistZip: false);
    }
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
      if (location.postalCode?.length == 5) {
        await _ref
            .read(profileControllerProvider.notifier)
            .updatePostalCode(location.postalCode!);
      }
      state = state.copyWith(
        loading: false,
        location: location,
        lastQuery: location.postalCode ?? location.label,
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
      final location = await bootstrap.storeLocatorRepository.geocodeQuery(query);
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

  void clear() {
    state = state.copyWith(
      clearLocation: true,
      clearError: true,
      loading: false,
    );
  }
}

final nearbyStoresProvider = FutureProvider<List<NearbyStore>>((ref) async {
  final locationState = ref.watch(shoppingLocationControllerProvider);
  if (!locationState.apiConfigured || locationState.location == null) {
    return const [];
  }

  final bootstrap = await ref.watch(appBootstrapProvider.future);
  final profile = await ref.watch(profileControllerProvider.future);
  return bootstrap.searchNearbyStoresUseCase.execute(
    origin: locationState.location!,
    categories: profile.constraints.feasibility.availability,
    transportationMode: profile.constraints.access.transportation,
    maxTravelMinutes: profile.constraints.access.maxTravelMinutes,
  );
});

final mealShoppingSummariesProvider =
    FutureProvider<Map<int, MealShoppingPlan>>((ref) async {
      final bootstrap = await ref.watch(appBootstrapProvider.future);
      final profile = await ref.watch(profileControllerProvider.future);
      final recommendations = await ref.watch(recommendationsProvider.future);
      final nearbyStores = await ref.watch(nearbyStoresProvider.future);

      final plans = <int, MealShoppingPlan>{};
      for (final recommendation in recommendations.recommendations) {
        final plan = bootstrap.buildMealShoppingPlanUseCase.buildSummary(
          food: recommendation.food,
          constraints: profile.constraints,
          nearbyStores: nearbyStores,
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
      for (final recommendation
          in recommendations.recommendations.take(_prefetchedMealPlanCount)) {
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
