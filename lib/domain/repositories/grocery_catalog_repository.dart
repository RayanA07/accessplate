import '../entities/grocery.dart';

abstract class GroceryCatalogRepository {
  GroceryRetailer get retailer;
  bool get isConfigured;

  Future<List<GroceryStore>> searchStores({
    required String postalCode,
    int limit = 8,
    int radiusMiles = 20,
  });

  Future<List<GroceryProduct>> searchProducts({
    required GroceryStore store,
    required String term,
    int limit = 12,
  });
}
