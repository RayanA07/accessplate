import 'package:access_plate/domain/engine/decision_engine.dart';
import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/engine/scoring/composite_scorer.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/repositories/food_repository.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/medical_restriction.dart';
import 'package:access_plate/domain/value_objects/prep_environment.dart';
import 'package:access_plate/domain/value_objects/religion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engine produces identical ranking for identical input', () async {
    final repo = _FakeFoodRepository(_foods);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(
        const ReferenceTables(
          rdaTable: {
            'female_19_50': {
              'iron_mg': 18,
              'calcium_mg': 1000,
              'potassium_mg': 2600,
              'magnesium_mg': 310,
              'zinc_mg': 8,
              'vit_a_mcg_rae': 700,
              'vit_c_mg': 75,
              'vit_d_mcg': 15,
              'vit_b12_mcg': 2.4,
              'folate_mcg_dfe': 400,
            },
          },
          medicalModifiers: {},
          microPriorityElevations: {},
          basePenaltyThresholds: {
            'sodium_mg': 750,
            'added_sugar_g': 12,
            'saturated_fat_g': 7,
          },
          basePenaltyWeights: {
            'sodium_mg': 0.4,
            'added_sugar_g': 0.3,
            'saturated_fat_g': 0.3,
          },
        ),
      ),
    );

    final user = UserConstraints.defaults();
    final first = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );
    final second = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(
      first.recommendations.map((item) => item.food.id),
      equals(second.recommendations.map((item) => item.food.id)),
    );
  });
}

class _FakeFoodRepository implements FoodRepository {
  _FakeFoodRepository(this.foods);

  final List<FoodRecord> foods;

  @override
  Future<int> countCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
  }) async {
    return (await findCandidates(
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid,
      maxCost: maxCost,
      environment: environment,
      availability: availability,
    ))
        .length;
  }

  @override
  Future<List<FoodRecord>> findCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
    int limit = 500,
  }) async {
    return foods
        .where((record) => record.food.costEstimate <= maxCost)
        .where((record) => environment.canHandle(record.food.prepMethod))
        .where((record) => record.food.availability.any(availability.contains))
        .take(limit)
        .toList();
  }
}

final _foods = <FoodRecord>[
  _record(
    id: 1,
    name: 'Lentil bowl',
    cost: 4,
    protein: 18,
    fiber: 12,
    sodium: 300,
    iron: 4,
  ),
  _record(
    id: 2,
    name: 'Chicken wrap',
    cost: 6,
    protein: 28,
    fiber: 4,
    sodium: 650,
    iron: 1,
  ),
  _record(
    id: 3,
    name: 'Greek yogurt',
    cost: 3,
    protein: 16,
    fiber: 0,
    sodium: 90,
    iron: 0.5,
    mealTypes: const {MealType.breakfast, MealType.snack},
  ),
];

FoodRecord _record({
  required int id,
  required String name,
  required double cost,
  required double protein,
  required double fiber,
  required double sodium,
  required double iron,
  Set<MealType> mealTypes = const {MealType.lunch, MealType.dinner},
}) {
  return FoodRecord(
    food: Food(
      id: id,
      name: name,
      category: 'prepared_meal',
      servingG: 100,
      servingLabel: '1 serving',
      costEstimate: cost,
      costConfidence: 'high',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: mealTypes,
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'protein'},
    ),
    nutrients: Nutrients(
      caloriesKcal: 400,
      proteinG: protein,
      carbsG: 40,
      fatG: 12,
      saturatedFatG: 2,
      fiberG: fiber,
      sugarG: 5,
      addedSugarG: 1,
      sodiumMg: sodium,
      potassiumMg: 400,
      calciumMg: 80,
      ironMg: iron,
      magnesiumMg: 40,
      zincMg: 1.5,
      vitAMcgRae: 50,
      vitCMg: 4,
      vitDMcg: 0,
      vitB12Mcg: 0.5,
      folateMcgDfe: 80,
    ),
  );
}
