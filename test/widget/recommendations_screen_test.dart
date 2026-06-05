import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/providers/demo_meals_store_data.dart';
import 'package:access_plate/presentation/providers/nearby_store_providers.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/providers/recommendations_provider.dart';
import 'package:access_plate/presentation/screens/recommendations/recommendations_screen.dart';
import 'package:access_plate/presentation/widgets/compact_action_plan_section.dart';
import 'package:access_plate/presentation/widgets/recommendation_card.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('recommendations screen shows the static demo location card', (
    tester,
  ) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Meals you can get today'), findsOneWidget);
    expect(find.text('3758 W Madison St, Chicago, IL 60624'), findsOneWidget);
    expect(find.text('6 nearby stores matched.'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(
      find.text('Offline — showing meals from your saved settings'),
      findsNothing,
    );
  });

  testWidgets('recommendations screen shows ranked meal cards', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(RecommendationCard).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byType(RecommendationCard), findsWidgets);
    expect(find.text("McDonald's | 0.2 mi"), findsWidgets);
    expect(find.text('Aldi | 0.7 mi'), findsWidgets);
    expect(find.text('Verified'), findsNothing);
  });

  testWidgets('recommendation details expand in place with static store info', (
    tester,
  ) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final planButton = find.widgetWithText(TextButton, 'Plan').first;
    await tester.scrollUntilVisible(
      planButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(planButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Go to'), findsWidgets);
    expect(find.textContaining("Buy at McDonald's"), findsOneWidget);
    expect(
      find.textContaining('Searching nearby stores for this meal...'),
      findsNothing,
    );
    expect(find.text('Verified'), findsNothing);
  });

  testWidgets('logging a meal shows daily tracking feedback', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final logButton = find.widgetWithText(FilledButton, 'Log meal').first;
    await tester.scrollUntilVisible(
      logButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(logButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('daily tracking'), findsOneWidget);
  });

  testWidgets('recommendations screen shows compact action plan', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.byType(CompactActionPlanSection), findsOneWidget);
    expect(find.text('Do this first today'), findsOneWidget);
    expect(
      find.text('Best first stop: Start at convenience store'),
      findsOneWidget,
    );
    expect(find.text('Buy'), findsWidgets);
  });

  testWidgets('compact action plan subtitle uses the muted hierarchy color', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final subtitle = tester.widget<Text>(
      find.text('Your next stop, home food, and buy order for today.'),
    );
    expect(subtitle.style?.color, const Color(0xFF888888));
  });
}

Widget _buildHarness({Map<int, MealShoppingPlan>? shoppingPlans}) {
  final profile = UserProfile.defaults().copyWith(onboardingComplete: true);
  final resolvedPlans =
      shoppingPlans ??
      {
        for (final recommendation in _result.recommendations)
          recommendation.food.id: _shoppingPlanFor(recommendation.food),
      };

  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
      recommendationsProvider.overrideWith((ref) async => _result),
      storeAvailabilityModeProvider.overrideWith(
        (ref) => const StoreAvailabilityModeState(
          mode: StoreAvailabilityMode.online,
          apiConfigured: true,
          hasInternet: true,
          location: demoMealsLocation,
          nearbyStores: demoMealsNearbyStores,
        ),
      ),
      shoppingLocationStateProvider.overrideWith(
        (ref) => const ShoppingLocationState(
          apiConfigured: true,
          location: demoMealsLocation,
        ),
      ),
      mealShoppingSummariesProvider.overrideWith((ref) async => resolvedPlans),
      prefetchedLiveMealShoppingPlansProvider.overrideWith(
        (ref) async => resolvedPlans,
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

  @override
  Future<void> logRecommendation(ScoredFood recommendation) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        todayIntake: {
          ..._profile.constraints.todayIntake,
          'calories_kcal': recommendation.nutrients.caloriesKcal,
        },
        todayIntakeDate: DateTime(2026, 6, 3),
        recentlyActed: {
          ..._profile.constraints.recentlyActed,
          recommendation.food.id: DateTime(2026, 6, 3, 12, 0),
        },
      ),
    );
    state = AsyncData(_profile);
  }
}

Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

const _sourceTripPlan = SourceTripPlan(
  mission: SourceTripMission.emergency,
  primarySource: AvailabilityContext.convenience,
  title: 'Start at convenience store',
  summary: 'Lowest travel burden for today.',
  reasons: ['Close by', 'Open now'],
  highlights: ['Quick pickup'],
  backupSource: AvailabilityContext.dollarStore,
  routeReason: 'Short trip with the fewest stops.',
);

final _todayPlan = TodayPlan(
  type: TodayPlanType.emergency,
  title: 'Emergency meal plan',
  summary: 'Fastest practical path for today.',
  steps: const ['Use pantry rice', 'Buy tuna at convenience store'],
  highlights: const ['Low travel'],
  leadRecommendation: _buildFood(1),
  purchases: const [
    PlannedPurchase(
      label: 'Canned tuna',
      priority: PlannedPurchasePriority.buyFirst,
    ),
    PlannedPurchase(label: 'Soda', priority: PlannedPurchasePriority.skipFirst),
  ],
  backupAction: 'Backup: Dollar store for crackers',
);

final _result = RecommendationResult(
  recommendations: List.generate(4, (index) => _buildFood(index + 1)),
  preferenceRelaxed: false,
  candidatePoolSize: 8,
  elapsedMs: 28,
  sourceTripPlan: _sourceTripPlan,
  todayPlan: _todayPlan,
);

MealShoppingPlan _shoppingPlanFor(Food food) {
  final stores = switch (food.id) {
    1 => [demoMealsNearbyStores[0], demoMealsNearbyStores[4]],
    2 => [demoMealsNearbyStores[3]],
    3 => [demoMealsNearbyStores[1], demoMealsNearbyStores[2]],
    _ => [demoMealsNearbyStores[5]],
  };
  final ingredient = IngredientRequirement(
    key: 'meal-${food.id}',
    label: food.name.contains('Oatmeal') ? 'Oatmeal cup' : 'Meal item',
    searchTerms: const ['meal'],
    pantryAliases: const ['meal'],
    evidence: IngredientEvidence.structured,
    quantityLabel: food.servingLabel,
  );
  return MealShoppingPlan(
    food: food,
    ingredients: IngredientPlan(
      atHome: const [],
      toBuy: [ingredient],
      buySummary: ingredient.label,
    ),
    chosenStore: stores.first,
    backupStores: stores.skip(1).toList(growable: false),
    candidateStores: stores,
    liveProductMatch: null,
    liveLookupAttempted: true,
    storeStatusNote: null,
    offlineAvailabilityContext: stores.first.primaryCategory,
  );
}

ScoredFood _buildFood(int id) {
  final names = [
    'McDonald\'s Oatmeal Cup',
    'Aldi Chicken Bowl',
    'Dollar Store Bean Taco',
    '7-Eleven Protein Snack Box',
  ];
  final mealTypes = [
    const {MealType.breakfast},
    const {MealType.lunch},
    const {MealType.dinner},
    const {MealType.lunch, MealType.dinner},
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
      mealTypes: mealTypes[(id - 1) % mealTypes.length],
      availability: switch (id) {
        1 => const {AvailabilityContext.fastFood},
        2 => const {AvailabilityContext.grocery},
        3 => const {AvailabilityContext.dollarStore},
        _ => const {AvailabilityContext.convenience},
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
