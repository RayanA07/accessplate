import 'explanation.dart';
import 'food.dart';
import 'nutrients.dart';

enum BlockingConstraint {
  safety('Safety profile'),
  budget('Budget'),
  environment('Preparation environment'),
  availability('Availability context'),
  preference('Preferences');

  const BlockingConstraint(this.label);

  final String label;
}

class InsufficientCandidatesAnalysis {
  const InsufficientCandidatesAnalysis({
    required this.currentCount,
    required this.minimumDesired,
    required this.mostRestrictive,
    required this.suggestion,
  });

  final int currentCount;
  final int minimumDesired;
  final BlockingConstraint mostRestrictive;
  final String suggestion;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.macro,
    required this.micro,
    required this.penalty,
    required this.cost,
    required this.preference,
  });

  final double macro;
  final double micro;
  final double penalty;
  final double cost;
  final double preference;
}

class ScoredFood {
  const ScoredFood({
    required this.food,
    required this.nutrients,
    required this.composite,
    required this.breakdown,
    this.displayScore = 0,
    this.explanation,
  });

  final Food food;
  final Nutrients nutrients;
  final double composite;
  final ScoreBreakdown breakdown;
  final double displayScore;
  final Explanation? explanation;

  ScoredFood copyWith({
    Food? food,
    Nutrients? nutrients,
    double? composite,
    ScoreBreakdown? breakdown,
    double? displayScore,
    Explanation? explanation,
  }) {
    return ScoredFood(
      food: food ?? this.food,
      nutrients: nutrients ?? this.nutrients,
      composite: composite ?? this.composite,
      breakdown: breakdown ?? this.breakdown,
      displayScore: displayScore ?? this.displayScore,
      explanation: explanation ?? this.explanation,
    );
  }
}

class RecommendationResult {
  const RecommendationResult({
    required this.recommendations,
    required this.preferenceRelaxed,
    required this.candidatePoolSize,
    required this.elapsedMs,
    this.diagnostic,
  });

  final List<ScoredFood> recommendations;
  final bool preferenceRelaxed;
  final int candidatePoolSize;
  final int elapsedMs;
  final InsufficientCandidatesAnalysis? diagnostic;

  bool get isEmpty => recommendations.isEmpty;
}
