import 'package:access_plate/domain/engine/decision_engine.dart';
import 'package:access_plate/domain/engine/access_advisor.dart';
import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/engine/scoring/composite_scorer.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/local_access.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
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
import 'package:access_plate/domain/value_objects/user_language.dart';
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

  test(
    'access-aware explanation and baskets reflect pantry and SNAP reality',
    () async {
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
        pantry: const PantryConstraints(
          stockByItem: {
            'rice': PantryStockLevel.enough,
            'beans': PantryStockLevel.enough,
          },
        ),
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
    },
  );

  test(
    'low and out pantry staples trigger a deterministic restock plan',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 40,
          name: 'Rice and beans bowl',
          cost: 1.8,
          calories: 360,
          protein: 15,
          carbs: 58,
          fat: 3,
          fiber: 10,
          sodium: 260,
          iron: 3.1,
          category: 'legume',
          availability: const {
            AvailabilityContext.foodPantry,
            AvailabilityContext.dollarStore,
            AvailabilityContext.grocery,
          },
          ingredients: const {'rice', 'beans'},
        ),
        _record(
          id: 41,
          name: 'Plain oats cup',
          cost: 1.1,
          calories: 220,
          protein: 7,
          carbs: 39,
          fat: 4,
          fiber: 5,
          sodium: 120,
          iron: 1.6,
          category: 'grain_whole',
          availability: const {
            AvailabilityContext.dollarStore,
            AvailabilityContext.grocery,
          },
          ingredients: const {'oats'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 4,
          availability: {
            AvailabilityContext.foodPantry,
            AvailabilityContext.dollarStore,
            AvailabilityContext.grocery,
          },
        ),
        access: const AccessConstraints(
          transportation: TransportationMode.transit,
          benefitPrograms: {BenefitProgram.snap},
        ),
        pantry: const PantryConstraints(
          stockByItem: {
            'rice': PantryStockLevel.low,
            'beans': PantryStockLevel.out,
            'oats': PantryStockLevel.out,
          },
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.todayPlan, isNotNull);
      expect(result.todayPlan?.type, TodayPlanType.restockRun);
      expect(
        result.todayPlan?.restockItems,
        containsAll(<String>['beans', 'oats']),
      );
      expect(
        result.recommendations.first.explanation?.accessTags,
        containsAll(<String>['Pantry low', 'Restock cue']),
      );
    },
  );

  test(
    'ZIP access snapshot can shift rank order toward a more reachable source',
    () async {
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

      expect(
        easierResult.recommendations.first.food.name,
        'Protein grain bowl',
      );
      expect(
        easierResult.sourceTripPlan?.primarySource,
        AvailabilityContext.grocery,
      );
      expect(
        harderResult.recommendations.first.food.name,
        'Convenience hummus snack box',
      );
      expect(
        harderResult.sourceTripPlan?.primarySource,
        AvailabilityContext.convenience,
      );
      expect(
        harderResult.recommendations.first.explanation?.accessTags,
        contains('Exact ZIP'),
      );
    },
  );

  test(
    'source trip plan can favor shortlist coverage over generic grocery preference',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 50,
          name: 'Dollar oats cup',
          cost: 1.4,
          calories: 240,
          protein: 7,
          carbs: 42,
          fat: 4,
          fiber: 5,
          sodium: 120,
          iron: 1.9,
          category: 'grain_whole',
          availability: const {AvailabilityContext.dollarStore},
          ingredients: const {'oats'},
        ),
        _record(
          id: 51,
          name: 'Dollar beans and rice bowl',
          cost: 2.1,
          calories: 360,
          protein: 14,
          carbs: 58,
          fat: 3,
          fiber: 10,
          sodium: 240,
          iron: 3.3,
          category: 'legume',
          availability: const {AvailabilityContext.dollarStore},
          ingredients: const {'beans', 'rice'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
        accessAdvisor: FoodAccessAdvisor(catalog: _balancedAccessCatalog),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 5,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.dollarStore,
          },
        ),
        access: const AccessConstraints(
          postalCode: '10001',
          transportation: TransportationMode.car,
          maxTravelMinutes: 20,
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.sourceTripPlan, isNotNull);
      expect(
        result.sourceTripPlan?.primarySource,
        AvailabilityContext.dollarStore,
      );
      expect(result.baskets, isNotEmpty);
      expect(
        result.baskets.first.primarySource,
        AvailabilityContext.dollarStore,
      );
      expect(result.sourceTripPlan?.reasons.join(' '), contains('Covers'));
    },
  );

  test('fallback ZIP model is labeled as lower-confidence evidence', () async {
    final repo = _FakeFoodRepository([
      _record(
        id: 53,
        name: 'Simple pantry soup',
        cost: 2.2,
        calories: 260,
        protein: 8,
        carbs: 34,
        fat: 8,
        fiber: 4,
        sodium: 520,
        iron: 1.2,
        availability: const {
          AvailabilityContext.convenience,
          AvailabilityContext.grocery,
        },
        ingredients: const {'soup'},
      ),
    ]);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
      accessAdvisor: FoodAccessAdvisor(catalog: _localAccessCatalog),
    );

    final user = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        maxCostPerMeal: 4,
        availability: {
          AvailabilityContext.convenience,
          AvailabilityContext.grocery,
        },
      ),
      access: const AccessConstraints(
        postalCode: '99999',
        transportation: TransportationMode.walk,
        maxTravelMinutes: 20,
      ),
    );

    final result = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );

    final evidenceFact =
        (result.recommendations.first.explanation?.decisionFacts ??
                const <DecisionFact>[])
            .firstWhere((fact) => fact.label == 'Evidence')
            .value;

    expect(
      evidenceFact,
      'Lower-confidence bundled fallback estimate',
    );
  });

  test(
    'source trip plan avoids pantry-first guidance for deli-style meals',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 55,
          name: 'Hot deli chicken bowl',
          cost: 4.8,
          calories: 520,
          protein: 28,
          carbs: 42,
          fat: 20,
          fiber: 3,
          sodium: 960,
          iron: 1.4,
          category: 'prepared_meal',
          availability: const {
            AvailabilityContext.foodPantry,
            AvailabilityContext.grocery,
          },
          ingredients: const {'chicken', 'rice', 'bowl', 'deli'},
        ),
        _record(
          id: 56,
          name: 'Turkey sandwich combo',
          cost: 4.4,
          calories: 480,
          protein: 24,
          carbs: 40,
          fat: 18,
          fiber: 4,
          sodium: 840,
          iron: 1.2,
          category: 'prepared_meal',
          availability: const {
            AvailabilityContext.foodPantry,
            AvailabilityContext.grocery,
          },
          ingredients: const {'turkey', 'sandwich', 'combo'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
        accessAdvisor: FoodAccessAdvisor(catalog: _pantryBiasAccessCatalog),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 6,
          availability: {
            AvailabilityContext.foodPantry,
            AvailabilityContext.grocery,
          },
        ),
        access: const AccessConstraints(
          postalCode: '20001',
          transportation: TransportationMode.transit,
          maxTravelMinutes: 25,
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.sourceTripPlan, isNotNull);
      expect(result.sourceTripPlan?.primarySource, AvailabilityContext.grocery);
      expect(result.baskets, isNotEmpty);
      expect(result.baskets.first.primarySource, AvailabilityContext.grocery);
    },
  );

  test(
    'benefits-aware source trip surfaces WIC staple coverage clearly',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 57,
          name: 'Store brand milk',
          cost: 3.2,
          calories: 150,
          protein: 8,
          carbs: 12,
          fat: 8,
          fiber: 0,
          sodium: 120,
          iron: 0.1,
          category: 'dairy',
          mealTypes: const {MealType.breakfast, MealType.snack},
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'milk'},
        ),
        _record(
          id: 58,
          name: 'Plain oats canister',
          cost: 2.4,
          calories: 300,
          protein: 10,
          carbs: 54,
          fat: 5,
          fiber: 8,
          sodium: 0,
          iron: 2.3,
          category: 'grain_whole',
          mealTypes: const {MealType.breakfast},
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'oats'},
        ),
        _record(
          id: 59,
          name: 'Convenience chicken sandwich',
          cost: 3.8,
          calories: 430,
          protein: 17,
          carbs: 38,
          fat: 18,
          fiber: 3,
          sodium: 760,
          iron: 1.5,
          availability: const {AvailabilityContext.convenience},
          ingredients: const {'chicken', 'bread', 'sandwich'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
        accessAdvisor: FoodAccessAdvisor(catalog: _wicAccessCatalog),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 5,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.convenience,
          },
        ),
        access: const AccessConstraints(
          postalCode: '60601',
          transportation: TransportationMode.transit,
          maxTravelMinutes: 15,
          benefitPrograms: {BenefitProgram.wic},
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(result.sourceTripPlan?.primarySource, AvailabilityContext.grocery);
      expect(
        result.sourceTripPlan?.highlights,
        contains('WIC staples'),
      );
      expect(result.sourceTripPlan?.reasons.join(' '), contains('WIC'));
    },
  );

  test('snap plan prioritizes staples before pricier caution items', () async {
    final repo = _FakeFoodRepository([
      _record(
        id: 60,
        name: 'Plain oats cup',
        cost: 1.2,
        calories: 220,
        protein: 7,
        carbs: 39,
        fat: 4,
        fiber: 5,
        sodium: 120,
        iron: 1.7,
        category: 'grain_whole',
        availability: const {AvailabilityContext.grocery},
        ingredients: const {'oats'},
      ),
      _record(
        id: 61,
        name: 'Banana',
        cost: 0.4,
        calories: 105,
        protein: 1,
        carbs: 27,
        fat: 0,
        fiber: 3,
        sodium: 1,
        iron: 0.3,
        category: 'fruit',
        availability: const {AvailabilityContext.grocery},
        ingredients: const {'banana'},
      ),
      _record(
        id: 62,
        name: 'Hot deli chicken bowl',
        cost: 4.8,
        calories: 520,
        protein: 28,
        carbs: 42,
        fat: 20,
        fiber: 3,
        sodium: 960,
        iron: 1.4,
        category: 'prepared_meal',
        availability: const {AvailabilityContext.grocery},
        ingredients: const {'chicken', 'rice', 'bowl'},
      ),
    ]);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
    );

    final user = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        maxCostPerMeal: 5,
        availability: {AvailabilityContext.grocery},
      ),
      access: const AccessConstraints(
        transportation: TransportationMode.car,
        benefitPrograms: {BenefitProgram.snap},
      ),
    );

    final result = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(result.todayPlan?.type, TodayPlanType.snapRun);
    expect(result.todayPlan?.checkpoints, hasLength(3));
    expect(
      result.todayPlan?.checkpoints.map((item) => item.title),
      containsAll(<String>['Now', 'Next meal', 'After that']),
    );
    final purchases = result.todayPlan?.purchases ?? const <PlannedPurchase>[];
    expect(
      purchases.any(
        (item) =>
            item.label == 'Plain oats cup' &&
            item.priority == PlannedPurchasePriority.buyFirst,
      ),
      isTrue,
    );
    expect(
      purchases.any(
        (item) =>
            item.label == 'Hot deli chicken bowl' &&
            item.priority == PlannedPurchasePriority.skipFirst,
      ),
      isTrue,
    );
  });

  test('state-aware SNAP restaurant note changes in participating states', () {
    const fastFood = Food(
      id: 65,
      name: 'Fast-food burger',
      category: 'prepared_meal',
      servingG: 180,
      servingLabel: '1 sandwich',
      costEstimate: 4.6,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: {MealType.lunch},
      availability: {AvailabilityContext.fastFood},
      allergens: {},
      religionExcluded: [],
      medicalRules: [],
      ingredients: {'beef', 'bread', 'burger'},
    );

    final accessAdvisor = const FoodAccessAdvisor();

    final californiaUser = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        availability: {AvailabilityContext.fastFood},
        groceryStore: GroceryStore(
          retailer: GroceryRetailer.kroger,
          locationId: 'ca-demo',
          name: 'Demo Store',
          addressLine1: '100 Main St',
          city: 'Los Angeles',
          state: 'CA',
          postalCode: '90011',
        ),
      ),
      access: const AccessConstraints(
        benefitPrograms: {BenefitProgram.snap},
      ),
    );

    final ohioUser = californiaUser.copyWith(
      feasibility: californiaUser.feasibility.copyWith(
        groceryStore: const GroceryStore(
          retailer: GroceryRetailer.kroger,
          locationId: 'oh-demo',
          name: 'Demo Store',
          addressLine1: '100 Main St',
          city: 'Cincinnati',
          state: 'OH',
          postalCode: '45211',
        ),
      ),
    );

    final californiaInsight = accessAdvisor.inspect(
      food: fastFood,
      user: californiaUser,
    );
    final ohioInsight = accessAdvisor.inspect(food: fastFood, user: ohioUser);

    expect(
      californiaInsight.snapSupport?.label,
      'Possible SNAP restaurant meal',
    );
    expect(californiaInsight.snapSupport?.detail, contains('California'));
    expect(ohioInsight.snapSupport?.label, 'Likely not SNAP-friendly');
    expect(ohioInsight.snapSupport?.detail, contains('Ohio'));
  });

  test('state-aware WIC note uses known state list wording', () {
    const groceryStaple = Food(
      id: 66,
      name: 'Milk gallon',
      category: 'dairy',
      servingG: 3780,
      servingLabel: '1 gallon',
      costEstimate: 4.2,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: {MealType.breakfast},
      availability: {AvailabilityContext.grocery},
      allergens: {},
      religionExcluded: [],
      medicalRules: [],
      ingredients: {'milk'},
    );

    final accessAdvisor = const FoodAccessAdvisor();
    final user = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        availability: {AvailabilityContext.grocery},
        groceryStore: GroceryStore(
          retailer: GroceryRetailer.kroger,
          locationId: 'oh-demo',
          name: 'Demo Store',
          addressLine1: '100 Main St',
          city: 'Cincinnati',
          state: 'OH',
          postalCode: '45211',
        ),
      ),
      access: const AccessConstraints(
        benefitPrograms: {BenefitProgram.wic},
      ),
    );

    final insight = accessAdvisor.inspect(food: groceryStaple, user: user);

    expect(insight.wicSupport?.label, 'Likely WIC candidate');
    expect(insight.wicSupport?.detail, contains('Ohio'));
  });

  test(
    'pantry-sourced items stay out of the buy list and show no purchase needed',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 63,
          name: 'Pantry oats cup',
          cost: 1.2,
          calories: 220,
          protein: 7,
          carbs: 39,
          fat: 4,
          fiber: 5,
          sodium: 120,
          iron: 1.7,
          category: 'grain_whole',
          availability: const {
            AvailabilityContext.foodPantry,
            AvailabilityContext.grocery,
          },
          ingredients: const {'oats'},
        ),
        _record(
          id: 64,
          name: 'Banana',
          cost: 0.4,
          calories: 105,
          protein: 1,
          carbs: 27,
          fat: 0,
          fiber: 3,
          sodium: 1,
          iron: 0.3,
          category: 'fruit',
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'banana'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 4,
          availability: {
            AvailabilityContext.foodPantry,
            AvailabilityContext.grocery,
          },
        ),
        access: const AccessConstraints(
          transportation: TransportationMode.walk,
          benefitPrograms: {BenefitProgram.snap},
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      final pantryChoice = result.recommendations.firstWhere(
        (item) => item.food.name == 'Pantry oats cup',
      );
      final benefitFact =
          (pantryChoice.explanation?.decisionFacts ?? const <DecisionFact>[])
              .firstWhere((fact) => fact.label == 'Benefits')
              .value;

      expect(benefitFact, 'No purchase needed');
      expect(
        result.todayPlan?.purchases.any(
          (item) => item.label == 'Pantry oats cup',
        ),
        isFalse,
      );
    },
  );

  test('basket planner can surface a two-meal pantry-stretch basket', () async {
    final repo = _FakeFoodRepository([
      _record(
        id: 80,
        name: 'Rice and beans bowl',
        cost: 2.1,
        calories: 360,
        protein: 14,
        carbs: 58,
        fat: 3,
        fiber: 10,
        sodium: 240,
        iron: 3.3,
        category: 'legume',
        availability: const {AvailabilityContext.dollarStore},
        ingredients: const {'rice', 'beans'},
      ),
      _record(
        id: 81,
        name: 'Plain oats cup',
        cost: 1.2,
        calories: 220,
        protein: 7,
        carbs: 39,
        fat: 4,
        fiber: 5,
        sodium: 120,
        iron: 1.7,
        category: 'grain_whole',
        availability: const {AvailabilityContext.dollarStore},
        ingredients: const {'oats'},
      ),
      _record(
        id: 82,
        name: 'Peanut butter sandwich',
        cost: 1.4,
        calories: 330,
        protein: 11,
        carbs: 32,
        fat: 16,
        fiber: 4,
        sodium: 260,
        iron: 1.9,
        category: 'snack',
        availability: const {AvailabilityContext.dollarStore},
        ingredients: const {'bread', 'peanut'},
      ),
    ]);
    final engine = DecisionEngine(
      repo: repo,
      scoreConfigProvider: ScoreConfigProvider(_tables),
    );

    final user = UserConstraints.defaults().copyWith(
      targets: const NutritionalTargets(
        calories: 500,
        proteinG: 26,
        carbsG: 58,
        fatG: 16,
        fiberG: 8,
      ),
      feasibility: const FeasibilityConstraints(
        maxCostPerMeal: 3,
        availability: {AvailabilityContext.dollarStore},
      ),
      pantry: const PantryConstraints(
        stockByItem: {
          'rice': PantryStockLevel.enough,
          'beans': PantryStockLevel.enough,
        },
      ),
    );

    final result = await engine.recommend(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(result.baskets, isNotEmpty);
    expect(
      result.baskets.any(
        (plan) =>
            plan.estimatedMealsCovered >= 2 &&
            plan.pantrySupportItems.contains('rice'),
      ),
      isTrue,
    );
  });

  test(
    'planning output honors Spanish and plain-language access settings',
    () async {
      final repo = _FakeFoodRepository([
        _record(
          id: 70,
          name: 'Plain oats cup',
          cost: 1.2,
          calories: 220,
          protein: 7,
          carbs: 39,
          fat: 4,
          fiber: 5,
          sodium: 120,
          iron: 1.7,
          category: 'grain_whole',
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'oats'},
        ),
        _record(
          id: 71,
          name: 'Banana',
          cost: 0.4,
          calories: 105,
          protein: 1,
          carbs: 27,
          fat: 0,
          fiber: 3,
          sodium: 1,
          iron: 0.3,
          category: 'fruit',
          availability: const {AvailabilityContext.grocery},
          ingredients: const {'banana'},
        ),
      ]);
      final engine = DecisionEngine(
        repo: repo,
        scoreConfigProvider: ScoreConfigProvider(_tables),
      );

      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 5,
          availability: {AvailabilityContext.grocery},
        ),
        access: const AccessConstraints(
          transportation: TransportationMode.car,
          benefitPrograms: {BenefitProgram.snap},
          language: UserLanguage.spanish,
          plainLanguage: true,
        ),
      );

      final result = await engine.recommend(
        user: user,
        weights: const CompositeWeights(),
      );

      expect(
        result.sourceTripPlan?.title,
        'Mejor primera parada: Tienda de comestibles',
      );
      expect(result.todayPlan?.title, 'Plan de hoy: compra con SNAP');
      expect(
        result.todayPlan?.steps.join(' '),
        anyOf(contains('Empieza con'), contains('Usa SNAP para')),
      );
      expect(
        result.todayPlan?.purchases.first.detail,
        anyOf(
          contains('SNAP'),
          contains('WIC'),
          contains('Empieza aqui.'),
          contains('basico'),
        ),
      );
    },
  );
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
      communityType: CommunityAccessType.innerNeighborhood,
      walkSupport: 0.78,
      transitSupport: 0.68,
      groceryGapSeverity: 0.74,
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
      communityType: CommunityAccessType.suburban,
      walkSupport: 0.6,
      transitSupport: 0.48,
      groceryGapSeverity: 0.46,
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
    communityType: CommunityAccessType.innerNeighborhood,
    walkSupport: 0.72,
    transitSupport: 0.64,
    groceryGapSeverity: 0.72,
    sources: {},
  ),
);

