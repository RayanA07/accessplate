import '../entities/demographics.dart';
import '../entities/user_constraints.dart';
import 'scoring/composite_scorer.dart';
import 'scoring/macro_scorer.dart';

class ReferenceTables {
  const ReferenceTables({
    required this.rdaTable,
    required this.medicalModifiers,
    required this.microPriorityElevations,
    required this.basePenaltyThresholds,
    required this.basePenaltyWeights,
  });

  final Map<String, Map<String, double>> rdaTable;
  final Map<String, dynamic> medicalModifiers;
  final Map<String, Map<String, double>> microPriorityElevations;
  final Map<String, double> basePenaltyThresholds;
  final Map<String, double> basePenaltyWeights;
}

class ScoreConfig {
  const ScoreConfig({
    required this.macroTargets,
    required this.macroWeights,
    required this.rda,
    required this.microPriorities,
    required this.penaltyThresholds,
    required this.penaltyWeights,
    required this.compositeWeights,
  });

  final NutritionalTargets macroTargets;
  final MacroWeights macroWeights;
  final Map<String, double> rda;
  final Map<String, double> microPriorities;
  final Map<String, double> penaltyThresholds;
  final Map<String, double> penaltyWeights;
  final CompositeWeights compositeWeights;
}

class PenaltyConfig {
  const PenaltyConfig({required this.thresholds, required this.weights});

  final Map<String, double> thresholds;
  final Map<String, double> weights;
}

class PenaltyConfigBuilder {
  const PenaltyConfigBuilder(this.modifierTable);

  final Map<String, dynamic> modifierTable;

  PenaltyConfig build({
    required Map<String, double> baseThresholds,
    required Map<String, double> baseWeights,
    required Set<String> activeConditions,
  }) {
    final thresholds = Map<String, double>.from(baseThresholds);
    final weights = Map<String, double>.from(baseWeights);

    for (final condition in activeConditions) {
      final modifier = modifierTable[condition];
      if (modifier is! Map<String, dynamic>) {
        continue;
      }
      _applyModifier(
        target: thresholds,
        modifierGroup:
            modifier['thresholds'] as Map<String, dynamic>? ?? const {},
      );
      _applyModifier(
        target: weights,
        modifierGroup: modifier['weights'] as Map<String, dynamic>? ?? const {},
      );
    }

    return PenaltyConfig(thresholds: thresholds, weights: weights);
  }

  void _applyModifier({
    required Map<String, double> target,
    required Map<String, dynamic> modifierGroup,
  }) {
    for (final entry in modifierGroup.entries) {
      final data = entry.value as Map<String, dynamic>;
      if (data.containsKey('absolute')) {
        target[entry.key] = (data['absolute'] as num).toDouble();
      } else if (data.containsKey('multiplier')) {
        target[entry.key] =
            (target[entry.key] ?? 0) * (data['multiplier'] as num).toDouble();
      }
    }
  }
}

class ScoreConfigProvider {
  const ScoreConfigProvider(this.tables);

  final ReferenceTables tables;

  ScoreConfig buildFor({
    required UserConstraints user,
    required CompositeWeights weights,
  }) {
    final rda =
        tables.rdaTable[user.demographics.demographicKey] ??
        tables.rdaTable['female_19_50'] ??
        const <String, double>{};

    final priorities = <String, double>{for (final key in rda.keys) key: 1};

    final priorityCodes = <String>[
      ...user.demographics.concerns.map((value) => value.code),
      ?user.preference.dietaryStyle.microPriorityCode,
    ];

    for (final code in priorityCodes) {
      final modifier = tables.microPriorityElevations[code];
      if (modifier == null) {
        continue;
      }
      for (final entry in modifier.entries) {
        priorities[entry.key] = (priorities[entry.key] ?? 1) * entry.value;
      }
    }

    final activeConditions = <String>{
      ...user.safety.medicalLimit.map((value) => '${value.code}_limit'),
      if (user.demographics.concerns.contains(HealthConcern.hypertension))
        'hypertension',
    };

    final penaltyConfig = PenaltyConfigBuilder(tables.medicalModifiers).build(
      baseThresholds: tables.basePenaltyThresholds,
      baseWeights: tables.basePenaltyWeights,
      activeConditions: activeConditions,
    );

    return ScoreConfig(
      macroTargets: user.targets,
      macroWeights: const MacroWeights(),
      rda: rda,
      microPriorities: priorities,
      penaltyThresholds: penaltyConfig.thresholds,
      penaltyWeights: penaltyConfig.weights,
      compositeWeights: _budgetAdjustedWeights(user, weights),
    );
  }

  CompositeWeights _budgetAdjustedWeights(
    UserConstraints user,
    CompositeWeights weights,
  ) {
    final normalized = weights.normalized();
    final budget = user.feasibility.maxCostPerMeal;

    if (budget <= 3) {
      return _scaledWeights(
        normalized,
        macro: 0.82,
        micro: 0.78,
        penalty: 1.10,
        cost: 2.35,
        preference: 0.95,
      );
    }

    if (budget <= 5) {
      return _scaledWeights(
        normalized,
        macro: 0.90,
        micro: 0.86,
        penalty: 1.06,
        cost: 1.75,
        preference: 0.98,
      );
    }

    return normalized;
  }

  CompositeWeights _scaledWeights(
    CompositeWeights weights, {
    required double macro,
    required double micro,
    required double penalty,
    required double cost,
    required double preference,
  }) {
    return CompositeWeights(
      macro: weights.macro * macro,
      micro: weights.micro * micro,
      penalty: weights.penalty * penalty,
      cost: weights.cost * cost,
      preference: weights.preference * preference,
    ).normalized();
  }
}
