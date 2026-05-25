import 'dart:math' as math;

import 'access_copy.dart';
import 'access_advisor.dart';
import 'source_content_model.dart';
import '../entities/local_access.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/benefit_program.dart';

class SourceNetworkAdvisor {
  const SourceNetworkAdvisor({
    this.catalog,
    this.contentModel = const SourceContentModel(),
    this.accessAdvisor = const FoodAccessAdvisor(),
  });

  final LocalAccessCatalog? catalog;
  final SourceContentModel contentModel;
  final FoodAccessAdvisor accessAdvisor;

  SourceTripPlan? buildPlan({
    required UserConstraints user,
    required List<ScoredFood> recommendations,
    required List<MealBasketPlan> baskets,
  }) {
    final candidates = user.feasibility.availability;
    if (candidates.isEmpty) {
      return null;
    }

    final resolution = (catalog ?? accessAdvisor.catalog)?.resolve(
      user.access.postalCode,
    );
    final copy = AccessCopy(user.access);
    final mission = _missionFor(
      user: user,
      recommendations: recommendations,
      baskets: baskets,
    );
    final primarySource = bestSourceForMission(
      candidates: candidates,
      mission: mission,
      user: user,
      resolution: resolution,
      foods: recommendations,
      baskets: baskets,
    );
    if (primarySource == null) {
      return null;
    }

    final backupSource = bestSourceForMission(
      candidates: candidates,
      mission: mission,
      user: user,
      resolution: resolution,
      exclude: {primarySource},
      foods: recommendations,
      baskets: baskets,
    );
    final primarySnapshot = resolution?.profile.sourceFor(primarySource);
    final grocerySnapshot = resolution?.profile.sourceFor(
      AvailabilityContext.grocery,
    );
    final contentFit = _contentFitForSource(
      source: primarySource,
      foods: recommendations,
      baskets: baskets,
      user: user,
    );

    return SourceTripPlan(
      mission: mission,
      primarySource: primarySource,
      backupSource: backupSource,
      title: copy.choose(
        'Best first stop: ${copy.sourceLabel(primarySource)}',
        'Mejor primera parada: ${copy.sourceLabel(primarySource)}',
      ),
      summary: _summaryFor(
        copy: copy,
        mission: mission,
        source: primarySource,
        resolution: resolution,
      ),
      reasons: _reasonsFor(
        copy: copy,
        source: primarySource,
        mission: mission,
        user: user,
        snapshot: primarySnapshot,
        grocerySnapshot: grocerySnapshot,
        contentFit: contentFit,
      ),
      highlights: _highlightsFor(
        copy: copy,
        source: primarySource,
        mission: mission,
        user: user,
        snapshot: primarySnapshot,
        contentFit: contentFit,
      ),
      bestFor: _bestForTags(
        copy: copy,
        source: primarySource,
        mission: mission,
        contentFit: contentFit,
      ),
      communityLabel: resolution?.profile.communityLabel,
      travelMinutes: primarySnapshot?.typicalTravelMinutes,
      snapshotNote: primarySnapshot?.note,
      routeReason: _routeReasonFor(
        copy: copy,
        source: primarySource,
        mission: mission,
        user: user,
        snapshot: primarySnapshot,
        grocerySnapshot: grocerySnapshot,
        contentFit: contentFit,
      ),
      benefitSummary: _benefitSummaryFor(
        copy: copy,
        source: primarySource,
        user: user,
        contentFit: contentFit,
      ),
      confidenceSummary: _confidenceSummary(copy, resolution),
      dataSourceSummary: _dataSourceSummary(copy: copy, user: user),
    );
  }

  AvailabilityContext? bestSourceForMission({
    required Set<AvailabilityContext> candidates,
    required SourceTripMission mission,
    required UserConstraints user,
    LocalAccessProfileResolution? resolution,
    Set<AvailabilityContext> exclude = const {},
    List<ScoredFood> foods = const [],
    List<MealBasketPlan> baskets = const [],
  }) {
    final ranked =
        candidates
            .where((source) => !exclude.contains(source))
            .map((source) {
              final contentFit = _contentFitForSource(
                source: source,
                foods: foods,
                baskets: baskets,
                user: user,
              );
              return _SourceScore(
                source: source,
                score: _scoreSource(
                  source: source,
                  mission: mission,
                  user: user,
                  resolution: resolution,
                  contentFit: contentFit,
                ),
              );
            })
            .toList(growable: false)
          ..sort((left, right) {
            final byScore = right.score.compareTo(left.score);
            if (byScore != 0) {
              return byScore;
            }
            return left.source.index.compareTo(right.source.index);
          });

    return ranked.isEmpty ? null : ranked.first.source;
  }

