import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/meal_history.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/engine/meal_history_summary.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/providers/meal_history_providers.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/providers/recommendations_provider.dart';
import 'package:access_plate/presentation/screens/recommendations/recommendations_screen.dart';
import 'package:access_plate/presentation/widgets/recommendation_card.dart';

void main() {
  testWidgets('recommendations screen opens on the discovery tab', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('What are you in the mood for?'), findsOneWidget);
    expect(find.text('Fast Food Restaurants'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Near Me'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Near Me'), findsOneWidget);
  });

  testWidgets('meals tab shows meal cards and expandable details', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Meals'));
    await tester.pumpAndSettle();

    expect(find.text('Suggested Meals'), findsOneWidget);
    for (var attempt = 0; attempt < 4; attempt++) {
      if (find.byType(RecommendationCard).evaluate().isNotEmpty) {
        break;
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    expect(find.byType(RecommendationCard), findsWidgets);

    await tester.ensureVisible(find.text('Show details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show details').first);
    await tester.pumpAndSettle();

    expect(find.text('Decision snapshot'), findsWidgets);
    expect(
      find.textContaining('Short trip with pantry-friendly staples.'),
      findsWidgets,
    );
  });

  testWidgets(
    'history and profile tabs expose progress and settings summaries',
    (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('History'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly Snapshot'), findsOneWidget);
      expect(find.text('Recent Days'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Total Daily Macros'), findsOneWidget);
    },
  );
}

Widget _buildHarness() {
  final profile = UserProfile.defaults().copyWith(onboardingComplete: true);

  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
      recommendationsProvider.overrideWith((ref) async => _result),
      discoverCatalogProvider.overrideWith((ref) async => _catalog),
      mealEntriesForDayProvider.overrideWith((ref, day) async => _todayLog),
      recentMealDaySummariesProvider.overrideWith(
        (ref, count) async => _recentDays,
      ),
      weeklyNutritionOverviewProvider.overrideWith(
        (ref, endDate) async => _weeklyOverview,
      ),
    ],
    child: const MaterialApp(home: RecommendationsScreen()),
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;

  @override
  Future<void> setStage(OnboardingStage stage) async {
    _profile = _profile.copyWith(
      onboardingStage: stage,
      onboardingComplete: false,
    );
    state = AsyncData(_profile);
  }

  @override
  Future<void> completeOnboarding() async {
    _profile = _profile.copyWith(
      onboardingComplete: true,
      onboardingStage: OnboardingStage.targets,
    );
    state = AsyncData(_profile);
  }
}

final _catalog = List<FoodRecord>.generate(8, (index) {
  return FoodRecord(
    food: _buildFood(index + 1).food,
    nutrients: _buildFood(index + 1).nutrients,
  );
});

final _result = RecommendationResult(
  recommendations: List.generate(4, (index) => _buildFood(index + 1)),
  preferenceRelaxed: false,
  candidatePoolSize: 8,
  elapsedMs: 28,
);

final _todayLog = <MealLogEntry>[
  MealLogEntry(
    id: 1,
    foodId: 1,
    foodName: 'McDonald\'s Oatmeal Cup',
    servingLabel: '1 cup',
    quantity: 1,
    loggedAt: DateTime(2026, 6, 2, 8, 0),
    nutrients: const Nutrients(
      caloriesKcal: 220,
      proteinG: 6,
      carbsG: 39,
      fatG: 4,
      saturatedFatG: 1,
      fiberG: 5,
      sugarG: 7,
      addedSugarG: 4,
      sodiumMg: 180,
      potassiumMg: 160,
      calciumMg: 40,
      ironMg: 1.6,
      magnesiumMg: 38,
      zincMg: 1.2,
      vitAMcgRae: 0,
      vitCMg: 0,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 18,
    ),
    source: MealLogSource.manual,
  ),
];

final _recentDays = List.generate(7, (index) {
  final date = DateTime(2026, 6, 2).subtract(Duration(days: index));
  return MealLogDaySummary(
    date: date,
    entries: index.isEven ? _todayLog : const [],
    totalNutrients: index.isEven
        ? const Nutrients(
            caloriesKcal: 1560,
            proteinG: 76,
            carbsG: 164,
            fatG: 48,
            saturatedFatG: 13,
            fiberG: 22,
            sugarG: 31,
            addedSugarG: 12,
            sodiumMg: 2100,
            potassiumMg: 2600,
            calciumMg: 640,
            ironMg: 11,
            magnesiumMg: 250,
            zincMg: 6,
            vitAMcgRae: 780,
            vitCMg: 46,
            vitDMcg: 4,
            vitB12Mcg: 1.2,
            folateMcgDfe: 210,
          )
        : Nutrients.zero,
  );
});

final _weeklyOverview = WeeklyNutritionOverview(
  startDate: DateTime(2026, 5, 27),
  endDate: DateTime(2026, 6, 2),
  days: _recentDays,
  totalNutrients: const Nutrients(
    caloriesKcal: 4680,
    proteinG: 228,
    carbsG: 492,
    fatG: 144,
    saturatedFatG: 39,
    fiberG: 66,
    sugarG: 93,
    addedSugarG: 36,
    sodiumMg: 6300,
    potassiumMg: 7800,
    calciumMg: 1920,
    ironMg: 33,
    magnesiumMg: 750,
    zincMg: 18,
    vitAMcgRae: 2340,
    vitCMg: 138,
    vitDMcg: 12,
    vitB12Mcg: 3.6,
    folateMcgDfe: 630,
  ),
);

ScoredFood _buildFood(int id) {
  final names = [
    'McDonald\'s Oatmeal Cup',
    'Chipotle Chicken Bowl',
    'Taco Bell Bean Taco',
    'In-N-Out Protein Style Burger',
  ];
  final name = names[(id - 1) % names.length];
  return ScoredFood(
    food: Food(
      id: id,
      name: name,
      category: 'prepared_meal',
      servingG: 240,
      servingLabel: '1 serving',
      costEstimate: 6.5,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.lunch, MealType.dinner},
      availability: const {
        AvailabilityContext.fastFood,
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'beans', 'oats', 'chicken', 'burger'},
      source: 'bundled_reference',
    ),
    nutrients: const Nutrients(
      caloriesKcal: 390,
      proteinG: 30,
      carbsG: 35,
      fatG: 12,
      saturatedFatG: 3,
      fiberG: 7,
      sugarG: 5,
      addedSugarG: 1,
      sodiumMg: 540,
      potassiumMg: 480,
      calciumMg: 110,
      ironMg: 3.2,
      magnesiumMg: 72,
      zincMg: 2.4,
      vitAMcgRae: 120,
      vitCMg: 10,
      vitDMcg: 0,
      vitB12Mcg: 0.6,
      folateMcgDfe: 76,
    ),
    composite: 0.78,
    displayScore: 96,
    breakdown: const ScoreBreakdown(
      macro: 0.82,
      micro: 0.56,
      penalty: 0.08,
      cost: 0.12,
      preference: 0.48,
    ),
    explanation: const Explanation(
      satisfied: [
        SatisfiedConstraint(
          category: 'access',
          description: 'Fast pickup and easy portion control.',
        ),
      ],
      positives: [
        ScoreFactor(
          label: 'Protein fit',
          weight: 0.5,
          detail: 'Keeps the meal aligned with your target.',
        ),
      ],
      tradeoffs: [
        ScoreFactor(
          label: 'Moderate sodium',
          weight: 0.2,
          detail: 'Balance the rest of the day accordingly.',
        ),
      ],
      compareWithIds: [],
      accessSummary: 'Short trip with pantry-friendly staples.',
      accessTags: ['Fast food', 'Quick pickup'],
      decisionFacts: [
        DecisionFact(label: 'Trip', value: 'Short'),
        DecisionFact(label: 'Protein', value: '30g'),
        DecisionFact(label: 'Cost', value: '\$6.50'),
      ],
    ),
  );
}
