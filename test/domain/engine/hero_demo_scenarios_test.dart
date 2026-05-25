import 'package:access_plate/domain/engine/access_advisor.dart';
import 'package:access_plate/domain/engine/decision_engine.dart';
import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/engine/scoring/composite_scorer.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/local_access.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/repositories/food_repository.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/prep_environment.dart';
import 'package:access_plate/domain/value_objects/religion.dart';
import 'package:access_plate/domain/value_objects/transportation_mode.dart';
import 'package:access_plate/domain/value_objects/user_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'hero scenario 01 gives a credible emergency first stop and backup',
    () async {
      final result =
          await _engineFor([
            _record(
              id: 101,
              name: 'Convenience tuna cracker kit',
              cost: 3.2,
              protein: 12,
              fiber: 3,
              sodium: 420,
              iron: 1.0,
              category: 'snack',
              availability: const {AvailabilityContext.convenience},
              ingredients: const {'tuna', 'crackers'},
            ),
            _record(
              id: 102,
              name: 'Dollar peanut butter crackers',
              cost: 1.8,
              protein: 8,
              fiber: 2,
              sodium: 280,
              iron: 0.7,
              category: 'snack',
              availability: const {
                AvailabilityContext.dollarStore,
                AvailabilityContext.convenience,
              },
              ingredients: const {'peanut', 'crackers'},
            ),
            _record(
              id: 103,
              name: 'Fast-food burger combo',
              cost: 7.0,
              protein: 20,
              fiber: 2,
              sodium: 980,
              iron: 2.1,
              category: 'prepared_meal',
              availability: const {AvailabilityContext.fastFood},
              ingredients: const {'beef', 'burger', 'fries'},
            ),
          ]).recommend(
            user: UserConstraints.defaults().copyWith(
              feasibility: const FeasibilityConstraints(
                maxCostPerMeal: 8,
                environment: PrepEnvironment.none,
                availability: {
                  AvailabilityContext.convenience,
                  AvailabilityContext.dollarStore,
                  AvailabilityContext.fastFood,
                },
              ),
              access: const AccessConstraints(
                postalCode: '45211',
                transportation: TransportationMode.limited,
                maxTravelMinutes: 10,
                emergencyMode: true,
                plainLanguage: true,
              ),
            ),
            weights: const CompositeWeights(),
          );

      expect(
        result.sourceTripPlan?.primarySource,
        AvailabilityContext.convenience,
      );
      expect(
        result.sourceTripPlan?.confidenceSummary,
        contains('exact bundled ZIP'),
      );
      expect(result.todayPlan?.type, TodayPlanType.emergency);
      expect(result.todayPlan?.summary, contains('fastest low-travel option'));
      expect(
        result.todayPlan?.purchases
            .where((item) => item.priority == PlannedPurchasePriority.skipFirst)
            .map((item) => item.label),
        contains('Fast-food burger combo'),
      );
      expect(result.todayPlan?.backupAction, contains('Backup:'));
    },
  );

  test(
    'hero scenario 02 stays pantry-first and buys only minimal add-ons',
    () async {
      final result =
          await _engineFor([
            _record(
              id: 201,
              name: 'Rice and beans bowl',
              cost: 2.4,
              protein: 14,
              fiber: 10,
              sodium: 250,
              iron: 3.1,
              category: 'legume',
              prepMethod: 'microwave',
              prepTimeMin: 5,
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.dollarStore,
                AvailabilityContext.grocery,
              },
              ingredients: const {'rice', 'beans'},
            ),
            _record(
              id: 202,
              name: 'Plain oats cup',
              cost: 1.4,
              protein: 7,
              fiber: 5,
              sodium: 120,
              iron: 1.7,
              category: 'grain_whole',
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.dollarStore,
                AvailabilityContext.grocery,
              },
              ingredients: const {'oats'},
            ),
            _record(
              id: 203,
              name: 'Banana',
              cost: 0.45,
              protein: 1,
              fiber: 3,
              sodium: 1,
              iron: 0.3,
              calories: 105,
              carbs: 27,
              fat: 0,
              category: 'fruit',
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.dollarStore,
                AvailabilityContext.grocery,
              },
              ingredients: const {'banana'},
            ),
            _record(
              id: 204,
              name: 'Fresh chicken salad',
              cost: 5.8,
              protein: 22,
              fiber: 3,
              sodium: 460,
              iron: 1.4,
              category: 'prepared_meal',
              availability: const {AvailabilityContext.grocery},
              ingredients: const {'chicken', 'salad'},
            ),
          ]).recommend(
            user: UserConstraints.defaults().copyWith(
              feasibility: const FeasibilityConstraints(
                maxCostPerMeal: 12,
                environment: PrepEnvironment.microwave,
                availability: {
                  AvailabilityContext.foodPantry,
                  AvailabilityContext.dollarStore,
                  AvailabilityContext.grocery,
                },
              ),
              access: const AccessConstraints(
                postalCode: '19133',
                transportation: TransportationMode.walk,
                maxTravelMinutes: 15,
                benefitPrograms: {BenefitProgram.snap},
                plainLanguage: true,
              ),
              pantry: const PantryConstraints(
                stockByItem: {
                  'rice': PantryStockLevel.enough,
                  'beans': PantryStockLevel.low,
                  'oats': PantryStockLevel.out,
                },
              ),
            ),
            weights: const CompositeWeights(),
          );

      expect(
        result.sourceTripPlan?.primarySource,
        AvailabilityContext.foodPantry,
      );
      expect(result.sourceTripPlan?.benefitSummary, contains('no purchase'));
      expect(result.todayPlan?.type, TodayPlanType.pantryFirst);
      expect(result.todayPlan?.steps.first, contains('rice'));
      expect(
        result.todayPlan?.summary,
        contains('Stretch food you already have'),
      );
      expect(
        result.todayPlan?.purchases.map((item) => item.label),
        isNot(contains('Rice and beans bowl')),
      );
      expect(
        result.baskets.any(
          (basket) => basket.pantrySupportItems.contains('rice'),
        ),
        isTrue,
      );
    },
  );

  test(
    'hero scenario 03 stays SNAP-aware instead of collapsing into generic restock',
    () async {
      final result =
          await _engineFor([
            _record(
              id: 301,
              name: 'Dollar beans and rice bag',
              cost: 2.3,
              protein: 14,
              fiber: 10,
              sodium: 240,
              iron: 3.3,
              category: 'legume',
              prepMethod: 'stove',
              prepTimeMin: 10,
              availability: const {
                AvailabilityContext.dollarStore,
                AvailabilityContext.grocery,
              },
              ingredients: const {'beans', 'rice'},
            ),
            _record(
              id: 302,
              name: 'Dollar oats tub',
              cost: 2.1,
              protein: 8,
              fiber: 6,
              sodium: 90,
              iron: 2.1,
              category: 'grain_whole',
              availability: const {
                AvailabilityContext.dollarStore,
                AvailabilityContext.grocery,
              },
              ingredients: const {'oats'},
            ),
            _record(
              id: 303,
              name: 'Prepared chicken deli plate',
              cost: 6.2,
              protein: 21,
              fiber: 1,
              sodium: 840,
              iron: 1.2,
              category: 'prepared_meal',
              availability: const {AvailabilityContext.convenience},
              ingredients: const {'chicken', 'deli'},
            ),
          ]).recommend(
            user: UserConstraints.defaults().copyWith(
              feasibility: const FeasibilityConstraints(
                maxCostPerMeal: 15,
                environment: PrepEnvironment.stoveTop,
                availability: {
                  AvailabilityContext.dollarStore,
                  AvailabilityContext.grocery,
                  AvailabilityContext.convenience,
                },
              ),
              access: const AccessConstraints(
                postalCode: '77026',
                transportation: TransportationMode.transit,
                maxTravelMinutes: 20,
                benefitPrograms: {BenefitProgram.snap},
                plainLanguage: false,
              ),
              pantry: const PantryConstraints(
                stockByItem: {
                  'oil': PantryStockLevel.enough,
                  'seasoning': PantryStockLevel.enough,
                  'rice': PantryStockLevel.low,
                },
              ),
            ),
            weights: const CompositeWeights(),
          );

      expect(
        result.sourceTripPlan?.primarySource,
        AvailabilityContext.dollarStore,
      );
      expect(result.sourceTripPlan?.mission, SourceTripMission.benefitsRun);
      expect(result.todayPlan?.type, TodayPlanType.snapRun);
      expect(result.todayPlan?.benefitSummary, contains('SNAP'));
      expect(
        result.todayPlan?.purchases
            .where((item) => item.priority == PlannedPurchasePriority.buyFirst)
            .map((item) => item.label),
        containsAll(<String>['Dollar beans and rice bag', 'Dollar oats tub']),
      );
      expect(
        result.todayPlan?.purchases
            .where((item) => item.priority == PlannedPurchasePriority.skipFirst)
            .map((item) => item.label),
        contains('Prepared chicken deli plate'),
      );
    },
  );

  test('hero scenario 04 chooses grocery as the stronger WIC stop', () async {
    final result =
        await _engineFor([
          _record(
            id: 401,
            name: 'Milk gallon',
            cost: 4.2,
            protein: 24,
            fiber: 0,
            sodium: 280,
            iron: 0.2,
            calories: 300,
            carbs: 36,
            fat: 8,
            saturatedFat: 5,
            category: 'dairy',
            mealTypes: const {MealType.breakfast, MealType.lunch},
            availability: const {AvailabilityContext.grocery},
            ingredients: const {'milk'},
          ),
          _record(
            id: 402,
            name: 'Whole grain cereal box',
            cost: 3.8,
            protein: 6,
            fiber: 6,
            sodium: 190,
            iron: 6,
            calories: 220,
            carbs: 44,
            fat: 3,
            category: 'grain_whole',
            mealTypes: const {MealType.breakfast, MealType.lunch},
            availability: const {
              AvailabilityContext.grocery,
              AvailabilityContext.convenience,
            },
            ingredients: const {'cereal', 'oats'},
          ),
          _record(
            id: 403,
            name: 'Convenience mac cup',
            cost: 2.4,
            protein: 6,
            fiber: 1,
            sodium: 620,
            iron: 1.1,
            category: 'prepared_meal',
            mealTypes: const {MealType.breakfast, MealType.lunch},
            availability: const {AvailabilityContext.convenience},
            ingredients: const {'pasta', 'cheese'},
          ),
        ]).recommend(
          user: UserConstraints.defaults().copyWith(
            feasibility: const FeasibilityConstraints(
              maxCostPerMeal: 10,
              environment: PrepEnvironment.microwave,
              availability: {
                AvailabilityContext.convenience,
                AvailabilityContext.grocery,
              },
            ),
            preference: const PreferenceConstraints(
              mealType: MealType.breakfast,
            ),
            access: const AccessConstraints(
              postalCode: '90011',
              transportation: TransportationMode.transit,
              maxTravelMinutes: 20,
              benefitPrograms: {BenefitProgram.wic},
              plainLanguage: true,
            ),
            pantry: const PantryConstraints(
              stockByItem: {
                'cereal': PantryStockLevel.low,
                'milk': PantryStockLevel.out,
              },
            ),
          ),
          weights: const CompositeWeights(),
        );

    expect(result.sourceTripPlan?.primarySource, AvailabilityContext.grocery);
    expect(result.sourceTripPlan?.mission, SourceTripMission.benefitsRun);
    expect(result.todayPlan?.type, TodayPlanType.wicStaples);
    expect(result.todayPlan?.steps.join(' '), contains('California'));
    expect(
      result.recommendations
          .map(
            (item) => item.explanation?.decisionFacts
                .firstWhere((fact) => fact.label == 'Benefits')
                .value,
          )
          .join(' | '),
      contains('Likely WIC candidate'),
    );
    expect(
      result.todayPlan?.purchases
          .where((item) => item.priority == PlannedPurchasePriority.skipFirst)
          .map((item) => item.label),
      contains('Convenience mac cup'),
    );
  });

  test(
    'hero scenario 05 keeps the core plan clear in Spanish plain-language mode',
    () async {
      final result =
          await _engineFor([
            _record(
              id: 501,
              name: 'Rice and beans bowl',
              cost: 2.1,
              protein: 14,
              fiber: 10,
              sodium: 240,
              iron: 3.3,
              category: 'legume',
              prepMethod: 'microwave',
              prepTimeMin: 5,
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.grocery,
              },
              ingredients: const {'rice', 'beans'},
            ),
            _record(
              id: 502,
              name: 'Plain oats cup',
              cost: 1.3,
              protein: 7,
              fiber: 5,
              sodium: 120,
              iron: 1.7,
              category: 'grain_whole',
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.convenience,
                AvailabilityContext.grocery,
              },
              ingredients: const {'oats'},
            ),
            _record(
              id: 503,
              name: 'Banana',
              cost: 0.4,
              protein: 1,
              fiber: 3,
              sodium: 1,
              iron: 0.3,
              calories: 105,
              carbs: 27,
              fat: 0,
              category: 'fruit',
              availability: const {
                AvailabilityContext.foodPantry,
                AvailabilityContext.convenience,
              },
              ingredients: const {'banana'},
            ),
          ]).recommend(
            user: UserConstraints.defaults().copyWith(
              feasibility: const FeasibilityConstraints(
                maxCostPerMeal: 10,
                environment: PrepEnvironment.microwave,
                availability: {
                  AvailabilityContext.foodPantry,
                  AvailabilityContext.convenience,
                  AvailabilityContext.grocery,
                },
              ),
              access: const AccessConstraints(
                postalCode: '60623',
                transportation: TransportationMode.limited,
                maxTravelMinutes: 12,
                benefitPrograms: {BenefitProgram.snap},
                language: UserLanguage.spanish,
                plainLanguage: true,
              ),
              pantry: const PantryConstraints(
                stockByItem: {
                  'rice': PantryStockLevel.enough,
                  'beans': PantryStockLevel.low,
                  'oats': PantryStockLevel.out,
                },
              ),
            ),
            weights: const CompositeWeights(),
          );

      expect(result.sourceTripPlan?.title, startsWith('Mejor primera parada:'));
      expect(
        result.sourceTripPlan?.dataSourceSummary,
        contains('datos ZIP incluidos'),
      );
      expect(result.todayPlan?.title, startsWith('Plan de hoy:'));
      expect(result.todayPlan?.routeReason, contains('mas realista'));
      expect(result.todayPlan?.backupAction, startsWith('Respaldo:'));
      expect(
        result.todayPlan?.steps.first,
        anyOf(contains('Usa'), contains('Empieza')),
      );
    },
  );
}

