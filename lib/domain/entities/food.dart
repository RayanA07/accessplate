import '../value_objects/allergen.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/meal_type.dart';
import '../value_objects/medical_restriction.dart';
import '../value_objects/religion.dart';
import 'nutrients.dart';

enum MedicalRuleSeverity { avoid, limit }

class MedicalRule {
  const MedicalRule({
    required this.restriction,
    required this.severity,
    this.reason,
  });

  final MedicalRestriction restriction;
  final MedicalRuleSeverity severity;
  final String? reason;
}

class ReligionRule {
  const ReligionRule({
    required this.religion,
    this.reason,
  });

  final Religion religion;
  final String? reason;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.servingG,
    required this.servingLabel,
    required this.costEstimate,
    required this.costConfidence,
    required this.prepMethod,
    required this.prepTimeMin,
    required this.mealTypes,
    required this.availability,
    required this.allergens,
    required this.religionExcluded,
    required this.medicalRules,
    required this.ingredients,
    this.cuisine,
    this.source = 'bundled',
  });

  final int id;
  final String name;
  final String category;
  final double servingG;
  final String servingLabel;
  final double costEstimate;
  final String costConfidence;
  final String prepMethod;
  final int prepTimeMin;
  final String? cuisine;
  final Set<MealType> mealTypes;
  final Set<AvailabilityContext> availability;
  final Set<Allergen> allergens;
  final List<ReligionRule> religionExcluded;
  final List<MedicalRule> medicalRules;
  final Set<String> ingredients;
  final String source;

  bool get readyToEat => prepMethod == 'none';
}

class FoodRecord {
  const FoodRecord({
    required this.food,
    required this.nutrients,
  });

  final Food food;
  final Nutrients nutrients;
}
