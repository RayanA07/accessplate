import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../application/recommend_use_case.dart';
import '../../application/update_profile_use_case.dart';
import '../../data/database.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/seed_loader.dart';
import '../../domain/engine/decision_engine.dart';
import '../../domain/engine/score_config_provider.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class AppBootstrap {
  AppBootstrap({
    required this.database,
    required this.referenceTables,
    required this.foodRepository,
    required this.profileRepository,
    required this.recommendUseCase,
    required this.updateProfileUseCase,
  });

  final Database database;
  final ReferenceTables referenceTables;
  final FoodRepository foodRepository;
  final ProfileRepository profileRepository;
  final RecommendUseCase recommendUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
}

final appBootstrapProvider = FutureProvider<AppBootstrap>((ref) async {
  final seedLoader = SeedLoader();
  final database = await AppDatabase(seedLoader: seedLoader).open();
  final referenceTables = await seedLoader.loadReferenceTables();
  final foodRepository = FoodRepositoryImpl(database);
  final profileRepository = ProfileRepositoryImpl(database);
  final engine = DecisionEngine(
    repo: foodRepository,
    scoreConfigProvider: ScoreConfigProvider(referenceTables),
  );

  return AppBootstrap(
    database: database,
    referenceTables: referenceTables,
    foodRepository: foodRepository,
    profileRepository: profileRepository,
    recommendUseCase: RecommendUseCase(engine),
    updateProfileUseCase: UpdateProfileUseCase(profileRepository),
  );
});
