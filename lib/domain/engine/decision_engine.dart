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
import 'scoring/variety_dampener.dart';
import 'today_plan_builder.dart';

class DecisionEngine {
  DecisionEngine({
    required this.repo,
    required this.scoreConfigProvider,
    FoodAccessAdvisor? accessAdvisor,
    this.safetyFilter = const SafetyFilter(),
    this.feasibilityFilter = const FeasibilityFilter(),
    this.preferenceFilter = const PreferenceFilter(),
    this.macroAlignmentPrioritizer = const MacroAlignmentPrioritizer(),
  }) : accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor();

  final FoodRepository repo;
  final ScoreConfigProvider scoreConfigProvider;
  final FoodAccessAdvisor accessAdvisor;
  final SafetyFilter safetyFilter;
  final FeasibilityFilter feasibilityFilter;
  final PreferenceFilter preferenceFilter;
  final MacroAlignmentPrioritizer macroAlignmentPrioritizer;

  Future<RecommendationResult> recommend({
    required UserConstraints user,
    required CompositeWeights weights,
    int limit = 10,
  }) async {
    final stopwatch = Stopwatch()..start();

    final fetched = await repo.findCandidates(
      excludeAllergens: user.safety.allergens,
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
      user.targets,
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
    );
    final baskets = basketPlanner.build(explained);
    final todayPlan = TodayPlanBuilder(
      user: user,
      accessAdvisor: accessAdvisor,
    ).build(recommendations: explained, baskets: baskets);
    await repo.touchFoods(explained.map((item) => item.food.id));

    stopwatch.stop();
    return RecommendationResult(
      recommendations: _attachComparables(explained),
      preferenceRelaxed: preferenceRelaxed,
      candidatePoolSize: preferred.length,
      elapsedMs: stopwatch.elapsedMilliseconds,
      baskets: baskets,
      todayPlan: todayPlan,
    );
  }

  ScoredFood _applyAccessRealism(ScoredFood scored, UserConstraints user) {
    final insight = accessAdvisor.inspect(food: scored.food, user: user);
    final adjustment = accessAdvisor.accessAdjustment(
      insight: insight,
      user: user,
    );
    return scored.copyWith(
      composite: scored.composite + adjustment,
      breakdown: ScoreBreakdown(
        macro: scored.breakdown.macro,
        micro: scored.breakdown.micro,
        penalty: scored.breakdown.penalty,
        cost: scored.breakdown.cost,
        preference: scored.breakdown.preference,
        access: adjustment,
      ),
    );
  }

  Future<InsufficientCandidatesAnalysis> _diagnoseEmptiness(
    UserConstraints user,
  ) async {
    final relaxedBudget = await repo.countCandidates(
      excludeAllergens: user.safety.allergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal * 1.5,
      environment: user.feasibility.environment,
      availability: user.feasibility.availability,
    );

    final relaxedEnvironment = await repo.countCandidates(
      excludeAllergens: user.safety.allergens,
      religion: user.safety.religion,
      medicalAvoid: user.safety.medicalAvoid,
      maxCost: user.feasibility.maxCostPerMeal,
      environment: PrepEnvironment.fullKitchen,
      availability: user.feasibility.availability,
    );

    final relaxedAvailability = await repo.countCandidates(
      excludeAllergens: user.safety.allergens,
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
    if (ranked.isEmpty) {
      return ranked;
    }
    if (ranked.length == 1) {
      return [ranked.first.copyWith(displayScore: 75)];
    }

    final high = ranked.first.composite;
    final low = ranked.last.composite;
    final range = high - low;
    if (range.abs() < 1e-9) {
      return ranked.map((item) => item.copyWith(displayScore: 75)).toList();
    }

    return ranked
        .map(
          (item) => item.copyWith(
            displayScore: 100 * ((item.composite - low) / range),
          ),
        )
        .toList();
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
}
