import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/local_access.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/dietary_style.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/providers/app_bootstrap.dart';
import 'package:access_plate/presentation/providers/live_grocery_providers.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/providers/recommendations_provider.dart';
import 'package:access_plate/presentation/screens/recommendations/recommendations_screen.dart';

void main() {
  testWidgets('recommendations screen stays balanced on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final profile = UserProfile.defaults().copyWith(
      onboardingComplete: true,
      constraints: UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          maxCostPerMeal: 11,
          availability: {
            AvailabilityContext.grocery,
            AvailabilityContext.convenience,
            AvailabilityContext.foodPantry,
          },
        ),
        preference: const PreferenceConstraints(
          dietaryStyle: DietaryStyle.vegetarian,
          mealType: MealType.lunch,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localAccessCatalogProvider.overrideWith((ref) async => _testAccessCatalog),
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
          recommendationsProvider.overrideWith((ref) async => _result),
        ],
        child: const MaterialApp(home: RecommendationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Vegetarian lunch suggestions'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recommended for now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recommended for now'), findsOneWidget);
    expect(
      find.text('Safe, feasible picks ordered by fit, quality, and tradeoffs.'),
      findsOneWidget,
    );
  });

  testWidgets('shows live grocery preview when a store is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final profile = UserProfile.defaults().copyWith(
      onboardingComplete: true,
      constraints: UserConstraints.defaults().copyWith(
        feasibility: const FeasibilityConstraints(
          availability: {AvailabilityContext.grocery},
          groceryStore: GroceryStore(
            retailer: GroceryRetailer.kroger,
            locationId: '01400477',
            name: 'Kroger Delhi',
            addressLine1: '5080 Delhi Pike',
            city: 'Cincinnati',
            state: 'OH',
            postalCode: '45238',
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localAccessCatalogProvider.overrideWith((ref) async => _testAccessCatalog),
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
          recommendationsProvider.overrideWith((ref) async => _result),
          liveGroceryMatchesProvider.overrideWith(
            (ref) async => {
              1: GroceryProductLookup(
                foodId: 1,
                foodName: 'Sweet potato with black beans',
                store: const GroceryStore(
                  retailer: GroceryRetailer.kroger,
                  locationId: '01400477',
                  name: 'Kroger Delhi',
                  addressLine1: '5080 Delhi Pike',
                  city: 'Cincinnati',
                  state: 'OH',
                  postalCode: '45238',
                ),
                plan: const GrocerySearchPlan(
                  term: 'black beans',
                  displayLabel: 'black beans',
                  rationale: 'Core staple search for this suggestion',
                  exactMatch: false,
                ),
                products: const [
                  GroceryProduct(
                    retailer: GroceryRetailer.kroger,
                    productId: '1',
                    description: 'Simple Truth Black Beans',
                    brand: 'Simple Truth',
                    regularPrice: 1.19,
                    availableInStore: true,
                  ),
                  GroceryProduct(
                    retailer: GroceryRetailer.kroger,
                    productId: '2',
                    description: 'Kroger Black Beans',
                    brand: 'Kroger',
                    regularPrice: 0.99,
                    availableInStore: true,
                  ),
                ],
              ),
            },
          ),
        ],
        child: const MaterialApp(home: RecommendationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('brands at Kroger Delhi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('black beans brands at Kroger Delhi'),
      findsOneWidget,
    );
    expect(find.text('Simple Truth | \$1.19'), findsOneWidget);
  });
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

final _result = RecommendationResult(
  recommendations: List.generate(10, (index) => _buildFood(index + 1)),
  preferenceRelaxed: false,
  candidatePoolSize: 17,
  elapsedMs: 32,
  todayPlan: TodayPlan(
    type: TodayPlanType.pantryFirst,
    title: 'Today plan: pantry-first',
    summary: 'Stretch pantry food before spending on a larger run.',
    steps: [
      'Use black beans from home first.',
      'Add one fresh item only if you still need it.',
      'Keep the total low before a full grocery trip.',
    ],
    highlights: ['Pantry-first', 'Food pantry'],
    leadRecommendation: ScoredFood(
      food: Food(
        id: 999,
        name: 'Sweet potato with black beans',
        category: 'vegetable_starchy',
        servingG: 320,
        servingLabel: '1 medium + 1/2 cup',
        costEstimate: 1.8,
        costConfidence: 'medium',
        prepMethod: 'microwave',
        prepTimeMin: 7,
        cuisine: 'american',
        mealTypes: const {MealType.lunch, MealType.dinner},
        availability: const {
          AvailabilityContext.grocery,
          AvailabilityContext.foodPantry,
        },
        allergens: const {},
        religionExcluded: const [],
        medicalRules: const [],
        ingredients: const {'sweet', 'potato', 'black', 'beans'},
        source: 'bundled_reference',
      ),
      nutrients: const Nutrients(
        caloriesKcal: 340,
        proteinG: 13,
        carbsG: 70,
        fatG: 1.5,
        saturatedFatG: 0.2,
        fiberG: 14,
        sugarG: 14,
        addedSugarG: 0,
        sodiumMg: 240,
        potassiumMg: 1040,
        calciumMg: 100,
        ironMg: 3.6,
        magnesiumMg: 90,
        zincMg: 1.6,
        vitAMcgRae: 1800,
        vitCMg: 36,
        vitDMcg: 0,
        vitB12Mcg: 0,
        folateMcgDfe: 180,
      ),
      composite: 0.76,
      displayScore: 100,
      breakdown: const ScoreBreakdown(
        macro: 0.8,
        micro: 0.75,
        penalty: 0.05,
        cost: 0.16,
        preference: 0.7,
      ),
    ),
  ),
);

const _testAccessCatalog = LocalAccessCatalog(
  exactZipProfiles: {},
  prefixProfiles: {},
  fallbackProfile: LocalAccessProfile(
    profileId: 'fallback',
    label: 'Fallback',
    communityLabel: 'Fallback',
    lowAccessArea: true,
    sources: {
      AvailabilityContext.foodPantry: SourceAccessSnapshot(
        nearbyOptions: 2,
        typicalTravelMinutes: 12,
        sameDayConfidence: 0.75,
      ),
      AvailabilityContext.grocery: SourceAccessSnapshot(
        nearbyOptions: 1,
        typicalTravelMinutes: 20,
        sameDayConfidence: 0.6,
      ),
    },
  ),
);

ScoredFood _buildFood(int id) {
  return ScoredFood(
    food: Food(
      id: id,
      name: 'Sweet potato with black beans',
      category: 'vegetable_starchy',
      servingG: 320,
      servingLabel: '1 medium + 1/2 cup',
      costEstimate: 1.8,
      costConfidence: 'medium',
      prepMethod: 'microwave',
      prepTimeMin: 7,
      cuisine: 'american',
      mealTypes: const {MealType.lunch, MealType.dinner},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.foodPantry,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'sweet', 'potato', 'black', 'beans'},
      source: 'bundled_reference',
    ),
    nutrients: const Nutrients(
      caloriesKcal: 340,
      proteinG: 13,
      carbsG: 70,
      fatG: 1.5,
      saturatedFatG: 0.2,
      fiberG: 14,
      sugarG: 14,
      addedSugarG: 0,
      sodiumMg: 240,
      potassiumMg: 1040,
      calciumMg: 100,
      ironMg: 3.6,
      magnesiumMg: 90,
      zincMg: 1.6,
      vitAMcgRae: 1800,
      vitCMg: 36,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 180,
    ),
    composite: 0.76,
    displayScore: 100,
    breakdown: const ScoreBreakdown(
      macro: 0.8,
      micro: 0.75,
      penalty: 0.05,
      cost: 0.16,
      preference: 0.7,
    ),
  );
}
