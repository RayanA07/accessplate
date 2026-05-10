import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/cache_policy.dart';
import '../seed_loader.dart';

class AppDatabase {
  AppDatabase({SeedLoader? seedLoader})
    : _seedLoader = seedLoader ?? SeedLoader();

  final SeedLoader _seedLoader;
  Database? _database;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'access_plate.sqlite');

    _database = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCacheTables(db);
          await _backfillCacheEntries(db);
        }
      },
      onOpen: (db) async {
        final count =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM foods'),
            ) ??
            0;
        if (count == 0) {
          await _seed(db);
        } else {
          await _backfillCacheEntries(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        cuisine TEXT,
        serving_g REAL NOT NULL,
        serving_label TEXT NOT NULL,
        cost_estimate REAL NOT NULL,
        cost_confidence TEXT NOT NULL,
        prep_method TEXT NOT NULL,
        prep_time_min INTEGER NOT NULL,
        meal_types_json TEXT NOT NULL,
        availability_json TEXT NOT NULL,
        allergens_json TEXT NOT NULL,
        religion_json TEXT NOT NULL,
        medical_json TEXT NOT NULL,
        ingredients_json TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrients (
        food_id INTEGER PRIMARY KEY,
        calories_kcal REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        saturated_fat_g REAL NOT NULL,
        fiber_g REAL NOT NULL,
        sugar_g REAL NOT NULL,
        added_sugar_g REAL NOT NULL,
        sodium_mg REAL NOT NULL,
        potassium_mg REAL NOT NULL,
        calcium_mg REAL NOT NULL,
        iron_mg REAL NOT NULL,
        magnesium_mg REAL NOT NULL,
        zinc_mg REAL NOT NULL,
        vit_a_mcg_rae REAL NOT NULL,
        vit_c_mg REAL NOT NULL,
        vit_d_mcg REAL NOT NULL,
        vit_b12_mcg REAL NOT NULL,
        folate_mcg_dfe REAL NOT NULL,
        FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE food_allergens (
        food_id INTEGER NOT NULL,
        allergen_code TEXT NOT NULL,
        FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE food_religion_excluded (
        food_id INTEGER NOT NULL,
        religion_code TEXT NOT NULL,
        reason TEXT,
        FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE food_medical_excluded (
        food_id INTEGER NOT NULL,
        restriction_code TEXT NOT NULL,
        severity TEXT NOT NULL,
        reason TEXT,
        FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE food_availability (
        food_id INTEGER NOT NULL,
        context_code TEXT NOT NULL,
        FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        json TEXT NOT NULL
      )
    ''');

    await _createCacheTables(db);

    await db.execute(
      'CREATE INDEX idx_food_allergens ON food_allergens(allergen_code)',
    );
    await db.execute(
      'CREATE INDEX idx_food_religion ON food_religion_excluded(religion_code)',
    );
    await db.execute(
      'CREATE INDEX idx_food_medical ON food_medical_excluded(restriction_code, severity)',
    );
    await db.execute(
      'CREATE INDEX idx_food_availability ON food_availability(context_code)',
    );
    await db.execute('CREATE INDEX idx_food_cost ON foods(cost_estimate)');
    await db.execute('CREATE INDEX idx_food_prep ON foods(prep_method)');
  }

  Future<void> _createCacheTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_entries (
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_accessed_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        access_count INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        PRIMARY KEY(entity_type, entity_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_entries_food_accessed ON cache_entries(entity_type, last_accessed_at)',
    );
  }

  Future<void> _seed(Database db) async {
    final foods = await _seedLoader.loadFoods();
    final batch = db.batch();
    final now = DateTime.now().toUtc();
    final createdAt = now.toIso8601String();
    final expiresAt = CachePolicy.expiresAtFrom(now).toUtc().toIso8601String();

    for (final item in foods) {
      final id = (item['id'] as num).toInt();
      final name = item['name'] as String;
      final mealTypes = List<String>.from(item['mealTypes'] as List<dynamic>);
      final availability = List<String>.from(
        item['availability'] as List<dynamic>,
      );
      final allergens = List<String>.from(item['allergens'] as List<dynamic>);
      final religionRules = List<Map<String, dynamic>>.from(
        (item['religionExcluded'] as List<dynamic>).map(
          (value) => Map<String, dynamic>.from(value as Map),
        ),
      );
      final medicalRules = List<Map<String, dynamic>>.from(
        (item['medicalExcluded'] as List<dynamic>).map(
          (value) => Map<String, dynamic>.from(value as Map),
        ),
      );
      final ingredients = _deriveIngredientTokens(name);
      final nutrients = Map<String, dynamic>.from(item['nutrients'] as Map);

      batch.insert('foods', {
        'id': id,
        'name': name,
        'category': item['category'],
        'cuisine': item['cuisine'],
        'serving_g': (item['servingG'] as num).toDouble(),
        'serving_label': item['servingLabel'],
        'cost_estimate': (item['cost'] as num).toDouble(),
        'cost_confidence': item['costConfidence'],
        'prep_method': item['prep'],
        'prep_time_min': (item['prepTimeMin'] as num).toInt(),
        'meal_types_json': jsonEncode(mealTypes),
        'availability_json': jsonEncode(availability),
        'allergens_json': jsonEncode(allergens),
        'religion_json': jsonEncode(religionRules),
        'medical_json': jsonEncode(medicalRules),
        'ingredients_json': jsonEncode(ingredients),
        'source': 'bundled_reference',
      });

      batch.insert('nutrients', {
        'food_id': id,
        'calories_kcal': (nutrients['calories'] as num).toDouble(),
        'protein_g': (nutrients['protein'] as num).toDouble(),
        'carbs_g': (nutrients['carbs'] as num).toDouble(),
        'fat_g': (nutrients['fat'] as num).toDouble(),
        'saturated_fat_g': (nutrients['saturatedFat'] as num).toDouble(),
        'fiber_g': (nutrients['fiber'] as num).toDouble(),
        'sugar_g': (nutrients['sugar'] as num).toDouble(),
        'added_sugar_g': (nutrients['addedSugar'] as num).toDouble(),
        'sodium_mg': (nutrients['sodium'] as num).toDouble(),
        'potassium_mg': (nutrients['potassium'] as num).toDouble(),
        'calcium_mg': (nutrients['calcium'] as num).toDouble(),
        'iron_mg': (nutrients['iron'] as num).toDouble(),
        'magnesium_mg': (nutrients['magnesium'] as num).toDouble(),
        'zinc_mg': (nutrients['zinc'] as num).toDouble(),
        'vit_a_mcg_rae': (nutrients['vitA'] as num).toDouble(),
        'vit_c_mg': (nutrients['vitC'] as num).toDouble(),
        'vit_d_mcg': (nutrients['vitD'] as num).toDouble(),
        'vit_b12_mcg': (nutrients['vitB12'] as num).toDouble(),
        'folate_mcg_dfe': (nutrients['folate'] as num).toDouble(),
      });

      for (final allergen in allergens) {
        batch.insert('food_allergens', {
          'food_id': id,
          'allergen_code': allergen,
        });
      }

      for (final context in availability) {
        batch.insert('food_availability', {
          'food_id': id,
          'context_code': context,
        });
      }

      for (final religion in religionRules) {
        batch.insert('food_religion_excluded', {
          'food_id': id,
          'religion_code': religion['religion'],
          'reason': religion['reason'],
        });
      }

      for (final rule in medicalRules) {
        batch.insert('food_medical_excluded', {
          'food_id': id,
          'restriction_code': rule['code'],
          'severity': rule['severity'],
          'reason': rule['reason'],
        });
      }

      batch.insert('cache_entries', {
        'entity_type': CachePolicy.foodEntityType,
        'entity_id': id,
        'created_at': createdAt,
        'updated_at': createdAt,
        'last_accessed_at': createdAt,
        'expires_at': expiresAt,
        'access_count': 0,
        'sync_status': 'bundled_reference',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _backfillCacheEntries(Database db) async {
    await _createCacheTables(db);
    final rows = await db.rawQuery(
      '''
      SELECT f.id
      FROM foods f
      LEFT JOIN cache_entries c
        ON c.entity_type = ? AND c.entity_id = f.id
      WHERE c.entity_id IS NULL
      ''',
      [CachePolicy.foodEntityType],
    );

    if (rows.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final createdAt = now.toIso8601String();
    final expiresAt = CachePolicy.expiresAtFrom(now).toUtc().toIso8601String();
    final batch = db.batch();

    for (final row in rows) {
      final id = (row['id'] as num).toInt();
      batch.insert('cache_entries', {
        'entity_type': CachePolicy.foodEntityType,
        'entity_id': id,
        'created_at': createdAt,
        'updated_at': createdAt,
        'last_accessed_at': createdAt,
        'expires_at': expiresAt,
        'access_count': 0,
        'sync_status': 'bundled_reference',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  List<String> _deriveIngredientTokens(String name) {
    const stopWords = {
      'with',
      'and',
      'plain',
      'cup',
      'whole',
      'grain',
      'mixed',
      'small',
      'large',
    };
    return name
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty && token.length > 2)
        .where((token) => !stopWords.contains(token))
        .toSet()
        .toList()
      ..sort();
  }
}
