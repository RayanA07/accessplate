import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../repositories/food_repository.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/meal_type.dart';
import '../value_objects/prep_environment.dart';
import 'explainer.dart';
import 'filters/feasibility_filter.dart';
import 'filters/preference_filter.dart';
import 'filters/safety_filter.dart';
import 'preference_scorer.dart';
import 'score_config_provider.dart';
import 'scoring/composite_scorer.dart';
import 'scoring/macro_scorer.dart';
import 'scoring/micro_scorer.dart';
import 'scoring/penalty_calculator.dart';
import 'scoring/variety_dampener.dart';

class DecisionEngine {
  DecisionEngine({
    required this.repo,
    required this.scoreConfigProvider,
    this.safetyFilter = const SafetyFilter(),
    this.feasibilityFilter = const FeasibilityFilter(),
    this.preferenceFilter = const PreferenceFilter(),
  });

  final FoodRepository repo;
  final ScoreConfigProvider scoreConfigProvider;
  final SafetyFilter safetyFilter;
  final FeasibilityFilter feasibilityFilter;
  final PreferenceFilter preferenceFilter;

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
    if (preferred.length < 5) {
      preferenceRelaxed = true;
      if (user.preference.mealType != MealType.any) {
        preferred = preferenceFilter.apply(
          feasible,
          user.preference.copyWith(
            mealType: MealType.any,
            applyVariety: false,
          ),
        );
      }
      if (preferred.length < 5) {
        preferred = feasible;
      }
    }

    final config = scoreConfigProvider.buildFor(
      user: user,
      weights: weights,
    );

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
        varietyDampener: VarietyDampener(
          recentlyActed: user.recentlyActed,
        ),
      ),
      weights: config.compositeWeights,
    );

    final ranked = preferred
        .map(
          (record) => scorer.score(
            record: record,
            budgetUsd: user.feasibility.maxCostPerMeal,
          ),
        )
        .toList()
      ..sort(_compareScoredFoods);

    final scaled = _applyDisplayScaling(ranked);
    final explainer = Explainer(config: config, user: user);
    final explained = scaled
        .take(limit)
        .map((item) => item.copyWith(explanation: explainer.explain(item)))
        .toList();

    stopwatch.stop();
    return RecommendationResult(
      recommendations: _attachComparables(explained),
      preferenceRelaxed: preferenceRelaxed,
      candidatePoolSize: preferred.length,
      elapsedMs: stopwatch.elapsedMilliseconds,
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
      final comparableIds = foods
          .where((candidate) => candidate.food.id != food.food.id)
          .where(
            (candidate) =>
                (candidate.displayScore - food.displayScore).abs() < 10,
          )
          .where((candidate) => _maxRelativeDelta(food, candidate) >= 0.2)
          .take(3)
          .map((candidate) => candidate.food.id)
          .toList();

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