  SourceTripMission _missionFor({
    required UserConstraints user,
    required List<ScoredFood> recommendations,
    required List<MealBasketPlan> baskets,
  }) {
    if (user.access.emergencyMode) {
      return SourceTripMission.emergency;
    }

    final readyPantryMatches = recommendations.any(
      (item) => item.explanation?.accessTags.contains('Pantry match') ?? false,
    );
    if (user.pantry.enoughItems.isNotEmpty && readyPantryMatches) {
      return SourceTripMission.pantryStretch;
    }

    final restockLoad =
        user.pantry.restockItems.length + user.pantry.lowStockItems.length;
    final severeOutage = user.pantry.restockItems.length >= 2;
    final broadShortage = restockLoad >= 3;
    final pantryThin = user.pantry.enoughItems.length <= 1;
    if (restockLoad > 0 &&
        (severeOutage ||
            broadShortage ||
            (user.access.benefitPrograms.isEmpty &&
                user.pantry.enoughItems.length <= 2) ||
            (user.access.benefitPrograms.isNotEmpty &&
                broadShortage &&
                pantryThin))) {
      return SourceTripMission.restock;
    }

    if (user.access.benefitPrograms.isNotEmpty) {
      return SourceTripMission.benefitsRun;
    }

    if (baskets.isNotEmpty) {
      return SourceTripMission.oneStopMeal;
    }

    return SourceTripMission.fallback;
  }

  double _scoreSource({
    required AvailabilityContext source,
    required SourceTripMission mission,
    required UserConstraints user,
    required LocalAccessProfileResolution? resolution,
    required _SourceContentFit contentFit,
  }) {
    final snapshot = resolution?.profile.sourceFor(source);
    final modelWeight = resolution?.modeledConfidence ?? 0.45;
    final communityFit = resolution?.profile.sourceFitFor(
      source,
      user.access.transportation,
    );
    var score = _baseContextScore(source);
    score += _missionAffinity(source, mission, user);
    score += _benefitAffinity(source, user);
    score += math.min(10, contentFit.availableFoodCount * 1.5);
    score += math.min(9, contentFit.fullBasketCount * 4.5);
    score += _contentAffinity(
      mission: mission,
      contentFit: contentFit,
      user: user,
    );
    score += _benefitCoverageAffinity(user: user, contentFit: contentFit);
    if (contentFit.availableFoodCount == 0) {
      score -= 9;
    }
    if (communityFit != null) {
      score += ((communityFit - 0.5) * 18) * modelWeight;
    }

    if (snapshot != null) {
      final maxTravel = user.access.maxTravelMinutes <= 0
          ? 20
          : user.access.maxTravelMinutes;
      final travelRatio = snapshot.typicalTravelMinutes / maxTravel;
      score += snapshot.sameDayConfidence * 22 * modelWeight;
      score += math.min(14, snapshot.nearbyOptions * 3.0) * modelWeight;
      if (travelRatio <= 0.65) {
        score += 4 + (6 * modelWeight);
      } else if (travelRatio <= 1.0) {
        score += 2 + (2 * modelWeight);
      } else {
        score -=
            (user.access.transportation.lowMobility ? 10 : 5) +
            ((user.access.transportation.lowMobility ? 6 : 3) * modelWeight);
      }
    } else if (resolution != null) {
      score -= 4 + (4 * modelWeight);
    } else {
      score += 2;
    }

    if (resolution?.profile.lowAccessArea == true &&
        source == AvailabilityContext.grocery) {
      score -= 4;
    }

    final profile = resolution?.profile;
    if (profile != null &&
        source == AvailabilityContext.grocery &&
        profile.groceryGapSeverity >= 0.65) {
      score -= profile.groceryGapSeverity * 4;
    }

    if (user.access.transportation.lowMobility &&
        source == AvailabilityContext.fastFood &&
        mission != SourceTripMission.emergency) {
      score -= 3;
    }

    return score;
  }

  double _baseContextScore(AvailabilityContext source) {
    switch (source) {
      case AvailabilityContext.foodPantry:
        return 8;
      case AvailabilityContext.dollarStore:
        return 7;
      case AvailabilityContext.convenience:
        return 6;
      case AvailabilityContext.grocery:
        return 5;
      case AvailabilityContext.fastFood:
        return 1;
    }
  }

