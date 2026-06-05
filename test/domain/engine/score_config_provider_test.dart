import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/engine/scoring/composite_scorer.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/value_objects/medical_restriction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const provider = ScoreConfigProvider(_tables);

  test('high cholesterol and heart-risk limits tighten penalty thresholds', () {
    final user = UserConstraints.defaults().copyWith(
      safety: const SafetyConstraints(
        medicalLimit: {
          MedicalRestriction.highCholesterol,
          MedicalRestriction.heartDiseaseCardiovascularRisk,
        },
      ),
    );

    final config = provider.buildFor(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(config.penaltyThresholds['saturated_fat_g'], closeTo(3.185, 0.001));
    expect(config.penaltyThresholds['sodium_mg'], closeTo(487.5, 0.001));
    expect(config.penaltyWeights['saturated_fat_g'], closeTo(0.918, 0.001));
    expect(config.penaltyWeights['sodium_mg'], closeTo(0.6, 0.001));
  });

  test('medical limit modifiers support legacy keys without _limit suffix', () {
    final user = UserConstraints.defaults().copyWith(
      safety: const SafetyConstraints(
        medicalLimit: {MedicalRestriction.lowPotassiumCkd},
      ),
    );

    final config = provider.buildFor(
      user: user,
      weights: const CompositeWeights(),
    );

    expect(config.penaltyThresholds['potassium_mg'], 600);
    expect(config.penaltyWeights['potassium_mg'], 0.4);
  });
}

const _tables = ReferenceTables(
  rdaTable: {
    'female_19_50': {'iron_mg': 18, 'calcium_mg': 1000},
  },
  medicalModifiers: {
    'low_potassium_ckd': {
      'thresholds': {
        'potassium_mg': {'absolute': 600},
      },
      'weights': {
        'potassium_mg': {'absolute': 0.4},
      },
    },
    'high_cholesterol_limit': {
      'thresholds': {
        'saturated_fat_g': {'multiplier': 0.7},
      },
      'weights': {
        'saturated_fat_g': {'multiplier': 1.7},
      },
    },
    'heart_disease_cardiovascular_risk_limit': {
      'thresholds': {
        'sodium_mg': {'multiplier': 0.65},
        'saturated_fat_g': {'multiplier': 0.65},
      },
      'weights': {
        'sodium_mg': {'multiplier': 1.5},
        'saturated_fat_g': {'multiplier': 1.8},
      },
    },
  },
  microPriorityElevations: {},
  basePenaltyThresholds: {'sodium_mg': 750, 'saturated_fat_g': 7},
  basePenaltyWeights: {'sodium_mg': 0.4, 'saturated_fat_g': 0.3},
);
