import '../entities/explanation.dart';
import '../entities/food.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/religion.dart';
import 'score_config_provider.dart';

class Explainer {
  const Explainer({required this.config, required this.user});

  final ScoreConfig config;
  final UserConstraints user;

  Explanation explain(ScoredFood scored) {
    return Explanation(
      satisfied: _satisfiedConstraints(scored.food),
      positives: _topPositives(scored),
      tradeoffs: _topTradeoffs(scored),
      compareWithIds: const [],
    );
  }

  List<SatisfiedConstraint> _satisfiedConstraints(Food food) {
    final satisfied = <SatisfiedConstraint>[];

    if (user.safety.allergens.isNotEmpty) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'allergen',
          description:
              'Avoids ${user.safety.allergens.map((item) => item.label).join(', ')}',
        ),
      );
    }

    if (user.safety.religion != Religion.none) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'religion',
          description: 'Compatible with ${user.safety.religion.label}',
        ),
      );
    }

    satisfied.add(
      SatisfiedConstraint(
        category: 'budget',
        description:
            '\$${food.costEstimate.toStringAsFixed(2)} now, under your \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)} limit',
      ),
    );

    satisfied.add(
      SatisfiedConstraint(
        category: 'environment',
        description: food.readyToEat
            ? 'Works with no prep'
            : 'Works for ${user.feasibility.environment.label} in ${food.prepTimeMin} min',
      ),
    );

    final availability = _matchedAvailability(food);
    if (availability != null) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'availability',
          description: 'Available at ${availability.label.toLowerCase()}',
        ),
      );
    }

    return satisfied;
  }

  List<ScoreFactor> _topPositives(ScoredFood scored) {
    final positives = <ScoreFactor>[];
    final nutrients = scored.nutrients;
    final targets = config.macroTargets;

    if (nutrients.proteinG >= _proteinFloor(targets)) {
      positives.add(
        ScoreFactor(
          label:
              scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.6
              ? 'Budget-friendly protein'
              : 'Strong protein fit',
          weight: scored.breakdown.macro,
          detail:
              '${nutrients.proteinG.toStringAsFixed(0)}g protein for \$${scored.food.costEstimate.toStringAsFixed(2)}',
        ),
      );
    }

    if ((config.microPriorities['iron_mg'] ?? 1) > 1.2 &&
        nutrients.ironMg >= 3) {
      positives.add(
        ScoreFactor(
          label: 'Helpful iron source',
          weight: scored.breakdown.micro,
          detail: '${nutrients.ironMg.toStringAsFixed(1)} mg iron',
        ),
      );
    }

    if (nutrients.fiberG >= _fiberFloor(targets)) {
      positives.add(
        ScoreFactor(
          label:
              scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.6
              ? 'Low-cost fiber win'
              : 'High fiber',
          weight: scored.breakdown.macro,
          detail: '${nutrients.fiberG.toStringAsFixed(0)}g fiber',
        ),
      );
    }

    if (scored.food.readyToEat) {
      positives.add(
        const ScoreFactor(
          label: 'Works with no prep',
          weight: 0.72,
          detail: 'Ready to eat as-is',
        ),
      );
    }

    final matchedAvailability = _matchedAvailability(scored.food);
    if (matchedAvailability != null &&
        matchedAvailability != AvailabilityContext.grocery) {
      positives.add(
        ScoreFactor(
          label: 'Easy to find today',
          weight: 0.68,
          detail: 'Available at ${matchedAvailability.label.toLowerCase()}',
        ),
      );
    }

    if (scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.5) {
      positives.add(
        ScoreFactor(
          label: 'Well under budget',
          weight: 1 - _budgetShare(scored.food),
          detail: '\$${scored.food.costEstimate.toStringAsFixed(2)} estimated',
        ),
      );
    }

    positives.sort((a, b) => b.weight.compareTo(a.weight));
    return positives.take(3).toList();
  }

  List<ScoreFactor> _topTradeoffs(ScoredFood scored) {
    final tradeoffs = <ScoreFactor>[];
    final nutrients = scored.nutrients;

    final sodiumThreshold = config.penaltyThresholds['sodium_mg'] ?? 0;
    if (sodiumThreshold > 0 && nutrients.sodiumMg > sodiumThreshold) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Higher sodium than ideal',
          weight: scored.breakdown.penalty,
          detail: '${nutrients.sodiumMg.toStringAsFixed(0)} mg sodium',
        ),
      );
    }

    final sugarThreshold = config.penaltyThresholds['added_sugar_g'] ?? 0;
    if (sugarThreshold > 0 && nutrients.addedSugarG > sugarThreshold) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Higher added sugar than ideal',
          weight: scored.breakdown.penalty,
          detail: '${nutrients.addedSugarG.toStringAsFixed(0)}g added sugar',
        ),
      );
    }

    if (_budgetShare(scored.food) > 0.8) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Near the top of your budget',
          weight: _budgetShare(scored.food),
          detail:
              '\$${scored.food.costEstimate.toStringAsFixed(2)} of \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)}',
        ),
      );
    }

    if (nutrients.proteinG < _proteinFloor(config.macroTargets)) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Lower protein than the best-value options',
          weight: 0.62,
          detail: '${nutrients.proteinG.toStringAsFixed(0)}g protein',
        ),
      );
    }

    if (!scored.food.readyToEat && scored.food.prepTimeMin >= 8) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Takes more time than the fastest options',
          weight: 0.45,
          detail: '${scored.food.prepTimeMin} min prep',
        ),
      );
    }

    tradeoffs.sort((a, b) => b.weight.compareTo(a.weight));
    return tradeoffs.take(2).toList();
  }

  AvailabilityContext? _matchedAvailability(Food food) {
    const priority = [
      AvailabilityContext.foodPantry,
      AvailabilityContext.dollarStore,
      AvailabilityContext.convenience,
      AvailabilityContext.fastFood,
      AvailabilityContext.grocery,
    ];

    for (final context in priority) {
      if (food.availability.contains(context) &&
          user.feasibility.availability.contains(context)) {
        return context;
      }
    }
    return null;
  }

  double _budgetShare(Food food) {
    final budget = user.feasibility.maxCostPerMeal;
    if (budget <= 0) {
      return 1;
    }
    return (food.costEstimate / budget).clamp(0, 1).toDouble();
  }

  double _proteinFloor(NutritionalTargets targets) {
    if (targets.proteinG <= 0) {
      return 0;
    }
    final scaled = targets.proteinG * 0.55;
    return scaled < 20 ? scaled : 20;
  }

  double _fiberFloor(NutritionalTargets targets) {
    if (targets.fiberG <= 0) {
      return 0;
    }
    final scaled = targets.fiberG * 0.60;
    return scaled < 8 ? scaled : 8;
  }
}
