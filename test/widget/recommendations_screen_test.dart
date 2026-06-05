import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
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

  testWidgets('recommendations screen shows ranked meal cards', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Meals you can get today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(RecommendationCard).first,
      200,
    );
    expect(find.byType(RecommendationCard), findsWidgets);
  });

  testWidgets('recommendation details expand in place', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final planButton = find.widgetWithText(TextButton, 'Plan').first;
    await tester.scrollUntilVisible(planButton, 200);
    await tester.pumpAndSettle();
    await tester.tap(planButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Go to'), findsWidgets);
    expect(find.textContaining('Buy at Kroger 1'), findsOneWidget);
    expect(find.textContaining('Store Brand'), findsWidgets);
  });

  testWidgets('logging a meal shows daily tracking feedback', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final logButton = find.widgetWithText(FilledButton, 'Log meal').first;
    await tester.scrollUntilVisible(logButton, 200);
    await tester.pumpAndSettle();
    await tester.tap(logButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('daily tracking'), findsOneWidget);
  });

  testWidgets('recommendations screen shows compact action plan', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.byType(CompactActionPlanSection), findsOneWidget);
    expect(find.text('Do this first today'), findsOneWidget);
    expect(find.text('Go first'), findsOneWidget);
    expect(find.text('Buy first'), findsWidgets);
    expect(find.text('Start at convenience store'), findsOneWidget);
  });

  testWidgets(
    'recommendations screen shows offline banner and store-type headlines in offline mode',
    (tester) async {
      await _setTallViewport(tester);
      final offlinePlans = {
        for (final recommendation in _result.recommendations)
          recommendation.food.id: _shoppingPlanWithoutStore(
            recommendation.food,
          ),
      };

      await tester.pumpWidget(
        _buildHarness(
          mode: const StoreAvailabilityModeState(
            mode: StoreAvailabilityMode.offline,
            apiConfigured: true,
            hasInternet: false,
          ),
          shoppingPlans: offlinePlans,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Offline — showing meals from your saved settings'),
        findsOneWidget,
      );
      expect(find.text('Nearby stores'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Available at: Grocery store').first,
        200,
      );
      expect(find.textContaining('Available at: Grocery store'), findsWidgets);
      expect(find.text('Verified'), findsNothing);
    },
  );
}

Widget _buildHarness({
  StoreAvailabilityModeState? mode,
  Map<int, MealShoppingPlan>? shoppingPlans,
}) {
  final profile = UserProfile.defaults().copyWith(onboardingComplete: true);
  final resolvedPlans =
      shoppingPlans ??
      {
        for (final recommendation in _result.recommendations)
          recommendation.food.id: _shoppingPlanFor(recommendation.food),
      };
  final resolvedMode =
      mode ??
      StoreAvailabilityModeState(
        mode: StoreAvailabilityMode.online,
        apiConfigured: true,
        hasInternet: true,
        location: const SearchLocation(
          kind: SearchLocationKind.device,
          label: '4001 W Chicago Ave, Chicago, IL 60651',
          latitude: 41.8955,
          longitude: -87.7261,
          verification: DataVerification.live,
          postalCode: '60651',
        ),
        nearbyStores: resolvedPlans.values
            .map((plan) => plan.chosenStore)
            .whereType<NearbyStore>()
            .toList(growable: false),
      );

  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
      recommendationsProvider.overrideWith((ref) async => _result),
      storeAvailabilityModeProvider.overrideWith((ref) => resolvedMode),
      shoppingLocationStateProvider.overrideWith(
        (ref) => ShoppingLocationState(
          apiConfigured: true,
          location: resolvedMode.location,
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
    PlannedPurchase(
      label: 'Soda',
      priority: PlannedPurchasePriority.skipFirst,
    ),
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
  final primaryGroceryStore = GroceryStore(
    retailer: GroceryRetailer.kroger,
    locationId: 'store-${food.id}',
    name: 'Kroger ${food.id}',
    addressLine1: '123 Market St',
    city: 'Demo',
    state: 'OH',
    postalCode: '45202',
  );
  final backupGroceryStore = GroceryStore(
    retailer: GroceryRetailer.kroger,
    locationId: 'backup-${food.id}',
    name: 'Kroger Backup ${food.id}',
    addressLine1: '200 Oak Ave',
    city: 'Demo',
    state: 'OH',
    postalCode: '45202',
  );
  final chosenStore = NearbyStore(
    placeId: 'near-${food.id}',
    name: primaryGroceryStore.name,
    address: primaryGroceryStore.addressLabel,
    latitude: 39.10,
    longitude: -84.51,
    categories: const {AvailabilityContext.grocery},
    primaryCategory: AvailabilityContext.grocery,
    discoveryVerification: DataVerification.live,
    travelMetric: const TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 1.4,
      durationMinutes: 7,
    ),
    linkedGroceryStore: primaryGroceryStore,
  );
  final backupStore = NearbyStore(
    placeId: 'backup-near-${food.id}',
    name: backupGroceryStore.name,
    address: backupGroceryStore.addressLabel,
    latitude: 39.11,
    longitude: -84.52,
    categories: const {AvailabilityContext.grocery},
    primaryCategory: AvailabilityContext.grocery,
    discoveryVerification: DataVerification.live,
    travelMetric: const TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 2.2,
      durationMinutes: 11,
    ),
    linkedGroceryStore: backupGroceryStore,
  );
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
    chosenStore: chosenStore,
    backupStores: [backupStore],
    candidateStores: [chosenStore, backupStore],
    liveProductMatch: LiveStoreMatch(
      store: chosenStore,
      lookup: LiveIngredientLookupResult(
        store: primaryGroceryStore,
        matches: [
          IngredientProductMatch(
            ingredient: ingredient,
            products: [
              GroceryProduct(
                retailer: GroceryRetailer.kroger,
                productId: 'product-${food.id}',
                description: '${food.name} package',
                brand: 'Store Brand',
                size: food.servingLabel,
                regularPrice: 3.49,
              ),
            ],
          ),
        ],
        unmatchedIngredients: const [],
      ),
    ),
    liveLookupAttempted: true,
    storeStatusNote: null,
    offlineAvailabilityContext: AvailabilityContext.grocery,
  );
}

MealShoppingPlan _shoppingPlanWithoutStore(Food food) {
  return MealShoppingPlan(
    food: food,
    ingredients: const IngredientPlan(
      atHome: [],
      toBuy: [
        IngredientRequirement(
          key: 'meal',
          label: 'Meal item',
          searchTerms: ['meal'],
          pantryAliases: ['meal'],
          evidence: IngredientEvidence.structured,
        ),
      ],
      buySummary: 'Meal item',
    ),
    chosenStore: null,
    backupStores: const [],
    candidateStores: const [],
    liveProductMatch: null,
    liveLookupAttempted: false,
    storeStatusNote: 'Nearby store verification is unavailable for this meal.',
    offlineAvailabilityContext: AvailabilityContext.grocery,
  );
}

ScoredFood _buildFood(int id) {
  final names = [
    'McDonald\'s Oatmeal Cup',
    'Chipotle Chicken Bowl',
    'Taco Bell Bean Taco',
    'In-N-Out Protein Style Burger',
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
