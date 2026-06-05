import 'food.dart';
import 'grocery.dart';
import 'store_search.dart';
import '../value_objects/availability_context.dart';

enum IngredientEvidence { menuItem, structured, estimated }

class IngredientRequirement {
  const IngredientRequirement({
    required this.key,
    required this.label,
    required this.searchTerms,
    required this.pantryAliases,
    required this.evidence,
    this.quantityLabel,
  });

  final String key;
  final String label;
  final List<String> searchTerms;
  final List<String> pantryAliases;
  final IngredientEvidence evidence;
  final String? quantityLabel;

  bool get isEstimated => evidence == IngredientEvidence.estimated;
  bool get isStructured => evidence == IngredientEvidence.structured;
  bool get isMenuItem => evidence == IngredientEvidence.menuItem;
}

class IngredientProductMatch {
  const IngredientProductMatch({
    required this.ingredient,
    required this.products,
  });

  final IngredientRequirement ingredient;
  final List<GroceryProduct> products;

  GroceryProduct? get cheapestProduct =>
      products.isEmpty ? null : products.first;
  double? get cheapestPrice => cheapestProduct?.effectivePrice;
}

class IngredientPlan {
  const IngredientPlan({
    required this.atHome,
    required this.toBuy,
    this.buySummary,
  });

  final List<IngredientRequirement> atHome;
  final List<IngredientRequirement> toBuy;
  final String? buySummary;

  bool get hasEstimatedItems =>
      [...atHome, ...toBuy].any((item) => item.isEstimated);
  bool get hasEstimatedToBuy => toBuy.any((item) => item.isEstimated);
  bool get isOrderOnly =>
      toBuy.isNotEmpty && toBuy.every((item) => item.isMenuItem);
}

class LiveIngredientLookupResult {
  const LiveIngredientLookupResult({
    required this.store,
    required this.matches,
    required this.unmatchedIngredients,
  });

  final GroceryStore store;
  final List<IngredientProductMatch> matches;
  final List<IngredientRequirement> unmatchedIngredients;

  int get matchedCount => matches.length;
  int get unmatchedCount => unmatchedIngredients.length;

  double? get verifiedTotalCost {
    if (unmatchedIngredients.isNotEmpty) {
      return null;
    }

    double total = 0;
    for (final match in matches) {
      final price = match.cheapestPrice;
      if (price == null) {
        return null;
      }
      total += price;
    }
    return total;
  }
}

class LiveStoreMatch {
  const LiveStoreMatch({required this.store, required this.lookup});

  final NearbyStore store;
  final LiveIngredientLookupResult lookup;
}

class MealShoppingPlan {
  const MealShoppingPlan({
    required this.food,
    required this.ingredients,
    required this.chosenStore,
    required this.backupStores,
    required this.candidateStores,
    required this.liveProductMatch,
    this.liveLookupAttempted = false,
    this.storeStatusNote,
    this.offlineAvailabilityContext,
    this.requiredMerchantKey,
    this.requiredMerchantName,
    this.merchantVerified = false,
    this.merchantAlternatives = const [],
  });

  final Food food;
  final IngredientPlan ingredients;
  final NearbyStore? chosenStore;
  final List<NearbyStore> backupStores;
  final List<NearbyStore> candidateStores;
  final LiveStoreMatch? liveProductMatch;
  final bool liveLookupAttempted;
  final String? storeStatusNote;
  final AvailabilityContext? offlineAvailabilityContext;

  /// Brand key this meal requires (e.g. `taco_bell`) when it is a chain-specific
  /// fast-food item; `null` for category-based meals.
  final String? requiredMerchantKey;

  /// Display name of the required brand (e.g. `Taco Bell`).
  final String? requiredMerchantName;

  /// True only when [chosenStore] is a verified store of [requiredMerchantKey].
  final bool merchantVerified;

  /// Nearby fast-food places that do *not* match the required brand. Surfaced
  /// only to honestly say "nearest fast-food options nearby: ..." — never to
  /// stand in for the required merchant.
  final List<NearbyStore> merchantAlternatives;

  /// Whether this meal can only be satisfied by one specific chain.
  bool get isMerchantSpecific => requiredMerchantKey != null;

  bool get hasNearbyStore => chosenStore != null;
  bool get hasLiveProducts =>
      liveProductMatch != null && liveProductMatch!.lookup.matches.isNotEmpty;
  bool get isPrimaryStoreConsistent =>
      liveProductMatch == null ||
      (chosenStore != null &&
          chosenStore!.placeId == liveProductMatch!.store.placeId);

  MealShoppingPlan copyWith({
    IngredientPlan? ingredients,
    NearbyStore? chosenStore,
    bool clearChosenStore = false,
    List<NearbyStore>? backupStores,
    List<NearbyStore>? candidateStores,
    LiveStoreMatch? liveProductMatch,
    bool clearLiveProductMatch = false,
    bool? liveLookupAttempted,
    String? storeStatusNote,
    AvailabilityContext? offlineAvailabilityContext,
    String? requiredMerchantKey,
    String? requiredMerchantName,
    bool? merchantVerified,
    List<NearbyStore>? merchantAlternatives,
  }) {
    return MealShoppingPlan(
      food: food,
      ingredients: ingredients ?? this.ingredients,
      chosenStore: clearChosenStore ? null : chosenStore ?? this.chosenStore,
      backupStores: backupStores ?? this.backupStores,
      candidateStores: candidateStores ?? this.candidateStores,
      liveProductMatch: clearLiveProductMatch
          ? null
          : liveProductMatch ?? this.liveProductMatch,
      liveLookupAttempted: liveLookupAttempted ?? this.liveLookupAttempted,
      storeStatusNote: storeStatusNote ?? this.storeStatusNote,
      offlineAvailabilityContext:
          offlineAvailabilityContext ?? this.offlineAvailabilityContext,
      requiredMerchantKey: requiredMerchantKey ?? this.requiredMerchantKey,
      requiredMerchantName: requiredMerchantName ?? this.requiredMerchantName,
      merchantVerified: merchantVerified ?? this.merchantVerified,
      merchantAlternatives: merchantAlternatives ?? this.merchantAlternatives,
    );
  }
}
