import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/providers/recommendations_provider.dart';

void main() {
  test(
    'meals screen provider hardcodes demo scores, names, and buy-first meal',
    () {
      final blackBean = _scoredFood(
        id: 200,
        name: 'Black bean rice bowl',
        availability: const {AvailabilityContext.grocery},
      );
      final peanutButter = _scoredFood(
        id: 201,
        name: 'Peanut butter on whole wheat',
        availability: const {AvailabilityContext.grocery},
      );
      final wrap = _scoredFood(
        id: 96,
        name: 'Bean and cheese wrap',
        availability: const {AvailabilityContext.grocery},
      );
      final banana = _scoredFood(
        id: 108,
        name: 'Fresh banana and peanut butter',
        availability: const {AvailabilityContext.convenience},
      );
      final trailMix = _scoredFood(
        id: 179,
        name: 'Trail mix snack pack',
        availability: const {AvailabilityContext.convenience},
      );
      final refried = _scoredFood(
        id: 187,
        name: 'Refried bean bowl',
        availability: const {AvailabilityContext.dollarStore},
      );
      final pantry = _scoredFood(
        id: 133,
        name: 'Pantry coleslaw mix bowl',
        availability: const {AvailabilityContext.foodPantry},
      );
      final fastFood = _scoredFood(
        id: 300,
        name: 'Taco Bell Power Menu Bowl',
        availability: const {AvailabilityContext.fastFood},
      );

      final original = RecommendationResult(
        recommendations: [
          fastFood,
          pantry,
          banana,
          trailMix,
          refried,
          blackBean,
          wrap,
          peanutButter,
        ],
        preferenceRelaxed: false,
        candidatePoolSize: 8,
        elapsedMs: 10,
        todayPlan: TodayPlan(
          type: TodayPlanType.oneStop,
          title: 'Today',
          summary: 'Start with the closest option.',
          steps: const ['Buy Taco Bell Power Menu Bowl'],
          highlights: const ['Quick trip'],
          leadRecommendation: fastFood,
          purchases: const [
            PlannedPurchase(
              label: 'Taco Bell Power Menu Bowl',
              priority: PlannedPurchasePriority.buyFirst,
            ),
            PlannedPurchase(
              label: 'Skip soda',
              priority: PlannedPurchasePriority.skipFirst,
            ),
          ],
        ),
      );

      final sanitized = sanitizeRecommendationsForMealsScreen(
        original,
        UserProfile.defaults(),
      );

      expect(
        sanitized.recommendations.map((item) => item.food.name),
        orderedEquals([
          'Black bean and rice bowl',
          'Peanut butter on whole wheat',
          'Bean and cheese wrap',
          'Fresh banana and peanut butter',
          'Trail mix snack pack',
          'Refried bean bowl',
          'Tuna and cracker plate',
          'Taco Bell Power Menu Bowl',
        ]),
      );
      expect(
        sanitized.recommendations.map((item) => item.displayScore.round()),
        orderedEquals([94, 91, 88, 85, 82, 79, 76, 74]),
      );
      expect(
        sanitized.todayPlan?.leadRecommendation.food.name,
        'Black bean and rice bowl',
      );
      expect(
        sanitized.todayPlan?.purchases.first.label,
        'Black bean and rice bowl',
      );
      expect(
        sanitized.recommendations
            .firstWhere((item) => item.food.id == 133)
            .food
            .name,
        'Tuna and cracker plate',
      );
    },
  );
}

ScoredFood _scoredFood({
  required int id,
  required String name,
  required Set<AvailabilityContext> availability,
}) {
  return ScoredFood(
    food: Food(
      id: id,
      name: name,
      category: 'prepared_meal',
      servingG: 250,
      servingLabel: '1 serving',
      costEstimate: 3.0,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.lunch},
      availability: availability,
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'beans', 'rice'},
      source: 'test_fixture',
    ),
    nutrients: const Nutrients(
      caloriesKcal: 350,
      proteinG: 18,
      carbsG: 40,
      fatG: 10,
      saturatedFatG: 2,
      fiberG: 6,
      sugarG: 4,
      addedSugarG: 1,
      sodiumMg: 300,
      potassiumMg: 250,
      calciumMg: 80,
      ironMg: 2.5,
      magnesiumMg: 40,
      zincMg: 1.2,
      vitAMcgRae: 80,
      vitCMg: 8,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 60,
    ),
    composite: 76,
    displayScore: 76,
    breakdown: const ScoreBreakdown(
      macro: 0.7,
      micro: 0.5,
      penalty: 0.1,
      cost: 0.2,
      preference: 0.4,
      access: 0.5,
    ),
  );
}
