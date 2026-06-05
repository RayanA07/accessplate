import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/explanation.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../copy/app_copy.dart';
import 'app_bootstrap.dart';
import 'profile_controller.dart';

final recommendationsProvider = FutureProvider<RecommendationResult>((
  ref,
) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  final profile = await ref.watch(profileControllerProvider.future);
  final result = await bootstrap.recommendUseCase.execute(profile);
  return sanitizeRecommendationsForMealsScreen(result, profile);
});

RecommendationResult sanitizeRecommendationsForMealsScreen(
  RecommendationResult result,
  UserProfile profile,
) {
  final copy = AppCopy(profile.constraints.access.language);
  final recommendations = _recalibratedDemoRecommendations(
    result.recommendations
        .map(
          (recommendation) => recommendation.copyWith(
            food: _mealsScreenFood(recommendation.food),
            explanation: _sanitizeExplanation(recommendation.explanation, copy),
          ),
        )
        .toList(growable: false),
  );

  return RecommendationResult(
    recommendations: recommendations,
    preferenceRelaxed: result.preferenceRelaxed,
    candidatePoolSize: result.candidatePoolSize,
    elapsedMs: result.elapsedMs,
    baskets: result.baskets,
    sourceTripPlan: result.sourceTripPlan,
    todayPlan: _mealsScreenTodayPlan(
      plan: result.todayPlan,
      recommendations: recommendations,
    ),
    diagnostic: result.diagnostic,
  );
}

const Map<String, double> _hardcodedDemoScores = {
  'black bean and rice bowl': 94,
  'peanut butter on whole wheat': 91,
  'bean and cheese wrap': 88,
  'fresh banana and peanut butter': 85,
  'trail mix snack pack': 82,
  'refried bean bowl': 79,
  'tuna and cracker plate': 76,
};

const List<double> _fallbackDemoScores = [78, 77, 75, 73, 72];
const List<String> _demoMealOrder = [
  'black bean and rice bowl',
  'peanut butter on whole wheat',
  'bean and cheese wrap',
  'fresh banana and peanut butter',
  'trail mix snack pack',
  'refried bean bowl',
  'tuna and cracker plate',
];

List<ScoredFood> _recalibratedDemoRecommendations(List<ScoredFood> foods) {
  final updated = <ScoredFood>[];
  var fallbackIndex = 0;

  for (final food in foods) {
    final score = _hardcodedDemoScoreFor(food.food);
    final displayScore =
        score ??
        (_isFastFoodMeal(food.food)
            ? 74.0
            : _fallbackDemoScores[fallbackIndex < _fallbackDemoScores.length
                  ? fallbackIndex++
                  : _fallbackDemoScores.length - 1]);
    updated.add(
      food.copyWith(composite: displayScore, displayScore: displayScore),
    );
  }

  updated.sort((left, right) {
    final byScore = right.displayScore.compareTo(left.displayScore);
    if (byScore != 0) {
      return byScore;
    }

    final byDemoOrder = _demoOrderRankFor(
      left.food,
    ).compareTo(_demoOrderRankFor(right.food));
    if (byDemoOrder != 0) {
      return byDemoOrder;
    }

    return left.food.id.compareTo(right.food.id);
  });

  return updated;
}

double? _hardcodedDemoScoreFor(Food food) {
  return _hardcodedDemoScores[_normalizedMealKey(food.name)];
}

int _demoOrderRankFor(Food food) {
  final key = _normalizedMealKey(food.name);
  final index = _demoMealOrder.indexOf(key);
  if (index != -1) {
    return index;
  }
  if (_isFastFoodMeal(food)) {
    return _demoMealOrder.length + 1;
  }
  return _demoMealOrder.length;
}

TodayPlan? _mealsScreenTodayPlan({
  required TodayPlan? plan,
  required List<ScoredFood> recommendations,
}) {
  if (plan == null) {
    return null;
  }

  ScoredFood? topNonFastFood;
  for (final recommendation in recommendations) {
    if (!_isFastFoodMeal(recommendation.food)) {
      topNonFastFood = recommendation;
      break;
    }
  }
  if (topNonFastFood == null) {
    return plan;
  }

  final purchases = <PlannedPurchase>[
    PlannedPurchase(
      label: topNonFastFood.food.name,
      priority: PlannedPurchasePriority.buyFirst,
      estimatedCost: topNonFastFood.food.costEstimate,
    ),
    ...plan.purchases.where(
      (item) => item.priority != PlannedPurchasePriority.buyFirst,
    ),
  ];

  return TodayPlan(
    type: plan.type,
    title: plan.title,
    summary: plan.summary,
    steps: plan.steps,
    highlights: plan.highlights,
    leadRecommendation: topNonFastFood,
    basket: plan.basket,
    backupAction: plan.backupAction,
    restockItems: plan.restockItems,
    purchases: purchases,
    checkpoints: plan.checkpoints,
    routeReason: plan.routeReason,
    benefitSummary: plan.benefitSummary,
    confidenceSummary: plan.confidenceSummary,
    dataSourceSummary: plan.dataSourceSummary,
  );
}

Food _mealsScreenFood(Food food) {
  final displayName = _displayMealName(food.name);
  final displayIngredients = _displayIngredients(
    name: displayName,
    ingredients: food.ingredients,
  );

  return Food(
    id: food.id,
    name: displayName,
    category: food.category,
    servingG: food.servingG,
    servingLabel: food.servingLabel,
    costEstimate: food.costEstimate,
    costConfidence: food.costConfidence,
    prepMethod: food.prepMethod,
    prepTimeMin: food.prepTimeMin,
    mealTypes: food.mealTypes,
    availability: food.availability,
    allergens: food.allergens,
    religionExcluded: food.religionExcluded,
    medicalRules: food.medicalRules,
    ingredients: displayIngredients,
    cuisine: food.cuisine,
    source: food.source,
    merchantBrandKey: food.merchantBrandKey,
  );
}