const _balancedAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {
    '10001': LocalAccessProfile(
      profileId: 'balanced',
      label: 'Balanced',
      communityLabel: 'Balanced',
      lowAccessArea: false,
      communityType: CommunityAccessType.denseUrban,
      walkSupport: 0.92,
      transitSupport: 0.94,
      groceryGapSeverity: 0.5,
      sources: {
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.85,
        ),
        AvailabilityContext.dollarStore: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.85,
        ),
      },
    ),
  },
  prefixProfiles: {},
  fallbackProfile: LocalAccessProfile(
    profileId: 'fallback',
    label: 'Fallback',
    communityLabel: 'Fallback',
    lowAccessArea: false,
    communityType: CommunityAccessType.innerNeighborhood,
    walkSupport: 0.78,
    transitSupport: 0.72,
    groceryGapSeverity: 0.38,
    sources: {},
  ),
);

const _pantryBiasAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {
    '20001': LocalAccessProfile(
      profileId: 'pantry_bias',
      label: 'Pantry bias',
      communityLabel: 'Pantry bias',
      lowAccessArea: false,
      communityType: CommunityAccessType.denseUrban,
      walkSupport: 0.84,
      transitSupport: 0.8,
      groceryGapSeverity: 0.34,
      sources: {
        AvailabilityContext.foodPantry: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 10,
          sameDayConfidence: 0.82,
        ),
        AvailabilityContext.grocery: SourceAccessSnapshot(
          nearbyOptions: 2,
          typicalTravelMinutes: 14,
          sameDayConfidence: 0.8,
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
    communityType: CommunityAccessType.innerNeighborhood,
    walkSupport: 0.72,
    transitSupport: 0.64,
    groceryGapSeverity: 0.72,
    sources: {},
  ),
);

const _wicAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {
    '60601': LocalAccessProfile(
      profileId: 'wic_focus',
      label: 'WIC focus',
      communityLabel: 'WIC focus',
      lowAccessArea: false,
      communityType: CommunityAccessType.denseUrban,
      walkSupport: 0.88,
      transitSupport: 0.9,
      groceryGapSeverity: 0.32,
      sources: {
        AvailabilityContext.convenience: SourceAccessSnapshot(
          nearbyOptions: 3,
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
  },
  prefixProfiles: {},
  fallbackProfile: LocalAccessProfile(
    profileId: 'fallback',
    label: 'Fallback',
    communityLabel: 'Fallback',
    lowAccessArea: false,
    communityType: CommunityAccessType.innerNeighborhood,
    walkSupport: 0.78,
    transitSupport: 0.72,
    groceryGapSeverity: 0.38,
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
