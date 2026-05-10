import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/application/use_cases/evict_stale_cache_use_case.dart';
import 'package:access_plate/domain/entities/cache_stats.dart';
import 'package:access_plate/domain/repositories/cache_repository.dart';

void main() {
  test('evict stale cache use case uses 90 day policy', () async {
    final repository = _FakeCacheRepository();
    final useCase = EvictStaleCacheUseCase(repository);

    final removed = await useCase();

    expect(removed, 4);
    expect(repository.lastUnusedDays, 90);
  });
}

class _FakeCacheRepository implements CacheRepository {
  int? lastUnusedDays;

  @override
  Future<int> evictExpiredItems({required int unusedDays}) async {
    lastUnusedDays = unusedDays;
    return 4;
  }

  @override
  Future<CacheStats> getStats() async {
    return const CacheStats(cachedFoodCount: 12, staleFoodCount: 4);
  }
}
