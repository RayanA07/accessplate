import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/application/use_cases/lookup_live_ingredient_products_use_case.dart';
import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/meal_shopping.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/repositories/grocery_catalog_repository.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';

void main() {
  test('reuses cached live product searches across repeated executions', () async {
    final repository = _CountingGroceryCatalogRepository(
      productsByStoreAndTerm: {
        '1001|milk': [_product('p1', 'Kroger Milk', 2.49)],
        '1001|oats': [_product('p2', 'Quaker Oats', 3.19)],
      },
    );
    final useCase = LookupLiveIngredientProductsUseCase(repository);
    final candidateStore = _nearbyStore();
    const ingredients = [
      IngredientRequirement(
        key: 'milk',
        label: 'Milk',
        searchTerms: ['milk'],
        pantryAliases: ['milk'],
        evidence: IngredientEvidence.structured,
      ),
      IngredientRequirement(
        key: 'oats',
        label: 'Oats',
        searchTerms: ['oats'],
        pantryAliases: ['oats'],
        evidence: IngredientEvidence.structured,
      ),
    ];

    final first = await useCase.execute(
      candidateStores: [candidateStore],
      ingredients: ingredients,
      productsPerIngredient: 1,
    );
    final second = await useCase.execute(
      candidateStores: [candidateStore],
      ingredients: ingredients,
      productsPerIngredient: 1,
    );

    expect(first?.store.placeId, 'store-1');
    expect(second?.store.placeId, 'store-1');
    expect(repository.searchProductsCalls, 2);
  });
}

NearbyStore _nearbyStore() {
  final groceryStore = GroceryStore(
    retailer: GroceryRetailer.kroger,
    locationId: '1001',
    name: 'Kroger',
    addressLine1: '123 Demo St',
    city: 'Demo',
    state: 'OH',
    postalCode: '45202',
  );
  return NearbyStore(
    placeId: 'store-1',
    name: 'Kroger',
    address: groceryStore.addressLabel,
    latitude: 39.10,
    longitude: -84.51,
    categories: const {AvailabilityContext.grocery},
    primaryCategory: AvailabilityContext.grocery,
    discoveryVerification: DataVerification.live,
    travelMetric: const TravelMetric(
      source: TravelMetricSource.liveRoute,
      distanceMiles: 1.2,
      durationMinutes: 6,
    ),
    linkedGroceryStore: groceryStore,
  );
}

GroceryProduct _product(String id, String description, double price) {
  return GroceryProduct(
    retailer: GroceryRetailer.kroger,
    productId: id,
    description: description,
    brand: description.split(' ').first,
    size: '1 ct',
    regularPrice: price,
  );
}

class _CountingGroceryCatalogRepository implements GroceryCatalogRepository {
  _CountingGroceryCatalogRepository({required this.productsByStoreAndTerm});

  final Map<String, List<GroceryProduct>> productsByStoreAndTerm;
  int searchProductsCalls = 0;

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
    searchProductsCalls += 1;
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
