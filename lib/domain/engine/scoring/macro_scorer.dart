import '../../entities/nutrients.dart';
import '../../entities/user_constraints.dart';

class MacroWeights {
  const MacroWeights({
    this.protein = 0.38,
    this.carbs = 0.10,
    this.fat = 0.07,
    this.calories = 0.20,
    this.fiber = 0.25,
  });

  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double fiber;
}

class MacroScorer {
  const MacroScorer({required this.targets, required this.weights});

  final NutritionalTargets targets;
  final MacroWeights weights;

  double score(Nutrients n) {
    final protein = minimumAgreement(
      targets.proteinG,
      n.proteinG,
      floorRatio: 0.55,
    );
    final carbs = agreement(
      targets.carbsG,
      n.carbsG,
      lowerGoodRatio: 0.45,
      upperGoodRatio: 1.45,
      upperZeroRatio: 2.10,
    );
    final fat = agreement(
      targets.fatG,
      n.fatG,
      lowerGoodRatio: 0.45,
      upperGoodRatio: 1.40,
      upperZeroRatio: 2.0,
    );
    final calories = agreement(
      targets.calories,
      n.caloriesKcal,
      lowerGoodRatio: 0.55,
      upperGoodRatio: 1.25,
      upperZeroRatio: 1.90,
    );
    final fiber = minimumAgreement(targets.fiberG, n.fiberG, floorRatio: 0.60);

    return weights.protein * protein +
        weights.carbs * carbs +
        weights.fat * fat +
        weights.calories * calories +
        weights.fiber * fiber;
  }

  static double agreement(
    double target,
    double actual, {
    double lowerGoodRatio = 0.65,
    double upperGoodRatio = 1.20,
    double upperZeroRatio = 1.80,
  }) {
    if (target <= 0) {
      return 1;
    }

    if (actual <= 0) {
      return 0;
    }

    final lowerGood = target * lowerGoodRatio;
    final upperGood = target * upperGoodRatio;

    if (actual >= lowerGood && actual <= upperGood) {
      return 1;
    }

    if (actual < lowerGood) {
      return (actual / lowerGood).clamp(0, 1).toDouble();
    }

    final upperZero = target * upperZeroRatio;
    if (actual >= upperZero) {
      return 0;
    }

    final decay = (upperZero - actual) / (upperZero - upperGood);
    return decay.clamp(0, 1).toDouble();
  }

  static double minimumAgreement(
    double target,
    double actual, {
    double floorRatio = 0.60,
  }) {
    if (target <= 0) {
      return 1;
    }

    if (actual <= 0) {
      return 0;
    }

    final floor = target * floorRatio;
    if (actual >= target) {
      return 1;
    }

    if (actual >= floor) {
      final span = target - floor;
      if (span <= 0) {
        return 1;
      }
      final progress = (actual - floor) / span;
      return (0.82 + (0.18 * progress)).clamp(0, 1).toDouble();
    }

    return (0.82 * (actual / floor)).clamp(0, 1).toDouble();
  }
}
