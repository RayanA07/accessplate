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
      plan.toBuy.every((item) => item.evidence == IngredientEvidence.structured),
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
}
