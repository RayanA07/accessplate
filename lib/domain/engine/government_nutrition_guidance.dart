import '../entities/demographics.dart';
import '../entities/user_constraints.dart';
import '../value_objects/dietary_style.dart';
import '../value_objects/meal_type.dart';

class DailyNutritionTargets {
  const DailyNutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.saturatedFatLimitG,
    required this.addedSugarLimitG,
    required this.sodiumLimitMg,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double saturatedFatLimitG;
  final double addedSugarLimitG;
  final double sodiumLimitMg;
}

class GovernmentNutritionGuidance {
  const GovernmentNutritionGuidance();

  bool hasPersonalizedInputs(Demographics demographics) {
    return demographics.heightCm != null && demographics.weightKg != null;
  }

  DailyNutritionTargets dailyTargetsFor(Demographics demographics) {
    final calories = _estimatedCalories(demographics).roundToDouble();
    final weightKg = _weightKg(demographics);
    final proteinFloor = demographics.concerns.contains(HealthConcern.pregnancy) ||
            demographics.concerns.contains(HealthConcern.lactating)
        ? 71.0
        : weightKg * 0.8;
    final proteinFromCalories = (calories * 0.15) / 4;
    final proteinG = _roundToNearest(maxOf(proteinFloor, proteinFromCalories), 1);
    final carbsG = _roundToNearest(maxOf(130, (calories * 0.55) / 4), 1);
    final fatG = _roundToNearest((calories * 0.30) / 9, 1);
    final fiberG = _roundToNearest(_fiberTargetFor(demographics), 1);

    return DailyNutritionTargets(
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      saturatedFatLimitG: _roundToNearest((calories * 0.10) / 9, 1),
      addedSugarLimitG: _roundToNearest((calories * 0.10) / 4, 1),
      sodiumLimitMg: 2300,
    );
  }

  NutritionalTargets mealTargetsFor({
    required Demographics demographics,
    required MealType mealType,
  }) {
    final daily = dailyTargetsFor(demographics);
    final share = switch (mealType) {
      MealType.breakfast => 0.25,
      MealType.lunch => 0.35,
      MealType.dinner => 0.35,
      MealType.snack => 0.15,
      MealType.any => 0.33,
    };

    return NutritionalTargets(
      calories: _roundToNearest(daily.calories * share, 1),
      proteinG: _roundToNearest(daily.proteinG * share, 1),
      carbsG: _roundToNearest(daily.carbsG * share, 1),
      fatG: _roundToNearest(daily.fatG * share, 1),
      fiberG: _roundToNearest(daily.fiberG * share, 1),
    );
  }

  Map<String, double> prioritizedMicronutrients({
    required Demographics demographics,
    required DietaryStyle dietaryStyle,
    required Map<String, Map<String, double>> rdaTable,
    required Map<String, Map<String, double>> microPriorityElevations,
  }) {
    final rda = rdaTable[demographics.demographicKey] ?? const <String, double>{};
    final activeCodes = <String>[
      ...demographics.concerns.map((value) => value.code),
      if (dietaryStyle.microPriorityCode != null)
        dietaryStyle.microPriorityCode!,
    ];

    if (activeCodes.isEmpty) {
      return const <String, double>{};
    }

    final weightedKeys = <String, double>{};
    for (final code in activeCodes) {
      final priority = microPriorityElevations[code];
      if (priority == null) {
        continue;
      }
      for (final entry in priority.entries) {
        weightedKeys[entry.key] = maxOf(weightedKeys[entry.key] ?? 0, entry.value);
      }
    }

    final sortedKeys = weightedKeys.keys.toList()
      ..sort((a, b) => (weightedKeys[b] ?? 0).compareTo(weightedKeys[a] ?? 0));

    return {
      for (final key in sortedKeys)
        if (rda.containsKey(key)) key: rda[key]!,
    };
  }

  double _estimatedCalories(Demographics demographics) {
    final age = demographics.ageYears.toDouble();
    final heightM = _heightM(demographics);
    final weightKg = _weightKg(demographics);

    final calories = switch (demographics.sex) {
      Sex.male => age < 19
          ? 88.5 -
              (61.9 * age) +
              _paCoefficient(demographics: demographics) *
                  ((26.7 * weightKg) + (903 * heightM)) +
              25
          : 662 -
              (9.53 * age) +
              _paCoefficient(demographics: demographics) *
                  ((15.91 * weightKg) + (539.6 * heightM)),
      Sex.female => age < 19
          ? 135.3 -
              (30.8 * age) +
              _paCoefficient(demographics: demographics) *
                  ((10.0 * weightKg) + (934 * heightM)) +
              25
          : 354 -
              (6.91 * age) +
              _paCoefficient(demographics: demographics) *
                  ((9.36 * weightKg) + (726 * heightM)),
    };

    var adjusted = calories;
    if (demographics.concerns.contains(HealthConcern.pregnancy)) {
      adjusted += 340;
    }
    if (demographics.concerns.contains(HealthConcern.lactating)) {
      adjusted += 330;
    }
    return adjusted.clamp(1400, 3600).toDouble();
  }

  double _paCoefficient({required Demographics demographics}) {
    final isAdult = demographics.ageYears >= 19;
    return switch (demographics.activityLevel) {
      ActivityLevel.sedentary => 1.00,
      ActivityLevel.light => isAdult
          ? (demographics.sex == Sex.male ? 1.11 : 1.12)
          : (demographics.sex == Sex.male ? 1.13 : 1.16),
      ActivityLevel.moderate => isAdult
          ? (demographics.sex == Sex.male ? 1.25 : 1.27)
          : (demographics.sex == Sex.male ? 1.26 : 1.31),
      ActivityLevel.active => isAdult
          ? (demographics.sex == Sex.male ? 1.36 : 1.36)
          : (demographics.sex == Sex.male ? 1.34 : 1.43),
      ActivityLevel.veryActive => isAdult
          ? (demographics.sex == Sex.male ? 1.48 : 1.45)
          : (demographics.sex == Sex.male ? 1.42 : 1.56),
    };
  }

  double _fiberTargetFor(Demographics demographics) {
    if (demographics.concerns.contains(HealthConcern.pregnancy)) {
      return 28;
    }
    if (demographics.concerns.contains(HealthConcern.lactating)) {
      return 29;
    }
    if (demographics.sex == Sex.male) {
      return demographics.ageYears <= 50 ? 38 : 30;
    }
    return demographics.ageYears <= 50 ? 25 : 21;
  }

  double _heightM(Demographics demographics) {
    final heightCm = demographics.heightCm ?? _defaultHeightCm(demographics);
    return (heightCm / 100).clamp(1.40, 2.10).toDouble();
  }

  double _weightKg(Demographics demographics) {
    return (demographics.weightKg ?? _defaultWeightKg(demographics))
        .clamp(40, 180)
        .toDouble();
  }

  double _defaultHeightCm(Demographics demographics) {
    return switch (demographics.sex) {
      Sex.male => demographics.ageYears < 19 ? 172 : 177,
      Sex.female => demographics.ageYears < 19 ? 162 : 163,
    };
  }

  double _defaultWeightKg(Demographics demographics) {
    return switch (demographics.sex) {
      Sex.male => demographics.ageYears < 19 ? 67 : 76,
      Sex.female => demographics.ageYears < 19 ? 57 : 59,
    };
  }

  double _roundToNearest(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  double maxOf(double a, double b) => a > b ? a : b;
}
