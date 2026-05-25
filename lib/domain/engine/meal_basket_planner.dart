import 'dart:math' as math;

import '../entities/nutrients.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import 'access_advisor.dart';
import 'access_copy.dart';
import 'source_content_model.dart';
import 'source_network_advisor.dart';
import 'scoring/macro_scorer.dart';
import 'scoring/penalty_calculator.dart';

class MealBasketPlanner {
  MealBasketPlanner({
    required this.user,
    required this.macroScorer,
    required this.penaltyCalculator,
    FoodAccessAdvisor? accessAdvisor,
    SourceNetworkAdvisor? sourceNetworkAdvisor,
  }) : _accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor(),
       _sourceNetworkAdvisor =
           sourceNetworkAdvisor ?? const SourceNetworkAdvisor();

  final UserConstraints user;
  final MacroScorer macroScorer;
  final PenaltyCalculator penaltyCalculator;
  final FoodAccessAdvisor _accessAdvisor;
  final SourceNetworkAdvisor _sourceNetworkAdvisor;
  final SourceContentModel _contentModel = const SourceContentModel();

  AccessCopy get _copy => AccessCopy(user.access);

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

    if (!user.access.emergencyMode) {
      for (var i = 0; i < pool.length; i++) {
        for (var j = i + 1; j < pool.length; j++) {
          for (var k = j + 1; k < pool.length; k++) {
            final trio = [pool[i], pool[j], pool[k]];
            if (_canCombine(trio)) {
              candidates.add(_buildCandidate(trio));
            }
          }
        }
      }
    }

    if (candidates.isEmpty) {
      return const [];
    }

    final byScore = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
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

    addFirst(
      byScore,
      (_) => _copy.choose('Best basket for today', 'Mejor canasta para hoy'),
    );
    addFirst(
      byCost,
      (_) => _copy.choose('Lowest total cost', 'Costo total mas bajo'),
    );
    addFirst(byStretch, (candidate) {
      if (candidate.emergencyFriendly) {
        return _copy.choose(
          'Emergency-ready basket',
          'Canasta lista para emergencia',
        );
      }
      if (candidate.pantryMatchCount > 0) {
        return _copy.choose(
          'Pantry-stretch basket',
          'Canasta para rendir despensa',
        );
      }
      return _copy.choose(
        'One-stop backup basket',
        'Canasta de respaldo de una parada',
      );
    });

