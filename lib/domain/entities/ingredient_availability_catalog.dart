import 'food.dart';
import '../value_objects/availability_context.dart';

class IngredientAvailabilityCatalog {
  const IngredientAvailabilityCatalog(this._contextsByIngredient);

  final Map<String, Set<AvailabilityContext>> _contextsByIngredient;

  factory IngredientAvailabilityCatalog.fromJson(Map<String, dynamic> json) {
    final contextsByIngredient = <String, Set<AvailabilityContext>>{};
    for (final entry in json.entries) {
      final ingredient = _normalize(entry.key);
      if (ingredient.isEmpty) {
        continue;
      }
      final rawContexts = entry.value;
      if (rawContexts is! List) {
        continue;
      }
      final contexts = rawContexts
          .map((value) => AvailabilityContext.fromCode(value.toString()))
          .toSet();
      if (contexts.isEmpty) {
        continue;
      }
      contextsByIngredient[ingredient] = contexts;
    }
    return IngredientAvailabilityCatalog(contextsByIngredient);
  }

  Set<AvailabilityContext> contextsFor(String ingredient) {
    return _contextsByIngredient[_normalize(ingredient)] ?? const {};
  }

  AvailabilityContext? preferredContextForMeal({
    required Food food,
    required Set<AvailabilityContext> enabledContexts,
  }) {
    final mealContexts = food.availability.intersection(enabledContexts);
    if (mealContexts.isEmpty) {
      return null;
    }

    final normalizedIngredients = food.ingredients
        .map(_normalize)
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet();
    if (normalizedIngredients.isEmpty) {
      return _pickPreferred(mealContexts);
    }

    Set<AvailabilityContext>? sharedContexts;
    for (final ingredient in normalizedIngredients) {
      final ingredientContexts = contextsFor(
        ingredient,
      ).intersection(enabledContexts);
      if (ingredientContexts.isEmpty) {
        return null;
      }
      sharedContexts = sharedContexts == null
          ? ingredientContexts
          : sharedContexts.intersection(ingredientContexts);
      if (sharedContexts.isEmpty) {
        return null;
      }
    }

    final supportedMealContexts = sharedContexts!.intersection(mealContexts);
    if (supportedMealContexts.isEmpty) {
      return null;
    }
    return _pickPreferred(supportedMealContexts);
  }

  List<Food> filterSupportedFoods({
    required Iterable<Food> foods,
    required Set<AvailabilityContext> enabledContexts,
  }) {
    return foods
        .where(
          (food) =>
              preferredContextForMeal(
                food: food,
                enabledContexts: enabledContexts,
              ) !=
              null,
        )
        .toList(growable: false);
  }

  AvailabilityContext? _pickPreferred(Set<AvailabilityContext> contexts) {
    for (final context in _priority) {
      if (contexts.contains(context)) {
        return context;
      }
    }
    return null;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static const List<AvailabilityContext> _priority = [
    AvailabilityContext.grocery,
    AvailabilityContext.foodPantry,
    AvailabilityContext.dollarStore,
    AvailabilityContext.convenience,
    AvailabilityContext.fastFood,
  ];
}
