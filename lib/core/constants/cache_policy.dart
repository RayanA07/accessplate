class CachePolicy {
  const CachePolicy._();

  static const int unusedDays = 90;
  static const String foodEntityType = 'food';

  static Duration get unusedDuration => const Duration(days: unusedDays);

  static DateTime expiresAtFrom(DateTime from) {
    return from.add(unusedDuration);
  }
}
