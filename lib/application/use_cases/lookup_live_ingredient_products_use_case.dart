import '../../domain/entities/grocery.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';

class LookupLiveIngredientProductsUseCase {
  LookupLiveIngredientProductsUseCase(this._repository);

  final GroceryCatalogRepository _repository;
  final Map<_ProductSearchKey, Future<List<GroceryProduct>>> _searchCache = {};

  Future<LiveStoreMatch?> execute({
    required List<NearbyStore> candidateStores,
    required List<IngredientRequirement> ingredients,
    int productsPerIngredient = 2,
    int maxStoresToCheck = 3,
  }) async {
    if (!_repository.isConfigured ||
        candidateStores.isEmpty ||
        ingredients.isEmpty) {
      return null;
    }

    final linkedStores = candidateStores
        .where((store) => store.linkedGroceryStore != null)
        .take(maxStoresToCheck)
        .toList(growable: false);
    if (linkedStores.isEmpty) {
      return null;
    }

    LiveStoreMatch? best;
    for (final nearbyStore in linkedStores) {
      final groceryStore = nearbyStore.linkedGroceryStore!;
      final matches = <IngredientProductMatch>[];
      final unmatched = <IngredientRequirement>[];

      for (final ingredient in ingredients) {
        final products = await _searchIngredient(
          store: groceryStore,
          ingredient: ingredient,
          limit: productsPerIngredient,
        );
        if (products.isEmpty) {
          unmatched.add(ingredient);
        } else {
          matches.add(
            IngredientProductMatch(
              ingredient: ingredient,
              products: products,
            ),
          );
        }
      }

      final candidate = LiveStoreMatch(
        store: nearbyStore,
        lookup: LiveIngredientLookupResult(
          store: groceryStore,
          matches: matches,
          unmatchedIngredients: unmatched,
        ),
      );

      if (_isBetter(candidate, best)) {
        best = candidate;
      }
      if (candidate.lookup.unmatchedIngredients.isEmpty &&
          candidate.lookup.matches.isNotEmpty) {
        return candidate;
      }
    }

    return best;
  }

  Future<List<GroceryProduct>> _searchIngredient({
    required GroceryStore store,
    required IngredientRequirement ingredient,
    required int limit,
  }) async {
    final normalizedTerms = ingredient.searchTerms
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (final term in normalizedTerms) {
      final key = _ProductSearchKey(store.locationId, term, limit);
      final productsFuture = _searchCache.putIfAbsent(
        key,
        () => _fetchProducts(store: store, term: term, limit: limit),
      );
      final products = await productsFuture;
      if (products.isNotEmpty) {
        return products;
      }
    }
    return const [];
  }

  Future<List<GroceryProduct>> _fetchProducts({
    required GroceryStore store,
    required String term,
    required int limit,
  }) async {
    try {
      final products = await _repository.searchProducts(
        store: store,
        term: term,
        limit: 10,
      );
      return _normalize(products, limit: limit);
    } on GroceryCatalogException {
      return const [];
    }
  }

  bool _isBetter(
    LiveStoreMatch candidate,
    LiveStoreMatch? current,
  ) {
    if (current == null) {
      return candidate.lookup.matches.isNotEmpty;
    }

    final coverageCompare = _compareCoverage(candidate, current);
    if (coverageCompare != 0) {
      return coverageCompare > 0;
    }

    final candidateDuration = candidate.store.travelMetric.durationMinutes;
    final currentDuration = current.store.travelMetric.durationMinutes;
    if (candidateDuration != null && currentDuration != null) {
      final byDuration = currentDuration.compareTo(candidateDuration);
      if (byDuration != 0) {
        return byDuration > 0;
      }
    }

    final candidateDistance =
        candidate.store.travelMetric.distanceMiles ?? double.infinity;
    final currentDistance =
        current.store.travelMetric.distanceMiles ?? double.infinity;
    if (candidateDistance != currentDistance) {
      return candidateDistance < currentDistance;
    }

    final candidateTotal = _partialTotal(candidate.lookup);
    final currentTotal = _partialTotal(current.lookup);
    if (candidateTotal == null) {
      return false;
    }
    if (currentTotal == null) {
      return true;
    }
    return candidateTotal < currentTotal;
  }

  int _compareCoverage(LiveStoreMatch left, LiveStoreMatch right) {
    final byMatched = left.lookup.matchedCount.compareTo(right.lookup.matchedCount);
    if (byMatched != 0) {
      return byMatched;
    }
    final byUnmatched =
        right.lookup.unmatchedCount.compareTo(left.lookup.unmatchedCount);
    if (byUnmatched != 0) {
      return byUnmatched;
    }
    final leftPriced = left.lookup.matches.where(
      (match) => match.cheapestPrice != null,
    ).length;
    final rightPriced = right.lookup.matches.where(
      (match) => match.cheapestPrice != null,
    ).length;
    return leftPriced.compareTo(rightPriced);
  }

  double? _partialTotal(LiveIngredientLookupResult result) {
    double total = 0;
    var any = false;
    for (final match in result.matches) {
      final price = match.cheapestPrice;
      if (price == null) {
        continue;
      }
      any = true;
      total += price;
    }
    return any ? total : null;
  }

  List<GroceryProduct> _normalize(
    List<GroceryProduct> products, {
    required int limit,
  }) {
    final available = products
        .where((product) => product.availableInStore)
        .toList(growable: false);
    available.sort((left, right) {
      final leftPrice = left.effectivePrice;
      final rightPrice = right.effectivePrice;
      if (leftPrice == null && rightPrice == null) {
        return left.brandLabel.compareTo(right.brandLabel);
      }
      if (leftPrice == null) {
        return 1;
      }
      if (rightPrice == null) {
        return -1;
      }
      final byPrice = leftPrice.compareTo(rightPrice);
      if (byPrice != 0) {
        return byPrice;
      }
      return left.brandLabel.compareTo(right.brandLabel);
    });

    final seen = <String>{};
    final picked = <GroceryProduct>[];
    for (final product in available) {
      final key =
          '${product.brandLabel.toLowerCase()}|${product.description.toLowerCase()}';
      if (seen.add(key)) {
        picked.add(product);
      }
      if (picked.length >= limit) {
        break;
      }
    }
    return picked;
  }
}

class _ProductSearchKey {
  const _ProductSearchKey(this.locationId, this.term, this.limit);

  final String locationId;
  final String term;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ProductSearchKey &&
        other.locationId == locationId &&
        other.term == term &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(locationId, term, limit);
}
