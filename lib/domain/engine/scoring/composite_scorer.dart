import 'dart:math' as math;

import '../../entities/food.dart';
import '../../entities/recommendation.dart';
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

  ScoredFood score({required FoodRecord record, required double budgetUsd}) {
    final food = record.food;
    final macro = macroScorer.score(record.nutrients);
    final micro = microScorer.score(record.nutrients);
    final penalty = penaltyCalculator.penalty(record.nutrients);
    final cost = budgetUsd <= 0
        ? 0.0
        : math.min(1.0, food.costEstimate / budgetUsd).toDouble();
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
}