  double _missionAffinity(
    AvailabilityContext source,
    SourceTripMission mission,
    UserConstraints user,
  ) {
    switch (mission) {
      case SourceTripMission.emergency:
        switch (source) {
          case AvailabilityContext.convenience:
            return 14;
          case AvailabilityContext.dollarStore:
            return 11;
          case AvailabilityContext.foodPantry:
            return 10;
          case AvailabilityContext.fastFood:
            return user.feasibility.environment.canHandle('none') ? 4 : 6;
          case AvailabilityContext.grocery:
            return 1;
        }
      case SourceTripMission.pantryStretch:
        switch (source) {
          case AvailabilityContext.foodPantry:
            return 15;
          case AvailabilityContext.dollarStore:
            return 9;
          case AvailabilityContext.grocery:
            return 6;
          case AvailabilityContext.convenience:
            return 4;
          case AvailabilityContext.fastFood:
            return -10;
        }
      case SourceTripMission.restock:
        switch (source) {
          case AvailabilityContext.grocery:
            return 13;
          case AvailabilityContext.dollarStore:
            return 12;
          case AvailabilityContext.foodPantry:
            return 8;
          case AvailabilityContext.convenience:
            return 3;
          case AvailabilityContext.fastFood:
            return -12;
        }
      case SourceTripMission.benefitsRun:
        switch (source) {
          case AvailabilityContext.grocery:
            return 12;
          case AvailabilityContext.dollarStore:
            return 8;
          case AvailabilityContext.convenience:
            return 5;
          case AvailabilityContext.foodPantry:
            return 4;
          case AvailabilityContext.fastFood:
            return -9;
        }
      case SourceTripMission.oneStopMeal:
        switch (source) {
          case AvailabilityContext.grocery:
            return 11;
          case AvailabilityContext.dollarStore:
            return 7;
          case AvailabilityContext.foodPantry:
            return 6;
          case AvailabilityContext.convenience:
            return 3;
          case AvailabilityContext.fastFood:
            return 1;
        }
      case SourceTripMission.fallback:
        return 0;
    }
  }

  double _benefitAffinity(AvailabilityContext source, UserConstraints user) {
    var score = 0.0;
    if (user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      switch (source) {
        case AvailabilityContext.grocery:
          score += 6;
        case AvailabilityContext.dollarStore:
          score += 5;
        case AvailabilityContext.convenience:
          score += 3;
        case AvailabilityContext.foodPantry:
          score += 2;
        case AvailabilityContext.fastFood:
          score -= 4;
      }
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      switch (source) {
        case AvailabilityContext.grocery:
          score += 8;
        case AvailabilityContext.foodPantry:
          score += 1;
        case AvailabilityContext.dollarStore:
          score -= 3;
        case AvailabilityContext.convenience:
          score -= 5;
        case AvailabilityContext.fastFood:
          score -= 10;
      }
    }
    return score;
  }

  double _contentAffinity({
    required SourceTripMission mission,
    required _SourceContentFit contentFit,
    required UserConstraints user,
  }) {
    switch (mission) {
      case SourceTripMission.emergency:
        return (contentFit.readyMealCount * 2.2) +
            (contentFit.lowPrepCount * 0.9) +
            (contentFit.lowCostCount * 0.7);
      case SourceTripMission.pantryStretch:
        return (contentFit.stapleCount * 1.8) +
            (contentFit.fullBasketCount * 1.5);
      case SourceTripMission.restock:
        return (contentFit.stapleCount * 2.4) +
            (contentFit.lowCostCount * 1.2) +
            _benefitCoverageAffinity(
              user: user,
              contentFit: contentFit,
              multiplier: 0.6,
            );
      case SourceTripMission.benefitsRun:
        return (contentFit.stapleCount * 1.9) +
            (contentFit.fullBasketCount * 1.6) +
            _benefitCoverageAffinity(
              user: user,
              contentFit: contentFit,
              multiplier: 1.25,
            );
      case SourceTripMission.oneStopMeal:
        return (contentFit.fullBasketCount * 4.0) +
            (contentFit.mealCount * 1.4) +
            (contentFit.availableFoodCount * 0.8);
      case SourceTripMission.fallback:
        return contentFit.availableFoodCount * 0.8;
    }
  }

  double _benefitCoverageAffinity({
    required UserConstraints user,
    required _SourceContentFit contentFit,
    double multiplier = 1,
  }) {
    var score = 0.0;
    if (user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      score += contentFit.snapStrongCount * 3.1;
      score += contentFit.snapCheckCount * 1.0;
      score += contentFit.noPurchaseCount * 1.2;
      score -= contentFit.snapCautionCount * 2.0;
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      score += contentFit.wicStrongCount * 4.2;
      score -= contentFit.wicCautionCount * 2.4;
    }
    return score * multiplier;
  }

