import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/application/services/meal_ingredient_planner.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';

void main() {
  const planner = MealIngredientPlanner();

  test('uses structured ingredient definitions when the meal is mapped', () {
    final plan = planner.build(
      food: Food(
        id: 2,
        name: 'Black bean rice bowl',
        category: 'prepared_meal',
        servingG: 320,
        servingLabel: '1 bowl',
        costEstimate: 4.25,
        costConfidence: 'medium',
        prepMethod: 'microwave',
        prepTimeMin: 3,
        mealTypes: const {MealType.lunch},
        availability: const {AvailabilityContext.grocery},
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {'black beans', 'brown rice', 'salsa'},
        source: 'test_fixture',
      ),
      pantry: const PantryConstraints(),
    );

    expect(plan.toBuy, isNotEmpty);
    expect(
      plan.toBuy.every(
        (item) => item.evidence == IngredientEvidence.structured,
      ),
      isTrue,
    );
    expect(plan.hasEstimatedToBuy, isFalse);
  });

  test('labels unmapped meals as estimated fallback ingredients', () {
    final plan = planner.build(
      food: Food(
        id: 999,
        name: 'Lentil spinach skillet',
        category: 'prepared_meal',
        servingG: 300,
        servingLabel: '1 skillet',
        costEstimate: 5.10,
        costConfidence: 'medium',
        prepMethod: 'stovetop',
        prepTimeMin: 10,
        mealTypes: const {MealType.dinner},
        availability: const {AvailabilityContext.grocery},
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {'lentils', 'spinach'},
        source: 'test_fixture',
      ),
      pantry: const PantryConstraints(),
    );

    expect(plan.toBuy, isNotEmpty);
    expect(plan.hasEstimatedToBuy, isTrue);
    expect(
      plan.toBuy.every((item) => item.evidence == IngredientEvidence.estimated),
      isTrue,
    );
  });

  test('bean and cheese wrap uses the updated structured buy list', () {
    final plan = planner.build(
      food: Food(
        id: 96,
        name: 'Bean and cheese wrap',
        category: 'prepared_meal',
        servingG: 266,
        servingLabel: '1 serving',
        costEstimate: 3.0,
        costConfidence: 'high',
        prepMethod: 'microwave',
        prepTimeMin: 2,
        mealTypes: const {MealType.lunch},
        availability: const {AvailabilityContext.grocery},
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {
          'flour tortillas',
          'refried beans',
          'cheese slices',
        },
        source: 'test_fixture',
      ),
      pantry: const PantryConstraints(),
    );

    expect(
      plan.toBuy.map((item) => '${item.label} | ${item.quantityLabel}'),
      orderedEquals([
        'Flour tortillas | 1 pack',
        'Refried beans | 1 can',
        'Cheese slices | 1 pack',
      ]),
    );
  });

  test('refried bean bowl uses the two-chip pantry-style buy list', () {
    final plan = planner.build(
      food: Food(
        id: 187,
        name: 'Refried bean bowl',
        category: 'prepared_meal',
        servingG: 206,
        servingLabel: '1 serving',
        costEstimate: 1.61,
        costConfidence: 'high',
        prepMethod: 'none',
        prepTimeMin: 0,
        mealTypes: const {MealType.lunch},
        availability: const {AvailabilityContext.dollarStore},
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {'refried beans', 'corn tortillas'},
        source: 'test_fixture',
      ),
      pantry: const PantryConstraints(),
    );

    expect(
      plan.toBuy.map((item) => '${item.label} | ${item.quantityLabel}'),
      orderedEquals(['Refried beans | 1 can', 'Corn tortillas | 1 pack']),
    );
  });

  test('tuna and cracker plate uses the updated buy list', () {
    final plan = planner.build(
      food: Food(
        id: 133,
        name: 'Tuna and cracker plate',
        category: 'prepared_meal',
        servingG: 331,
        servingLabel: '1 serving',
        costEstimate: 1.02,
        costConfidence: 'medium',
        prepMethod: 'microwave',
        prepTimeMin: 3,
        mealTypes: const {MealType.lunch},
        availability: const {AvailabilityContext.foodPantry},
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {'tuna', 'crackers'},
        source: 'test_fixture',
      ),
      pantry: const PantryConstraints(),
    );

    expect(
      plan.toBuy.map((item) => '${item.label} | ${item.quantityLabel}'),
      orderedEquals(['Canned tuna | 1 can', 'Saltine crackers | 1 box']),
    );
  });
}
