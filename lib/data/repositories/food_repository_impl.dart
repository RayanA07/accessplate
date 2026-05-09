import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/value_objects/allergen.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/medical_restriction.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../../domain/value_objects/religion.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(this._db);

  final Database _db;

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
    final query = _buildQuery(
      countOnly: false,
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid,
      maxCost: maxCost,
      environment: environment,
      availability: availability,
      limit: limit,
    );

    final rows = await _db.rawQuery(query.sql, query.arguments);
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
    final query = _buildQuery(
      countOnly: true,
      excludeAllergens: excludeAllergens,
      religion: religion,
      medicalAvoid: medicalAvoid,
      maxCost: maxCost,
      environment: environment,
      availability: availability,
    );
    final rows = await _db.rawQuery(query.sql, query.arguments);
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  _SqlQuery _buildQuery({
    required bool countOnly,
    required Set<Allergen> excludeAllergens,
    required Religion religion,
    required Set<MedicalRestriction> medicalAvoid,
    required double maxCost,
    required PrepEnvironment environment,
    required Set<AvailabilityContext> availability,
    int? limit,
  }) {
    final where = <String>[
      'f.cost_estimate <= ?',
      'f.prep_method IN (${_placeholders(environment.allowedPrepMethods.length)})',
      'EXISTS (SELECT 1 FROM food_availability fa WHERE fa.food_id = f.id AND fa.context_code IN (${_placeholders(availability.length)}))',
    ];

    final args = <Object?>[
      maxCost,
      ...environment.allowedPrepMethods,
      ...availability.map((value) => value.code),
    ];

    if (excludeAllergens.isNotEmpty) {
      where.add(
        'f.id NOT IN (SELECT food_id FROM food_allergens WHERE allergen_code IN (${_placeholders(excludeAllergens.length)}))',
      );
      args.addAll(excludeAllergens.map((value) => value.code));
    }

    if (religion != Religion.none) {
      where.add(
        'f.id NOT IN (SELECT food_id FROM food_religion_excluded WHERE religion_code = ?)',
      );
      args.add(religion.code);
    }

    if (medicalAvoid.isNotEmpty) {
      where.add(
        "f.id NOT IN (SELECT food_id FROM food_medical_excluded WHERE severity = 'avoid' AND restriction_code IN (${_placeholders(medicalAvoid.length)}))",
      );
      args.addAll(medicalAvoid.map((value) => value.code));
    }

    final select = countOnly
        ? 'SELECT COUNT(*) AS count'
        : 'SELECT f.*, n.*';
    final join = countOnly ? '' : ' JOIN nutrients n ON n.food_id = f.id';
    final buffer = StringBuffer()
      ..write('$select FROM foods f$join WHERE ${where.join(' AND ')}');

    if (!countOnly) {
      buffer.write(' ORDER BY f.cost_estimate ASC');
    }
    if (limit != null) {
      buffer.write(' LIMIT ?');
      args.add(limit);
    }

    return _SqlQuery(buffer.toString(), args);
  }

  String _placeholders(int count) => List.filled(count, '?').join(',');

  FoodRecord _mapRecord(Map<String, Object?> row) {
    final allergens = _decodeStringList(row['allergens_json'] as String)
        .map(Allergen.fromCode)
        .toSet();
    final availability = _decodeStringList(row['availability_json'] as String)
        .map(AvailabilityContext.fromCode)
        .toSet();
    final mealTypes = _decodeStringList(row['meal_types_json'] as String)
        .map(MealType.fromCode)
        .toSet();

    final religionRules = (jsonDecode(row['religion_json'] as String) as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .map(
          (entry) => ReligionRule(
            religion: Religion.fromCode(entry['religion'] as String),
            reason: entry['reason'] as String?,
          ),
        )
        .toList();

    final medicalRules = (jsonDecode(row['medical_json'] as String) as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .map(
          (entry) => MedicalRule(
            restriction: MedicalRestriction.fromCode(entry['code'] as String),
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

class _SqlQuery {
  const _SqlQuery(this.sql, this.arguments);

  final String sql;
  final List<Object?> arguments;
}