    return selected.take(3).toList(growable: false);
  }

  bool _canCombine(List<ScoredFood> items) {
    final budget = user.feasibility.maxCostPerMeal;
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.food.costEstimate,
    );
    final totalNutrients = items.fold(
      Nutrients.zero,
      (sum, item) => sum.plus(item.nutrients),
    );
    final estimatedMealsCovered = _estimateMealsCovered(
      items: items,
      totalNutrients: totalNutrients,
    );
    final allowedBudget = budget <= 0 ? 0 : budget * estimatedMealsCovered;
    if (budget > 0 && totalCost > allowedBudget) {
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
    if (expensiveCount > estimatedMealsCovered) {
      return false;
    }

    if (items.length >= 3 && estimatedMealsCovered < 2) {
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
    }.toList()..sort();
    final estimatedMealsCovered = _estimateMealsCovered(
      items: items,
      totalNutrients: totalNutrients,
      pantryMatches: pantryMatches,
    );
    final lowTravelAll = insights.every(
      (insight) => !insight.travelBurden.isHigh,
    );
    final emergencyFriendly =
        totalCost <= _emergencyBudget() &&
        totalPrepMinutes <= 10 &&
        lowTravelAll;
    final costPressure = _costPressure(totalCost / estimatedMealsCovered);
    final pantryBonus = math.min(0.18, pantryMatches.length * 0.08).toDouble();
    final accessBonus = insights.every((insight) => insight.lowTravel)
        ? 0.08
        : 0;
    final emergencyBonus = user.access.emergencyMode && emergencyFriendly
        ? 0.12
        : 0;
    final mealCoverageBonus = (estimatedMealsCovered - 1) * 0.12;
    final score =
        (averageComposite * 0.45) +
        (macroScore * 0.25) -
        (penaltyScore * 0.18) -
        (costPressure * 0.14) +
        pantryBonus +
        accessBonus +
        emergencyBonus +
        mealCoverageBonus;

    final sharedSources = _sharedSources(items);
    final resolution = _sourceNetworkAdvisor.catalog?.resolve(
      user.access.postalCode,
    );
    final primarySource = _preferredSharedSource(
      sharedSources,
      emergencyFriendly: emergencyFriendly,
      pantryMatches: pantryMatches,
      items: items,
    );
    final primarySourceSnapshot = primarySource == null
        ? null
        : resolution?.profile.sourceFor(primarySource);
    final summary = _summaryFor(
      items: items,
      totalCost: totalCost,
      emergencyFriendly: emergencyFriendly,
      pantryMatches: pantryMatches,
      estimatedMealsCovered: estimatedMealsCovered,
      primarySource: primarySource,
      sourceTravelMinutes: primarySourceSnapshot?.typicalTravelMinutes,
    );
    final highlights = _highlightsFor(
      items: items,
      totalCost: totalCost,
      pantryMatches: pantryMatches,
      estimatedMealsCovered: estimatedMealsCovered,
      primarySource: primarySource,
      sourceTravelMinutes: primarySourceSnapshot?.typicalTravelMinutes,
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
        estimatedMealsCovered: estimatedMealsCovered,
        pantrySupportItems: pantryMatches,
        primarySource: primarySource,
        sourceTravelMinutes: primarySourceSnapshot?.typicalTravelMinutes,
      ),
    );
  }

  Set<AvailabilityContext> _sharedSources(List<ScoredFood> items) {
    final active = user.feasibility.availability;
    final plausible = active.where((source) {
      return items.every(
        (item) =>
            item.food.availability.contains(source) &&
            _contentModel.plausibleFitForFood(item.food, source),
      );
    }).toSet();
    if (plausible.isNotEmpty) {
      return plausible;
    }

    var shared = items.first.food.availability.intersection(active);
    for (final item in items.skip(1)) {
      shared = shared.intersection(item.food.availability.intersection(active));
    }
    return shared;
  }

  AvailabilityContext? _preferredSharedSource(
    Set<AvailabilityContext> sources, {
    required bool emergencyFriendly,
    required List<String> pantryMatches,
    required List<ScoredFood> items,
  }) {
    final mission = emergencyFriendly
        ? SourceTripMission.emergency
        : pantryMatches.isNotEmpty
        ? SourceTripMission.pantryStretch
        : user.pantry.restockItems.isNotEmpty ||
              user.pantry.lowStockItems.isNotEmpty
        ? SourceTripMission.restock
        : SourceTripMission.oneStopMeal;
    return _sourceNetworkAdvisor.bestSourceForMission(
      candidates: sources,
      mission: mission,
      user: user,
      resolution: _sourceNetworkAdvisor.catalog?.resolve(
        user.access.postalCode,
      ),
      foods: items,
    );
  }

  String _summaryFor({
    required List<ScoredFood> items,
    required double totalCost,
    required bool emergencyFriendly,
    required List<String> pantryMatches,
    required int estimatedMealsCovered,
    required AvailabilityContext? primarySource,
    required int? sourceTravelMinutes,
  }) {
    final copy = _copy;
    if (user.access.emergencyMode && emergencyFriendly) {
      return copy.choose(
        'Fast, cheaper basket built for a hard day.',
        'Canasta rapida y barata para un dia dificil.',
      );
    }
    if (estimatedMealsCovered > 1 && pantryMatches.isNotEmpty) {
      return copy.choose(
        'Stretches into about $estimatedMealsCovered meals by building on food you already have.',
        'Rinde para unas $estimatedMealsCovered comidas al apoyarse en comida que ya tienes.',
      );
    }
    if (estimatedMealsCovered > 1) {
      return copy.choose(
        'Covers about $estimatedMealsCovered meals from one realistic trip.',
        'Cubre unas $estimatedMealsCovered comidas con un solo viaje realista.',
      );
    }
    if (pantryMatches.isNotEmpty) {
      return copy.choose(
        'Builds on food you already have to keep the total down.',
        'Se apoya en comida que ya tienes para mantener bajo el total.',
      );
    }
    if (primarySource != null && sourceTravelMinutes != null) {
      return copy.choose(
        'One-stop basket that stays realistic through ${copy.lowerSourceLabel(primarySource)} in about $sourceTravelMinutes minutes.',
        'Canasta de una parada que sigue siendo realista por ${copy.lowerSourceLabel(primarySource)} en unos $sourceTravelMinutes minutos.',
      );
    }
    if (primarySource != null) {
      return copy.choose(
        'One-stop basket that stays realistic through ${copy.lowerSourceLabel(primarySource)}.',
        'Canasta de una parada que sigue siendo realista por ${copy.lowerSourceLabel(primarySource)}.',
      );
    }
    if (items.length == 1) {
      return copy.choose(
        'Single-item fallback that still fits your current setup.',
        'Respaldo de un solo articulo que todavia encaja con tu situacion.',
      );
    }
    return copy.choose(
      'Two-item basket that balances cost, access, and nutrition.',
      'Canasta de dos articulos que equilibra costo, acceso y nutricion.',
    );
  }

  List<String> _highlightsFor({
    required List<ScoredFood> items,
    required double totalCost,
    required List<String> pantryMatches,
    required int estimatedMealsCovered,
    required AvailabilityContext? primarySource,
    required int? sourceTravelMinutes,
    required int totalPrepMinutes,
    required bool emergencyFriendly,
  }) {
    final copy = _copy;
    final highlights = <String>['\$${totalCost.toStringAsFixed(2)} total'];
    if (estimatedMealsCovered > 1) {
      highlights.add(
        copy.choose(
          '$estimatedMealsCovered meals',
          '$estimatedMealsCovered comidas',
        ),
      );
    }
    if (primarySource != null) {
      highlights.add(copy.sourceLabel(primarySource));
      if (sourceTravelMinutes != null) {
        highlights.add('$sourceTravelMinutes min');
      }
    }
    if (pantryMatches.isNotEmpty) {
      highlights.add(
        copy.choose(
          'Uses ${pantryMatches.take(2).join(' + ')}',
          'Usa ${pantryMatches.take(2).join(' + ')}',
        ),
      );
    }
    if (emergencyFriendly) {
      highlights.add(copy.choose('Emergency fit', 'Ajuste de emergencia'));
    } else if (totalPrepMinutes > 0) {
      highlights.add(
        copy.choose(
          '$totalPrepMinutes min total prep',
          '$totalPrepMinutes min de preparacion total',
        ),
      );
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

  int _estimateMealsCovered({
    required List<ScoredFood> items,
    required Nutrients totalNutrients,
    List<String> pantryMatches = const [],
  }) {
    final targetCalories = user.targets.calories <= 0
        ? 700
        : user.targets.calories;
    var meals = 1;

    final secondMealCalories = math.max(targetCalories * 1.45, 850);
    if (totalNutrients.caloriesKcal >= secondMealCalories &&
        (items.length >= 2 ||
            totalNutrients.proteinG >=
                math.max(18, user.targets.proteinG * 0.75) ||
            pantryMatches.isNotEmpty)) {
      meals = 2;
    }

    final thirdMealCalories = math.max(targetCalories * 2.15, 1325);
    if (items.length >= 3 &&
        totalNutrients.caloriesKcal >= thirdMealCalories &&
        totalNutrients.fiberG >= math.max(10, user.targets.fiberG * 1.5)) {
      meals = 3;
    }

    return meals;
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
      estimatedMealsCovered: plan.estimatedMealsCovered,
      pantrySupportItems: plan.pantrySupportItems,
      primarySource: plan.primarySource,
      sourceTravelMinutes: plan.sourceTravelMinutes,
    );
  }

  static String _keyFor(List<int> ids) => ids.join('-');
}

extension on TravelBurden {
  bool get isHigh => this == TravelBurden.high;
}