  String _summaryFor({
    required AccessCopy copy,
    required SourceTripMission mission,
    required AvailabilityContext source,
    required LocalAccessProfileResolution? resolution,
  }) {
    final zipPrefix = switch (resolution?.matchType) {
      LocalAccessMatchType.exact => copy.choose(
        'Your ZIP snapshot',
        'Tu panorama de codigo postal',
      ),
      LocalAccessMatchType.prefix => copy.choose(
        'Your ZIP-area snapshot',
        'Tu panorama de area postal',
      ),
      LocalAccessMatchType.fallback => copy.choose(
        'The fallback snapshot',
        'El panorama de respaldo',
      ),
      null => copy.choose('Your setup', 'Tu configuracion'),
    };
    final sourceLabel = copy.lowerSourceLabel(source);
    switch (mission) {
      case SourceTripMission.emergency:
        return copy.choose(
          '$zipPrefix suggests $sourceLabel is the fastest first stop for a hard day.',
          '$zipPrefix sugiere que $sourceLabel es la parada mas rapida para un dia dificil.',
        );
      case SourceTripMission.pantryStretch:
        return copy.choose(
          '$zipPrefix makes $sourceLabel the best place to stretch what you already have at home.',
          '$zipPrefix hace que $sourceLabel sea el mejor lugar para rendir lo que ya tienes en casa.',
        );
      case SourceTripMission.restock:
        return copy.choose(
          '$zipPrefix points to $sourceLabel as the strongest first stop for a small staple restock.',
          '$zipPrefix apunta a $sourceLabel como la mejor primera parada para una pequena reposicion de basicos.',
        );
      case SourceTripMission.benefitsRun:
        return copy.choose(
          '$zipPrefix points to $sourceLabel as the better benefits-aware stop for today.',
          '$zipPrefix apunta a $sourceLabel como la mejor parada para usar beneficios hoy.',
        );
      case SourceTripMission.oneStopMeal:
        return copy.choose(
          '$zipPrefix makes $sourceLabel the more realistic one-stop meal run.',
          '$zipPrefix hace que $sourceLabel sea la parada mas realista para resolver la comida en un solo viaje.',
        );
      case SourceTripMission.fallback:
        return copy.choose(
          '$zipPrefix makes $sourceLabel the simplest realistic first stop right now.',
          '$zipPrefix hace que $sourceLabel sea la parada mas simple y realista en este momento.',
        );
    }
  }

