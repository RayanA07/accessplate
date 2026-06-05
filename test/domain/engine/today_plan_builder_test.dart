import 'package:access_plate/domain/engine/today_plan_builder.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodayPlanBuilder', () {
    test('returns null when there are no recommendations', () {
      final plan = TodayPlanBuilder(
        user: UserConstraints.defaults(),
      ).build(recommendations: const [], baskets: const []);

      expect(plan, isNull);
    });

    test(
      'pantry-first uses a pantry-ready basket lead and ignores incompatible trip copy',
      () {
        final user = UserConstraints.defaults().copyWith(
          feasibility: const FeasibilityConstraints(
            maxCostPerMeal: 6,
            availability: {
              AvailabilityContext.dollarStore,
              AvailabilityContext.grocery,
            },
          ),
          pantry: const PantryConstraints(
            stockByItem: {
              'rice': PantryStockLevel.enough,
              'salt': PantryStockLevel.enough,
              'beans': PantryStockLevel.out,
            },
          ),
        );

        final basketLead = _scoredFood(
          id: 3,
          name: 'Rice and beans bowl',
          cost: 2.0,
          category: 'legume',
          ingredients: const {'rice', 'beans'},
          availability: const {AvailabilityContext.dollarStore},
        );
        final basketAddOn = _scoredFood(
          id: 4,
          name: 'Banana',
          cost: 0.4,
          category: 'fruit',
          ingredients: const {'banana'},
          availability: const {AvailabilityContext.dollarStore},
        );
        final basket = _basket(
          items: [basketLead, basketAddOn],
          primarySource: AvailabilityContext.dollarStore,
        );

        final plan = TodayPlanBuilder(user: user).build(
          recommendations: [
            _scoredFood(
              id: 1,
              name: 'Trail mix pouch',
              cost: 2.5,
              category: 'snack',
              ingredients: const {'nuts'},
            ),
            _scoredFood(
              id: 2,
              name: 'Soup cup',
              cost: 2.2,
              category: 'prepared_meal',
              ingredients: const {'soup'},
            ),
          ],
          baskets: [basket],
          sourceTripPlan: const SourceTripPlan(
            mission: SourceTripMission.benefitsRun,
            primarySource: AvailabilityContext.grocery,
            title: 'Injected source plan',
            summary: 'Injected source summary',
            reasons: [],
            highlights: [],
            routeReason: 'Injected benefits route reason',
            benefitSummary: 'Injected benefits summary',
          ),
        );

        expect(plan, isNotNull);
        expect(plan?.type, TodayPlanType.pantryFirst);
        expect(plan?.leadRecommendation.food.name, 'Rice and beans bowl');
        expect(plan?.steps.first, contains('rice'));
        expect(plan?.steps.join(' ').toLowerCase(), contains('dollar store'));
        expect(plan?.steps.join(' ').toLowerCase(), isNot(contains('grocery')));
        expect(plan?.routeReason, isNot('Injected benefits route reason'));
        expect(plan?.benefitSummary, isNot('Injected benefits summary'));
      },
    );

    test('severe pantry shortage takes precedence over a WIC staples run', () {
      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 6,
          availability: {AvailabilityContext.grocery},
        ),
        access: const AccessConstraints(benefitPrograms: {BenefitProgram.wic}),
        pantry: const PantryConstraints(
          stockByItem: {
            'salt': PantryStockLevel.enough,
            'oats': PantryStockLevel.out,
            'beans': PantryStockLevel.out,
          },
        ),
      );

      final plan = TodayPlanBuilder(user: user).build(
        recommendations: [
          _scoredFood(
            id: 10,
            name: 'Milk gallon',
            cost: 4.2,
            category: 'dairy',
            ingredients: const {'milk'},
          ),
          _scoredFood(
            id: 11,
            name: 'Plain oats cup',
            cost: 1.2,
            category: 'grain_whole',
            ingredients: const {'oats'},
          ),
          _scoredFood(
            id: 12,
            name: 'Beans pouch',
            cost: 1.4,
            category: 'legume',
            ingredients: const {'beans'},
          ),
        ],
        baskets: const [],
      );

      expect(plan, isNotNull);
      expect(plan?.type, TodayPlanType.restockRun);
      expect(plan?.restockItems, containsAll(<String>['beans', 'oats']));
    });

    test('WIC restock purchases stay secondary to the core staple pick', () {
      final user = UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 6,
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
        access: const AccessConstraints(benefitPrograms: {BenefitProgram.wic}),
        pantry: const PantryConstraints(
          stockByItem: {
            'oil': PantryStockLevel.enough,
            'salt': PantryStockLevel.enough,
            'oats': PantryStockLevel.out,
          },
        ),
      );

      final plan = TodayPlanBuilder(user: user).build(
        recommendations: [
          _scoredFood(
            id: 20,
            name: 'Milk gallon',
            cost: 4.2,
            category: 'dairy',
            ingredients: const {'milk'},
          ),
          _scoredFood(
            id: 21,
            name: 'Plain oats cup',
            cost: 1.2,
            category: 'grain_whole',
            ingredients: const {'oats'},
          ),
          _scoredFood(
            id: 22,
            name: 'Banana',
            cost: 0.4,
            category: 'fruit',
            ingredients: const {'banana'},
          ),
        ],
        baskets: const [],
      );

      expect(plan, isNotNull);
      expect(plan?.type, TodayPlanType.wicStaples);
      expect(
        plan?.purchases.any(
          (item) => item.priority == PlannedPurchasePriority.buyFirst,
        ),
        isTrue,
      );
      expect(
        plan?.purchases.firstWhere((item) => item.label == 'oats').priority,
        PlannedPurchasePriority.ifBudgetLeft,
      );
    });

    test(
      'benefit enrollment without positive support falls back to the one-stop basket',
      () {
        final user = UserConstraints.defaults().copyWith(
          feasibility: const FeasibilityConstraints(
            maxCostPerMeal: 8,
            availability: {AvailabilityContext.grocery},
          ),
          access: const AccessConstraints(
            benefitPrograms: {BenefitProgram.snap},
          ),
        );

        final deliBowl = _scoredFood(
          id: 30,
          name: 'Hot deli chicken bowl',
          cost: 4.8,
          category: 'prepared_meal',
          ingredients: const {'chicken', 'rice', 'bowl'},
        );
        final deliPlate = _scoredFood(
          id: 31,
          name: 'Prepared chicken deli plate',
          cost: 5.0,
          category: 'prepared_meal',
          ingredients: const {'chicken', 'plate', 'deli'},
        );

        final plan = TodayPlanBuilder(user: user).build(
          recommendations: [deliBowl, deliPlate],
          baskets: [
            _basket(
              items: [deliBowl, deliPlate],
              primarySource: AvailabilityContext.grocery,
            ),
          ],
        );

        expect(plan, isNotNull);
        expect(plan?.type, TodayPlanType.oneStop);
      },
    );
  });
}

