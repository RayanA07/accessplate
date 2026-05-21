import 'package:access_plate/domain/engine/decision_engine.dart';
import 'package:access_plate/domain/engine/access_advisor.dart';
import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/engine/scoring/composite_scorer.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/local_access.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/repositories/food_repository.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/domain/value_objects/dietary_style.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/medical_restriction.dart';
import 'package:access_plate/domain/value_objects/prep_environment.dart';
import 'package:access_plate/domain/value_objects/religion.dart';
import 'package:access_plate/domain/value_objects/transportation_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engine produces identical ranking for identical input', () async {
    final repo = _FakeFoodRepository(_foods);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
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

  test(
    'vegetarian filter excludes fish and meat even when pool is small',
    () async {
      final repo = _FakeFoodRepository(_foods);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        preference: const PreferenceConstraints(
          dietaryStyle: DietaryStyle.vegetarian,
          mealType: MealType.lunch,
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.recommendations, isNotEmpty);
      expect(
        result.recommendations.every((item) => item.food.isVegetarian),
        isTrue,
      );
      expect(
        result.recommendations.map((item) => item.food.name),
        isNot(contains('Chicken wrap')),
      );
    },
  );

  test(
    'high-protein targets keep macro-aligned meals ahead of low-protein alternatives',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 10,
          name: 'Chips and guac platter',
          category: 'snack',
          cost: 2.5,
          calories: 640,
          protein: 12,
          carbs: 56,
          fat: 22,
          fiber: 10,
          sodium: 180,
          iron: 18,
          potassium: 2600,
          calcium: 1000,
          magnesium: 310,
          zinc: 8,
          vitA: 700,
          vitC: 75,
          vitB12: 2.4,
          folate: 400,
          mealTypes: const {MealType.snack, MealType.lunch},
          ingredients: const {'chips', 'guacamole'},
        ),
        _record(
          id: 11,
          name: 'Chicken rice bowl',
          cost: 8.5,
          calories: 620,
          protein: 34,
          carbs: 52,
          fat: 22,
          fiber: 9,
          sodium: 980,
          iron: 1,
          potassium: 250,
          calcium: 40,
          magnesium: 20,
          zinc: 1,
          vitA: 30,
          vitC: 4,
          vitB12: 0.5,
          folate: 60,
          ingredients: const {'chicken', 'rice', 'bowl'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        targets: const NutritionalTargets(
          calories: 650,
          proteinG: 52,
          carbsG: 57,
          fatG: 22,
          fiberG: 10,
        ),
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 10,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.convenience,
          },
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.recommendations, hasLength(2));
      expect(result.recommendations.first.food.name, 'Chicken rice bowl');
      expect(result.recommendations.last.food.name, 'Chips and guac platter');
    },
  );

  test(
    'tight budgets favor cheaper good-enough meals over pricier closer matches',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 12,
          name: 'Dollar-store bean rice cup',
          cost: 2.25,
          calories: 340,
          protein: 17,
          carbs: 48,
          fat: 4,
          fiber: 10,
          sodium: 280,
          iron: 3.2,
          availability: const {
            AvailabilityContext.convenience,
            AvailabilityContext.dollarStore,
            AvailabilityContext.foodPantry,
          },
          ingredients: const {'beans', 'rice', 'cup'},
        ),
        _record(
          id: 13,
          name: 'Turkey quinoa bowl',
          cost: 4.9,
          calories: 450,
          protein: 30,
          carbs: 50,
          fat: 14,
          fiber: 8,
          sodium: 290,
          iron: 2.0,
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'turkey', 'quinoa', 'bowl'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        targets: const NutritionalTargets(
          calories: 460,
          proteinG: 30,
          carbsG: 52,
          fatG: 14,
          fiberG: 10,
        ),
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 5,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.convenience,
            AvailabilityContext.foodPantry,
            AvailabilityContext.dollarStore,
          },
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.recommendations, hasLength(2));
      expect(
        result.recommendations.first.food.name,
        'Dollar-store bean rice cup',
      );
      expect(result.recommendations.last.food.name, 'Turkey quinoa bowl');
    },
  );

  test('access-aware explanation and baskets reflect pantry and SNAP reality', () async {
    final repo = _FakeFoodRepository([
      _record(
        id: 20,
        name: 'Rice & beans (canned)',
        cost: 1.2,
        calories: 320,
        protein: 14,
        carbs: 53,
        fat: 3,
        fiber: 11,
        sodium: 260,
        iron: 3.4,
        category: 'legume',
        availability: const {
          AvailabilityContext.foodPantry,
          AvailabilityContext.dollarStore,
          AvailabilityContext.grocery,
        },
        ingredients: const {'rice', 'beans'},
      ),
      _record(
        id: 21,
        name: 'Banana',
        cost: 0.3,
        calories: 110,
        protein: 1,
        carbs: 28,
        fat: 0,
        fiber: 3,
        sodium: 1,
        iron: 0.4,
        category: 'fruit',
        availability: const {
          AvailabilityContext.foodPantry,
          AvailabilityContext.dollarStore,
          AvailabilityContext.convenience,
        },
        ingredients: const {'banana'},
      ),
      _record(
        id: 22,
        name: 'Chicken combo meal',
        cost: 5.5,
        calories: 680,
        protein: 29,
        carbs: 72,
        fat: 25,
        fiber: 4,
        sodium: 980,
        iron: 1.2,
        availability: const {AvailabilityContext.fastFood},
        ingredients: const {'chicken', 'combo'},
      ),
    ]);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
    );

    final user = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        maxCostPerMeal: 3,
        availability: {
          AvailabilityContext.foodPantry,
          AvailabilityContext.dollarStore,
          AvailabilityContext.convenience,
          AvailabilityContext.fastFood,
        },
      ),
      access: const AccessConstraints(
        transportation: TransportationMode.limited,
        benefitPrograms: {BenefitProgram.snap},
        emergencyMode: true,
      ),
      pantry: const PantryConstraints(itemsOnHand: {'rice', 'beans'}),
    );

    final result = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(result.recommendations.first.food.name, 'Rice & beans (canned)');
      expect(
        result.recommendations.first.explanation?.accessTags,
      containsAll(<String>['Food pantry', 'Pantry match', 'Emergency fit']),
      );
    expect(result.baskets, isNotEmpty);
    expect(
      result.baskets.any(
        (plan) =>
            plan.title.contains('Emergency') ||
            plan.highlights.contains('Emergency fit'),
      ),
      isTrue,
    );
    expect(result.todayPlan, isNotNull);
    expect(result.todayPlan?.title, contains('emergency'));
  });

  test('ZIP access snapshot can shift rank order toward a more reachable source', () async {
    final repo = _FakeFoodRepository([
      _record(
        id: 30,
        name: 'Protein grain bowl',
        cost: 4.6,
        calories: 460,
        protein: 29,
        carbs: 50,
        fat: 11,
        fiber: 9,
        sodium: 280,
        iron: 2.4,
        availability: const {AvailabilityContext.grocery},
        ingredients: const {'grain', 'bowl'},
      ),
      _record(
        id: 31,
        name: 'Convenience hummus snack box',
        cost: 4.0,
        calories: 390,
        protein: 16,
        carbs: 39,
        fat: 15,
        fiber: 7,
        sodium: 300,
        iron: 1.8,
        availability: const {
          AvailabilityContext.convenience,
          AvailabilityContext.dollarStore,
        },
        ingredients: const {'hummus', 'crackers'},
      ),
    ]);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
      accessAdvisor: FoodAccessAdvisor(catalog: _localAccessCatalog),
    );

    final baseUser = UserConstraints.defaults().copyWith(
      targets: const NutritionalTargets(
        calories: 450,
        proteinG: 28,
        carbsG: 52,
        fatG: 13,
        fiberG: 9,
      ),
      feasibility: const FeasibilityConstraints(
        maxCostPerMeal: 5,
        availability: {
          AvailabilityContext.grocery,
          AvailabilityContext.convenience,
          AvailabilityContext.dollarStore,
        },
      ),
      access: const AccessConstraints(
        transportation: TransportationMode.car,
        maxTravelMinutes: 25,
      ),
    );

    final easierGroceryZip = baseUser.copyWith(
      access: baseUser.access.copyWith(postalCode: '45238'),
    );
    final harderGroceryZip = baseUser.copyWith(
      access: baseUser.access.copyWith(postalCode: '45211'),
    );

    final easierResult = await engine.recommend(
      user: easierGroceryZip,
      weights: const CompositeWeights(),
    );
    final harderResult = await engine.recommend(
      user: harderGroceryZip,
      weights: const CompositeWeights(),
    );

    expect(easierResult.recommendations.first.food.name, 'Protein grain bowl');
    expect(
      harderResult.recommendations.first.food.name,
      'Convenience hummus snack box',
    );
    expect(
      harderResult.recommendations.first.explanation?.accessTags,
      contains('Exact ZIP'),
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
    )).length;
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

  @override
  Future<void> touchFoods(Iterable<int> ids) async {}
}

