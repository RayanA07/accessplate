import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/widgets/meal_logo_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MealLogoResolver', () {
    test('uses Chipotle logo for chipotle fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Chipotle Chicken Burrito Bowl',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Chipotle');
      expect(selection?.assetPath, 'assets/branding/meal_logos/chipotle.png');
    });

    test('uses Taco Bell logo for taco bell fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Taco Bell Power Menu Bowl',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Taco Bell');
      expect(selection?.assetPath, 'assets/branding/meal_logos/taco_bell.png');
    });

    test('uses Chick-fil-A logo for chick-fil-a fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Chick-fil-A grilled nuggets',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Chick-fil-A');
      expect(
        selection?.assetPath,
        'assets/branding/meal_logos/chick_fil_a.png',
      );
    });

    test('uses McDonald\'s logo for mcdonalds fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'McDonald\'s Big Mac',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'McDonald\'s');
      expect(selection?.assetPath, 'assets/branding/meal_logos/mcdonalds.png');
    });

    test('uses Burger King logo for burger king fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Burger King Whopper Jr.',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Burger King');
      expect(
        selection?.assetPath,
        'assets/branding/meal_logos/burger_king.png',
      );
    });

    test('uses Wendy\'s logo for wendys fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Wendy\'s chili',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Wendy\'s');
      expect(selection?.assetPath, 'assets/branding/meal_logos/wendys.png');
    });

    test('uses Subway logo for subway fast-food meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'Subway turkey footlong',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection?.label, 'Subway');
      expect(selection?.assetPath, 'assets/branding/meal_logos/subway.png');
    });

    test('does not use grocery store logos for grocery meals', () {
      final selection = MealLogoResolver.resolve(
        food: _food(name: 'Rice and beans bowl'),
        constraints: UserConstraints.defaults().copyWith(
          feasibility: const FeasibilityConstraints(
            availability: {AvailabilityContext.grocery},
            groceryStore: GroceryStore(
              retailer: GroceryRetailer.kroger,
              locationId: 'kroger-demo',
              name: 'Kroger Marketplace',
              addressLine1: '1 Main St',
              city: 'Cincinnati',
              state: 'OH',
              postalCode: '45211',
            ),
          ),
        ),
        plan: _plan(
          chosenStore: NearbyStore(
            placeId: 'kroger-nearby',
            name: 'Kroger Marketplace',
            address: '1 Main St',
            latitude: 0,
            longitude: 0,
            categories: const {AvailabilityContext.grocery},
            primaryCategory: AvailabilityContext.grocery,
            discoveryVerification: DataVerification.live,
            travelMetric: const TravelMetric(
              source: TravelMetricSource.liveRoute,
              durationMinutes: 8,
            ),
          ),
          offlineAvailabilityContext: AvailabilityContext.grocery,
        ),
      );

      expect(selection, isNull);
    });

    test(
      'does not use grocery logos even when the nearby store name matches',
      () {
        final selection = MealLogoResolver.resolve(
          food: _food(name: 'Homestyle chicken soup'),
          plan: _plan(
            chosenStore: NearbyStore(
              placeId: 'safeway-nearby',
              name: 'Safeway',
              address: '100 Market St',
              latitude: 0,
              longitude: 0,
              categories: const {AvailabilityContext.grocery},
              primaryCategory: AvailabilityContext.grocery,
              discoveryVerification: DataVerification.live,
              travelMetric: const TravelMetric(
                source: TravelMetricSource.liveRoute,
                durationMinutes: 12,
              ),
            ),
            offlineAvailabilityContext: AvailabilityContext.grocery,
          ),
        );

        expect(selection, isNull);
      },
    );

    test('falls back when there is no supported brand match', () {
      final selection = MealLogoResolver.resolve(
        food: _food(
          name: 'White Castle sliders',
          availability: const {AvailabilityContext.fastFood},
        ),
      );

      expect(selection, isNull);
    });
  });
}

Food _food({
  required String name,
  Set<AvailabilityContext> availability = const {AvailabilityContext.grocery},
}) {
  return Food(
    id: name.hashCode,
    name: name,
    category: 'prepared_meal',
    servingG: 100,
    servingLabel: '1 serving',
    costEstimate: 4,
    costConfidence: 'medium',
    prepMethod: 'none',
    prepTimeMin: 0,
    mealTypes: const {MealType.lunch},
    availability: availability,
    allergens: const {},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: {'rice', 'beans'},
  );
}

MealShoppingPlan _plan({
  required NearbyStore chosenStore,
  required AvailabilityContext offlineAvailabilityContext,
}) {
  return MealShoppingPlan(
    food: _food(name: 'Plan food'),
    ingredients: const IngredientPlan(atHome: [], toBuy: []),
    chosenStore: chosenStore,
    backupStores: const [],
    candidateStores: [chosenStore],
    liveProductMatch: null,
    offlineAvailabilityContext: offlineAvailabilityContext,
  );
}
