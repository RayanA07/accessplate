import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../application/use_cases/evict_stale_cache_use_case.dart';
import '../../application/use_cases/lookup_live_grocery_products_use_case.dart';
import '../../application/use_cases/recommend_foods_use_case.dart';
import '../../application/use_cases/search_grocery_stores_use_case.dart';
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
import '../../data/seed_loader.dart';
import '../../domain/entities/local_access.dart';
import '../../domain/engine/access_advisor.dart';
import '../../domain/engine/decision_engine.dart';
import '../../domain/engine/score_config_provider.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';
import '../../domain/repositories/cache_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class AppBootstrap {
  AppBootstrap({
    required this.database,
    required this.referenceTables,
    required this.localAccessCatalog,
    required this.foodRepository,
    required this.profileRepository,
    required this.cacheRepository,
    required this.groceryCatalogRepository,
    required this.recommendUseCase,
    required this.updateProfileUseCase,
    required this.evictStaleCacheUseCase,
    required this.searchGroceryStoresUseCase,
    required this.lookupLiveGroceryProductsUseCase,
  });

  final Database database;
  final ReferenceTables referenceTables;
  final LocalAccessCatalog localAccessCatalog;
  final FoodRepository foodRepository;
  final ProfileRepository profileRepository;
  final CacheRepository cacheRepository;
  final GroceryCatalogRepository groceryCatalogRepository;
  final RecommendFoodsUseCase recommendUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final EvictStaleCacheUseCase evictStaleCacheUseCase;
  final SearchGroceryStoresUseCase searchGroceryStoresUseCase;
  final LookupLiveGroceryProductsUseCase lookupLiveGroceryProductsUseCase;
}

final appBootstrapProvider = FutureProvider<AppBootstrap>((ref) async {
  final seedLoader = SeedLoader();
  final database = await AppDatabase(seedLoader: seedLoader).open();
  final referenceTables = await seedLoader.loadReferenceTables();
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
    localAccessCatalog: localAccessCatalog,
    foodRepository: foodRepository,
    profileRepository: profileRepository,
    cacheRepository: cacheRepository,
    groceryCatalogRepository: groceryCatalogRepository,
    recommendUseCase: RecommendFoodsUseCase(engine),
    updateProfileUseCase: UpdateProfileUseCase(profileRepository),
    evictStaleCacheUseCase: evictStaleCacheUseCase,
    searchGroceryStoresUseCase: SearchGroceryStoresUseCase(
      groceryCatalogRepository,
    ),
    lookupLiveGroceryProductsUseCase: LookupLiveGroceryProductsUseCase(
      groceryCatalogRepository,
    ),
  );
});

final localAccessCatalogProvider = FutureProvider<LocalAccessCatalog>((ref) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  return bootstrap.localAccessCatalog;
});
