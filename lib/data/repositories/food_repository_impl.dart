import 'dart:convert';

import '../../domain/entities/food.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/value_objects/allergen.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/medical_restriction.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../../domain/value_objects/religion.dart';
import '../local/cache_dao.dart';
import '../local/food_dao.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl({required FoodDao foodDao, required CacheDao cacheDao})
    : _foodDao = foodDao,
      _cacheDao = cacheDao;

  final FoodDao _foodDao;
  final CacheDao _cacheDao;

  @override
  Future<List<FoodRecord>> findCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
    int limit = 500,
  }) async {
    final rows = await _foodDao.findCandidateRows(
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid,
      maxCost: maxCost,
      environment: environment,
      availability: availability,
      limit: limit,
    );
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<int> countCandidates({
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
  }) async {
    return _foodDao.countCandidates(
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid,
      maxCost: maxCost,
      environment: environment,
      availability: availability,
    );
  }

  @override
  Future<void> touchFoods(Iterable<int> ids) {
    return _cacheDao.touchFoods(ids);
  }

  FoodRecord _mapRecord(Map<String, Object?> row) {
    final allergens = _decodeStringList(
      row['allergens_json'] as String,
    ).map(Allergen.fromCode).toSet();
    final availability = _decodeStringList(
      row['availability_json'] as String,
    ).map(AvailabilityContext.fromCode).toSet();
    final mealTypes = _decodeStringList(
      row['meal_types_json'] as String,
    ).map(MealType.fromCode).toSet();

    final religionRules =
        (jsonDecode(row['religion_json'] as String) as List<dynamic>)
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(
              (entry) => ReligionRule(
                religion: Religion.fromCode(entry['religion'] as String),
                reason: entry['reason'] as String?,
              ),
            )
            .toList();

    final medicalRules =
        (jsonDecode(row['medical_json'] as String) as List<dynamic>)
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(
              (entry) => MedicalRule(
                restriction: MedicalRestriction.fromCode(
                  entry['code'] as String,
                ),
                severity: entry['severity'] == 'avoid'
                    ? MedicalRuleSeverity.avoid
                    : MedicalRuleSeverity.limit,
                reason: entry['reason'] as String?,
              ),
            )
            .toList();

    final food = Food(
      id: (row['id'] as num).toInt(),
      name: row['name'] as String,
      category: row['category'] as String,
      cuisine: row['cuisine'] as String?,
      servingG: (row['serving_g'] as num).toDouble(),
      servingLabel: row['serving_label'] as String,
      costEstimate: (row['cost_estimate'] as num).toDouble(),
      costConfidence: row['cost_confidence'] as String,
      prepMethod: row['prep_method'] as String,
      prepTimeMin: (row['prep_time_min'] as num).toInt(),
      mealTypes: mealTypes,
      availability: availability,
      allergens: allergens,
      religionExcluded: religionRules,
      medicalRules: medicalRules,
      ingredients: _decodeStringList(row['ingredients_json'] as String).toSet(),
      source: row['source'] as String,
    );

    final nutrients = Nutrients.fromJson(
      row.map((key, value) => MapEntry(key, value)),
    );

    return FoodRecord(food: food, nutrients: nutrients);
  }

  List<String> _decodeStringList(String raw) {
    return List<String>.from(jsonDecode(raw) as List<dynamic>);
  }
}
