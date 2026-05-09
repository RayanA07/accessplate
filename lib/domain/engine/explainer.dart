import '../entities/explanation.dart';
import '../entities/food.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/religion.dart';
import 'score_config_provider.dart';

class Explainer {
  const Explainer({
    required this.config,
    required this.user,
  });

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
            'Under \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)} at \$${food.costEstimate.toStringAsFixed(2)}',
      ),
    );

    satisfied.add(
      SatisfiedConstraint(
        category: 'environment',
        description: 'Works for ${user.feasibility.environment.label}',
      ),
    );

    return satisfied;
  }

  List<ScoreFactor> _topPositives(ScoredFood scored) {
    final positives = <ScoreFactor>[];
    final nutrients = scored.nutrients;
    final targets = config.macroTargets;

    if (nutrients.proteinG >= targets.proteinG * 0.75) {
      positives.add(
        ScoreFactor(
          label: 'Strong protein fit',
          weight: scored.breakdown.macro,
          detail:
              '${nutrients.proteinG.toStringAsFixed(0)}g vs ${targets.proteinG.toStringAsFixed(0)}g target',
        ),
      );
    }

    if ((config.microPriorities['iron_mg'] ?? 1) > 1.2 && nutrients.ironMg >= 3) {
      positives.add(
        ScoreFactor(
          label: 'Helpful iron source',
          weight: scored.breakdown.micro,
          detail: '${nutrients.ironMg.toStringAsFixed(1)} mg iron',
        ),
      );
    }

    if (nutrients.fiberG >= 5) {
      positives.add(
        ScoreFactor(
          label: 'High fiber',
          weight: scored.breakdown.macro,
          detail: '${nutrients.fiberG.toStringAsFixed(0)}g fiber',
        ),
      );
    }

    if (scored.breakdown.cost <= 0.5) {
      positives.add(
        ScoreFactor(
          label: 'Well under budget',
          weight: 1 - scored.breakdown.cost,
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

    if (scored.breakdown.cost > 0.8) {
      tradeoffs.add(
        ScoreFactor(
          label: 'Near the top of your budget',
          weight: scored.breakdown.cost,
          detail:
              '\$${scored.food.costEstimate.toStringAsFixed(2)} of \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)}',
        ),
      );
    }

    tradeoffs.sort((a, b) => b.weight.compareTo(a.weight));
    return tradeoffs.take(2).toList();
  }
}
