import '../../domain/entities/food.dart';
import '../../domain/entities/grocery.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';

class MealLogoSelection {
  const MealLogoSelection({
    required this.assetPath,
    required this.label,
    required this.isFastFood,
  });

  final String assetPath;
  final String label;
  final bool isFastFood;
}

abstract final class MealLogoResolver {
  static const MealLogoSelection _burgerKing = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/burger_king.png',
    label: 'Burger King',
    isFastFood: true,
  );

  static const MealLogoSelection _chickFilA = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/chick_fil_a.png',
    label: 'Chick-fil-A',
    isFastFood: true,
  );

  static const MealLogoSelection _chipotle = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/chipotle.png',
    label: 'Chipotle',
    isFastFood: true,
  );

  static const MealLogoSelection _tacoBell = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/taco_bell.png',
    label: 'Taco Bell',
    isFastFood: true,
  );

  static const MealLogoSelection _kroger = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/kroger.png',
    label: 'Kroger',
    isFastFood: false,
  );

  static const MealLogoSelection _mcdonalds = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/mcdonalds.png',
    label: 'McDonald\'s',
    isFastFood: true,
  );

  static const MealLogoSelection _safeway = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/safeway.png',
    label: 'Safeway',
    isFastFood: false,
  );

  static const MealLogoSelection _subway = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/subway.png',
    label: 'Subway',
    isFastFood: true,
  );

  static const MealLogoSelection _wendys = MealLogoSelection(
    assetPath: 'assets/branding/meal_logos/wendys.png',
    label: 'Wendy\'s',
    isFastFood: true,
  );

  static MealLogoSelection? resolve({
    required Food food,
    MealShoppingPlan? plan,
    UserConstraints? constraints,
  }) {
    return _fastFoodLogo(food: food, plan: plan);
  }

  static MealLogoSelection? _fastFoodLogo({
    required Food food,
    MealShoppingPlan? plan,
  }) {
    final behavesLikeFastFood =
        food.availability.contains(AvailabilityContext.fastFood) ||
        plan?.offlineAvailabilityContext == AvailabilityContext.fastFood ||
        plan?.chosenStore?.primaryCategory == AvailabilityContext.fastFood;
    if (!behavesLikeFastFood) {
      return null;
    }

    // Prefer the structured brand key derived at seed time over fragile name
    // string heuristics. The chosen store is merchant-verified by the planner,
    // so its name is a safe secondary source.
    return _logoForBrandKey(food.merchantBrandKey) ??
        _logoForBrandKey(plan?.requiredMerchantKey) ??
        _logoForText(food.name) ??
        _logoForText(plan?.chosenStore?.name) ??
        _logoForText(plan?.liveProductMatch?.store.name);
  }

  static const Map<String, MealLogoSelection> _logosByBrandKey = {
    'burger_king': _burgerKing,
    'chick_fil_a': _chickFilA,
    'chipotle': _chipotle,
    'taco_bell': _tacoBell,
    'mcdonalds': _mcdonalds,
    'subway': _subway,
    'wendys': _wendys,
  };

  static MealLogoSelection? _logoForBrandKey(String? brandKey) {
    if (brandKey == null) {
      return null;
    }
    return _logosByBrandKey[brandKey];
  }

  static MealLogoSelection? _storeLogo({MealShoppingPlan? plan}) {
    final chosenStore = plan?.chosenStore;
    final liveStore = plan?.liveProductMatch?.lookup.store;

    // Only surface a store-brand logo for a store we have actually matched this
    // meal to (a verified live product store or the chosen nearby store). The
    // user's *saved* grocery store is deliberately NOT used here: showing, say,
    // the Safeway logo on a dollar-store item is a brand mismatch. When nothing
    // is verified we return null and the thumbnail falls back to neutral meal
    // art rather than a misleading store brand.
    final directMatch =
        _logoForText(liveStore?.name) ??
        _logoForText(chosenStore?.linkedGroceryStore?.name) ??
        _logoForText(chosenStore?.name);
    if (directMatch != null) {
      return directMatch;
    }

    final chosenIsGrocery =
        chosenStore?.primaryCategory == AvailabilityContext.grocery ||
        chosenStore?.categories.contains(AvailabilityContext.grocery) == true;
    if (liveStore?.retailer == GroceryRetailer.kroger ||
        (chosenIsGrocery &&
            chosenStore?.linkedGroceryStore?.retailer ==
                GroceryRetailer.kroger)) {
      return _kroger;
    }

    return null;
  }

  static MealLogoSelection? _logoForText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = _compactText(value);
    if (normalized.contains('burgerking')) {
      return _burgerKing;
    }
    if (normalized.contains('chickfila')) {
      return _chickFilA;
    }
    if (normalized.contains('chipotle')) {
      return _chipotle;
    }
    if (normalized.contains('kroger')) {
      return _kroger;
    }
    if (normalized.contains('mcdonalds')) {
      return _mcdonalds;
    }
    if (normalized.contains('safeway')) {
      return _safeway;
    }
    if (normalized.contains('subway')) {
      return _subway;
    }
    if (normalized.contains('tacobell')) {
      return _tacoBell;
    }
    if (normalized.contains('wendys')) {
      return _wendys;
    }
    return null;
  }

  static String _compactText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
