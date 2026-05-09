import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/engine/score_config_provider.dart';

class SeedLoader {
  Future<List<Map<String, dynamic>>> loadFoods() async {
    final raw = await rootBundle.loadString('assets/reference/foods.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<ReferenceTables> loadReferenceTables() async {
    final medicalRaw =
        await rootBundle.loadString('assets/reference/medical_modifiers.json');
    final rdaRaw =
        await rootBundle.loadString('assets/reference/micronutrient_rda.json');

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
        in (medical['microPriorityElevations'] as Map<String, dynamic>).entries) {
      priorityElevations[entry.key] = Map<String, double>.from(
        (entry.value as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
    }

    return ReferenceTables(
      rdaTable: rdaTable,
      medicalModifiers:
          Map<String, dynamic>.from(medical['medicalModifiers'] as Map),
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
}
