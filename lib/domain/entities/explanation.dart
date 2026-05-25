class SatisfiedConstraint {
  const SatisfiedConstraint({
    required this.category,
    required this.description,
  });

  final String category;
  final String description;
}

class ScoreFactor {
  const ScoreFactor({required this.label, required this.weight, this.detail});

  final String label;
  final double weight;
  final String? detail;
}

class DecisionFact {
  const DecisionFact({required this.label, required this.value});

  final String label;
  final String value;
}

class Explanation {
  const Explanation({
    required this.satisfied,
    required this.positives,
    required this.tradeoffs,
    required this.compareWithIds,
    this.accessSummary,
    this.accessTags = const [],
    this.decisionFacts = const [],
  });

  final List<SatisfiedConstraint> satisfied;
  final List<ScoreFactor> positives;
  final List<ScoreFactor> tradeoffs;
  final List<int> compareWithIds;
  final String? accessSummary;
  final List<String> accessTags;
  final List<DecisionFact> decisionFacts;

  Explanation copyWith({
    List<SatisfiedConstraint>? satisfied,
    List<ScoreFactor>? positives,
    List<ScoreFactor>? tradeoffs,
    List<int>? compareWithIds,
    String? accessSummary,
    List<String>? accessTags,
    List<DecisionFact>? decisionFacts,
  }) {
    return Explanation(
      satisfied: satisfied ?? this.satisfied,
      positives: positives ?? this.positives,
      tradeoffs: tradeoffs ?? this.tradeoffs,
      compareWithIds: compareWithIds ?? this.compareWithIds,
      accessSummary: accessSummary ?? this.accessSummary,
      accessTags: accessTags ?? this.accessTags,
      decisionFacts: decisionFacts ?? this.decisionFacts,
    );
  }
}
