import '../../core/constants/cache_policy.dart';
import '../../domain/entities/cache_stats.dart';
import '../../domain/repositories/cache_repository.dart';
import '../local/cache_dao.dart';
import '../local/food_dao.dart';

class CacheRepositoryImpl implements CacheRepository {
  CacheRepositoryImpl({required CacheDao cacheDao, required FoodDao foodDao})
    : _cacheDao = cacheDao,
      _foodDao = foodDao;

  final CacheDao _cacheDao;
  final FoodDao _foodDao;

  @override
  Future<CacheStats> getStats() {
    final cutoff = DateTime.now().toUtc().subtract(
      const Duration(days: CachePolicy.unusedDays),
    );
    return _cacheDao.getStats(cutoff: cutoff);
  }

  @override
  Future<int> evictExpiredItems({required int unusedDays}) async {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(Duration(days: unusedDays));
    final staleIds = await _cacheDao.findStaleFoodIds(cutoff: cutoff);

    if (staleIds.isNotEmpty) {
      await _foodDao.deleteFoodsByIds(staleIds);
      await _cacheDao.deleteFoodEntries(staleIds);
    }

    await _cacheDao.recordCleanupRun(now);
    return staleIds.length;
  }
}
