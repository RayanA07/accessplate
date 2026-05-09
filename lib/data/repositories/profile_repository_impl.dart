import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<UserProfile?> load() async {
    final rows = await _db.query(
      'app_profile',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final json = rows.first['json'] as String;
    return UserProfile.fromJson(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _db.insert(
      'app_profile',
      {
        'id': 1,
        'json': jsonEncode(profile.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete('app_profile', where: 'id = ?', whereArgs: const [1]);
  }
}
