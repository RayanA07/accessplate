import '../entities/food.dart';
import '../entities/user_constraints.dart';
import '../value_objects/meal_type.dart';
import 'scoring/variety_dampener.dart';

class PreferenceScorer {
  PreferenceScorer({
    required this.preference,
    required this.varietyDampener,
  });

  final PreferenceConstraints preference;
  final VarietyDampener varietyDampener;

  static const Map<String, Set<String>> relatedCuisines = {
    'mexican': {'tex_mex', 'latin_american', 'central_american'},
    'mediterranean': {'greek', 'italian', 'middle_eastern', 'levantine'},
    'asian': {'japanese', 'chinese', 'korean', 'thai', 'vietnamese'},
    'indian': {'south_asian', 'pakistani', 'sri_lankan'},
  };

  double score(Food food) {
    final cuisine = _cuisineScore(food);
    final meal = _mealScore(food);
    final base = (0.6 * cuisine) + (0.4 * meal);
    final varietyFactor = preference.applyVariety
        ? varietyDampener.factorFor(food.id)
        : 1.0;
    return (base * varietyFactor).clamp(0, 1).toDouble();
  }

  double _cuisineScore(Food food) {
    final desired = preference.cuisinePreference;
    if (desired == null || desired.isEmpty || food.cuisine == null) {
      return 0;
    }
    if (food.cuisine == desired) {
      return 1;
    }
    if (relatedCuisines[desired]?.contains(food.cuisine) ?? false) {
      return 0.5;
    }
    return 0;
  }

  double _mealScore(Food food) {
    if (preference.mealType == MealType.any) {
      return 1;
    }
    if (food.mealTypes.contains(preference.mealType) ||
        food.mealTypes.contains(MealType.any)) {
      return 1;
    }
    return 0;
  }
}
