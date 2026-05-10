import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class ProfileDao {
  ProfileDao(this._db);

  final Database _db;

  Future<Map<String, dynamic>?> loadProfileJson() async {
    final rows = await _db.query(
      'app_profile',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(
      jsonDecode(rows.first['json'] as String) as Map,
    );
  }

  Future<void> saveProfileJson(Map<String, dynamic> json) {
    return _db.insert('app_profile', {
      'id': 1,
      'json': jsonEncode(json),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear() {
    return _db.delete('app_profile', where: 'id = ?', whereArgs: const [1]);
  }
}
