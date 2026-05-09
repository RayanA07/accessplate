import '../../entities/food.dart';
import '../../entities/user_constraints.dart';
import '../../value_objects/meal_type.dart';

class PreferenceFilter {
  const PreferenceFilter();

  List<FoodRecord> apply(
    List<FoodRecord> foods,
    PreferenceConstraints preference,
  ) {
    Iterable<FoodRecord> filtered = foods;

    if (preference.dislikedIngredients.isNotEmpty) {
      filtered = filtered.where((record) {
        return !preference.dislikedIngredients.any(
          record.food.ingredients.contains,
        );
      });
    }

    if (preference.mealType != MealType.any) {
      filtered = filtered.where((record) {
        return record.food.mealTypes.contains(preference.mealType) ||
            record.food.mealTypes.contains(MealType.any);
      });
    }

    return filtered.toList();
  }
}
