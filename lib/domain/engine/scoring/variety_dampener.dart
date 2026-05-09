class VarietyDampener {
  VarietyDampener({
    required this.recentlyActed,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  final Map<int, DateTime> recentlyActed;
  final DateTime now;

  double factorFor(int foodId) {
    final last = recentlyActed[foodId];
    if (last == null) {
      return 1;
    }
    final age = now.difference(last);
    if (age < const Duration(hours: 24)) {
      return 0.5;
    }
    if (age < const Duration(hours: 72)) {
      return 0.75;
    }
    return 1;
  }
}
