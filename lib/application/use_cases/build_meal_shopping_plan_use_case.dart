import '../../domain/entities/food.dart';
import '../../domain/entities/ingredient_availability_catalog.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/merchant_brand.dart';
import '../services/meal_ingredient_planner.dart';
import 'lookup_live_ingredient_products_use_case.dart';

class BuildMealShoppingPlanUseCase {
  BuildMealShoppingPlanUseCase({
    required LookupLiveIngredientProductsUseCase liveProductLookupUseCase,
    required IngredientAvailabilityCatalog ingredientAvailabilityCatalog,
    MealIngredientPlanner? ingredientPlanner,
    MerchantBrandCatalog merchantBrandCatalog = MerchantBrandCatalog.defaults,
  }) : _liveProductLookupUseCase = liveProductLookupUseCase,
       _ingredientAvailabilityCatalog = ingredientAvailabilityCatalog,
       _ingredientPlanner = ingredientPlanner ?? const MealIngredientPlanner(),
       _merchantBrandCatalog = merchantBrandCatalog;

  final LookupLiveIngredientProductsUseCase _liveProductLookupUseCase;
  final IngredientAvailabilityCatalog _ingredientAvailabilityCatalog;
  final MealIngredientPlanner _ingredientPlanner;
  final MerchantBrandCatalog _merchantBrandCatalog;

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

    // Separate category matching from merchant matching. A chain-specific
    // fast-food meal (e.g. a Taco Bell bowl) may only be tied to a nearby store
    // of the same brand. It must never fall back to "the nearest fast-food
    // place" — that is exactly how a Taco Bell meal ended up showing Marco's
    // Pizza. Generic/grocery meals keep the simple nearest-in-category choice.
    final requiredMerchantKey = food.merchantBrandKey;
    final requiredMerchantName = _merchantBrandCatalog
        .brandForKey(requiredMerchantKey)
        ?.displayName;
    final isMerchantSpecific = requiredMerchantKey != null;

    NearbyStore? chosenStore;
    var merchantVerified = false;
    var merchantAlternatives = const <NearbyStore>[];
    if (isMerchantSpecific) {
      final brandMatches = candidateStores
          .where((store) => store.matchesMerchant(requiredMerchantKey))
          .toList(growable: false);
      if (brandMatches.isNotEmpty) {
        // candidateStores arrive distance-sorted, so first == nearest match.
        chosenStore = brandMatches.first;
        merchantVerified = true;
      } else {
        // No verified brand nearby: keep chosenStore null and remember the
        // other fast-food places only so the UI can name them as alternatives.
        merchantAlternatives = candidateStores.take(3).toList(growable: false);
      }
    } else {
      chosenStore = candidateStores.isEmpty ? null : candidateStores.first;
    }

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
        // For a verified chain meal, backups are only other same-brand stores.
        // For an unverified chain meal there are no valid backups (wrong-brand
        // places must not masquerade as backups). Generic meals use all
        // candidates.
        candidateStores: isMerchantSpecific
            ? (merchantVerified
                  ? candidateStores
                        .where((s) => s.matchesMerchant(requiredMerchantKey))
                        .toList(growable: false)
                  : const <NearbyStore>[])
            : candidateStores,
        chosenStore: chosenStore,
      ),
      candidateStores: candidateStores,
      liveProductMatch: null,
      liveLookupAttempted: false,
      storeStatusNote: _storeStatusNote(
        food: food,
        relevantContexts: relevantContexts,
        chosenStore: chosenStore,
        requiredMerchantName: requiredMerchantName,
        isMerchantSpecific: isMerchantSpecific,
        merchantAlternatives: merchantAlternatives,
      ),
      offlineAvailabilityContext: offlineAvailabilityContext,
      requiredMerchantKey: requiredMerchantKey,
      requiredMerchantName: requiredMerchantName,
      merchantVerified: merchantVerified,
      merchantAlternatives: merchantAlternatives,
    );
  }

  Future<MealShoppingPlan> enrichWithLiveProducts(
    MealShoppingPlan basePlan,
  ) async {
    if (basePlan.ingredients.toBuy.isEmpty ||
        basePlan.ingredients.isOrderOnly ||
        basePlan.isMerchantSpecific ||
        basePlan.candidateStores.isEmpty) {
      // Chain-specific fast-food meals are never enriched with live grocery
      // products, and live lookups must never reassign their store.
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
    required String? requiredMerchantName,
    required bool isMerchantSpecific,
    required List<NearbyStore> merchantAlternatives,
  }) {
    if (chosenStore != null) {
      return null;
    }
    if (isMerchantSpecific) {
      final brand = requiredMerchantName ?? 'this restaurant';
      final base = 'No nearby $brand verified for this search.';
      if (merchantAlternatives.isEmpty) {
        return base;
      }
      final names = merchantAlternatives
          .take(2)
          .map((store) => store.name)
          .join(', ');
      return '$base Nearest fast-food options nearby: $names.';
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
