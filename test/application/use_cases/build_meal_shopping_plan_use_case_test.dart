import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/application/use_cases/build_meal_shopping_plan_use_case.dart';
import 'package:access_plate/application/use_cases/lookup_live_ingredient_products_use_case.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/ingredient_availability_catalog.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/repositories/grocery_catalog_repository.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';

void main() {
  group('BuildMealShoppingPlanUseCase', () {
    test(
      'keeps the chosen store aligned with live products when the closest store also has coverage',
      () async {
        final repository = _FakeGroceryCatalogRepository(
          productsByStoreAndTerm: {
            '1001|black beans': [_product('p1', 'Simple Truth', 1.89)],
            '1001|brown rice cup': [_product('p2', 'Minute', 2.19)],
            '1001|salsa': [_product('p3', 'Herdez', 2.49)],
            '1002|black beans': [_product('p4', 'Kroger', 1.99)],
            '1002|brown rice cup': [_product('p5', 'Ben\'s', 2.29)],
            '1002|salsa': [_product('p6', 'Pace', 2.69)],
          },
        );
        final useCase = BuildMealShoppingPlanUseCase(
          liveProductLookupUseCase: LookupLiveIngredientProductsUseCase(
            repository,
          ),
          ingredientAvailabilityCatalog: _ingredientAvailabilityCatalog,
        );

        final basePlan = useCase.buildSummary(
          food: _groceryMeal(),
          constraints: _constraints(),
          nearbyStores: [
            _nearbyStore(
              placeId: 'near',
              name: 'Kroger Marketplace',
              locationId: '1001',
              durationMinutes: 8,
              distanceMiles: 1.8,
            ),
            _nearbyStore(
              placeId: 'far',
              name: 'Kroger',
              locationId: '1002',
              durationMinutes: 15,
              distanceMiles: 4.7,
            ),
          ],
        );

        expect(basePlan.chosenStore?.placeId, 'near');

        final enriched = await useCase.enrichWithLiveProducts(basePlan);

        expect(enriched.chosenStore?.placeId, 'near');
        expect(enriched.liveProductMatch?.store.placeId, 'near');
        expect(enriched.isPrimaryStoreConsistent, isTrue);
        expect(enriched.backupStores.map((store) => store.placeId), ['far']);
      },
    );

    test(
      'promotes a backup store to chosen primary when live coverage is better',
      () async {
        final repository = _FakeGroceryCatalogRepository(
          productsByStoreAndTerm: {
            '1001|black beans': [_product('p1', 'Simple Truth', 1.89)],
            '1002|black beans': [_product('p4', 'Kroger', 1.99)],
            '1002|brown rice cup': [_product('p5', 'Ben\'s', 2.29)],
            '1002|salsa': [_product('p6', 'Pace', 2.69)],
          },
        );
        final useCase = BuildMealShoppingPlanUseCase(
          liveProductLookupUseCase: LookupLiveIngredientProductsUseCase(
            repository,
          ),
          ingredientAvailabilityCatalog: _ingredientAvailabilityCatalog,
        );

        final basePlan = useCase.buildSummary(
          food: _groceryMeal(),
          constraints: _constraints(),
          nearbyStores: [
            _nearbyStore(
              placeId: 'near',
              name: 'Kroger Marketplace',
              locationId: '1001',
              durationMinutes: 8,
              distanceMiles: 1.8,
            ),
            _nearbyStore(
              placeId: 'far',
              name: 'Kroger',
              locationId: '1002',
              durationMinutes: 15,
              distanceMiles: 4.7,
            ),
          ],
        );

        final enriched = await useCase.enrichWithLiveProducts(basePlan);

        expect(enriched.chosenStore?.placeId, 'far');
        expect(enriched.liveProductMatch?.store.placeId, 'far');
        expect(enriched.isPrimaryStoreConsistent, isTrue);
        expect(enriched.backupStores.map((store) => store.placeId), ['near']);
        expect(enriched.liveProductMatch?.lookup.unmatchedIngredients, isEmpty);
      },
    );

    test(
      'does not pick a different brand for a chain-specific meal (Taco Bell + only Marco\'s)',
      () {
        final useCase = _useCase();

        final plan = useCase.buildSummary(
          food: _tacoBellMeal(),
          constraints: _fastFoodConstraints(),
          nearbyStores: [
            _fastFoodStore(
              placeId: 'marcos',
              name: "Marco's Pizza",
              brandKey: 'marcos_pizza',
              distanceMiles: 1.5,
            ),
            _fastFoodStore(
              placeId: 'subway',
              name: 'Subway',
              brandKey: 'subway',
              distanceMiles: 2.1,
            ),
          ],
        );

        // The chain meal is NOT tied to a wrong-brand store.
        expect(plan.chosenStore, isNull);
        expect(plan.isMerchantSpecific, isTrue);
        expect(plan.merchantVerified, isFalse);
        expect(plan.requiredMerchantName, 'Taco Bell');
        // No wrong-brand store is dressed up as a backup.
        expect(plan.backupStores, isEmpty);
        // Alternatives are surfaced honestly for "nearest fast food" copy.
        expect(
          plan.merchantAlternatives.map((store) => store.name),
          ["Marco's Pizza", 'Subway'],
        );
        expect(
          plan.storeStatusNote,
          'No nearby Taco Bell verified for this search. '
          "Nearest fast-food options nearby: Marco's Pizza, Subway.",
        );
      },
    );

    test(
      'verifies a chain-specific meal against the matching brand and nearest one',
      () {
        final useCase = _useCase();

        final plan = useCase.buildSummary(
          food: _tacoBellMeal(),
          constraints: _fastFoodConstraints(),
          nearbyStores: [
            _fastFoodStore(
              placeId: 'marcos',
              name: "Marco's Pizza",
              brandKey: 'marcos_pizza',
              distanceMiles: 0.4,
            ),
            _fastFoodStore(
              placeId: 'tb-near',
              name: 'Taco Bell',
              brandKey: 'taco_bell',
              distanceMiles: 1.2,
            ),
            _fastFoodStore(
              placeId: 'tb-far',
              name: 'Taco Bell',
              brandKey: 'taco_bell',
              distanceMiles: 3.6,
            ),
          ],
        );

        expect(plan.merchantVerified, isTrue);
        expect(plan.chosenStore?.placeId, 'tb-near');
        expect(plan.chosenStore?.brandKey, 'taco_bell');
        // Backups only include other Taco Bells, never Marco's Pizza.
        expect(plan.backupStores.map((store) => store.placeId), ['tb-far']);
        expect(plan.storeStatusNote, isNull);
      },
    );

    test('adds an offline source context from the bundled ingredient map', () {
      final useCase = BuildMealShoppingPlanUseCase(
        liveProductLookupUseCase: LookupLiveIngredientProductsUseCase(
          _FakeGroceryCatalogRepository(productsByStoreAndTerm: const {}),
        ),
        ingredientAvailabilityCatalog: _ingredientAvailabilityCatalog,
      );

      final plan = useCase.buildSummary(
        food: _groceryMeal(),
        constraints: _constraints(),
        nearbyStores: const [],
      );

      expect(plan.chosenStore, isNull);
      expect(plan.offlineAvailabilityContext, AvailabilityContext.grocery);
    });
  });
}

