class CacheStats {
  const CacheStats({
    required this.cachedFoodCount,
    required this.staleFoodCount,
    this.lastCleanupAt,
  });

  final int cachedFoodCount;
  final int staleFoodCount;
  final DateTime? lastCleanupAt;
}
