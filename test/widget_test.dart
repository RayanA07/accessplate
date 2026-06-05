import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/demographics.dart';
import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
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

  testWidgets('selection tile prominent radio style uses green accent state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AccessPlateTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              SelectionTile(
                title: 'Selected',
                selected: true,
                visualStyle: SelectionTileVisualStyle.prominentRadio,
                onTap: () {},
              ),
              SelectionTile(
                title: 'Unselected',
                selected: false,
                visualStyle: SelectionTileVisualStyle.prominentRadio,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final inks = tester.widgetList<Ink>(find.byType(Ink)).toList();
    final selectedDecoration = inks.first.decoration! as BoxDecoration;
    final unselectedDecoration = inks.last.decoration! as BoxDecoration;
    final indicators = find.byType(AnimatedContainer);
    final selectedIndicator = tester
        .widgetList<AnimatedContainer>(indicators)
        .first;
    final unselectedIndicator = tester
        .widgetList<AnimatedContainer>(indicators)
        .last;
    final selectedIndicatorDecoration =
        selectedIndicator.decoration! as BoxDecoration;
    final unselectedIndicatorDecoration =
        unselectedIndicator.decoration! as BoxDecoration;

    expect(selectedDecoration.color, const Color(0xFFE8F5E9));
    expect(unselectedDecoration.color, NihPalette.white);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == NihPalette.success,
      ),
      findsOneWidget,
    );
    expect(tester.getSize(indicators.first), const Size(24, 24));
    expect(selectedIndicatorDecoration.color, NihPalette.success);
    expect(unselectedIndicatorDecoration.color, Colors.transparent);
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
          storeAvailabilityModeProvider.overrideWith(
            (ref) => _onlineStoreAvailabilityMode(),
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

  testWidgets(
    'recommendation card shows approximate distance when only straight-line data exists',
    (tester) async {
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
            storeAvailabilityModeProvider.overrideWith(
              (ref) => _onlineStoreAvailabilityMode(
                location: const SearchLocation(
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
    },
  );

  testWidgets(
    'recommendation card keeps unavailable store note in subtitle only',
    (tester) async {
      final recommendation = _sampleFood(3);
      final unavailablePlan = _shoppingPlanWithoutStore(recommendation.food);
      const unavailableNote =
          'Nearby store verification is unavailable for this meal.';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingLocationStateProvider.overrideWith(
              (ref) => const ShoppingLocationState(
                apiConfigured: true,
                location: SearchLocation(
                  kind: SearchLocationKind.device,
                  label: '4001 W Chicago Ave, Chicago, IL 60651',
                  latitude: 41.8955,
                  longitude: -87.7261,
                  verification: DataVerification.live,
                ),
              ),
            ),
            storeAvailabilityModeProvider.overrideWith(
              (ref) => _onlineStoreAvailabilityMode(),
            ),
            mealShoppingSummariesProvider.overrideWith(
              (ref) async => {recommendation.food.id: unavailablePlan},
            ),
            prefetchedLiveMealShoppingPlansProvider.overrideWith(
              (ref) async => {recommendation.food.id: unavailablePlan},
            ),
          ],
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
      );
      await tester.pumpAndSettle();

      expect(find.text(unavailableNote), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Plan'));
      await tester.pumpAndSettle();

      expect(find.text(unavailableNote), findsWidgets);
      expect(
        find.text(
          'Store data unavailable offline. Use your access settings to find this at a nearby store.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'recommendation card shows simple preparation steps for demo meals',
    (tester) async {
      final recommendations = [
        _sampleFood(
          11,
          name: 'Tuna salad on whole-wheat',
          ingredients: const {'tuna', 'whole-wheat bread'},
        ),
        _sampleFood(
          12,
          name: 'Bean and rice bowl',
          servingLabel: '1 bowl',
          ingredients: const {'beans', 'rice'},
        ),
        _sampleFood(
          13,
          name: 'Peanut butter on whole wheat',
          ingredients: const {'peanut butter', 'whole wheat bread'},
        ),
      ];
      final shoppingPlans = {
        for (final recommendation in recommendations)
          recommendation.food.id: _shoppingPlanFor(recommendation.food),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingLocationStateProvider.overrideWith(
              (ref) => const ShoppingLocationState(apiConfigured: true),
            ),
            storeAvailabilityModeProvider.overrideWith(
              (ref) => _onlineStoreAvailabilityMode(),
            ),
            mealShoppingSummariesProvider.overrideWith(
              (ref) async => shoppingPlans,
            ),
            prefetchedLiveMealShoppingPlansProvider.overrideWith(
              (ref) async => shoppingPlans,
            ),
          ],
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final recommendation in recommendations)
                      RecommendationCard(
                        recommendation: recommendation,
                        onExplain: () {},
                        onTrack: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < recommendations.length; index++) {
        final button = find.widgetWithText(TextButton, 'Plan').first;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      expect(find.text('How to prepare'), findsNWidgets(3));
      expect(find.text('Open tuna pouch and drain'), findsOneWidget);
      expect(
        find.text(
          'Mix with any available condiment (mayo, mustard, or hot sauce)',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Cook instant rice per packet (microwave: 90 seconds)'),
        findsOneWidget,
      );
      expect(find.text('Open and drain canned beans'), findsOneWidget);
      expect(find.text('Spread peanut butter on bread'), findsOneWidget);
      expect(find.text('No cooking needed'), findsOneWidget);
    },
  );

  testWidgets(
    'score badge opens a distinct score breakdown sheet for each demo meal',
    (tester) async {
      const constraints = UserConstraints(
        safety: SafetyConstraints(),
        feasibility: FeasibilityConstraints(
          maxCostPerMeal: 8,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.convenience,
          },
        ),
        preference: PreferenceConstraints(),
        access: AccessConstraints(maxTravelMinutes: 20),
        pantry: PantryConstraints(),
        targets: NutritionalTargets(),
        demographics: Demographics(sex: Sex.female, ageYears: 30),
      );
      final recommendations = [
        _sampleFood(
          21,
          name: 'Tuna salad on whole-wheat',
          servingLabel: '1 sandwich',
          ingredients: const {'tuna', 'whole-wheat bread', 'mustard'},
          costEstimate: 3.5,
          prepMethod: 'none',
          prepTimeMin: 0,
          displayScore: 96,
          breakdown: const ScoreBreakdown(
            macro: 0.9,
            micro: 0.58,
            penalty: 0.05,
            cost: 0.08,
            preference: 0.52,
            access: 0.05,
          ),
        ),
        _sampleFood(
          22,
          name: 'Bean and rice bowl',
          servingLabel: '1 bowl',
          ingredients: const {'beans', 'rice'},
          costEstimate: 2.25,
          displayScore: 82,
          breakdown: const ScoreBreakdown(
            macro: 0.7,
            micro: 0.46,
            penalty: 0.1,
            cost: 0.18,
            preference: 0.48,
            access: -0.02,
          ),
        ),
        _sampleFood(
          23,
          name: 'Peanut butter on whole wheat',
          servingLabel: '1 sandwich',
          ingredients: const {'peanut butter', 'whole wheat bread'},
          costEstimate: 1.75,
          displayScore: 74,
          breakdown: const ScoreBreakdown(
            macro: 0.52,
            micro: 0.34,
            penalty: 0.12,
            cost: 0.28,
            preference: 0.44,
            access: -0.08,
          ),
        ),
      ];
      final shoppingPlans = {
        recommendations[0].food.id: _shoppingPlanFor(
          recommendations[0].food,
          metric: const TravelMetric(
            source: TravelMetricSource.liveRoute,
            distanceMiles: 1.0,
            durationMinutes: 5,
          ),
          atHome: const [
            IngredientRequirement(
              key: 'mustard',
              label: 'Mustard',
              searchTerms: ['mustard'],
              pantryAliases: ['mustard'],
              evidence: IngredientEvidence.structured,
            ),
          ],
          toBuy: const [
            IngredientRequirement(
              key: 'tuna',
              label: 'Tuna pouch',
              searchTerms: ['tuna'],
              pantryAliases: ['tuna'],
              evidence: IngredientEvidence.structured,
            ),
            IngredientRequirement(
              key: 'bread',
              label: 'Whole-wheat bread',
              searchTerms: ['whole wheat bread'],
              pantryAliases: ['bread'],
              evidence: IngredientEvidence.structured,
            ),
          ],
        ),
        recommendations[1].food.id: _shoppingPlanFor(
          recommendations[1].food,
          metric: const TravelMetric(
            source: TravelMetricSource.liveRoute,
            distanceMiles: 2.1,
            durationMinutes: 12,
          ),
          atHome: const [
            IngredientRequirement(
              key: 'rice',
              label: 'Instant rice',
              searchTerms: ['rice'],
              pantryAliases: ['rice'],
              evidence: IngredientEvidence.structured,
            ),
          ],
          toBuy: const [
            IngredientRequirement(
              key: 'beans',
              label: 'Canned beans',
              searchTerms: ['beans'],
              pantryAliases: ['beans'],
              evidence: IngredientEvidence.structured,
            ),
          ],
        ),
        recommendations[2].food.id: _shoppingPlanFor(
          recommendations[2].food,
          metric: const TravelMetric(
            source: TravelMetricSource.liveRoute,
            distanceMiles: 3.4,
            durationMinutes: 18,
          ),
          atHome: const [],
          toBuy: const [
            IngredientRequirement(
              key: 'peanut_butter',
              label: 'Peanut butter',
              searchTerms: ['peanut butter'],
              pantryAliases: ['peanut butter'],
              evidence: IngredientEvidence.structured,
            ),
            IngredientRequirement(
              key: 'bread',
              label: 'Whole-wheat bread',
              searchTerms: ['whole wheat bread'],
              pantryAliases: ['bread'],
              evidence: IngredientEvidence.structured,
            ),
          ],
        ),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingLocationStateProvider.overrideWith(
              (ref) => const ShoppingLocationState(apiConfigured: true),
            ),
            storeAvailabilityModeProvider.overrideWith(
              (ref) => _onlineStoreAvailabilityMode(),
            ),
            mealShoppingSummariesProvider.overrideWith(
              (ref) async => shoppingPlans,
            ),
            prefetchedLiveMealShoppingPlansProvider.overrideWith(
              (ref) async => shoppingPlans,
            ),
          ],
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final recommendation in recommendations)
                      RecommendationCard(
                        recommendation: recommendation,
                        constraints: constraints,
                        onExplain: () {},
                        onTrack: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final recommendation in recommendations) {
        await tester.tap(
          find.byKey(ValueKey('score-badge-${recommendation.food.id}')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('score-sheet-title')), findsOneWidget);
        expect(find.text('How this was scored.'), findsOneWidget);
        expect(find.text('Nutrition fit'), findsOneWidget);
        expect(find.text('Budget fit'), findsOneWidget);
        expect(find.text('Access fit'), findsOneWidget);
        expect(find.text('Dietary safety'), findsOneWidget);
        expect(find.text('Pantry overlap'), findsOneWidget);
        expect(find.text('Overall fit score.'), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('score-sheet-overall-score')),
              )
              .data,
          '${recommendation.displayScore.round()}',
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Got it.'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'recommendation card never pairs a chain meal with a wrong-brand store',
    (tester) async {
      final recommendation = _sampleFood(
        1020,
        name: 'Taco Bell Power Menu Bowl',
        availability: const {AvailabilityContext.fastFood},
      );
      final marcos = NearbyStore(
        placeId: 'marcos',
        name: "Marco's Pizza",
        address: "Marco's Pizza, 123 Demo St",
        latitude: 39.10,
        longitude: -84.51,
        categories: const {AvailabilityContext.fastFood},
        primaryCategory: AvailabilityContext.fastFood,
        discoveryVerification: DataVerification.live,
        travelMetric: const TravelMetric(
          source: TravelMetricSource.straightLineApproximate,
          distanceMiles: 1.5,
        ),
        brandKey: 'marcos_pizza',
      );
      final unverifiedPlan = MealShoppingPlan(
        food: recommendation.food,
        ingredients: IngredientPlan(
          atHome: const [],
          toBuy: [
            IngredientRequirement(
              key: 'order-1020',
              label: recommendation.food.name,
              searchTerms: const [],
              pantryAliases: const [],
              evidence: IngredientEvidence.menuItem,
              quantityLabel: recommendation.food.servingLabel,
            ),
          ],
        ),
        chosenStore: null,
        backupStores: const [],
        candidateStores: [marcos],
        liveProductMatch: null,
        liveLookupAttempted: true,
        storeStatusNote:
            'No nearby Taco Bell verified for this search. '
            "Nearest fast-food options nearby: Marco's Pizza.",
        offlineAvailabilityContext: AvailabilityContext.fastFood,
        requiredMerchantKey: 'taco_bell',
        requiredMerchantName: 'Taco Bell',
        merchantVerified: false,
        merchantAlternatives: [marcos],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingLocationStateProvider.overrideWith(
              (ref) => const ShoppingLocationState(apiConfigured: true),
            ),
            storeAvailabilityModeProvider.overrideWith(
              (ref) => _onlineStoreAvailabilityMode(),
            ),
            mealShoppingSummariesProvider.overrideWith(
              (ref) async => {recommendation.food.id: unverifiedPlan},
            ),
            prefetchedLiveMealShoppingPlansProvider.overrideWith(
              (ref) async => {recommendation.food.id: unverifiedPlan},
            ),
          ],
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
      );
      await tester.pumpAndSettle();

      // It says, explicitly, that the required chain was not found.
      expect(
        find.textContaining('No nearby Taco Bell verified'),
        findsOneWidget,
      );
      // It is never presented as verified, and never as a "Go to" store.
      expect(find.text('Verified'), findsNothing);
      expect(
        find.textContaining("Marco's Pizza | "),
        findsNothing,
        reason: "Marco's Pizza must not be shown as the meal's store",
      );
    },
  );
}

ScoredFood _sampleFood(
  int id, {
  String name = 'Oatmeal cup',
  String servingLabel = '1 cup',
  Set<String> ingredients = const {'oatmeal', 'oats'},
  double costEstimate = 1.25,
  String prepMethod = 'microwave',
  int prepTimeMin = 2,
  Set<AvailabilityContext> availability = const {
    AvailabilityContext.grocery,
    AvailabilityContext.convenience,
  },
  double displayScore = 88,
  ScoreBreakdown breakdown = const ScoreBreakdown(
    macro: 0.72,
    micro: 0.44,
    penalty: 0.08,
    cost: 0.12,
    preference: 0.5,
  ),
}) {
  return ScoredFood(
    food: Food(
      id: id,
      name: name,
      category: 'grain_whole',
      servingG: 64,
      servingLabel: servingLabel,
      costEstimate: costEstimate,
      costConfidence: 'medium',
      prepMethod: prepMethod,
      prepTimeMin: prepTimeMin,
      mealTypes: const {MealType.breakfast},
      availability: availability,
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: ingredients,
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
    displayScore: displayScore,
    breakdown: breakdown,
  );
}

StoreAvailabilityModeState _onlineStoreAvailabilityMode({
  SearchLocation? location,
}) {
  return StoreAvailabilityModeState(
    mode: StoreAvailabilityMode.online,
    apiConfigured: true,
    hasInternet: true,
    location:
        location ??
        const SearchLocation(
          kind: SearchLocationKind.device,
          label: '4001 W Chicago Ave, Chicago, IL 60651',
          latitude: 41.8955,
          longitude: -87.7261,
          verification: DataVerification.live,
          postalCode: '60651',
        ),
  );
}

MealShoppingPlan _shoppingPlanFor(
  Food food, {
  List<IngredientRequirement> atHome = const [],
  List<IngredientRequirement>? toBuy,
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
    key: food.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
    label: food.name,
    searchTerms: [food.name.toLowerCase()],
    pantryAliases: [food.name.toLowerCase()],
    evidence: IngredientEvidence.structured,
    quantityLabel: food.servingLabel,
  );
  final buyItems = toBuy ?? [ingredient];
  return MealShoppingPlan(
    food: food,
    ingredients: IngredientPlan(
      atHome: atHome,
      toBuy: buyItems,
      buySummary: buyItems.map((item) => item.label).join(', '),
    ),
    chosenStore: chosenStore,
    backupStores: const [],
    candidateStores: [chosenStore],
    liveProductMatch: LiveStoreMatch(
      store: chosenStore,
      lookup: LiveIngredientLookupResult(
        store: groceryStore,
        matches: [
          for (final item in buyItems)
            IngredientProductMatch(
              ingredient: item,
              products: [
                GroceryProduct(
                  retailer: GroceryRetailer.kroger,
                  productId: 'p-${food.id}-${item.key}',
                  description: item.label,
                  brand: 'Store Brand',
                  size: item.quantityLabel ?? food.servingLabel,
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
    offlineAvailabilityContext: AvailabilityContext.grocery,
  );
}

MealShoppingPlan _shoppingPlanWithoutStore(Food food) {
  final ingredient = IngredientRequirement(
    key: food.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
    label: food.name,
    searchTerms: [food.name.toLowerCase()],
    pantryAliases: [food.name.toLowerCase()],
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
    chosenStore: null,
    backupStores: const [],
    candidateStores: const [],
    liveProductMatch: null,
    liveLookupAttempted: false,
    storeStatusNote: 'Nearby store verification is unavailable for this meal.',
    offlineAvailabilityContext: AvailabilityContext.grocery,
  );
}
