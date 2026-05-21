import 'package:access_plate/application/services/grocery_query_planner.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final planner = GroceryQueryPlanner();

  test('builds a staple-first search for grocery yogurt foods', () {
    final food = Food(
      id: 4,
      name: 'Greek yogurt with berries and oats',
      category: 'dairy',
      servingG: 180,
      servingLabel: '1 cup',
      costEstimate: 1.8,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.breakfast},
      availability: const {AvailabilityContext.grocery},
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'greek', 'yogurt', 'berries', 'oats'},
    );

    final plans = planner.buildSearchPlans(food);

    expect(plans, isNotEmpty);
    expect(plans.first.term, 'greek yogurt');
    expect(plans.first.exactMatch, isFalse);
    expect(plans.last.term, contains('greek'));
  });

  test('returns no search plan for non-grocery foods', () {
    final food = Food(
      id: 88,
      name: 'Chicken sandwich combo',
      category: 'fast_food',
      servingG: 250,
      servingLabel: '1 combo',
      costEstimate: 6.9,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.lunch},
      availability: const {AvailabilityContext.fastFood},
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'chicken', 'bun', 'fries'},
      source: 'restaurant_menu',
    );

    expect(planner.buildSearchPlans(food), isEmpty);
  });
}
