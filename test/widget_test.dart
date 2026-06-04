import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/providers/nearby_store_providers.dart';
import 'package:access_plate/presentation/widgets/meal_basket_card.dart';
import 'package:access_plate/presentation/widgets/recommendation_card.dart';
import 'package:access_plate/presentation/widgets/section_card.dart';
import 'package:access_plate/presentation/widgets/selection_tile.dart';
import 'package:access_plate/presentation/widgets/today_plan_card.dart';

void main() {
  testWidgets('section card renders child content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AccessPlateTheme.light(),
        home: Scaffold(body: SectionCard(child: Text('AccessPlate'))),
      ),
    );

    expect(find.text('AccessPlate'), findsOneWidget);
  });

  testWidgets('selection tile gives selected items a darker surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AccessPlateTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              SelectionTile(title: 'Selected', selected: true, onTap: () {}),
              SelectionTile(title: 'Unselected', selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    final inks = tester.widgetList<Ink>(find.byType(Ink)).toList();
    final selectedDecoration = inks.first.decoration! as BoxDecoration;
    final unselectedDecoration = inks.last.decoration! as BoxDecoration;

    expect(selectedDecoration.color, const Color(0xFFF5F8EE));
    expect(unselectedDecoration.color, const Color(0xFFFEFBF5));
  });

  testWidgets('today plan card renders summary and steps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AccessPlateTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayPlanCard(
              plan: TodayPlan(
                type: TodayPlanType.snapRun,
                title: 'Today plan: SNAP-aware run',
                summary: 'Use likely SNAP staples first.',
                steps: const [
                  'Start with oatmeal and bananas.',
                  'Keep the total under \$4.00.',
                  'Use a backup staple if the first item is out.',
                ],
                highlights: const ['SNAP-aware', 'Grocery store'],
                checkpoints: const [
                  PlanCheckpoint(
                    title: 'Now',
                    detail: 'Buy oatmeal cup first with SNAP.',
                  ),
                  PlanCheckpoint(
                    title: 'Next meal',
                    detail: 'Pair the staple buy with yogurt cup.',
                  ),
                  PlanCheckpoint(
                    title: 'After that',
                    detail: 'Restock bananas if money is left.',
                  ),
                ],
                purchases: const [
                  PlannedPurchase(
                    label: 'Oatmeal cup',
                    priority: PlannedPurchasePriority.buyFirst,
                    detail: 'Likely SNAP item',
                    estimatedCost: 1.25,
                  ),
                  PlannedPurchase(
                    label: 'Yogurt cup',
                    priority: PlannedPurchasePriority.ifBudgetLeft,
                    estimatedCost: 1.75,
                  ),
                  PlannedPurchase(
                    label: 'Hot sandwich',
                    priority: PlannedPurchasePriority.skipFirst,
                    detail: 'Save for later if the trip gets expensive.',
                    estimatedCost: 3.80,
                  ),
                ],
                leadRecommendation: _sampleFood(1),
                backupAction: 'Backup: yogurt cup from grocery store.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Today plan: SNAP-aware run'), findsOneWidget);
    expect(find.text('Use likely SNAP staples first.'), findsOneWidget);
    expect(find.text('Start with oatmeal and bananas.'), findsOneWidget);
    expect(find.text('Next 2 meals'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Pair the staple buy with yogurt cup.'), findsOneWidget);
    expect(find.text('Buy first'), findsOneWidget);
    expect(find.text('If money is left'), findsOneWidget);
    expect(find.text('Skip first if budget gets tight'), findsOneWidget);
    expect(find.text('Hot sandwich'), findsOneWidget);
    expect(find.text('Backup: yogurt cup from grocery store.'), findsOneWidget);
  });

  testWidgets('meal basket card renders meal coverage and pantry support', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AccessPlateTheme.light(),
        home: Scaffold(
          body: MealBasketCard(
            plan: MealBasketPlan(
              title: 'Pantry-stretch basket',
              summary: 'Covers about 2 meals from one realistic trip.',
              items: [_sampleFood(1), _sampleFood(2)],
              totalNutrients: const Nutrients(
                caloriesKcal: 560,
                proteinG: 12,
                carbsG: 78,
                fatG: 8,
                saturatedFatG: 2,
                fiberG: 10,
                sugarG: 14,
                addedSugarG: 4,
                sodiumMg: 220,
                potassiumMg: 240,
                calciumMg: 60,
                ironMg: 2.0,
                magnesiumMg: 50,
                zincMg: 1.5,
                vitAMcgRae: 0,
                vitCMg: 0,
                vitDMcg: 0,
                vitB12Mcg: 0,
                folateMcgDfe: 40,
              ),
              totalCost: 2.45,
              totalPrepMinutes: 2,
              highlights: const ['\$2.45 total', '2 meals'],
              estimatedMealsCovered: 2,
              pantrySupportItems: const ['rice', 'beans'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pantry-stretch basket'), findsOneWidget);
    expect(find.text('Covers about 2 meals from one trip.'), findsOneWidget);
    expect(find.text('Uses from home: rice + beans'), findsOneWidget);
  });

  testWidgets('recommendation card stays stable at larger text sizes', (
    tester,
  ) async {
    final recommendation = _sampleFood(1).copyWith(
      explanation: const Explanation(
        satisfied: [
          SatisfiedConstraint(
            category: 'access',
            description: 'Matches a lower-cost breakfast need.',
          ),
        ],
        positives: [
          ScoreFactor(
            label: 'Low cost',
            weight: 0.4,
            detail: 'Keeps the first buy small.',
          ),
        ],
        tradeoffs: [
          ScoreFactor(
            label: 'Protein is modest',
            weight: 0.1,
            detail: 'Pair with another staple if needed.',
          ),
        ],
        compareWithIds: [],
        accessSummary: 'Short trip with pantry-friendly staples.',
        accessTags: ['Grocery store', 'Pantry match'],
        decisionFacts: [
          DecisionFact(label: 'Trip', value: 'Short'),
          DecisionFact(label: 'Benefits', value: 'Likely SNAP-compatible'),
          DecisionFact(label: 'From home', value: 'Oats already on hand'),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingLocationStateProvider.overrideWith(
            (ref) => const ShoppingLocationState(apiConfigured: true),
          ),
          mealShoppingSummariesProvider.overrideWith(
            (ref) async => {
              recommendation.food.id: _shoppingPlanFor(recommendation.food),
            },
          ),
          prefetchedLiveMealShoppingPlansProvider.overrideWith(
            (ref) async => {
              recommendation.food.id: _shoppingPlanFor(recommendation.food),
            },
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecommendationCard(
                  recommendation: recommendation,
                  onExplain: () {},
                  onTrack: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final planButton = find.widgetWithText(TextButton, 'Plan');
    await tester.scrollUntilVisible(planButton, 200);
    await tester.tap(planButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Oatmeal cup'), findsWidgets);
    expect(find.text('Go to'), findsWidgets);
    expect(find.textContaining('Store Brand'), findsWidgets);
  });

  testWidgets('recommendation card shows approximate distance when only straight-line data exists', (
    tester,
  ) async {
    final recommendation = _sampleFood(2);
    final approximatePlan = _shoppingPlanFor(
      recommendation.food,
      metric: const TravelMetric(
        source: TravelMetricSource.straightLineApproximate,
        distanceMiles: 0.8,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingLocationStateProvider.overrideWith(
            (ref) => const ShoppingLocationState(
              apiConfigured: true,
              location: SearchLocation(
                kind: SearchLocationKind.address,
                label: '123 Main St',
                latitude: 39.10,
                longitude: -84.51,
                verification: DataVerification.live,
              ),
            ),
          ),
          mealShoppingSummariesProvider.overrideWith(
            (ref) async => {recommendation.food.id: approximatePlan},
          ),
          prefetchedLiveMealShoppingPlansProvider.overrideWith(
            (ref) async => {recommendation.food.id: approximatePlan},
          ),
        ],
        child: MaterialApp(
          theme: AccessPlateTheme.light(),
          home: Scaffold(
            body: RecommendationCard(
              recommendation: recommendation,
              onExplain: () {},
              onTrack: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Approx. 0.8 mi'), findsOneWidget);
    expect(find.textContaining('min'), findsNothing);
  });
}

ScoredFood _sampleFood(int id) {
  return ScoredFood(
    food: Food(
      id: id,
      name: 'Oatmeal cup',
      category: 'grain_whole',
      servingG: 64,
      servingLabel: '1 cup',
      costEstimate: 1.25,
      costConfidence: 'medium',
      prepMethod: 'microwave',
      prepTimeMin: 2,
      mealTypes: const {MealType.breakfast},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'oatmeal', 'oats'},
      source: 'bundled_reference',
    ),
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
    composite: 0.7,
    displayScore: 88,
    breakdown: const ScoreBreakdown(
      macro: 0.72,
      micro: 0.44,
      penalty: 0.08,
      cost: 0.12,
      preference: 0.5,
    ),
  );
}

MealShoppingPlan _shoppingPlanFor(
  Food food, {
  TravelMetric metric = const TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 1.4,
    durationMinutes: 7,
  ),
}) {
  final groceryStore = GroceryStore(
    retailer: GroceryRetailer.kroger,
    locationId: 'store-${food.id}',
    name: 'Kroger',
    addressLine1: '123 Market St',
    city: 'Demo',
    state: 'OH',
    postalCode: '45202',
  );
  final chosenStore = NearbyStore(
    placeId: 'near-${food.id}',
    name: groceryStore.name,
    address: groceryStore.addressLabel,
    latitude: 39.10,
    longitude: -84.51,
    categories: const {AvailabilityContext.grocery},
    primaryCategory: AvailabilityContext.grocery,
    discoveryVerification: DataVerification.live,
    travelMetric: metric,
    linkedGroceryStore: groceryStore,
  );
  final ingredient = IngredientRequirement(
    key: 'oatmeal',
    label: 'Oatmeal cup',
    searchTerms: const ['oatmeal'],
    pantryAliases: const ['oatmeal'],
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
    backupStores: const [],
    candidateStores: [chosenStore],
    liveProductMatch: LiveStoreMatch(
      store: chosenStore,
      lookup: LiveIngredientLookupResult(
        store: groceryStore,
        matches: [
          IngredientProductMatch(
            ingredient: ingredient,
            products: const [
              GroceryProduct(
                retailer: GroceryRetailer.kroger,
                productId: 'p-1',
                description: 'Oatmeal cup',
                brand: 'Store Brand',
                size: '1 cup',
                regularPrice: 1.25,
              ),
            ],
          ),
        ],
        unmatchedIngredients: const [],
      ),
    ),
    liveLookupAttempted: true,
    storeStatusNote: null,
  );
}