const _tables = ReferenceTables(
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
  microPriorityElevations: {
    'vegetarian': {'iron_mg': 1.2},
  },
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
);

const _localAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {
    '45211': LocalAccessProfile(
      profileId: 'westwood',
      label: 'Westwood',
      communityLabel: 'Westwood',
      lowAccessArea: true,
      sources: {
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 5,
          typicalTravelMinutes: 7,
          sameDayConfidence: 0.9,
        ),
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.85,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 1,
          typicalTravelMinutes: 26,
          sameDayConfidence: 0.58,
        ),
      },
    ),
    '45238': LocalAccessProfile(
      profileId: 'delhi',
      label: 'Delhi',
      communityLabel: 'Delhi Township',
      lowAccessArea: false,
      sources: {
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.84,
        ),
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.8,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.94,
        ),
      },
    ),
  },
  prefixProfiles: {},
  fallbackProfile: LocalAccessProfile(
    profileId: 'fallback',
    label: 'Fallback',
    communityLabel: 'Fallback',
    lowAccessArea: true,
    sources: {},
  ),
);

final _foods = <FoodRecord>[
  _record(
    id: 1,
    name: 'Lentil bowl',
    cost: 4,
    protein: 18,
    fiber: 12,
    sodium: 300,
    iron: 4,
    ingredients: const {'lentil', 'bowl'},
  ),
  _record(
    id: 2,
    name: 'Chicken wrap',
    cost: 6,
    protein: 28,
    fiber: 4,
    sodium: 650,
    iron: 1,
    ingredients: const {'chicken', 'wrap'},
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
    allergens: const {Allergen.dairy},
    ingredients: const {'greek', 'yogurt'},
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
  double calories = 400,
  double carbs = 40,
  double fat = 12,
  double saturatedFat = 2,
  double sugar = 5,
  double addedSugar = 1,
  double potassium = 400,
  double calcium = 80,
  double magnesium = 40,
  double zinc = 1.5,
  double vitA = 50,
  double vitC = 4,
  double vitD = 0,
  double vitB12 = 0.5,
  double folate = 80,
  Set<MealType> mealTypes = const {MealType.lunch, MealType.dinner},
  String category = 'prepared_meal',
  Set<AvailabilityContext> availability = const {
    AvailabilityContext.grocery,
    AvailabilityContext.convenience,
  },
  Set<Allergen> allergens = const {},
  Set<String> ingredients = const {'protein'},
}) {
  return FoodRecord(
    food: Food(
      id: id,
      name: name,
      category: category,
      servingG: 100,
      servingLabel: '1 serving',
      costEstimate: cost,
      costConfidence: 'high',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: mealTypes,
      availability: availability,
      allergens: allergens,
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: ingredients,
    ),
    nutrients: Nutrients(
      caloriesKcal: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      saturatedFatG: saturatedFat,
      fiberG: fiber,
      sugarG: sugar,
      addedSugarG: addedSugar,
      sodiumMg: sodium,
      potassiumMg: potassium,
      calciumMg: calcium,
      ironMg: iron,
      magnesiumMg: magnesium,
      zincMg: zinc,
      vitAMcgRae: vitA,
      vitCMg: vitC,
      vitDMcg: vitD,
      vitB12Mcg: vitB12,
      folateMcgDfe: folate,
    ),
  );
}
