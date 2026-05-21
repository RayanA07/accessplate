import '../../domain/entities/grocery.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';

class SearchGroceryStoresUseCase {
  SearchGroceryStoresUseCase(this._repository);

  final GroceryCatalogRepository _repository;

  Future<List<GroceryStore>> execute({
    required String postalCode,
    int limit = 8,
    int radiusMiles = 20,
  }) {
    return _repository.searchStores(
      postalCode: postalCode,
      limit: limit,
      radiusMiles: radiusMiles,
    );
  }
}