  List<String> _reasonsFor({
    required AccessCopy copy,
    required AvailabilityContext source,
    required SourceTripMission mission,
    required UserConstraints user,
    required SourceAccessSnapshot? snapshot,
    required SourceAccessSnapshot? grocerySnapshot,
    required _SourceContentFit contentFit,
  }) {
    final reasons = <String>[];
    String? sameDayReason;
    String? shorterTripReason;
    String? snapshotNote;
    if (snapshot != null) {
      reasons.add(
        copy.choose(
          '${snapshot.typicalTravelMinutes} min typical travel with ${snapshot.nearbyOptions} nearby option${snapshot.nearbyOptions == 1 ? '' : 's'}.',
          '${snapshot.typicalTravelMinutes} min de viaje tipico con ${snapshot.nearbyOptions} opcion${snapshot.nearbyOptions == 1 ? '' : 'es'} cercana${snapshot.nearbyOptions == 1 ? '' : 's'}.',
        ),
      );
      if (snapshot.sameDayConfidence >= 0.85) {
        sameDayReason = copy.choose(
          'Higher same-day confidence for today\'s trip.',
          'Mayor confianza de resolverlo hoy.',
        );
      }
      if (grocerySnapshot != null &&
          source != AvailabilityContext.grocery &&
          snapshot.typicalTravelMinutes <
              grocerySnapshot.typicalTravelMinutes) {
        shorterTripReason = copy.choose(
          'Shorter trip than the bundled grocery route in this snapshot.',
          'Viaje mas corto que la ruta de supermercado en este panorama.',
        );
      }
      if (snapshot.note?.isNotEmpty == true) {
        snapshotNote = snapshot.note!;
      }
    }
    if (contentFit.availableFoodCount > 0) {
      reasons.add(
        copy.choose(
          'Covers ${contentFit.availableFoodCount} of your top ${contentFit.totalFoodsConsidered} current option${contentFit.totalFoodsConsidered == 1 ? '' : 's'}.',
          'Cubre ${contentFit.availableFoodCount} de tus ${contentFit.totalFoodsConsidered} opcion${contentFit.totalFoodsConsidered == 1 ? '' : 'es'} principales.',
        ),
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      if (contentFit.noPurchaseCount > 0 &&
          source == AvailabilityContext.foodPantry) {
        reasons.add(
          copy.choose(
            'No purchase needed for ${contentFit.noPurchaseCount} top option${contentFit.noPurchaseCount == 1 ? '' : 's'} if pantry stock is there.',
            'No hace falta comprar ${contentFit.noPurchaseCount == 1 ? 'esa opcion' : 'esas opciones'} si la despensa las tiene hoy.',
          ),
        );
      } else if (contentFit.snapStrongCount > 0) {
        reasons.add(
          copy.choose(
            'Covers ${contentFit.snapStrongCount} likely SNAP-compatible option${contentFit.snapStrongCount == 1 ? '' : 's'}.',
            'Cubre ${contentFit.snapStrongCount} opcion${contentFit.snapStrongCount == 1 ? '' : 'es'} probablemente compatibles con SNAP.',
          ),
        );
      } else if (contentFit.snapCheckCount > 0) {
        reasons.add(
          copy.choose(
            'Some shortlist items here may need a SNAP check at checkout.',
            'Algunas opciones aqui pueden necesitar revisar SNAP en caja.',
          ),
        );
      }
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      if (contentFit.wicStrongCount > 0) {
        reasons.add(
          copy.choose(
            'Includes ${contentFit.wicStrongCount} likely WIC staple candidate${contentFit.wicStrongCount == 1 ? '' : 's'}; final rules still depend on brand, size, and state list.',
            'Incluye ${contentFit.wicStrongCount} posible${contentFit.wicStrongCount == 1 ? '' : 's'} basico${contentFit.wicStrongCount == 1 ? '' : 's'} WIC; la regla final depende de marca, tamano y lista estatal.',
          ),
        );
      } else if (source != AvailabilityContext.grocery &&
          contentFit.availableFoodCount > 0) {
        reasons.add(
          copy.choose(
            'Not the strongest WIC stop for this shortlist.',
            'No es la parada WIC mas fuerte para esta lista.',
          ),
        );
      }
    }
    if (contentFit.fullBasketCount > 0) {
      reasons.add(
        copy.choose(
          'Supports ${contentFit.fullBasketCount} full basket option${contentFit.fullBasketCount == 1 ? '' : 's'} from today\'s shortlist.',
          'Soporta ${contentFit.fullBasketCount} opcion${contentFit.fullBasketCount == 1 ? '' : 'es'} de canasta completa de la lista de hoy.',
        ),
      );
    }
    if (source == AvailabilityContext.foodPantry &&
        contentFit.stapleCount > 0) {
      reasons.add(
        copy.choose(
          'Better fit for pantry-style staples than deli-style meal picks.',
          'Encaja mejor con basicos de despensa que con comidas tipo deli.',
        ),
      );
    } else if (source == AvailabilityContext.dollarStore &&
        contentFit.stapleCount > 0) {
      reasons.add(
        copy.choose(
          'Shortlist leans toward shelf-stable basics this stop is more likely to cover.',
          'La lista se inclina a basicos de anaquel que esta parada cubre mejor.',
        ),
      );
    } else if (source == AvailabilityContext.convenience &&
        contentFit.readyMealCount > 0) {
      reasons.add(
        copy.choose(
          'Stronger fit for quick grab-and-go items than a full restock.',
          'Encaja mejor con comida rapida para llevar que con una gran reposicion.',
        ),
      );
    } else if (source == AvailabilityContext.grocery &&
        (contentFit.fullBasketCount > 0 || contentFit.mealCount > 0)) {
      reasons.add(
        copy.choose(
          'More credible stop for a fuller basket of meals and fresh items.',
          'Parada mas creible para una canasta mas completa de comidas y frescos.',
        ),
      );
    }

    if (mission == SourceTripMission.restock) {
      reasons.add(
        copy.choose(
          'Better fit for replacing basic staples before a larger run.',
          'Encaja mejor para reponer basicos antes de una compra mayor.',
        ),
      );
    } else if (mission == SourceTripMission.pantryStretch) {
      reasons.add(
        copy.choose(
          'Works better for topping off what is already in the kitchen.',
          'Funciona mejor para completar lo que ya esta en la cocina.',
        ),
      );
    } else if (mission == SourceTripMission.emergency) {
      reasons.add(
        copy.choose(
          'Lower-burden stop for a same-day meal decision.',
          'Parada de menor carga para resolver una comida hoy mismo.',
        ),
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        source != AvailabilityContext.fastFood) {
      reasons.add(
        copy.choose(
          'More practical for a SNAP-funded basics run.',
          'Mas practico para una compra basica con SNAP.',
        ),
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        source == AvailabilityContext.grocery) {
      reasons.add(
        copy.choose(
          'Stronger fit for WIC staples than convenience-only stops.',
          'Mejor ajuste para basicos de WIC que una parada solo de conveniencia.',
        ),
      );
    }

    for (final trailingReason in [
      sameDayReason,
      shorterTripReason,
      snapshotNote,
    ]) {
      if (trailingReason == null || reasons.length >= 3) {
        continue;
      }
      reasons.add(trailingReason);
    }

    return reasons.take(3).toList(growable: false);
  }

  List<String> _highlightsFor({
    required AccessCopy copy,
    required AvailabilityContext source,
    required SourceTripMission mission,
    required UserConstraints user,
    required SourceAccessSnapshot? snapshot,
    required _SourceContentFit contentFit,
  }) {
    final highlights = <String>[
      copy.sourceLabel(source),
      _missionLabel(copy, mission),
    ];
    if (snapshot != null) {
      highlights.add('${snapshot.typicalTravelMinutes} min');
    }
    if (contentFit.noPurchaseCount > 0 &&
        source == AvailabilityContext.foodPantry) {
      highlights.add(copy.choose('No purchase', 'Sin compra'));
    } else if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        contentFit.snapStrongCount > 0) {
      highlights.add(copy.choose('SNAP basics', 'Basicos SNAP'));
    } else if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        contentFit.snapCheckCount > 0) {
      highlights.add(copy.choose('SNAP check', 'Revisa SNAP'));
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        contentFit.wicStrongCount > 0) {
      highlights.add(copy.choose('WIC staples', 'Basicos WIC'));
    }
    if (contentFit.fullBasketCount > 0) {
      highlights.add(copy.choose('Basket fit', 'Ajuste de canasta'));
    } else if (contentFit.stapleCount >= 2) {
      highlights.add(copy.choose('Staple fit', 'Ajuste de basicos'));
    } else if (contentFit.readyMealCount >= 2) {
      highlights.add(copy.choose('Quick meal fit', 'Ajuste de comida rapida'));
    }
    return highlights.take(4).toList(growable: false);
  }

  List<String> _bestForTags({
    required AccessCopy copy,
    required AvailabilityContext source,
    required SourceTripMission mission,
    required _SourceContentFit contentFit,
  }) {
    final tags = <String>{};
    if (contentFit.noPurchaseCount > 0 &&
        source == AvailabilityContext.foodPantry) {
      tags.add(copy.choose('No purchase', 'Sin compra'));
    }
    if (contentFit.snapStrongCount > 0) {
      tags.add(copy.choose('SNAP basics', 'Basicos SNAP'));
    }
    if (contentFit.wicStrongCount > 0) {
      tags.add(copy.choose('WIC staples', 'Basicos WIC'));
    }
    if (contentFit.stapleCount > 0) {
      tags.add(copy.choose('Staples', 'Basicos'));
    }
    if (contentFit.fullBasketCount > 0) {
      tags.add(copy.choose('One-stop basket', 'Canasta de una parada'));
    }
    if (contentFit.readyMealCount > 0) {
      tags.add(copy.choose('Fast meal', 'Comida rapida'));
    }
    if (contentFit.lowPrepCount > 0 && mission == SourceTripMission.emergency) {
      tags.add(copy.choose('No-prep', 'Sin preparacion'));
    }

    switch (source) {
      case AvailabilityContext.foodPantry:
        tags.add(copy.choose('Pantry stretch', 'Rinde despensa'));
      case AvailabilityContext.dollarStore:
        tags.add(copy.choose('Budget restock', 'Reposicion barata'));
      case AvailabilityContext.convenience:
        tags.add(copy.choose('Quick grab', 'Compra rapida'));
      case AvailabilityContext.grocery:
        tags.add(copy.choose('Full basket', 'Canasta completa'));
      case AvailabilityContext.fastFood:
        tags.add(copy.choose('Ready meal', 'Comida lista'));
    }

    return tags.take(3).toList(growable: false);
  }

  String _missionLabel(AccessCopy copy, SourceTripMission mission) {
    switch (mission) {
      case SourceTripMission.emergency:
        return copy.choose('Emergency stop', 'Parada de emergencia');
      case SourceTripMission.pantryStretch:
        return copy.choose('Pantry stretch', 'Rinde despensa');
      case SourceTripMission.restock:
        return copy.choose('Staple restock', 'Reposicion de basicos');
      case SourceTripMission.benefitsRun:
        return copy.choose('Benefits run', 'Compra con beneficios');
      case SourceTripMission.oneStopMeal:
        return copy.choose('One-stop meal', 'Comida de una parada');
      case SourceTripMission.fallback:
        return copy.choose('Fallback', 'Respaldo');
    }
  }

  String _routeReasonFor({
    required AccessCopy copy,
    required AvailabilityContext source,
    required SourceTripMission mission,
    required UserConstraints user,
    required SourceAccessSnapshot? snapshot,
    required SourceAccessSnapshot? grocerySnapshot,
    required _SourceContentFit contentFit,
  }) {
    final shorterThanGrocery =
        snapshot != null &&
        grocerySnapshot != null &&
        source != AvailabilityContext.grocery &&
        snapshot.typicalTravelMinutes < grocerySnapshot.typicalTravelMinutes;
    if (source == AvailabilityContext.foodPantry &&
        contentFit.noPurchaseCount > 0) {
      return copy.choose(
        'More realistic than a store-first route because this stop can work with no purchase if pantry stock is there today.',
        'Es mas realista que empezar en tienda porque esta parada puede funcionar sin compra si hoy la despensa tiene stock.',
      );
    }
    if (shorterThanGrocery && contentFit.fullBasketCount > 0) {
      return copy.choose(
        'More realistic than the harder grocery route because the trip is shorter and this stop still covers a fuller basket.',
        'Es mas realista que la ruta mas pesada al supermercado porque el viaje es mas corto y esta parada todavia cubre una canasta mas completa.',
      );
    }
    if (shorterThanGrocery &&
        (mission == SourceTripMission.pantryStretch ||
            mission == SourceTripMission.restock ||
            contentFit.stapleCount > 0)) {
      return copy.choose(
        'More realistic than the harder grocery route because the trip is shorter and today\'s shortlist leans on simple staples.',
        'Es mas realista que la ruta mas pesada al supermercado porque el viaje es mas corto y la lista de hoy se apoya en basicos simples.',
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        contentFit.wicStrongCount > 0) {
      return copy.choose(
        'More realistic today because it puts likely WIC staples ahead of easier but weaker stops.',
        'Es mas realista hoy porque pone los posibles basicos WIC por delante de paradas mas faciles pero mas debiles.',
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        contentFit.snapStrongCount > 0) {
      return copy.choose(
        'More realistic today because it puts likely SNAP staples ahead of pricier or less certain options.',
        'Es mas realista hoy porque pone los posibles basicos SNAP por delante de opciones mas caras o menos seguras.',
      );
    }
    if (mission == SourceTripMission.emergency) {
      return copy.choose(
        'More realistic today because it keeps the first stop fast and the meal simple.',
        'Es mas realista hoy porque mantiene rapida la primera parada y simple la comida.',
      );
    }
    if (mission == SourceTripMission.oneStopMeal &&
        contentFit.fullBasketCount > 0) {
      return copy.choose(
        'More realistic today because this stop covers more of the meal in one trip.',
        'Es mas realista hoy porque esta parada cubre mas de la comida en un solo viaje.',
      );
    }
    return copy.choose(
      'More realistic today because it matches the lower-burden route in your current access model.',
      'Es mas realista hoy porque coincide con la ruta de menor carga en tu modelo de acceso actual.',
    );
  }

  String? _benefitSummaryFor({
    required AccessCopy copy,
    required AvailabilityContext source,
    required UserConstraints user,
    required _SourceContentFit contentFit,
  }) {
    if (source == AvailabilityContext.foodPantry &&
        contentFit.noPurchaseCount > 0) {
      return copy.choose(
        'Best when you need food first with no purchase.',
        'Mejor cuando necesitas comida primero sin compra.',
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      if (contentFit.wicStrongCount > 0) {
        return copy.choose(
          'Stronger stop for likely WIC staple candidates.',
          'Parada mas fuerte para posibles basicos WIC.',
        );
      }
      if (source != AvailabilityContext.grocery &&
          contentFit.availableFoodCount > 0) {
        return copy.choose(
          'Not the strongest WIC stop for this shortlist; use the grocery backup if you need approved WIC staples.',
          'No es la parada WIC mas fuerte para esta lista; usa el respaldo de supermercado si necesitas basicos WIC aprobados.',
        );
      }
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      if (contentFit.snapStrongCount > 0) {
        return copy.choose(
          'Stronger stop for likely SNAP-compatible basics.',
          'Parada mas fuerte para basicos probablemente compatibles con SNAP.',
        );
      }
      if (contentFit.snapCheckCount > 0) {
        return copy.choose(
          'Some shortlist items here may need a SNAP check at checkout.',
          'Algunas opciones aqui pueden necesitar revisar SNAP en caja.',
        );
      }
    }
    return null;
  }

  String? _confidenceSummary(
    AccessCopy copy,
    LocalAccessProfileResolution? resolution,
  ) {
    if (resolution == null) {
      return null;
    }
    switch (resolution.matchType) {
      case LocalAccessMatchType.exact:
        return copy.choose(
          'Higher-confidence access read because this is an exact bundled ZIP match.',
          'Lectura de acceso de mayor confianza porque este es un ZIP incluido exacto.',
        );
      case LocalAccessMatchType.prefix:
        return copy.choose(
          'Moderate-confidence access read because this uses a broader bundled ZIP-area estimate.',
          'Lectura de acceso de confianza media porque usa una estimacion incluida mas amplia por area ZIP.',
        );
      case LocalAccessMatchType.fallback:
        return copy.choose(
          'Lower-confidence access read because this falls back to the general bundled low-resource model.',
          'Lectura de acceso de menor confianza porque cae al modelo general incluido de pocos recursos.',
        );
    }
  }

  String _dataSourceSummary({
    required AccessCopy copy,
    required UserConstraints user,
  }) {
    final store = user.feasibility.groceryStore;
    if (store != null) {
      return copy.choose(
        'First-stop ranking still uses bundled ZIP access data. Live grocery brands and prices only apply to ${store.name}.',
        'La eleccion de primera parada sigue usando datos ZIP incluidos. Las marcas y precios de comestibles en vivo solo aplican a ${store.name}.',
      );
    }
    return copy.choose(
      'First-stop ranking uses bundled ZIP access data only, not live store inventory.',
      'La eleccion de primera parada usa solo datos ZIP incluidos, no inventario en vivo de tiendas.',
    );
  }

  _SourceContentFit _contentFitForSource({
    required AvailabilityContext source,
    required List<ScoredFood> foods,
    required List<MealBasketPlan> baskets,
    required UserConstraints user,
  }) {
    final availableFoods = foods
        .take(6)
        .where(
          (item) =>
              item.food.availability.contains(source) &&
              contentModel.plausibleFitForFood(item.food, source),
        )
        .toList(growable: false);
    final fullBasketCount = baskets
        .take(3)
        .where(
          (basket) => basket.items.every(
            (item) =>
                item.food.availability.contains(source) &&
                contentModel.strongFitForFood(item.food, source),
          ),
        )
        .length;

    var stapleCount = 0;
    var readyMealCount = 0;
    var mealCount = 0;
    var lowPrepCount = 0;
    var lowCostCount = 0;
    var noPurchaseCount = 0;
    var snapStrongCount = 0;
    var snapCheckCount = 0;
    var snapCautionCount = 0;
    var wicStrongCount = 0;
    var wicCautionCount = 0;
    for (final item in availableFoods) {
      if (_looksLikeStaple(item)) {
        stapleCount += 1;
      }
      if (_looksLikeReadyMeal(item)) {
        readyMealCount += 1;
      }
      if (_looksLikeMeal(item)) {
        mealCount += 1;
      }
      if (item.food.readyToEat || item.food.prepTimeMin <= 5) {
        lowPrepCount += 1;
      }
      if (item.food.costEstimate <= 3.5) {
        lowCostCount += 1;
      }
      final snapSupport = accessAdvisor.snapSupportForSource(
        food: item.food,
        source: source,
        user: user,
      );
      final wicSupport = accessAdvisor.wicSupportForSource(
        food: item.food,
        source: source,
        user: user,
      );
      if (source == AvailabilityContext.foodPantry) {
        noPurchaseCount += 1;
      }
      if (snapSupport?.positive ?? false) {
        snapStrongCount += 1;
      } else if ((snapSupport?.neutral ?? false) &&
          source != AvailabilityContext.foodPantry) {
        snapCheckCount += 1;
      } else if (snapSupport?.caution ?? false) {
        snapCautionCount += 1;
      }
      if (wicSupport?.positive ?? false) {
        wicStrongCount += 1;
      } else if (wicSupport?.caution ?? false) {
        wicCautionCount += 1;
      }
    }

    return _SourceContentFit(
      availableFoodCount: availableFoods.length,
      fullBasketCount: fullBasketCount,
      stapleCount: stapleCount,
      readyMealCount: readyMealCount,
      mealCount: mealCount,
      lowPrepCount: lowPrepCount,
      lowCostCount: lowCostCount,
      noPurchaseCount: noPurchaseCount,
      snapStrongCount: snapStrongCount,
      snapCheckCount: snapCheckCount,
      snapCautionCount: snapCautionCount,
      wicStrongCount: wicStrongCount,
      wicCautionCount: wicCautionCount,
      totalFoodsConsidered: foods.take(6).length,
    );
  }

  bool _looksLikeStaple(ScoredFood item) {
    return contentModel.looksLikeStaple(item.food);
  }

  bool _looksLikeReadyMeal(ScoredFood item) {
    return contentModel.looksLikeReadyMeal(item.food);
  }

  bool _looksLikeMeal(ScoredFood item) {
    return contentModel.looksLikeMeal(item.food) ||
        (item.nutrients.proteinG >= 10 &&
            (item.nutrients.carbsG >= 18 || item.nutrients.fatG >= 8));
  }
}

class _SourceScore {
  const _SourceScore({required this.source, required this.score});

  final AvailabilityContext source;
  final double score;
}

class _SourceContentFit {
  const _SourceContentFit({
    required this.availableFoodCount,
    required this.fullBasketCount,
    required this.stapleCount,
    required this.readyMealCount,
    required this.mealCount,
    required this.lowPrepCount,
    required this.lowCostCount,
    required this.noPurchaseCount,
    required this.snapStrongCount,
    required this.snapCheckCount,
    required this.snapCautionCount,
    required this.wicStrongCount,
    required this.wicCautionCount,
    required this.totalFoodsConsidered,
  });

  final int availableFoodCount;
  final int fullBasketCount;
  final int stapleCount;
  final int readyMealCount;
  final int mealCount;
  final int lowPrepCount;
  final int lowCostCount;
  final int noPurchaseCount;
  final int snapStrongCount;
  final int snapCheckCount;
  final int snapCautionCount;
  final int wicStrongCount;
  final int wicCautionCount;
  final int totalFoodsConsidered;
}
