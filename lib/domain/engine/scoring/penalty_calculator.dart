import 'dart:math' as math;

import '../../entities/nutrients.dart';

class PenaltyCalculator {
  const PenaltyCalculator({
    required this.thresholds,
    required this.weights,
  });

  final Map<String, double> thresholds;
  final Map<String, double> weights;

  double penalty(Nutrients n) {
    final weightedTerms = <double>[];
    final termWeights = <double>[];

    void term(String key, double value) {
      final threshold = thresholds[key];
      final weight = weights[key];
      if (threshold == null || weight == null || threshold <= 0) {
        return;
      }
      final excess = math.max(0, value - threshold) / threshold;
      weightedTerms.add(weight * excess.clamp(0, 1));
      termWeights.add(weight);
    }

    term('sodium_mg', n.sodiumMg);
    term('added_sugar_g', n.addedSugarG);
    term('saturated_fat_g', n.saturatedFatG);
    if (thresholds.containsKey('potassium_mg')) {
      term('potassium_mg', n.potassiumMg);
    }

    if (termWeights.isEmpty) {
      return 0;
    }

    final numerator = weightedTerms.fold<double>(0, (sum, value) => sum + value);
    final denominator =
        termWeights.fold<double>(0, (sum, value) => sum + value);
    return (numerator / denominator).clamp(0, 1).toDouble();
  }
}
