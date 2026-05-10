import '../../entities/nutrients.dart';
import '../../entities/user_constraints.dart';

class MacroWeights {
  const MacroWeights({
    this.protein = 0.30,
    this.carbs = 0.20,
    this.fat = 0.20,
    this.calories = 0.20,
    this.fiber = 0.10,
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
    final protein = agreement(targets.proteinG, n.proteinG);
    final carbs = agreement(targets.carbsG, n.carbsG);
    final fat = agreement(targets.fatG, n.fatG);
    final calories = agreement(targets.calories, n.caloriesKcal);
    final fiber = agreement(targets.fiberG, n.fiberG);

    return weights.protein * protein +
        weights.carbs * carbs +
        weights.fat * fat +
        weights.calories * calories +
        weights.fiber * fiber;
  }

  static double agreement(double target, double actual) {
    if (target <= 0) {
      return actual <= 0 ? 1 : 0;
    }
    final score = 1 - ((target - actual).abs() / target);
    return score.clamp(0, 1).toDouble();
  }
}