final _ingredientAvailabilityCatalog = IngredientAvailabilityCatalog.fromJson(
  const {
    'black beans': ['grocery', 'dollar_store', 'food_pantry'],
    'brown rice': ['grocery', 'dollar_store', 'food_pantry'],
    'salsa': ['grocery'],
  },
);

BuildMealShoppingPlanUseCase _useCase() {
  return BuildMealShoppingPlanUseCase(
    liveProductLookupUseCase: LookupLiveIngredientProductsUseCase(
      _FakeGroceryCatalogRepository(productsByStoreAndTerm: const {}),
    ),
    ingredientAvailabilityCatalog: _ingredientAvailabilityCatalog,
  );
}

UserConstraints _constraints() {
  return UserConstraints.defaults().copyWith(
    feasibility: const FeasibilityConstraints(
      availability: {AvailabilityContext.grocery},
    ),
  );
}

UserConstraints _fastFoodConstraints() {
  return UserConstraints.defaults().copyWith(
    feasibility: const FeasibilityConstraints(
      availability: {AvailabilityContext.fastFood},
    ),
  );
}

Food _tacoBellMeal() {
  return Food(
    id: 1020,
    name: 'Taco Bell Power Menu Bowl',
    category: 'prepared_meal',
    servingG: 420,
    servingLabel: '1 bowl',
    costEstimate: 8.79,
    costConfidence: 'low',
    prepMethod: 'none',
    prepTimeMin: 0,
    mealTypes: const {MealType.lunch, MealType.dinner},
    availability: const {AvailabilityContext.fastFood},
    allergens: const {},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: const {'beans', 'cheese', 'chicken', 'rice'},
    source: 'test_fixture',
    merchantBrandKey: 'taco_bell',
  );
}