MealBasketPlan _basket({
  required List<ScoredFood> items,
  required AvailabilityContext primarySource,
}) {
  return MealBasketPlan(
    title: 'Basket',
    summary: 'Basket summary',
    items: items,
    totalNutrients: Nutrients.zero,
    totalCost: items.fold<double>(
      0,
      (sum, item) => sum + item.food.costEstimate,
    ),
    totalPrepMinutes: items.fold<int>(
      0,
      (sum, item) => sum + item.food.prepTimeMin,
    ),
    highlights: const ['Basket fit'],
    primarySource: primarySource,
  );
}

ScoredFood _scoredFood({
  required int id,
  required String name,
  required double cost,
  required String category,
  required Set<String> ingredients,
  Set<AvailabilityContext> availability = const {AvailabilityContext.grocery},
  String prepMethod = 'none',
  int prepTimeMin = 0,
}) {
  return ScoredFood(
    food: Food(
      id: id,
      name: name,
      category: category,
      servingG: 100,
      servingLabel: '1 serving',
      costEstimate: cost,
      costConfidence: 'medium',
      prepMethod: prepMethod,
      prepTimeMin: prepTimeMin,
      mealTypes: const {MealType.lunch},
      availability: availability,
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: ingredients,
    ),
    nutrients: Nutrients.zero,
    composite: 1,
    breakdown: const ScoreBreakdown(
      macro: 0,
      micro: 0,
      penalty: 0,
      cost: 0,
      preference: 0,
    ),
  );
}
