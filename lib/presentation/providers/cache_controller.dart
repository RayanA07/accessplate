import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/cache_policy.dart';
import '../../domain/entities/cache_stats.dart';
import 'app_bootstrap.dart';

final cacheControllerProvider =
    AsyncNotifierProvider<CacheController, CacheStats>(CacheController.new);

class CacheController extends AsyncNotifier<CacheStats> {
  @override
  Future<CacheStats> build() async {
    final bootstrap = await ref.watch(appBootstrapProvider.future);
    return bootstrap.cacheRepository.getStats();
  }

  Future<int> runCleanup() async {
    final bootstrap = await ref.read(appBootstrapProvider.future);
    final removed = await bootstrap.cacheRepository.evictExpiredItems(
      unusedDays: CachePolicy.unusedDays,
    );
    state = AsyncData(await bootstrap.cacheRepository.getStats());
    return removed;
  }
}