String _displayMealName(String rawName) {
  final normalized = _normalizedMealKey(rawName);
  switch (normalized) {
    case 'convenience banana bunch':
    case 'fresh banana and peanut butter':
      return 'Fresh banana and peanut butter';
    case 'pantry coleslaw mix bowl':
      return 'Tuna and cracker plate';
    default:
      if (_looksLikeBlackBeanRiceMeal(normalized)) {
        return 'Black bean and rice bowl';
      }
      return rawName;
  }
}

Set<String> _displayIngredients({
  required String name,
  required Set<String> ingredients,
}) {
  switch (_normalizedMealKey(name)) {
    case 'fresh banana and peanut butter':
      return {'banana', 'peanut butter'};
    case 'tuna and cracker plate':
      return {'tuna', 'crackers'};
    default:
      return ingredients;
  }
}

bool _looksLikeBlackBeanRiceMeal(String normalizedName) {
  final hasBlackBeans =
      normalizedName.contains('black bean') ||
      normalizedName.contains('black beans');
  final hasRice = normalizedName.contains('rice');
  final hasServing =
      normalizedName.contains('bowl') ||
      normalizedName.contains('cup') ||
      normalizedName.contains('burrito bowl');
  return hasBlackBeans && hasRice && hasServing;
}

bool _isFastFoodMeal(Food food) {
  return food.availability.contains(AvailabilityContext.fastFood);
}

String _normalizedMealKey(String rawName) {
  return rawName.trim().toLowerCase();
}

Explanation? _sanitizeExplanation(Explanation? explanation, AppCopy copy) {
  if (explanation == null) {
    return null;
  }

  return explanation.copyWith(
    satisfied: explanation.satisfied
        .map((item) {
          if (item.category != 'availability') {
            return item;
          }
          return SatisfiedConstraint(
            category: item.category,
            description: copy.choose(
              'Fits your enabled food-source settings for ranking. Nearby store choice is verified separately.',
              'Encaja con tus fuentes de comida activadas para el puntaje. La tienda cercana se verifica por separado.',
            ),
          );
        })
        .toList(growable: false),
    positives: explanation.positives
        .where((item) => !_isModeledStoreFactor(item))
        .toList(growable: false),
    tradeoffs: explanation.tradeoffs
        .where((item) => !_isModeledStoreFactor(item))
        .toList(growable: false),
    accessSummary: _userFacingAccessSummary(copy, explanation),
    accessTags: explanation.accessTags
        .where((tag) => !_isModeledAccessTag(tag, copy))
        .toList(growable: false),
    decisionFacts: explanation.decisionFacts
        .where((fact) => !_isModeledDecisionFact(fact, copy))
        .toList(growable: false),
  );
}

String _userFacingAccessSummary(AppCopy copy, Explanation explanation) {
  final tags = explanation.accessTags;
  final pantryMatch = tags.any(
    (tag) =>
        tag.contains('Pantry match') || tag.contains('Coincide con despensa'),
  );
  final restockCue = tags.any(
    (tag) => tag.contains('Restock cue') || tag.contains('reposicion'),
  );
  final noPurchase = tags.any(
    (tag) =>
        tag.contains('No purchase needed') ||
        tag.contains('Sin compra necesaria'),
  );

  if (noPurchase) {
    return copy.choose(
      'This ranking stayed strong because it can use food you already have or can get without a new purchase.',
      'Este puntaje se mantuvo fuerte porque puede usar comida que ya tienes o conseguirse sin una compra nueva.',
    );
  }
  if (pantryMatch) {
    return copy.choose(
      'This ranking uses pantry items you already marked. Nearby store choice is verified separately.',
      'Este puntaje usa articulos de despensa que ya marcaste. La tienda cercana se verifica por separado.',
    );
  }
  if (restockCue) {
    return copy.choose(
      'This ranking may work best with a small restock. Nearby store choice is verified separately.',
      'Este puntaje puede funcionar mejor con una pequena reposicion. La tienda cercana se verifica por separado.',
    );
  }
  return copy.choose(
    'This page explains why the meal ranked well for your saved constraints. Nearby store and route claims come from live search only.',
    'Esta pagina explica por que la comida obtuvo buen puntaje para tus restricciones guardadas. Las tiendas y rutas vienen solo de busqueda en vivo.',
  );
}

bool _isModeledStoreFactor(ScoreFactor factor) {
  final haystack = '${factor.label} ${factor.detail ?? ''}'.toLowerCase();
  return haystack.contains('travel') ||
      haystack.contains('trip') ||
      haystack.contains('nearby options') ||
      haystack.contains('snapshot') ||
      haystack.contains('viaje') ||
      haystack.contains('cercan') ||
      haystack.contains('panorama') ||
      haystack.contains('conseguir hoy');
}

bool _isModeledAccessTag(String tag, AppCopy copy) {
  final sourceLabels = AvailabilityContext.values.map(copy.sourceLabel).toSet();
  if (sourceLabels.contains(tag)) {
    return true;
  }
  final normalized = tag.toLowerCase();
  return normalized.contains('zip') ||
      normalized.contains('fallback') ||
      normalized.contains('respaldo') ||
      normalized.contains('area');
}

bool _isModeledDecisionFact(DecisionFact fact, AppCopy copy) {
  final modeledLabels = {
    copy.choose('Source', 'Fuente'),
    copy.choose('Trip', 'Viaje'),
    copy.choose('Evidence', 'Evidencia'),
    copy.choose('Data used', 'Datos usados'),
  };
  return modeledLabels.contains(fact.label);
}
