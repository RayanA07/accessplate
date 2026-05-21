import 'dart:math' as math;

import '../entities/nutrients.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import 'access_advisor.dart';
import 'scoring/macro_scorer.dart';
import 'scoring/penalty_calculator.dart';

class MealBasketPlanner {
  MealBasketPlanner({
    required this.user,
    required this.macroScorer,
    required this.penaltyCalculator,
    FoodAccessAdvisor? accessAdvisor,
  }) : _accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor();

  final UserConstraints user;
  final MacroScorer macroScorer;
  final PenaltyCalculator penaltyCalculator;
  final FoodAccessAdvisor _accessAdvisor;

  List<MealBasketPlan> build(List<ScoredFood> ranked) {
    if (ranked.isEmpty) {
      return const [];
    }

    final pool = ranked.take(user.access.emergencyMode ? 8 : 10).toList();
    final candidates = <_CandidateBasket>[
      for (final item in pool) _buildCandidate([item]),
    ];

    for (var i = 0; i < pool.length; i++) {
      for (var j = i + 1; j < pool.length; j++) {
        final pair = [pool[i], pool[j]];
        if (_canCombine(pair)) {
          candidates.add(_buildCandidate(pair));
        }
      }
    }

    if (candidates.isEmpty) {
      return const [];
    }

    final byScore = [...candidates]
      ..sort((a, b) => b.score.compareTo(a.score));
    final byCost = [...candidates]
      ..sort((a, b) => a.plan.totalCost.compareTo(b.plan.totalCost));
    final byStretch = [...candidates]
      ..sort((a, b) {
        final pantryCompare = b.pantryMatchCount.compareTo(a.pantryMatchCount);
        if (pantryCompare != 0) {
          return pantryCompare;
        }
        final emergencyCompare = (b.emergencyFriendly ? 1 : 0).compareTo(
          a.emergencyFriendly ? 1 : 0,
        );
        if (emergencyCompare != 0) {
          return emergencyCompare;
        }
        return b.score.compareTo(a.score);
      });

    final selected = <MealBasketPlan>[];
    final usedKeys = <String>{};

    void addFirst(
      List<_CandidateBasket> source,
      String Function(_CandidateBasket candidate) titleBuilder,
    ) {
      for (final candidate in source) {
        if (usedKeys.add(candidate.key)) {
          selected.add(candidate.planForTitle(titleBuilder(candidate)));
          return;
        }
      }
    }

    addFirst(byScore, (_) => 'Best basket for today');
    addFirst(byCost, (_) => 'Lowest total cost');
    addFirst(byStretch, (candidate) {
      if (candidate.emergencyFriendly) {
        return 'Emergency-ready basket';
      }
      if (candidate.pantryMatchCount > 0) {
        return 'Pantry-stretch basket';
      }
      return 'One-stop backup basket';
    });

    return selected.take(3).toList(growable: false);
  }

  bool _canCombine(List<ScoredFood> items) {
    final budget = user.feasibility.maxCostPerMeal;
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.food.costEstimate,
    );
    if (budget > 0 && totalCost > budget) {
      return false;
    }

    if (items.every((item) => item.food.category == 'prepared_meal')) {
      return false;
    }

    final sharedSources = _sharedSources(items);
    if (sharedSources.isEmpty) {
      return false;
    }

    final expensiveCount = items
        .where((item) => item.food.costEstimate >= budget * 0.65)
        .length;
    if (expensiveCount > 1) {
      return false;
    }

