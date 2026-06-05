import 'dart:math' as math;

import '../entities/food.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../repositories/food_repository.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/dietary_style.dart';
import '../value_objects/meal_type.dart';
import '../value_objects/prep_environment.dart';
import 'access_advisor.dart';
import 'explainer.dart';
import 'filters/feasibility_filter.dart';
import 'filters/macro_alignment_prioritizer.dart';
import 'meal_basket_planner.dart';
import 'filters/preference_filter.dart';
import 'filters/safety_filter.dart';
import 'preference_scorer.dart';
import 'score_config_provider.dart';
import 'scoring/composite_scorer.dart';
import 'scoring/macro_scorer.dart';
import 'scoring/micro_scorer.dart';
import 'scoring/penalty_calculator.dart';
import 'source_network_advisor.dart';
import 'scoring/variety_dampener.dart';
import 'today_plan_builder.dart';

class DecisionEngine {
  DecisionEngine({
    required this.repo,
    required this.scoreConfigProvider,
    FoodAccessAdvisor? accessAdvisor,
    SourceNetworkAdvisor? sourceNetworkAdvisor,
    this.safetyFilter = const SafetyFilter(),
    this.feasibilityFilter = const FeasibilityFilter(),
    this.preferenceFilter = const PreferenceFilter(),
    this.macroAlignmentPrioritizer = const MacroAlignmentPrioritizer(),
  }) : accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor(),
       sourceNetworkAdvisor =
           sourceNetworkAdvisor ??
           SourceNetworkAdvisor(
             catalog: accessAdvisor?.catalog,
             accessAdvisor: accessAdvisor ?? const FoodAccessAdvisor(),
           );

  final FoodRepository repo;
  final ScoreConfigProvider scoreConfigProvider;
  final FoodAccessAdvisor accessAdvisor;
  final SourceNetworkAdvisor sourceNetworkAdvisor;
  final SafetyFilter safetyFilter;
  final FeasibilityFilter feasibilityFilter;
  final PreferenceFilter preferenceFilter;
  final MacroAlignmentPrioritizer macroAlignmentPrioritizer;

  static const double _nutritionWeight = 0.40;
  static const double _budgetWeight = 0.20;
  static const double _accessWeight = 0.20;
  static const double _safetyWeight = 0.10;
  static const double _pantryWeight = 0.10;

