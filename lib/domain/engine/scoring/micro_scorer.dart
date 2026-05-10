import 'dart:math' as math;

import '../../entities/nutrients.dart';

class MicroScorer {
  const MicroScorer({
    required this.rdaByNutrient,
    required this.priorities,
    this.currentIntake = const {},
  });

  static const double epsilon = 1e-6;

  final Map<String, double> rdaByNutrient;
  final Map<String, double> priorities;
  final Map<String, double> currentIntake;

  double score(Nutrients n) {
    final contributions = <double>[];
    final weights = <double>[];

    void add(String key, double amount) {
      final rda = rdaByNutrient[key];
      if (rda == null || rda <= 0) {
        return;
      }
      final intake = currentIntake[key] ?? 0;
      final gap = math.max(0, rda - intake);
      if (gap <= epsilon) {
        return;
      }
      final priority = priorities[key] ?? 1;
      final fill = math.min(1, amount / (gap + epsilon));
      contributions.add(fill * priority);
      weights.add(priority);
    }

    add('iron_mg', n.ironMg);
    add('calcium_mg', n.calciumMg);
    add('potassium_mg', n.potassiumMg);
    add('magnesium_mg', n.magnesiumMg);
    add('zinc_mg', n.zincMg);
    add('vit_a_mcg_rae', n.vitAMcgRae);
    add('vit_c_mg', n.vitCMg);
    add('vit_d_mcg', n.vitDMcg);
    add('vit_b12_mcg', n.vitB12Mcg);
    add('folate_mcg_dfe', n.folateMcgDfe);

    if (weights.isEmpty) {
      return 0;
    }

    final numerator = contributions.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final denominator = weights.fold<double>(0, (sum, value) => sum + value);
    return (numerator / denominator).clamp(0, 1).toDouble();
  }
}