    return true;
  }

  _CandidateBasket _buildCandidate(List<ScoredFood> items) {
    final totalNutrients = items.fold(
      Nutrients.zero,
      (sum, item) => sum.plus(item.nutrients),
    );
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.food.costEstimate,
    );
    final totalPrepMinutes = items.fold<int>(
      0,
      (sum, item) => sum + item.food.prepTimeMin,
    );
    final macroScore = macroScorer.score(totalNutrients);
    final penaltyScore = penaltyCalculator.penalty(totalNutrients);
    final averageComposite =
        items.fold<double>(0, (sum, item) => sum + item.composite) /
        items.length;
    final insights = items
        .map((item) => _accessAdvisor.inspect(food: item.food, user: user))
        .toList(growable: false);
    final pantryMatches = {
      for (final insight in insights) ...insight.pantryMatches,
    }.toList()
      ..sort();
    final lowTravelAll = insights.every((insight) => !insight.travelBurden.isHigh);
    final emergencyFriendly =
        totalCost <= _emergencyBudget() &&
        totalPrepMinutes <= 10 &&
        lowTravelAll;
    final costPressure = _costPressure(totalCost);
    final pantryBonus = math.min(0.18, pantryMatches.length * 0.08).toDouble();
    final accessBonus = insights.every((insight) => insight.lowTravel) ? 0.08 : 0;
    final emergencyBonus =
        user.access.emergencyMode && emergencyFriendly ? 0.12 : 0;
    final score =
        (averageComposite * 0.45) +
        (macroScore * 0.25) -
        (penaltyScore * 0.18) -
        (costPressure * 0.14) +
        pantryBonus +
        accessBonus +
        emergencyBonus;

    final sharedSources = _sharedSources(items);
    final primarySource = _preferredSharedSource(sharedSources);
    final summary = _summaryFor(
      items: items,
      totalCost: totalCost,
      emergencyFriendly: emergencyFriendly,
      pantryMatches: pantryMatches,
      primarySource: primarySource,
    );
    final highlights = _highlightsFor(
      items: items,
      totalCost: totalCost,
      pantryMatches: pantryMatches,
      primarySource: primarySource,
      totalPrepMinutes: totalPrepMinutes,
      emergencyFriendly: emergencyFriendly,
    );

    return _CandidateBasket(
      key: items.map((item) => item.food.id).toList()..sort(),
      score: score,
      pantryMatchCount: pantryMatches.length,
      emergencyFriendly: emergencyFriendly,
      plan: MealBasketPlan(
        title: '',
        summary: summary,
        items: items,
        totalNutrients: totalNutrients,
        totalCost: totalCost,
        totalPrepMinutes: totalPrepMinutes,
        highlights: highlights,
      ),
    );
  }

  Set<AvailabilityContext> _sharedSources(List<ScoredFood> items) {
    final active = user.feasibility.availability;
    var shared = items.first.food.availability.intersection(active);
    for (final item in items.skip(1)) {
      shared = shared.intersection(item.food.availability.intersection(active));
    }
    return shared;
  }

  AvailabilityContext? _preferredSharedSource(Set<AvailabilityContext> sources) {
    final priority = user.access.emergencyMode || user.access.transportation.lowMobility
        ? const [
            AvailabilityContext.foodPantry,
            AvailabilityContext.dollarStore,
            AvailabilityContext.convenience,
            AvailabilityContext.fastFood,
            AvailabilityContext.grocery,
          ]
        : const [
            AvailabilityContext.grocery,
            AvailabilityContext.foodPantry,
            AvailabilityContext.dollarStore,
            AvailabilityContext.convenience,
            AvailabilityContext.fastFood,
          ];

    for (final source in priority) {
      if (sources.contains(source)) {
        return source;
      }
    }
    return null;
  }

  String _summaryFor({
    required List<ScoredFood> items,
    required double totalCost,
    required bool emergencyFriendly,
    required List<String> pantryMatches,
    required AvailabilityContext? primarySource,
  }) {
    if (user.access.emergencyMode && emergencyFriendly) {
      return 'Fast, cheaper basket built for a hard day.';
    }
    if (pantryMatches.isNotEmpty) {
      return 'Builds on food you already have to keep the total down.';
    }
    if (primarySource != null) {
      return 'One-stop basket that stays realistic through ${primarySource.label.toLowerCase()}.';
    }
    if (items.length == 1) {
      return 'Single-item fallback that still fits your current setup.';
    }
    return 'Two-item basket that balances cost, access, and nutrition.';
  }

  List<String> _highlightsFor({
    required List<ScoredFood> items,
    required double totalCost,
    required List<String> pantryMatches,
    required AvailabilityContext? primarySource,
    required int totalPrepMinutes,
    required bool emergencyFriendly,
  }) {
    final highlights = <String>[
      '\$${totalCost.toStringAsFixed(2)} total',
    ];
    if (primarySource != null) {
      highlights.add(primarySource.label);
    }
    if (pantryMatches.isNotEmpty) {
      highlights.add('Uses ${pantryMatches.take(2).join(' + ')}');
    }
    if (emergencyFriendly) {
      highlights.add('Emergency fit');
    } else if (totalPrepMinutes > 0) {
      highlights.add('$totalPrepMinutes min total prep');
    }
    return highlights;
  }

  double _costPressure(double totalCost) {
    final budget = user.feasibility.maxCostPerMeal;
    if (budget <= 0) {
      return 1;
    }
    return (totalCost / budget).clamp(0, 1.2).toDouble();
  }

  double _emergencyBudget() {
    final budget = user.feasibility.maxCostPerMeal;
    return user.access.emergencyMode && budget > 4 ? 4 : budget;
  }
}

class _CandidateBasket {
  _CandidateBasket({
    required List<int> key,
    required this.score,
    required this.pantryMatchCount,
    required this.emergencyFriendly,
    required this.plan,
  }) : key = _keyFor(key);

  final String key;
  final double score;
  final int pantryMatchCount;
  final bool emergencyFriendly;
  final MealBasketPlan plan;

  MealBasketPlan planForTitle(String title) {
    return MealBasketPlan(
      title: title,
      summary: plan.summary,
      items: plan.items,
      totalNutrients: plan.totalNutrients,
      totalCost: plan.totalCost,
      totalPrepMinutes: plan.totalPrepMinutes,
      highlights: plan.highlights,
    );
  }

  static String _keyFor(List<int> ids) => ids.join('-');
}

extension on TravelBurden {
  bool get isHigh => this == TravelBurden.high;
}