  Future<RecommendationResult> recommend({
    required UserConstraints user,
    required CompositeWeights weights,
    int limit = 10,
  }) async {
    final stopwatch = Stopwatch()..start();
    final effectiveAllergens = user.safety.effectiveAllergens;

    final fetched = await repo.findCandidates(
      excludeAllergens: effectiveAllergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal,
      environment: user.feasibility.environment,
      availability: user.feasibility.availability,
      limit: 1000,
    );

    final safe = safetyFilter.apply(fetched, user.safety);
    final feasible = feasibilityFilter.apply(safe, user.feasibility);
    if (feasible.isEmpty) {
      final diagnostic = await _diagnoseEmptiness(user);
      stopwatch.stop();
      return RecommendationResult(
        recommendations: const [],
        preferenceRelaxed: false,
        candidatePoolSize: 0,
        elapsedMs: stopwatch.elapsedMilliseconds,
        diagnostic: diagnostic,
      );
    }

    var preferenceRelaxed = false;
    var preferred = preferenceFilter.apply(feasible, user.preference);
    if (preferred.length < 5 && user.preference.mealType != MealType.any) {
      final relaxedPreference = preferenceFilter.apply(
        feasible,
        user.preference.copyWith(mealType: MealType.any, applyVariety: false),
      );
      if (relaxedPreference.length > preferred.length) {
        preferred = relaxedPreference;
        preferenceRelaxed = true;
      }
    }

    if (preferred.isEmpty) {
      stopwatch.stop();
      return RecommendationResult(
        recommendations: const [],
        preferenceRelaxed: preferenceRelaxed,
        candidatePoolSize: 0,
        elapsedMs: stopwatch.elapsedMilliseconds,
        diagnostic: InsufficientCandidatesAnalysis(
          currentCount: 0,
          minimumDesired: 5,
          mostRestrictive: BlockingConstraint.preference,
          suggestion: _preferenceSuggestion(user),
        ),
      );
    }

    final config = scoreConfigProvider.buildFor(user: user, weights: weights);

    final scorer = CompositeScorer(
      macroScorer: MacroScorer(
        targets: config.macroTargets,
        weights: config.macroWeights,
      ),
      microScorer: MicroScorer(
        rdaByNutrient: config.rda,
        priorities: config.microPriorities,
        currentIntake: user.todayIntake,
      ),
      penaltyCalculator: PenaltyCalculator(
        thresholds: config.penaltyThresholds,
        weights: config.penaltyWeights,
      ),
      preferenceScorer: PreferenceScorer(
        preference: user.preference,
        varietyDampener: VarietyDampener(recentlyActed: user.recentlyActed),
      ),
      weights: config.compositeWeights,
    );

    final ranked = macroAlignmentPrioritizer.apply(
      preferred
          .map(
            (record) => _applyAccessRealism(
              scorer.score(record: record, feasibility: user.feasibility),
              user,
            ),
          )
          .toList(),
      config.macroTargets,
    )..sort(_compareScoredFoods);

    final scaled = _applyDisplayScaling(ranked);
    final explainer = Explainer(
      config: config,
      user: user,
      accessAdvisor: accessAdvisor,
    );
    final explained = scaled
        .take(limit)
        .map((item) => item.copyWith(explanation: explainer.explain(item)))
        .toList();
    final basketPlanner = MealBasketPlanner(
      user: user,
      macroScorer: MacroScorer(
        targets: config.macroTargets,
        weights: config.macroWeights,
      ),
      penaltyCalculator: PenaltyCalculator(
        thresholds: config.penaltyThresholds,
        weights: config.penaltyWeights,
      ),
      accessAdvisor: accessAdvisor,
      sourceNetworkAdvisor: sourceNetworkAdvisor,
    );
    final baskets = basketPlanner.build(explained);
    final sourceTripPlan = sourceNetworkAdvisor.buildPlan(
      user: user,
      recommendations: explained,
      baskets: baskets,
    );
    final todayPlan =
        TodayPlanBuilder(
          user: user,
          accessAdvisor: accessAdvisor,
          sourceNetworkAdvisor: sourceNetworkAdvisor,
        ).build(
          recommendations: explained,
          baskets: baskets,
          sourceTripPlan: sourceTripPlan,
        );
    await repo.touchFoods(explained.map((item) => item.food.id));

    stopwatch.stop();
    return RecommendationResult(
      recommendations: _attachComparables(explained),
      preferenceRelaxed: preferenceRelaxed,
      candidatePoolSize: preferred.length,
      elapsedMs: stopwatch.elapsedMilliseconds,
      baskets: baskets,
      sourceTripPlan: sourceTripPlan,
      todayPlan: todayPlan,
    );
  }

  ScoredFood _applyAccessRealism(ScoredFood scored, UserConstraints user) {
    final insight = accessAdvisor.inspect(food: scored.food, user: user);
    final accessFit = _accessFit(insight: insight, user: user);
    final nutritionFit = _nutritionFit(scored.breakdown);
    final budgetFit = (1 - scored.breakdown.cost).clamp(0.0, 1.0).toDouble();
    final safetyFit = _dietarySafetyFit(food: scored.food, user: user);
    final pantryFit = _pantryOverlapFit(food: scored.food, user: user);
    final weightedFit =
        (_nutritionWeight * nutritionFit) +
        (_budgetWeight * budgetFit) +
        (_accessWeight * accessFit) +
        (_safetyWeight * safetyFit) +
        (_pantryWeight * pantryFit);
    final compositeScore = (weightedFit * 100).clamp(0.0, 100.0).toDouble();

    return scored.copyWith(
      composite: compositeScore,
      breakdown: ScoreBreakdown(
        macro: scored.breakdown.macro,
        micro: scored.breakdown.micro,
        penalty: scored.breakdown.penalty,
        cost: scored.breakdown.cost,
        preference: scored.breakdown.preference,
        access: accessFit,
      ),
    );
  }

  Future<InsufficientCandidatesAnalysis> _diagnoseEmptiness(
    UserConstraints user,
  ) async {
    final relaxedBudget = await repo.countCandidates(
      excludeAllergens: user.safety.effectiveAllergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal * 1.5,
      environment: user.feasibility.environment,
      availability: user.feasibility.availability,
    );

    final relaxedEnvironment = await repo.countCandidates(
      excludeAllergens: user.safety.effectiveAllergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal,
      environment: PrepEnvironment.fullKitchen,
      availability: user.feasibility.availability,
    );

    final relaxedAvailability = await repo.countCandidates(
      excludeAllergens: user.safety.effectiveAllergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal,
      environment: user.feasibility.environment,
      availability: AvailabilityContext.values.toSet(),
    );

    final gains = <BlockingConstraint, int>{
      BlockingConstraint.budget: relaxedBudget,
      BlockingConstraint.environment: relaxedEnvironment,
      BlockingConstraint.availability: relaxedAvailability,
    };

    final best = gains.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );

