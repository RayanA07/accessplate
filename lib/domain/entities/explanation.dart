class SatisfiedConstraint {
  const SatisfiedConstraint({
    required this.category,
    required this.description,
  });

  final String category;
  final String description;
}

class ScoreFactor {
  const ScoreFactor({
    required this.label,
    required this.weight,
    this.detail,
  });

  final String label;
  final double weight;
  final String? detail;
}

class Explanation {
  const Explanation({
    required this.satisfied,
    required this.positives,
    required this.tradeoffs,
    required this.compareWithIds,
  });

  final List<SatisfiedConstraint> satisfied;
  final List<ScoreFactor> positives;
  final List<ScoreFactor> tradeoffs;
  final List<int> compareWithIds;

  Explanation copyWith({
    List<SatisfiedConstraint>? satisfied,
    List<ScoreFactor>? positives,
    List<ScoreFactor>? tradeoffs,
    List<int>? compareWithIds,
  }) {
    return Explanation(
      satisfied: satisfied ?? this.satisfied,
      positives: positives ?? this.positives,
      tradeoffs: tradeoffs ?? this.tradeoffs,
      compareWithIds: compareWithIds ?? this.compareWithIds,
    );
  }
}