DecisionEngine _engineFor(List<FoodRecord> foods) {
  const accessCatalog = _heroAccessCatalog;
  return DecisionEngine(
    repo: _FakeFoodRepository(foods),
    scoreConfigProvider: ScoreConfigProvider(_tables),
    accessAdvisor: const FoodAccessAdvisor(catalog: accessCatalog),
  );
}

class _FakeFoodRepository implements FoodRepository {
  _FakeFoodRepository(this.foods);

  final List<FoodRecord> foods;

  @override
  Future<int> countCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<dynamic> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
  }) async {
    return (await findCandidates(
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid.cast(),
      maxCost: maxCost,
      environment: environment,
      availability: availability,
    )).length;
  }

  @override
  Future<List<FoodRecord>> findCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<dynamic> medicalAvoid,
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
);

const _heroAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {
    '45211': LocalAccessProfile(
      profileId: 'westwood_demo',
      label: 'Westwood',
      communityLabel: 'Westwood',
      stateCode: 'OH',
      lowAccessArea: true,
      communityType: CommunityAccessType.innerNeighborhood,
      walkSupport: 0.78,
      transitSupport: 0.68,
      groceryGapSeverity: 0.74,
      sources: {
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 5,
          typicalTravelMinutes: 6,
          sameDayConfidence: 0.92,
        ),
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.86,
        ),
        AvailabilityContext.fastFood: SourceAccessSnapshot(
          nearbyOptions: 4,
          typicalTravelMinutes: 7,
          sameDayConfidence: 0.83,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 1,
          typicalTravelMinutes: 24,
          sameDayConfidence: 0.58,
        ),
      },
    ),
    '19133': LocalAccessProfile(
      profileId: 'fairhill_demo',
      label: 'Fairhill',
      communityLabel: 'Fairhill',
      stateCode: 'PA',
      lowAccessArea: true,
      communityType: CommunityAccessType.innerNeighborhood,
      walkSupport: 0.82,
      transitSupport: 0.74,
      groceryGapSeverity: 0.72,
      sources: {
        AvailabilityContext.foodPantry: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.9,
        ),
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.84,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 1,
          typicalTravelMinutes: 21,
          sameDayConfidence: 0.62,
        ),
      },
    ),
    '77026': LocalAccessProfile(
      profileId: 'fifth_ward_demo',
      label: 'Fifth Ward',
      communityLabel: 'Fifth Ward',
      stateCode: 'TX',
      lowAccessArea: true,
      communityType: CommunityAccessType.innerNeighborhood,
      walkSupport: 0.7,
      transitSupport: 0.8,
      groceryGapSeverity: 0.68,
      sources: {
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.88,
        ),
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 4,
          typicalTravelMinutes: 9,
          sameDayConfidence: 0.86,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 16,
          sameDayConfidence: 0.74,
        ),
      },
    ),
    '90011': LocalAccessProfile(
      profileId: 'south_la_demo',
      label: 'South Los Angeles',
      communityLabel: 'South Los Angeles',
      stateCode: 'CA',
      lowAccessArea: true,
      communityType: CommunityAccessType.denseUrban,
      walkSupport: 0.76,
      transitSupport: 0.88,
      groceryGapSeverity: 0.58,
      sources: {
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 4,
          typicalTravelMinutes: 6,
          sameDayConfidence: 0.9,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 11,
          sameDayConfidence: 0.86,
        ),
      },
    ),
    '60623': LocalAccessProfile(
      profileId: 'little_village_demo',
      label: 'Little Village',
      communityLabel: 'Little Village',
      stateCode: 'IL',
      lowAccessArea: true,
      communityType: CommunityAccessType.denseUrban,
      walkSupport: 0.8,
      transitSupport: 0.76,
      groceryGapSeverity: 0.65,
      sources: {
        AvailabilityContext.foodPantry: SourceAccessSnapshot(
          nearbyOptions: 3,
          typicalTravelMinutes: 7,
          sameDayConfidence: 0.9,
        ),
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 4,
          typicalTravelMinutes: 8,
          sameDayConfidence: 0.86,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 18,
          sameDayConfidence: 0.7,
        ),
      },
    ),
  },
  prefixProfiles: {},
  fallbackProfile: LocalAccessProfile(
    profileId: 'fallback_demo',
    label: 'Fallback',
    communityLabel: 'Fallback',
    lowAccessArea: true,
    communityType: CommunityAccessType.innerNeighborhood,
    walkSupport: 0.72,
    transitSupport: 0.64,
    groceryGapSeverity: 0.72,
    sources: {},
  ),
);

FoodRecord _record({
  required int id,
  required String name,
  required double cost,
  required double protein,
  required double fiber,
  required double sodium,
  required double iron,
  double calories = 320,
  double carbs = 38,
  double fat = 8,
  double saturatedFat = 2,
  double sugar = 5,
  double addedSugar = 0,
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
  String prepMethod = 'none',
  int prepTimeMin = 0,
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
      prepMethod: prepMethod,
      prepTimeMin: prepTimeMin,
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