    if (best.value <= 0) {
      return const InsufficientCandidatesAnalysis(
        currentCount: 0,
        minimumDesired: 5,
        mostRestrictive: BlockingConstraint.safety,
        suggestion:
            'Your safety profile excludes every current food. Review allergens, religion, or avoid-only medical limits.',
      );
    }

    return InsufficientCandidatesAnalysis(
      currentCount: 0,
      minimumDesired: 5,
      mostRestrictive: best.key,
      suggestion: _suggestionFor(best.key, user, best.value),
    );
  }

  String _suggestionFor(
    BlockingConstraint constraint,
    UserConstraints user,
    int unlockedCount,
  ) {
    switch (constraint) {
      case BlockingConstraint.budget:
        final target = user.feasibility.maxCostPerMeal * 1.5;
        return 'Raising your budget to about \$${target.toStringAsFixed(0)} unlocks $unlockedCount options.';
      case BlockingConstraint.environment:
        return 'A broader prep setup unlocks $unlockedCount options. Switching to stovetop or full kitchen helps most.';
      case BlockingConstraint.availability:
        return 'Adding more shopping contexts unlocks $unlockedCount options.';
      case BlockingConstraint.preference:
        return 'Relaxing your current meal or dislike preferences opens more options.';
      case BlockingConstraint.safety:
        return 'Review your safety settings. They currently exclude the full dataset.';
    }
  }

  String _preferenceSuggestion(UserConstraints user) {
    if (user.preference.dietaryStyle != DietaryStyle.unrestricted) {
      return 'No foods matched your ${user.preference.dietaryStyle.label.toLowerCase()} filter with the rest of your current profile. Try widening budget, prep, or shopping contexts.';
    }

    if (user.preference.dislikedIngredients.isNotEmpty) {
      return 'Your current meal or ingredient preferences exclude every remaining option. Try removing one dislike or switching meal timing to Any time.';
    }

    return 'Your current meal timing filters out every remaining option. Switching to Any time usually unlocks more foods.';
  }

  int _compareScoredFoods(ScoredFood a, ScoredFood b) {
    final byComposite = b.composite.compareTo(a.composite);
    if (byComposite != 0) {
      return byComposite;
    }
    final byMacro = b.breakdown.macro.compareTo(a.breakdown.macro);
    if (byMacro != 0) {
      return byMacro;
    }
    final byCost = a.food.costEstimate.compareTo(b.food.costEstimate);
    if (byCost != 0) {
      return byCost;
    }
    final byPenalty = a.breakdown.penalty.compareTo(b.breakdown.penalty);
    if (byPenalty != 0) {
      return byPenalty;
    }
    return a.food.id.compareTo(b.food.id);
  }

  List<ScoredFood> _applyDisplayScaling(List<ScoredFood> ranked) {
    return ranked
        .map(
          (item) => item.copyWith(
            displayScore: item.composite.clamp(0.0, 100.0).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  List<ScoredFood> _attachComparables(List<ScoredFood> foods) {
    return foods.map((food) {
      final cheaper =
          foods
              .where((candidate) => candidate.food.id != food.food.id)
              .where(
                (candidate) =>
                    candidate.food.costEstimate <=
                    food.food.costEstimate * 0.85,
              )
              .toList()
            ..sort((a, b) {
              final byComposite = b.composite.compareTo(a.composite);
              if (byComposite != 0) {
                return byComposite;
              }
              return a.food.costEstimate.compareTo(b.food.costEstimate);
            });

      final healthier =
          foods
              .where((candidate) => candidate.food.id != food.food.id)
              .where(
                (candidate) =>
                    candidate.breakdown.penalty + 0.05 <
                        food.breakdown.penalty ||
                    candidate.nutrients.proteinG >=
                        food.nutrients.proteinG + 4 ||
                    candidate.nutrients.fiberG >= food.nutrients.fiberG + 3,
              )
              .where(
                (candidate) =>
                    candidate.food.costEstimate <=
                    food.food.costEstimate * 1.35,
              )
              .toList()
            ..sort((a, b) {
              final byPenalty = a.breakdown.penalty.compareTo(
                b.breakdown.penalty,
              );
              if (byPenalty != 0) {
                return byPenalty;
              }
              final byComposite = b.composite.compareTo(a.composite);
              if (byComposite != 0) {
                return byComposite;
              }
              return a.food.costEstimate.compareTo(b.food.costEstimate);
            });

      final similar =
          foods
              .where((candidate) => candidate.food.id != food.food.id)
              .where(
                (candidate) =>
                    (candidate.displayScore - food.displayScore).abs() < 10,
              )
              .where((candidate) => _maxRelativeDelta(food, candidate) >= 0.2)
              .toList()
            ..sort(_compareScoredFoods);

      final comparableIds = <int>{
        if (cheaper.isNotEmpty) cheaper.first.food.id,
        if (healthier.isNotEmpty) healthier.first.food.id,
        ...similar.map((candidate) => candidate.food.id),
      }.take(3).toList();

      return food.copyWith(
        explanation: food.explanation?.copyWith(compareWithIds: comparableIds),
      );
    }).toList();
  }

  double _maxRelativeDelta(ScoredFood a, ScoredFood b) {
    final deltas = <double>[
      _relativeDelta(a.nutrients.proteinG, b.nutrients.proteinG),
      _relativeDelta(a.food.costEstimate, b.food.costEstimate),
      _relativeDelta(a.nutrients.sodiumMg, b.nutrients.sodiumMg),
      _relativeDelta(a.nutrients.fiberG, b.nutrients.fiberG),
    ];
    deltas.sort();
    return deltas.last;
  }

  double _relativeDelta(double a, double b) {
    final baseline = a.abs() < 1e-6 ? 1 : a.abs();
    return ((a - b).abs() / baseline).clamp(0, 1).toDouble();
  }

  double _nutritionFit(ScoreBreakdown breakdown) {
    final macroFit = breakdown.macro.clamp(0.0, 1.0).toDouble();
    final microFit = breakdown.micro.clamp(0.0, 1.0).toDouble();
    final penaltyRelief = (1 - breakdown.penalty).clamp(0.0, 1.0).toDouble();
    return ((macroFit * 0.50) + (microFit * 0.20) + (penaltyRelief * 0.30))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _accessFit({
    required FoodAccessInsight insight,
    required UserConstraints user,
  }) {
    if (insight.source == null) {
      return 0.0;
    }

    var fit = 0.55;
    switch (insight.travelBurden) {
      case TravelBurden.low:
        fit += 0.18;
      case TravelBurden.medium:
        fit += 0.04;
      case TravelBurden.high:
        fit -= 0.18;
    }

    final snapshot = insight.sourceSnapshot;
    if (snapshot != null) {
      fit += (snapshot.sameDayConfidence - 0.5) * 0.18;
      fit += math.min(0.08, snapshot.nearbyOptions * 0.015).toDouble();
    }

    if (insight.snapFriendly) {
      fit += 0.03;
    }

    if (insight.wicStapleCandidate) {
      fit += 0.02;
    }

    if (user.access.emergencyMode && insight.emergencyFriendly) {
      fit += 0.06;
    }

    if (user.access.transportation.lowMobility && insight.lowTravel) {
      fit += 0.03;
    }

    if (insight.localProfile?.lowAccessArea == true &&
        insight.source == AvailabilityContext.grocery &&
        insight.travelBurden != TravelBurden.low) {
      fit -= 0.10;
    }

    if (insight.lowerConfidenceAccessModel && snapshot != null) {
      fit -= 0.03;
    }

    return fit.clamp(0.0, 1.0).toDouble();
  }

  double _dietarySafetyFit({
    required Food food,
    required UserConstraints user,
  }) {
    final allergenConflict = food.allergens.any(
      user.safety.effectiveAllergens.contains,
    );
    if (allergenConflict) {
      return 0.0;
    }

    final religion = user.safety.religion;
    if (religion.code != 'none' &&
        food.religionExcluded.any((rule) => rule.religion == religion)) {
      return 0.0;
    }

    final avoidConflict = food.medicalRules.any(
      (rule) =>
          rule.severity == MedicalRuleSeverity.avoid &&
          user.safety.medicalAvoid.contains(rule.restriction),
    );
    if (avoidConflict) {
      return 0.0;
    }

    final limitConflict = food.medicalRules.any(
      (rule) =>
          rule.severity == MedicalRuleSeverity.limit &&
          user.safety.medicalLimit.contains(rule.restriction),
    );
    return limitConflict ? 0.65 : 1.0;
  }

  double _pantryOverlapFit({
    required Food food,
    required UserConstraints user,
  }) {
    final ingredients = food.ingredients;
    if (ingredients.isEmpty) {
      return 0.0;
    }
    final matched = ingredients.where((item) {
      final stock = user.pantry.stockFor(item);
      return stock == PantryStockLevel.enough || stock == PantryStockLevel.low;
    }).length;
    return (matched / ingredients.length).clamp(0.0, 1.0).toDouble();
  }
}
