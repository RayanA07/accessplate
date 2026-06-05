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
    final fastFoodLogo = _fastFoodLogo(food: food, plan: plan);
    if (fastFoodLogo != null) {
      return fastFoodLogo;
    }

    return _storeLogo(food: food, plan: plan, constraints: constraints);
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

    return _logoForText(food.name) ??
        _logoForText(plan?.chosenStore?.name) ??
        _logoForText(plan?.liveProductMatch?.store.name);
  }

  static MealLogoSelection? _storeLogo({
    required Food food,
    MealShoppingPlan? plan,
    UserConstraints? constraints,
  }) {
    final context = plan?.offlineAvailabilityContext;
    final chosenStore = plan?.chosenStore;
    final liveStore = plan?.liveProductMatch?.lookup.store;
    final savedStore = constraints?.feasibility.groceryStore;

    final directMatch =
        _logoForText(liveStore?.name) ??
        _logoForText(chosenStore?.linkedGroceryStore?.name) ??
        _logoForText(chosenStore?.name) ??
        _logoForText(savedStore?.name);
    if (directMatch != null) {
      return directMatch;
    }

    final groceryLike =
        context == AvailabilityContext.grocery ||
        chosenStore?.primaryCategory == AvailabilityContext.grocery ||
        chosenStore?.categories.contains(AvailabilityContext.grocery) == true ||
        food.availability.contains(AvailabilityContext.grocery);
    if (!groceryLike) {
      return null;
    }

    if (liveStore?.retailer == GroceryRetailer.kroger ||
        chosenStore?.linkedGroceryStore?.retailer == GroceryRetailer.kroger ||
        savedStore?.retailer == GroceryRetailer.kroger) {
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
