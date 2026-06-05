import '../../entities/recommendation.dart';
import '../../entities/user_constraints.dart';

class MacroAlignmentPrioritizer {
  const MacroAlignmentPrioritizer({this.alignmentBonus = 10.0});

  static const double minimumMacroScore = 0.45;
  static const double proteinTargetRatio = 0.5;
  static const double proteinTargetCapG = 25.0;
  static const double calorieTargetRatio = 0.45;
  static const double calorieTargetCapKcal = 350.0;
  static const double proteinDensityRatio = 0.65;

  final double alignmentBonus;

  List<ScoredFood> apply(List<ScoredFood> foods, NutritionalTargets targets) {
    return foods.map((food) => prioritize(food, targets)).toList();
  }

  ScoredFood prioritize(ScoredFood food, NutritionalTargets targets) {
    if (!isAligned(food, targets)) {
      return food;
    }

    // Rankings now use a 0-100 fit score, so aligned meals need a larger
    // bonus to preserve the original "target-matching meal beats mismatch"
    // behavior.
    return food.copyWith(composite: food.composite + alignmentBonus);
  }

  bool isAligned(ScoredFood food, NutritionalTargets targets) {
    if (food.breakdown.macro < minimumMacroScore) {
      return false;
    }

    if (food.nutrients.proteinG <
        _boundedMinimum(
          targets.proteinG * proteinTargetRatio,
          proteinTargetCapG,
        )) {
      return false;
    }

    if (food.nutrients.caloriesKcal <
        _boundedMinimum(
          targets.calories * calorieTargetRatio,
          calorieTargetCapKcal,
        )) {
      return false;
    }

    final targetProteinDensity = _proteinDensity(
      calories: targets.calories,
      proteinG: targets.proteinG,
    );
    if (targetProteinDensity <= 0) {
      return true;
    }

    final actualProteinDensity = _proteinDensity(
      calories: food.nutrients.caloriesKcal,
      proteinG: food.nutrients.proteinG,
    );
    return actualProteinDensity >= targetProteinDensity * proteinDensityRatio;
  }

  double _boundedMinimum(double scaledTarget, double cap) {
    if (scaledTarget <= 0) {
      return 0;
    }
    return scaledTarget < cap ? scaledTarget : cap;
  }

  double _proteinDensity({required double calories, required double proteinG}) {
    if (calories <= 0) {
      return 0;
    }
    return ((proteinG * 4) / calories).clamp(0, 1).toDouble();
  }
}
