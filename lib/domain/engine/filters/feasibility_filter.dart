import '../../entities/food.dart';
import '../../entities/user_constraints.dart';

class FeasibilityFilter {
  const FeasibilityFilter();

  List<FoodRecord> apply(
    List<FoodRecord> foods,
    FeasibilityConstraints feasibility,
  ) {
    return foods.where((record) {
      final food = record.food;
      if (food.costEstimate > feasibility.maxCostPerMeal) {
        return false;
      }
      if (!feasibility.environment.canHandle(food.prepMethod)) {
        return false;
      }
      if (!food.availability.any(feasibility.availability.contains)) {
        return false;
      }
      return true;
    }).toList();
  }
}
