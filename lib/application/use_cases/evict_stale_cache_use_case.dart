import '../../core/constants/cache_policy.dart';
import '../../domain/repositories/cache_repository.dart';

class EvictStaleCacheUseCase {
  EvictStaleCacheUseCase(this._repository);

  final CacheRepository _repository;

  Future<int> call() {
    return _repository.evictExpiredItems(unusedDays: CachePolicy.unusedDays);
  }
}
