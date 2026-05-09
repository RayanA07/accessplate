import 'package:access_plate/domain/engine/filters/safety_filter.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/religion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('peanut-allergic user never sees peanut-tagged foods', () {
    const filter = SafetyFilter();
    final foods = [
      _food(
        id: 1,
        name: 'Peanut butter sandwich',
        allergens: {Allergen.peanut},
      ),
      _food(
        id: 2,
        name: 'Sunflower butter sandwich',
      ),
    ];

    final result = filter.apply(
      foods,
      const SafetyConstraints(allergens: {Allergen.peanut}),
    );

    expect(result.map((item) => item.food.id), equals([2]));
  });

  test('religious exclusions are enforced', () {
    const filter = SafetyFilter();
    final foods = [
      _food(
        id: 1,
        name: 'Pork tacos',
        religionExcluded: [
          ReligionRule(religion: Religion.halal, reason: 'pork'),
        ],
      ),
      _food(id: 2, name: 'Bean tacos'),
    ];

    final result = filter.apply(
      foods,
      const SafetyConstraints(religion: Religion.halal),
    );

    expect(result.map((item) => item.food.id), equals([2]));
  });
}

FoodRecord _food({
  required int id,
  required String name,
  Set<Allergen> allergens = const {},
  List<ReligionRule> religionExcluded = const [],
}) {
  return FoodRecord(
    food: Food(
      id: id,
      name: name,
      category: 'prepared_meal',
      servingG: 100,
      servingLabel: '1 serving',
      costEstimate: 3,
      costConfidence: 'high',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.lunch},
      availability: const {AvailabilityContext.grocery},
      allergens: allergens,
      religionExcluded: religionExcluded,
      medicalRules: const [],
      ingredients: const {'bread'},
    ),
    nutrients: const Nutrients(
      caloriesKcal: 300,
      proteinG: 15,
      carbsG: 30,
      fatG: 10,
      saturatedFatG: 2,
      fiberG: 4,
      sugarG: 5,
      addedSugarG: 2,
      sodiumMg: 200,
      potassiumMg: 200,
      calciumMg: 50,
      ironMg: 1,
      magnesiumMg: 20,
      zincMg: 1,
      vitAMcgRae: 10,
      vitCMg: 2,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 20,
    ),
  );
}
