import '../entities/food.dart';
import '../value_objects/allergen.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/medical_restriction.dart';
import '../value_objects/prep_environment.dart';
import '../value_objects/religion.dart';

abstract class FoodRepository {
  Future<List<FoodRecord>> findCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
    int limit = 500,
  });

  Future<int> countCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
  });

  Future<void> touchFoods(Iterable<int> ids);
}
