import 'package:sqflite/sqflite.dart';

import '../../core/constants/cache_policy.dart';
import '../../domain/entities/cache_stats.dart';

class CacheDao {
  CacheDao(this._db);

  final Database _db;

  Future<void> touchFoods(Iterable<int> ids, {DateTime? now}) async {
    final foodIds = ids.toSet().toList(growable: false);
    if (foodIds.isEmpty) {
      return;
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    final updatedAt = timestamp.toIso8601String();
    final expiresAt = CachePolicy.expiresAtFrom(
      timestamp,
    ).toUtc().toIso8601String();
    final batch = _db.batch();

    for (final id in foodIds) {
      batch.rawUpdate(
        '''
        UPDATE cache_entries
        SET updated_at = ?,
            last_accessed_at = ?,
            expires_at = ?,
            access_count = access_count + 1
        WHERE entity_type = ? AND entity_id = ?
        ''',
        [updatedAt, updatedAt, expiresAt, CachePolicy.foodEntityType, id],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<CacheStats> getStats({required DateTime cutoff}) async {
    final totalRows = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM cache_entries WHERE entity_type = ?',
      [CachePolicy.foodEntityType],
    );
    final staleRows = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM cache_entries
      WHERE entity_type = ? AND last_accessed_at <= ?
      ''',
      [CachePolicy.foodEntityType, cutoff.toUtc().toIso8601String()],
    );
    final metadataRows = await _db.query(
      'cache_metadata',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['last_cleanup_at'],
      limit: 1,
    );

    final lastCleanupRaw = metadataRows.isEmpty
        ? null
        : metadataRows.first['value'] as String?;

    return CacheStats(
      cachedFoodCount: Sqflite.firstIntValue(totalRows) ?? 0,
      staleFoodCount: Sqflite.firstIntValue(staleRows) ?? 0,
      lastCleanupAt: lastCleanupRaw == null
          ? null
          : DateTime.tryParse(lastCleanupRaw),
    );
  }

  Future<List<int>> findStaleFoodIds({required DateTime cutoff}) async {
    final rows = await _db.query(
      'cache_entries',
      columns: const ['entity_id'],
      where: 'entity_type = ? AND last_accessed_at <= ?',
      whereArgs: [CachePolicy.foodEntityType, cutoff.toUtc().toIso8601String()],
    );
    return rows
        .map((row) => row['entity_id'])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList(growable: false);
  }

  Future<void> deleteFoodEntries(Iterable<int> ids) async {
    final foodIds = ids.toList(growable: false);
    if (foodIds.isEmpty) {
      return;
    }
    final placeholders = List.filled(foodIds.length, '?').join(',');
    await _db.delete(
      'cache_entries',
      where: 'entity_type = ? AND entity_id IN ($placeholders)',
      whereArgs: [CachePolicy.foodEntityType, ...foodIds],
    );
  }

  Future<void> recordCleanupRun(DateTime at) {
    return _db.insert('cache_metadata', {
      'key': 'last_cleanup_at',
      'value': at.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
