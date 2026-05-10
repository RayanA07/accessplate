import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../application/use_cases/evict_stale_cache_use_case.dart';
import '../../application/use_cases/recommend_foods_use_case.dart';
import '../../application/use_cases/update_profile_use_case.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../data/repositories/cache_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/local/app_database.dart';
import '../../data/local/cache_dao.dart';
import '../../data/local/food_dao.dart';
import '../../data/local/profile_dao.dart';
import '../../data/seed_loader.dart';
import '../../domain/engine/decision_engine.dart';
import '../../domain/engine/score_config_provider.dart';
import '../../domain/repositories/cache_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class AppBootstrap {
  AppBootstrap({
    required this.database,
    required this.referenceTables,
    required this.foodRepository,
    required this.profileRepository,
    required this.cacheRepository,
    required this.recommendUseCase,
    required this.updateProfileUseCase,
    required this.evictStaleCacheUseCase,
  });

  final Database database;
  final ReferenceTables referenceTables;
  final FoodRepository foodRepository;
  final ProfileRepository profileRepository;
  final CacheRepository cacheRepository;
  final RecommendFoodsUseCase recommendUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final EvictStaleCacheUseCase evictStaleCacheUseCase;
}

final appBootstrapProvider = FutureProvider<AppBootstrap>((ref) async {
  final seedLoader = SeedLoader();
  final database = await AppDatabase(seedLoader: seedLoader).open();
  final referenceTables = await seedLoader.loadReferenceTables();
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
  final engine = DecisionEngine(
    repo: foodRepository,
    scoreConfigProvider: ScoreConfigProvider(referenceTables),
  );
  final evictStaleCacheUseCase = EvictStaleCacheUseCase(cacheRepository);
  await evictStaleCacheUseCase();

  return AppBootstrap(
    database: database,
    referenceTables: referenceTables,
    foodRepository: foodRepository,
    profileRepository: profileRepository,
    cacheRepository: cacheRepository,
    recommendUseCase: RecommendFoodsUseCase(engine),
    updateProfileUseCase: UpdateProfileUseCase(profileRepository),
    evictStaleCacheUseCase: evictStaleCacheUseCase,
  );
});
