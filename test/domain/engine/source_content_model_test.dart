import 'package:access_plate/domain/engine/source_content_model.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = SourceContentModel();

  test('shelf-stable staples fit pantry and dollar-store runs better', () {
    final staple = _food(
      id: 1,
      name: 'Rice and beans pack',
      category: 'legume',
      ingredients: const {'rice', 'beans'},
      mealTypes: const {MealType.lunch, MealType.dinner},
    );

    expect(
      model.fitForFood(staple, AvailabilityContext.foodPantry),
      greaterThan(model.fitForFood(staple, AvailabilityContext.fastFood)),
    );
    expect(
      model.fitForFood(staple, AvailabilityContext.dollarStore),
      greaterThan(model.fitForFood(staple, AvailabilityContext.convenience)),
    );
  });

  test('deli-style prepared meals fit grocery better than food pantry', () {
    final deliMeal = _food(
      id: 2,
      name: 'Hot deli chicken bowl',
      category: 'prepared_meal',
      ingredients: const {'chicken', 'rice', 'bowl', 'deli'},
      mealTypes: const {MealType.lunch, MealType.dinner},
    );

    expect(
      model.fitForFood(deliMeal, AvailabilityContext.grocery),
      greaterThan(model.fitForFood(deliMeal, AvailabilityContext.foodPantry)),
    );
    expect(
      model.strongFitForFood(deliMeal, AvailabilityContext.grocery),
      isTrue,
    );
    expect(
      model.strongFitForFood(deliMeal, AvailabilityContext.foodPantry),
      isFalse,
    );
  });
}

Food _food({
  required int id,
  required String name,
  required String category,
  required Set<String> ingredients,
  required Set<MealType> mealTypes,
}) {
  return Food(
    id: id,
    name: name,
    category: category,
    servingG: 100,
    servingLabel: '1 serving',
    costEstimate: 3.5,
    costConfidence: 'medium',
    prepMethod: 'none',
    prepTimeMin: 0,
    mealTypes: mealTypes,
    availability: AvailabilityContext.values.toSet(),
    allergens: const <Allergen>{},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: ingredients,
  );
}