NearbyStore _fastFoodStore({
  required String placeId,
  required String name,
  required String brandKey,
  required double distanceMiles,
}) {
  return NearbyStore(
    placeId: placeId,
    name: name,
    address: '$name address',
    latitude: 39.10,
    longitude: -84.51,
    categories: const {AvailabilityContext.fastFood},
    primaryCategory: AvailabilityContext.fastFood,
    discoveryVerification: DataVerification.live,
    travelMetric: TravelMetric(
      source: TravelMetricSource.straightLineApproximate,
      distanceMiles: distanceMiles,
    ),
    brandKey: brandKey,
  );
}

Food _groceryMeal() {
  return Food(
    id: 2,
    name: 'Black bean rice bowl',
    category: 'prepared_meal',
    servingG: 320,
    servingLabel: '1 bowl',
    costEstimate: 4.25,
    costConfidence: 'medium',
    prepMethod: 'microwave',
    prepTimeMin: 3,
    mealTypes: const {MealType.lunch},
    availability: const {AvailabilityContext.grocery},
    allergens: const {},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: const {'black beans', 'brown rice', 'salsa'},
    source: 'test_fixture',
  );
}

NearbyStore _nearbyStore({
  required String placeId,
  required String name,
  required String locationId,
  required int durationMinutes,
  required double distanceMiles,
}) {
  final groceryStore = GroceryStore(
    retailer: GroceryRetailer.kroger,
    locationId: locationId,
    name: name,
    addressLine1: '123 Demo St',
    city: 'Demo',
    state: 'OH',
    postalCode: '45202',
  );
  return NearbyStore(
    placeId: placeId,
    name: name,
    address: groceryStore.addressLabel,
    latitude: 39.10,
    longitude: -84.51,
    categories: const {AvailabilityContext.grocery},
    primaryCategory: AvailabilityContext.grocery,
    discoveryVerification: DataVerification.live,
    travelMetric: TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: distanceMiles,
      durationMinutes: durationMinutes,
    ),
    linkedGroceryStore: groceryStore,
  );
}

GroceryProduct _product(String id, String brand, double price) {
  return GroceryProduct(
    retailer: GroceryRetailer.kroger,
    productId: id,
    description: '$brand item',
    brand: brand,
    size: '1 ct',
    regularPrice: price,
  );
}

class _FakeGroceryCatalogRepository implements GroceryCatalogRepository {
  _FakeGroceryCatalogRepository({required this.productsByStoreAndTerm});

  final Map<String, List<GroceryProduct>> productsByStoreAndTerm;

  @override
  bool get isConfigured => true;

  @override
  GroceryRetailer get retailer => GroceryRetailer.kroger;

  @override
  Future<List<GroceryProduct>> searchProducts({
    required GroceryStore store,
    required String term,
    int limit = 12,
  }) async {
    return productsByStoreAndTerm['${store.locationId}|${term.toLowerCase()}'] ??
        const <GroceryProduct>[];
  }

  @override
  Future<List<GroceryStore>> searchStores({
    required String postalCode,
    int limit = 8,
    int radiusMiles = 20,
  }) {
    throw UnimplementedError();
  }
}
