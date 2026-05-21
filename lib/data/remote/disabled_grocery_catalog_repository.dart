import '../../domain/entities/grocery.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';

class DisabledGroceryCatalogRepository implements GroceryCatalogRepository {
  const DisabledGroceryCatalogRepository();

  @override
  GroceryRetailer get retailer => GroceryRetailer.kroger;

  @override
  bool get isConfigured => false;

  @override
  Future<List<GroceryStore>> searchStores({
    required String postalCode,
    int limit = 8,
    int radiusMiles = 20,
  }) async {
    return const [];
  }

  @override
  Future<List<GroceryProduct>> searchProducts({
    required GroceryStore store,
    required String term,
    int limit = 12,
  }) async {
    return const [];
  }
}
