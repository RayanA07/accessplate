import '../entities/cache_stats.dart';

abstract class CacheRepository {
  Future<CacheStats> getStats();

  Future<int> evictExpiredItems({required int unusedDays});
}
