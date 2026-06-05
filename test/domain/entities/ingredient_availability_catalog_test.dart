import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/ingredient_availability_catalog.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = IngredientAvailabilityCatalog.fromJson(const {
    'tuna': ['grocery', 'convenience', 'dollar_store'],
    'bread': ['grocery', 'food_pantry'],
    'beans': ['grocery', 'food_pantry'],
    'rice': ['grocery', 'dollar_store'],
  });

  test('selects a shared offline source for a supported meal', () {
    final food = Food(
      id: 1,
      name: 'Tuna salad on whole-wheat',
      category: 'prepared_meal',
      servingG: 280,
      servingLabel: '1 sandwich',
      costEstimate: 3.5,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.lunch},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'tuna', 'bread'},
      source: 'test',
    );

    expect(
      catalog.preferredContextForMeal(
        food: food,
        enabledContexts: const {
          AvailabilityContext.grocery,
          AvailabilityContext.convenience,
          AvailabilityContext.foodPantry,
        },
      ),
      AvailabilityContext.grocery,
    );
  });

  test('rejects meals without one shared enabled source', () {
    final food = Food(
      id: 2,
      name: 'Bean and rice bowl',
      category: 'prepared_meal',
      servingG: 320,
      servingLabel: '1 bowl',
      costEstimate: 2.8,
      costConfidence: 'medium',
      prepMethod: 'microwave',
      prepTimeMin: 2,
      mealTypes: const {MealType.lunch},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.dollarStore,
        AvailabilityContext.foodPantry,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'beans', 'rice'},
      source: 'test',
    );

    expect(
      catalog.preferredContextForMeal(
        food: food,
        enabledContexts: const {
          AvailabilityContext.foodPantry,
          AvailabilityContext.dollarStore,
        },
      ),
      isNull,
    );
  });
}
