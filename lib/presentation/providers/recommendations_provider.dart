import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/explanation.dart';
import '../../domain/entities/ingredient_availability_catalog.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../copy/app_copy.dart';
import 'app_bootstrap.dart';
import 'nearby_store_providers.dart';
import 'profile_controller.dart';

final recommendationsProvider = FutureProvider<RecommendationResult>((
  ref,
) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  final profile = await ref.watch(profileControllerProvider.future);
  final availabilityMode = ref.watch(storeAvailabilityModeProvider);
  final result = await bootstrap.recommendUseCase.execute(profile);
  final sanitized = _sanitizeUserFacingResult(result, profile);
  if (!availabilityMode.isOffline) {
    return sanitized;
  }
  return _filterForOfflineMode(
    sanitized,
    profile,
    bootstrap.ingredientAvailabilityCatalog,
  );
});

RecommendationResult _sanitizeUserFacingResult(
  RecommendationResult result,
  UserProfile profile,
) {
  final copy = AppCopy(profile.constraints.access.language);
  return RecommendationResult(
    recommendations: result.recommendations
        .map(
          (recommendation) => recommendation.copyWith(
            explanation: _sanitizeExplanation(recommendation.explanation, copy),
          ),
        )
        .toList(growable: false),
    preferenceRelaxed: result.preferenceRelaxed,
    candidatePoolSize: result.candidatePoolSize,
    elapsedMs: result.elapsedMs,
    baskets: result.baskets,
    sourceTripPlan: result.sourceTripPlan,
    todayPlan: result.todayPlan,
    diagnostic: result.diagnostic,
  );
}

RecommendationResult _filterForOfflineMode(
  RecommendationResult result,
  UserProfile profile,
  IngredientAvailabilityCatalog ingredientAvailabilityCatalog,
) {
  final filteredRecommendations = result.recommendations
      .where(
        (recommendation) =>
            ingredientAvailabilityCatalog.preferredContextForMeal(
              food: recommendation.food,
              enabledContexts: profile.constraints.feasibility.availability,
            ) !=
            null,
      )
      .toList(growable: false);

  return RecommendationResult(
    recommendations: filteredRecommendations,
    preferenceRelaxed: result.preferenceRelaxed,
    candidatePoolSize: filteredRecommendations.length,
    elapsedMs: result.elapsedMs,
    baskets: result.baskets,
    sourceTripPlan: result.sourceTripPlan,
    todayPlan: result.todayPlan,
    diagnostic: result.diagnostic,
  );
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
