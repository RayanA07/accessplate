import 'dart:math' as math;

import '../../entities/food.dart';
import '../../entities/nutrients.dart';
import '../../entities/recommendation.dart';
import '../../entities/user_constraints.dart';
import '../../value_objects/availability_context.dart';
import '../preference_scorer.dart';
import 'macro_scorer.dart';
import 'micro_scorer.dart';
import 'penalty_calculator.dart';

class CompositeWeights {
  const CompositeWeights({
    this.macro = 0.30,
    this.micro = 0.25,
    this.penalty = 0.20,
    this.cost = 0.15,
    this.preference = 0.10,
  });

  final double macro;
  final double micro;
  final double penalty;
  final double cost;
  final double preference;

  CompositeWeights normalized() {
    final sum = macro + micro + penalty + cost + preference;
    if (sum <= 0) {
      return const CompositeWeights();
    }
    return CompositeWeights(
      macro: macro / sum,
      micro: micro / sum,
      penalty: penalty / sum,
      cost: cost / sum,
      preference: preference / sum,
    );
  }

  CompositeWeights copyWith({
    double? macro,
    double? micro,
    double? penalty,
    double? cost,
    double? preference,
  }) {
    return CompositeWeights(
      macro: macro ?? this.macro,
      micro: micro ?? this.micro,
      penalty: penalty ?? this.penalty,
      cost: cost ?? this.cost,
      preference: preference ?? this.preference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macro': macro,
      'micro': micro,
      'penalty': penalty,
      'cost': cost,
      'preference': preference,
    };
  }

  factory CompositeWeights.fromJson(Map<String, dynamic> json) {
    return CompositeWeights(
      macro: (json['macro'] as num?)?.toDouble() ?? 0.30,
      micro: (json['micro'] as num?)?.toDouble() ?? 0.25,
      penalty: (json['penalty'] as num?)?.toDouble() ?? 0.20,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.15,
      preference: (json['preference'] as num?)?.toDouble() ?? 0.10,
    );
  }
}

class CompositeScorer {
  const CompositeScorer({
    required this.macroScorer,
    required this.microScorer,
    required this.penaltyCalculator,
    required this.preferenceScorer,
    required this.weights,
  });

  final MacroScorer macroScorer;
  final MicroScorer microScorer;
  final PenaltyCalculator penaltyCalculator;
  final PreferenceScorer preferenceScorer;
  final CompositeWeights weights;

  ScoredFood score({
    required FoodRecord record,
    required FeasibilityConstraints feasibility,
  }) {
    final food = record.food;
    final macro = macroScorer.score(record.nutrients);
    final micro = microScorer.score(record.nutrients);
    final penalty = penaltyCalculator.penalty(record.nutrients);
    final cost = _costPressure(
      food: food,
      nutrients: record.nutrients,
      feasibility: feasibility,
    );
    final preference = preferenceScorer.score(food);

    final composite =
        weights.macro * macro +
        weights.micro * micro -
        weights.penalty * penalty -
        weights.cost * cost +
        weights.preference * preference;

    return ScoredFood(
      food: food,
      nutrients: record.nutrients,
      composite: composite,
      breakdown: ScoreBreakdown(
        macro: macro,
        micro: micro,
        penalty: penalty,
        cost: cost,
        preference: preference,
      ),
    );
  }

  double _costPressure({
    required Food food,
    required Nutrients nutrients,
    required FeasibilityConstraints feasibility,
  }) {
    final budgetUsd = feasibility.maxCostPerMeal;
    if (budgetUsd <= 0) {
      return 1;
    }

    final priceShare = (food.costEstimate / budgetUsd).clamp(0, 1).toDouble();
    final sharePressure = switch (_budgetMode(budgetUsd)) {
      _BudgetMode.crisis => math.pow(priceShare, 0.72).toDouble(),
      _BudgetMode.tight => math.pow(priceShare, 0.84).toDouble(),
      _BudgetMode.standard => math.pow(priceShare, 1.0).toDouble(),
    };

    final proteinFloor = _boundedFloor(macroScorer.targets.proteinG, 0.55, 20);
    final fiberFloor = _boundedFloor(macroScorer.targets.fiberG, 0.60, 8);

    final proteinShortfall = _shortfallRatio(proteinFloor, nutrients.proteinG);
    final fiberShortfall = _shortfallRatio(fiberFloor, nutrients.fiberG);
    final floorPenalty = (proteinShortfall * 0.60) + (fiberShortfall * 0.40);

    final proteinPerDollar =
        nutrients.proteinG / math.max(food.costEstimate, 1);
    final fiberPerDollar = nutrients.fiberG / math.max(food.costEstimate, 1);

    var valueRelief = 0.0;
    valueRelief += math.min(0.22, proteinPerDollar / 28).toDouble();
    valueRelief += math.min(0.16, fiberPerDollar / 18).toDouble();

    if (food.readyToEat) {
      valueRelief += 0.10;
    } else if (food.prepTimeMin <= 5) {
      valueRelief += 0.05;
    }

    if (_supportsBudgetAccess(food, feasibility.availability)) {
      valueRelief += 0.06;
    }

    final pressure =
        (sharePressure * 0.72) + (floorPenalty * 0.38) - valueRelief;
    return pressure.clamp(0, 1).toDouble();
  }

  _BudgetMode _budgetMode(double budgetUsd) {
    if (budgetUsd <= 3.0) {
      return _BudgetMode.crisis;
    }
    if (budgetUsd <= 5.0) {
      return _BudgetMode.tight;
    }
    return _BudgetMode.standard;
  }

  bool _supportsBudgetAccess(
    Food food,
    Set<AvailabilityContext> activeContexts,
  ) {
    const budgetContexts = {
      AvailabilityContext.foodPantry,
      AvailabilityContext.dollarStore,
      AvailabilityContext.convenience,
    };

    return food.availability.any(
      (context) =>
          budgetContexts.contains(context) && activeContexts.contains(context),
    );
  }

  double _boundedFloor(double target, double ratio, double cap) {
    if (target <= 0) {
      return 0;
    }
    return math.min(target * ratio, cap).toDouble();
  }

  double _shortfallRatio(double floor, double actual) {
    if (floor <= 0) {
      return 0;
    }
    if (actual >= floor) {
      return 0;
    }
    return ((floor - actual) / floor).clamp(0, 1).toDouble();
  }
}

enum _BudgetMode { crisis, tight, standard }
