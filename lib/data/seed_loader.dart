import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/ingredient_availability_catalog.dart';
import '../domain/entities/local_access.dart';
import '../domain/engine/score_config_provider.dart';

class SeedLoader {
  Future<List<Map<String, dynamic>>> loadFoods() async {
    final bundled = await _loadFoodAsset('assets/reference/foods.json');
    final supplement = await _loadFoodAsset(
      'assets/reference/foods_supplement.json',
    );
    final fastFoodMenus = await _loadFoodAsset(
      'assets/reference/fast_food_menus.json',
    );
    return [...bundled, ...supplement, ...fastFoodMenus];
  }

  Future<List<Map<String, dynamic>>> _loadFoodAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<ReferenceTables> loadReferenceTables() async {
    final medicalRaw = await rootBundle.loadString(
      'assets/reference/medical_modifiers.json',
    );
    final rdaRaw = await rootBundle.loadString(
      'assets/reference/micronutrient_rda.json',
    );

    final medical = Map<String, dynamic>.from(
      jsonDecode(medicalRaw) as Map<String, dynamic>,
    );
    final rda = Map<String, dynamic>.from(
      jsonDecode(rdaRaw) as Map<String, dynamic>,
    );

    final rdaTable = <String, Map<String, double>>{};
    for (final entry in (rda['rda'] as Map<String, dynamic>).entries) {
      rdaTable[entry.key] = Map<String, double>.from(
        (entry.value as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
    }

    final priorityElevations = <String, Map<String, double>>{};
    for (final entry
        in (medical['microPriorityElevations'] as Map<String, dynamic>)
            .entries) {
      priorityElevations[entry.key] = Map<String, double>.from(
        (entry.value as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
    }

    return ReferenceTables(
      rdaTable: rdaTable,
      medicalModifiers: Map<String, dynamic>.from(
        medical['medicalModifiers'] as Map,
      ),
      microPriorityElevations: priorityElevations,
      basePenaltyThresholds: Map<String, double>.from(
        (medical['basePenaltyThresholds'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      basePenaltyWeights: Map<String, double>.from(
        (medical['basePenaltyWeights'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }

  Future<LocalAccessCatalog> loadLocalAccessCatalog() async {
    final raw = await rootBundle.loadString(
      'assets/reference/local_access_profiles.json',
    );
    return LocalAccessCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
    );
  }

  Future<IngredientAvailabilityCatalog>
  loadIngredientAvailabilityCatalog() async {
    final raw = await rootBundle.loadString(
      'assets/reference/ingredient_store_types.json',
    );
    return IngredientAvailabilityCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
    );
  }
}
