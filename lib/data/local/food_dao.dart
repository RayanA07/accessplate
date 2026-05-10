import 'package:sqflite/sqflite.dart';

import '../../domain/value_objects/allergen.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/medical_restriction.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../../domain/value_objects/religion.dart';

class FoodDao {
  FoodDao(this._db);

  final Database _db;

  Future<List<Map<String, Object?>>> findCandidateRows({
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
    return _db.rawQuery(query.sql, query.arguments);
  }

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

  Future<void> deleteFoodsByIds(Iterable<int> ids) async {
    final foodIds = ids.toList(growable: false);
    if (foodIds.isEmpty) {
      return;
    }

    final placeholders = _placeholders(foodIds.length);
    final whereClause = 'food_id IN ($placeholders)';
    final foodWhereClause = 'id IN ($placeholders)';
    final batch = _db.batch();

    batch.delete('nutrients', where: whereClause, whereArgs: foodIds);
    batch.delete('food_allergens', where: whereClause, whereArgs: foodIds);
    batch.delete(
      'food_religion_excluded',
      where: whereClause,
      whereArgs: foodIds,
    );
    batch.delete(
      'food_medical_excluded',
      where: whereClause,
      whereArgs: foodIds,
    );
    batch.delete('food_availability', where: whereClause, whereArgs: foodIds);
    batch.delete('foods', where: foodWhereClause, whereArgs: foodIds);

    await batch.commit(noResult: true);
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

    final select = countOnly ? 'SELECT COUNT(*) AS count' : 'SELECT f.*, n.*';
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
}

class _SqlQuery {
  const _SqlQuery(this.sql, this.arguments);

  final String sql;
  final List<Object?> arguments;
}
