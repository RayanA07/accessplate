import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../application/use_cases/evict_stale_cache_use_case.dart';
import '../../application/use_cases/build_meal_shopping_plan_use_case.dart';
import '../../application/use_cases/lookup_live_grocery_products_use_case.dart';
import '../../application/use_cases/lookup_live_ingredient_products_use_case.dart';
import '../../application/use_cases/recommend_foods_use_case.dart';
import '../../application/use_cases/search_grocery_stores_use_case.dart';
import '../../application/use_cases/search_nearby_stores_use_case.dart';
import '../../application/use_cases/update_profile_use_case.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../data/repositories/cache_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/local/app_database.dart';
import '../../data/local/cache_dao.dart';
import '../../data/local/food_dao.dart';
import '../../data/local/profile_dao.dart';
import '../../data/remote/disabled_grocery_catalog_repository.dart';
import '../../data/remote/grocery_api_config.dart';
import '../../data/remote/kroger_catalog_repository.dart';
import '../../data/remote/open_street_map_api_config.dart';
import '../../data/remote/open_street_map_store_locator_repository.dart';
import '../../data/seed_loader.dart';
import '../../domain/entities/ingredient_availability_catalog.dart';
import '../../domain/entities/local_access.dart';
import '../../domain/engine/access_advisor.dart';
import '../../domain/engine/decision_engine.dart';
import '../../domain/engine/score_config_provider.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';
import '../../domain/repositories/cache_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/store_locator_repository.dart';

class AppBootstrap {
  AppBootstrap({
    required this.database,
    required this.referenceTables,
    required this.ingredientAvailabilityCatalog,
    required this.localAccessCatalog,
    required this.foodRepository,
    required this.profileRepository,
    required this.cacheRepository,
    required this.groceryCatalogRepository,
    required this.storeLocatorRepository,
    required this.recommendUseCase,
    required this.updateProfileUseCase,
    required this.evictStaleCacheUseCase,
    required this.searchGroceryStoresUseCase,
    required this.searchNearbyStoresUseCase,
    required this.lookupLiveGroceryProductsUseCase,
    required this.lookupLiveIngredientProductsUseCase,
    required this.buildMealShoppingPlanUseCase,
  });

  final Database database;
  final ReferenceTables referenceTables;
  final IngredientAvailabilityCatalog ingredientAvailabilityCatalog;
  final LocalAccessCatalog localAccessCatalog;
  final FoodRepository foodRepository;
  final ProfileRepository profileRepository;
  final CacheRepository cacheRepository;
  final GroceryCatalogRepository groceryCatalogRepository;
  final StoreLocatorRepository storeLocatorRepository;
  final RecommendFoodsUseCase recommendUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final EvictStaleCacheUseCase evictStaleCacheUseCase;
  final SearchGroceryStoresUseCase searchGroceryStoresUseCase;
  final SearchNearbyStoresUseCase searchNearbyStoresUseCase;
  final LookupLiveGroceryProductsUseCase lookupLiveGroceryProductsUseCase;
  final LookupLiveIngredientProductsUseCase lookupLiveIngredientProductsUseCase;
  final BuildMealShoppingPlanUseCase buildMealShoppingPlanUseCase;
}

final appBootstrapProvider = FutureProvider<AppBootstrap>((ref) async {
  final seedLoader = SeedLoader();
  final database = await AppDatabase(seedLoader: seedLoader).open();
  final referenceTables = await seedLoader.loadReferenceTables();
  final ingredientAvailabilityCatalog = await seedLoader
      .loadIngredientAvailabilityCatalog();
  final localAccessCatalog = await seedLoader.loadLocalAccessCatalog();
  final foodDao = FoodDao(database);
  final profileDao = ProfileDao(database);
  final cacheDao = CacheDao(database);
  final foodRepository = FoodRepositoryImpl(
    foodDao: foodDao,
    cacheDao: cacheDao,
  );
  final profileRepository = ProfileRepositoryImpl(profileDao);
  final cacheRepository = CacheRepositoryImpl(
    cacheDao: cacheDao,
    foodDao: foodDao,
  );
  final groceryConfig = GroceryApiConfig.fromEnvironment();
  final groceryCatalogRepository = groceryConfig.isConfigured
      ? KrogerCatalogRepository(config: groceryConfig)
      : const DisabledGroceryCatalogRepository();
  final osmConfig = OpenStreetMapApiConfig.fromEnvironment();
  final storeLocatorRepository = OpenStreetMapStoreLocatorRepository(
    config: osmConfig,
  );
  final liveIngredientLookupUseCase = LookupLiveIngredientProductsUseCase(
    groceryCatalogRepository,
  );
  final engine = DecisionEngine(
    repo: foodRepository,
    scoreConfigProvider: ScoreConfigProvider(referenceTables),
    accessAdvisor: FoodAccessAdvisor(catalog: localAccessCatalog),
  );
  final evictStaleCacheUseCase = EvictStaleCacheUseCase(cacheRepository);
  await evictStaleCacheUseCase();

  return AppBootstrap(
    database: database,
    referenceTables: referenceTables,
    ingredientAvailabilityCatalog: ingredientAvailabilityCatalog,
    localAccessCatalog: localAccessCatalog,
    foodRepository: foodRepository,
    profileRepository: profileRepository,
    cacheRepository: cacheRepository,
    groceryCatalogRepository: groceryCatalogRepository,
    storeLocatorRepository: storeLocatorRepository,
    recommendUseCase: RecommendFoodsUseCase(engine),
    updateProfileUseCase: UpdateProfileUseCase(profileRepository),
    evictStaleCacheUseCase: evictStaleCacheUseCase,
    searchGroceryStoresUseCase: SearchGroceryStoresUseCase(
      groceryCatalogRepository,
    ),
    searchNearbyStoresUseCase: SearchNearbyStoresUseCase(
      storeLocatorRepository,
      groceryCatalogRepository: groceryCatalogRepository,
    ),
    lookupLiveGroceryProductsUseCase: LookupLiveGroceryProductsUseCase(
      groceryCatalogRepository,
    ),
    lookupLiveIngredientProductsUseCase: liveIngredientLookupUseCase,
    buildMealShoppingPlanUseCase: BuildMealShoppingPlanUseCase(
      liveProductLookupUseCase: liveIngredientLookupUseCase,
      ingredientAvailabilityCatalog: ingredientAvailabilityCatalog,
    ),
  );
});

final localAccessCatalogProvider = FutureProvider<LocalAccessCatalog>((
  ref,
) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  return bootstrap.localAccessCatalog;
});

final referenceTablesProvider = FutureProvider<ReferenceTables>((ref) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  return bootstrap.referenceTables;
});
