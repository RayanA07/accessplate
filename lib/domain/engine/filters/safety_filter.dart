import '../../entities/food.dart';
import '../../entities/user_constraints.dart';
import '../../value_objects/religion.dart';

class SafetyFilter {
  const SafetyFilter();

  List<FoodRecord> apply(List<FoodRecord> foods, SafetyConstraints safety) {
    return foods.where((record) {
      final food = record.food;
      final allergenConflict = food.allergens.any(
        (allergen) => safety.allergens.contains(allergen),
      );
      if (allergenConflict) {
        return false;
      }

      if (safety.religion != Religion.none &&
          food.religionExcluded.any(
            (rule) => rule.religion == safety.religion,
          )) {
        return false;
      }

      for (final restriction in safety.medicalAvoid) {
        final excluded = food.medicalRules.any(
          (rule) =>
              rule.restriction == restriction &&
              rule.severity == MedicalRuleSeverity.avoid,
        );
        if (excluded) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
