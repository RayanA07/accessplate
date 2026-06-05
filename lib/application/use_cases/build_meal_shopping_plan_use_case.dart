import '../../domain/entities/food.dart';
import '../../domain/entities/ingredient_availability_catalog.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';
import '../services/meal_ingredient_planner.dart';
import 'lookup_live_ingredient_products_use_case.dart';

class BuildMealShoppingPlanUseCase {
  BuildMealShoppingPlanUseCase({
    required LookupLiveIngredientProductsUseCase liveProductLookupUseCase,
    required IngredientAvailabilityCatalog ingredientAvailabilityCatalog,
    MealIngredientPlanner? ingredientPlanner,
  }) : _liveProductLookupUseCase = liveProductLookupUseCase,
       _ingredientAvailabilityCatalog = ingredientAvailabilityCatalog,
       _ingredientPlanner = ingredientPlanner ?? const MealIngredientPlanner();

  final LookupLiveIngredientProductsUseCase _liveProductLookupUseCase;
  final IngredientAvailabilityCatalog _ingredientAvailabilityCatalog;
  final MealIngredientPlanner _ingredientPlanner;

  MealShoppingPlan buildSummary({
    required Food food,
    required UserConstraints constraints,
    required List<NearbyStore> nearbyStores,
  }) {
    final ingredientPlan = _ingredientPlanner.build(
      food: food,
      pantry: constraints.pantry,
    );
    final relevantContexts = _relevantContexts(food, constraints);
    final candidateStores = nearbyStores
        .where((store) => relevantContexts.any(store.supportsCategory))
        .toList(growable: false);
    final chosenStore = candidateStores.isEmpty ? null : candidateStores.first;
    final offlineAvailabilityContext =
        _ingredientAvailabilityCatalog.preferredContextForMeal(
          food: food,
          enabledContexts: constraints.feasibility.availability,
        ) ??
        _preferredRelevantContext(relevantContexts);

    return MealShoppingPlan(
      food: food,
      ingredients: ingredientPlan,
      chosenStore: chosenStore,
      backupStores: _backupStores(
        candidateStores: candidateStores,
        chosenStore: chosenStore,
      ),
      candidateStores: candidateStores,
      liveProductMatch: null,
      liveLookupAttempted: false,
      storeStatusNote: _storeStatusNote(
        food: food,
        relevantContexts: relevantContexts,
        chosenStore: chosenStore,
      ),
      offlineAvailabilityContext: offlineAvailabilityContext,
    );
  }

  Future<MealShoppingPlan> enrichWithLiveProducts(
    MealShoppingPlan basePlan,
  ) async {
    if (basePlan.ingredients.toBuy.isEmpty ||
        basePlan.ingredients.isOrderOnly ||
        basePlan.candidateStores.isEmpty) {
      return basePlan.copyWith(liveLookupAttempted: true);
    }

    final liveMatch = await _liveProductLookupUseCase.execute(
      candidateStores: basePlan.candidateStores,
      ingredients: basePlan.ingredients.toBuy,
    );

    final chosenStore = liveMatch?.store ?? basePlan.chosenStore;
    return basePlan.copyWith(
      chosenStore: chosenStore,
      backupStores: _backupStores(
        candidateStores: basePlan.candidateStores,
        chosenStore: chosenStore,
      ),
      liveProductMatch: liveMatch,
      liveLookupAttempted: true,
      storeStatusNote: _refinedStoreStatusNote(
        plan: basePlan,
        chosenStore: chosenStore,
        liveMatch: liveMatch,
      ),
    );
  }

  Set<AvailabilityContext> _relevantContexts(
    Food food,
    UserConstraints constraints,
  ) {
    final contexts = food.availability.intersection(
      constraints.feasibility.availability,
    );
    if (contexts.isEmpty) {
      return const {};
    }

    if (contexts.contains(AvailabilityContext.fastFood) &&
        contexts.length == 1) {
      return const {AvailabilityContext.fastFood};
    }

    if (contexts.contains(AvailabilityContext.grocery)) {
      return const {AvailabilityContext.grocery};
    }

    if (contexts.contains(AvailabilityContext.convenience)) {
      return const {AvailabilityContext.convenience};
    }

    if (contexts.contains(AvailabilityContext.dollarStore)) {
      return const {AvailabilityContext.dollarStore};
    }

    if (contexts.contains(AvailabilityContext.foodPantry)) {
      return const {AvailabilityContext.foodPantry};
    }

    return contexts;
  }

  List<NearbyStore> _backupStores({
    required List<NearbyStore> candidateStores,
    required NearbyStore? chosenStore,
  }) {
    return candidateStores
        .where((store) => store.placeId != chosenStore?.placeId)
        .take(2)
        .toList(growable: false);
  }

  AvailabilityContext? _preferredRelevantContext(
    Set<AvailabilityContext> relevantContexts,
  ) {
    for (final context in const [
      AvailabilityContext.grocery,
      AvailabilityContext.foodPantry,
      AvailabilityContext.dollarStore,
      AvailabilityContext.convenience,
      AvailabilityContext.fastFood,
    ]) {
      if (relevantContexts.contains(context)) {
        return context;
      }
    }
    return null;
  }

  String? _storeStatusNote({
    required Food food,
    required Set<AvailabilityContext> relevantContexts,
    required NearbyStore? chosenStore,
  }) {
    if (chosenStore != null) {
      return null;
    }
    if (relevantContexts.isEmpty) {
      return 'No verified nearby store for this meal type is available.';
    }
    if (food.availability.length == 1 &&
        food.availability.contains(AvailabilityContext.fastFood)) {
      return 'No verified nearby fast-food location was found for this search.';
    }
    return 'Nearby store verification is unavailable for this meal.';
  }

  String? _refinedStoreStatusNote({
    required MealShoppingPlan plan,
    required NearbyStore? chosenStore,
    required LiveStoreMatch? liveMatch,
  }) {
    if (chosenStore == null) {
      return plan.storeStatusNote;
    }
    if (liveMatch == null) {
      return plan.storeStatusNote ??
          'No verified product match was available for this store search.';
    }
    if (liveMatch.lookup.unmatchedIngredients.isEmpty) {
      return null;
    }
    return 'Live products were verified for some items at ${liveMatch.store.name}; unmatched items stay generic.';
  }
}
