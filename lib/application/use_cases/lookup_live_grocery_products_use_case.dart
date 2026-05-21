import '../../domain/entities/food.dart';
import '../../domain/entities/grocery.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';
import '../services/grocery_query_planner.dart';

class LookupLiveGroceryProductsUseCase {
  LookupLiveGroceryProductsUseCase(
    this._repository, {
    GroceryQueryPlanner? queryPlanner,
  }) : _queryPlanner = queryPlanner ?? GroceryQueryPlanner();

  final GroceryCatalogRepository _repository;
  final GroceryQueryPlanner _queryPlanner;

  Future<Map<int, GroceryProductLookup>> execute({
    required GroceryStore store,
    required Iterable<Food> foods,
    int productsPerFood = 4,
  }) async {
    if (!_repository.isConfigured) {
      return const {};
    }

    final lookups = await Future.wait(
      foods.map(
        (food) => _lookupFood(
          store: store,
          food: food,
          productsPerFood: productsPerFood,
        ),
      ),
    );

    return {
      for (final lookup in lookups.whereType<GroceryProductLookup>())
        lookup.foodId: lookup,
    };
  }

  Future<GroceryProductLookup?> _lookupFood({
    required GroceryStore store,
    required Food food,
    required int productsPerFood,
  }) async {
    final plans = _queryPlanner.buildSearchPlans(food);
    if (plans.isEmpty) {
      return null;
    }

    for (final plan in plans) {
      try {
        final products = await _repository.searchProducts(
          store: store,
          term: plan.term,
          limit: 12,
        );
        final normalized = _normalizeProducts(products, limit: productsPerFood);
        if (normalized.isNotEmpty) {
          return GroceryProductLookup(
            foodId: food.id,
            foodName: food.name,
            store: store,
            plan: plan,
            products: normalized,
          );
        }
      } on GroceryCatalogException {
        return null;
      }
    }

    return null;
  }

  List<GroceryProduct> _normalizeProducts(
    List<GroceryProduct> products, {
    required int limit,
  }) {
    final sorted = products
        .where((product) => product.availableInStore)
        .toList(growable: false);
    if (sorted.isEmpty) {
      return const [];
    }

    sorted.sort((left, right) {
      final priceCompare = _compareNullable(
        left.effectivePrice,
        right.effectivePrice,
      );
      if (priceCompare != 0) {
        return priceCompare;
      }
      return left.brandLabel.compareTo(right.brandLabel);
    });

    final seenBrands = <String>{};
    final uniqueBrands = <GroceryProduct>[];
    for (final product in sorted) {
      final brandKey = product.brandLabel.toLowerCase();
      if (seenBrands.add(brandKey)) {
        uniqueBrands.add(product);
      }
      if (uniqueBrands.length >= limit) {
        break;
      }
    }

    return uniqueBrands;
  }

  int _compareNullable(double? left, double? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return left.compareTo(right);
  }
}
