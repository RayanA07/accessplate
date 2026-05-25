import 'access_advisor.dart';
import 'access_copy.dart';
import '../entities/explanation.dart';
import '../entities/food.dart';
import '../entities/local_access.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/benefit_program.dart';
import '../value_objects/religion.dart';
import 'score_config_provider.dart';

class Explainer {
  Explainer({
    required this.config,
    required this.user,
    FoodAccessAdvisor? accessAdvisor,
  }) : _accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor();

  final ScoreConfig config;
  final UserConstraints user;
  final FoodAccessAdvisor _accessAdvisor;
  AccessCopy get _copy => AccessCopy(user.access);

  Explanation explain(ScoredFood scored) {
    final accessInsight = _accessAdvisor.inspect(food: scored.food, user: user);
    return Explanation(
      satisfied: _satisfiedConstraints(scored.food, accessInsight),
      positives: _topPositives(scored, accessInsight),
      tradeoffs: _topTradeoffs(scored, accessInsight),
      compareWithIds: const [],
      accessSummary: _accessSummary(accessInsight),
      accessTags: _accessTags(accessInsight),
      decisionFacts: _decisionFacts(scored.food, accessInsight),
    );
  }

  List<SatisfiedConstraint> _satisfiedConstraints(
    Food food,
    FoodAccessInsight accessInsight,
  ) {
    final satisfied = <SatisfiedConstraint>[];
    final copy = _copy;

    if (user.safety.allergens.isNotEmpty) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'allergen',
          description: copy.choose(
            'Avoids ${user.safety.allergens.map((item) => item.label).join(', ')}',
            'Evita ${user.safety.allergens.map((item) => item.label).join(', ')}',
          ),
        ),
      );
    }

    if (user.safety.religion != Religion.none) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'religion',
          description: copy.choose(
            'Compatible with ${user.safety.religion.label}',
            'Compatible con ${user.safety.religion.label}',
          ),
        ),
      );
    }

    satisfied.add(
      SatisfiedConstraint(
        category: 'budget',
        description: copy.choose(
          '\$${food.costEstimate.toStringAsFixed(2)} now, under your \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)} limit',
          '\$${food.costEstimate.toStringAsFixed(2)} ahora, debajo de tu limite de \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)}',
        ),
      ),
    );

    satisfied.add(
      SatisfiedConstraint(
        category: 'environment',
        description: food.readyToEat
            ? copy.choose('Works with no prep', 'Funciona sin preparar')
            : copy.choose(
                'Works for ${user.feasibility.environment.label} in ${food.prepTimeMin} min',
                'Funciona con ${user.feasibility.environment.label} en ${food.prepTimeMin} min',
              ),
      ),
    );

    final availability = accessInsight.source ?? _matchedAvailability(food);
    if (availability != null) {
      final zipSuffix =
          accessInsight.zipAware &&
              accessInsight.matchType != LocalAccessMatchType.fallback
          ? copy.choose(' in your ZIP snapshot', ' en tu panorama postal')
          : '';
      satisfied.add(
        SatisfiedConstraint(
          category: 'availability',
          description: user.access.plainLanguage
              ? copy.choose(
                  'Realistic from ${_copy.lowerSourceLabel(availability)}$zipSuffix',
                  'Realista desde ${_copy.lowerSourceLabel(availability)}$zipSuffix',
                )
              : copy.choose(
                  'Available at ${_copy.lowerSourceLabel(availability)}$zipSuffix',
                  'Disponible en ${_copy.lowerSourceLabel(availability)}$zipSuffix',
                ),
        ),
      );
    }

    if (accessInsight.snapFriendly) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'benefit',
          description:
              accessInsight.snapSupport?.label ??
              copy.choose(
                'Works with SNAP at this source',
                'Funciona con SNAP en esta fuente',
              ),
        ),
      );
    }

    if (accessInsight.wicStapleCandidate) {
      satisfied.add(
        SatisfiedConstraint(
          category: 'benefit',
          description:
              accessInsight.wicSupport?.label ??
              copy.choose(
                'Looks like a WIC staple match',
                'Parece un basico compatible con WIC',
              ),
        ),
      );
    }

    return satisfied;
  }

  List<ScoreFactor> _topPositives(
    ScoredFood scored,
    FoodAccessInsight accessInsight,
  ) {
    final positives = <ScoreFactor>[];
    final nutrients = scored.nutrients;
    final targets = config.macroTargets;
    final copy = _copy;

    if (nutrients.proteinG >= _proteinFloor(targets)) {
      positives.add(
        ScoreFactor(
          label:
              scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.6
              ? copy.choose('Budget-friendly protein', 'Proteina a buen costo')
              : copy.choose('Strong protein fit', 'Buen ajuste de proteina'),
          weight: scored.breakdown.macro,
          detail: copy.choose(
            '${nutrients.proteinG.toStringAsFixed(0)}g protein for \$${scored.food.costEstimate.toStringAsFixed(2)}',
            '${nutrients.proteinG.toStringAsFixed(0)}g de proteina por \$${scored.food.costEstimate.toStringAsFixed(2)}',
          ),
        ),
      );
    }

    if ((config.microPriorities['iron_mg'] ?? 1) > 1.2 &&
        nutrients.ironMg >= 3) {
      positives.add(
        ScoreFactor(
          label: copy.choose('Helpful iron source', 'Fuente util de hierro'),
          weight: scored.breakdown.micro,
          detail: copy.choose(
            '${nutrients.ironMg.toStringAsFixed(1)} mg iron',
            '${nutrients.ironMg.toStringAsFixed(1)} mg de hierro',
          ),
        ),
      );
    }

    if (nutrients.fiberG >= _fiberFloor(targets)) {
      positives.add(
        ScoreFactor(
          label:
              scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.6
              ? copy.choose('Low-cost fiber win', 'Fibra de bajo costo')
              : copy.choose('High fiber', 'Mucha fibra'),
          weight: scored.breakdown.macro,
          detail: copy.choose(
            '${nutrients.fiberG.toStringAsFixed(0)}g fiber',
            '${nutrients.fiberG.toStringAsFixed(0)}g de fibra',
          ),
        ),
      );
    }

    if (scored.food.readyToEat) {
      positives.add(
        ScoreFactor(
          label: copy.choose('Works with no prep', 'Funciona sin preparar'),
          weight: 0.72,
          detail: copy.choose('Ready to eat as-is', 'Listo para comer'),
        ),
      );
    }

    final matchedAvailability =
        accessInsight.source ?? _matchedAvailability(scored.food);
    if (matchedAvailability != null &&
        matchedAvailability != AvailabilityContext.grocery) {
      positives.add(
        ScoreFactor(
          label: copy.choose(
            'Easy to find today',
            'Mas facil de conseguir hoy',
          ),
          weight: 0.68,
          detail: copy.choose(
            'Available at ${_copy.lowerSourceLabel(matchedAvailability)}',
            'Disponible en ${_copy.lowerSourceLabel(matchedAvailability)}',
          ),
        ),
      );
    }

    if (scored.food.costEstimate <= user.feasibility.maxCostPerMeal * 0.5) {
      positives.add(
        ScoreFactor(
          label: copy.choose(
            'Well under budget',
            'Muy por debajo del presupuesto',
          ),
          weight: 1 - _budgetShare(scored.food),
          detail: copy.choose(
            '\$${scored.food.costEstimate.toStringAsFixed(2)} estimated',
            '\$${scored.food.costEstimate.toStringAsFixed(2)} estimado',
          ),
        ),
      );
    }

    if (accessInsight.pantryReadyMatches.isNotEmpty) {
      positives.add(
        ScoreFactor(
          label: copy.choose(
            'Stretches food you already have',
            'Rinde la comida que ya tienes',
          ),
          weight: 0.88,
          detail: accessInsight.pantryReadyMatches.take(3).join(', '),
        ),
      );
    }

    if (accessInsight.pantryLowMatches.isNotEmpty) {
      positives.add(
        ScoreFactor(
          label: copy.choose(
            'Builds on low pantry staples',
            'Se apoya en basicos que se estan acabando',
          ),
          weight: 0.66,
          detail: accessInsight.pantryLowMatches.take(3).join(', '),
        ),
      );
    }

    if (accessInsight.lowTravel) {
      positives.add(
        ScoreFactor(
          label: user.access.plainLanguage
              ? copy.choose('Lower-travel option', 'Opcion de viaje mas corto')
              : copy.choose('Lower travel burden', 'Menor carga de viaje'),
          weight: 0.78,
          detail: _travelDetail(accessInsight),
        ),
      );
    }

    if (accessInsight.sourceSnapshot != null &&
        accessInsight.nearbyOptions >= 2 &&
        accessInsight.zipAware) {
      final sourceDescriptor = accessInsight.source == null
          ? copy.choose('nearby', 'cercanas')
          : _copy.lowerSourceLabel(accessInsight.source!);
      positives.add(
        ScoreFactor(
          label: copy.choose(
            'Supported by nearby options',
            'Respaldado por opciones cercanas',
          ),
          weight: 0.8,
          detail: copy.choose(
            '${accessInsight.nearbyOptions} $sourceDescriptor options in the bundled local snapshot',
            '${accessInsight.nearbyOptions} opciones de $sourceDescriptor en el panorama local incluido',
          ),
        ),
      );
    }

    if (user.access.emergencyMode && accessInsight.emergencyFriendly) {
      positives.add(
        ScoreFactor(
          label: copy.choose('Emergency-friendly', 'Sirve en emergencia'),
          weight: 0.92,
          detail: copy.choose(
            'Cheap, fast, and manageable today',
            'Barato, rapido y manejable hoy',
          ),
        ),
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        (accessInsight.snapSupport?.positive ?? false)) {
      positives.add(
        ScoreFactor(
          label: accessInsight.snapSupport!.label,
          weight: 0.8,
          detail: accessInsight.snapSupport!.detail,
        ),
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        (accessInsight.wicSupport?.positive ?? false)) {
      positives.add(
        ScoreFactor(
          label: accessInsight.wicSupport!.label,
          weight: 0.78,
          detail: accessInsight.wicSupport!.detail,
        ),
      );
    }

    positives.sort((a, b) => b.weight.compareTo(a.weight));
    return positives.take(3).toList();
  }

  List<ScoreFactor> _topTradeoffs(
    ScoredFood scored,
    FoodAccessInsight accessInsight,
  ) {
    final tradeoffs = <ScoreFactor>[];
    final nutrients = scored.nutrients;
    final copy = _copy;

    final sodiumThreshold = config.penaltyThresholds['sodium_mg'] ?? 0;
    if (sodiumThreshold > 0 && nutrients.sodiumMg > sodiumThreshold) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Higher sodium than ideal',
            'Mas sodio de lo ideal',
          ),
          weight: scored.breakdown.penalty,
          detail: copy.choose(
            '${nutrients.sodiumMg.toStringAsFixed(0)} mg sodium',
            '${nutrients.sodiumMg.toStringAsFixed(0)} mg de sodio',
          ),
        ),
      );
    }

    final sugarThreshold = config.penaltyThresholds['added_sugar_g'] ?? 0;
    if (sugarThreshold > 0 && nutrients.addedSugarG > sugarThreshold) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Higher added sugar than ideal',
            'Mas azucar agregada de lo ideal',
          ),
          weight: scored.breakdown.penalty,
          detail: copy.choose(
            '${nutrients.addedSugarG.toStringAsFixed(0)}g added sugar',
            '${nutrients.addedSugarG.toStringAsFixed(0)}g de azucar agregada',
          ),
        ),
      );
    }

    if (_budgetShare(scored.food) > 0.8) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Near the top of your budget',
            'Cerca del tope de tu presupuesto',
          ),
          weight: _budgetShare(scored.food),
          detail: copy.choose(
            '\$${scored.food.costEstimate.toStringAsFixed(2)} of \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)}',
            '\$${scored.food.costEstimate.toStringAsFixed(2)} de \$${user.feasibility.maxCostPerMeal.toStringAsFixed(0)}',
          ),
        ),
      );
    }

    if (nutrients.proteinG < _proteinFloor(config.macroTargets)) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Lower protein than the best-value options',
            'Menos proteina que las mejores opciones',
          ),
          weight: 0.62,
          detail: copy.choose(
            '${nutrients.proteinG.toStringAsFixed(0)}g protein',
            '${nutrients.proteinG.toStringAsFixed(0)}g de proteina',
          ),
        ),
      );
    }

    if (!scored.food.readyToEat && scored.food.prepTimeMin >= 8) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Takes more time than the fastest options',
            'Toma mas tiempo que las opciones mas rapidas',
          ),
          weight: 0.45,
          detail: copy.choose(
            '${scored.food.prepTimeMin} min prep',
            '${scored.food.prepTimeMin} min de preparacion',
          ),
        ),
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        (accessInsight.snapSupport?.caution ?? false)) {
      tradeoffs.add(
        ScoreFactor(
          label: accessInsight.snapSupport!.label,
          weight: 0.82,
          detail: accessInsight.snapSupport!.detail,
        ),
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        accessInsight.wicSupport?.caution == true) {
      tradeoffs.add(
        ScoreFactor(
          label: accessInsight.wicSupport!.label,
          weight: 0.76,
          detail: accessInsight.wicSupport!.detail,
        ),
      );
    }

    if (accessInsight.travelBurden == TravelBurden.high) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Harder trip for your travel setup',
            'Viaje mas dificil para tu transporte',
          ),
          weight: 0.84,
          detail: _travelDetail(accessInsight),
        ),
      );
    }

    if (user.access.emergencyMode && !accessInsight.emergencyFriendly) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Not ideal for emergency mode',
            'No es ideal para modo de emergencia',
          ),
          weight: 0.8,
          detail: copy.choose(
            'A cheaper or faster option is likely available',
            'Probablemente hay una opcion mas barata o rapida',
          ),
        ),
      );
    }

    if (accessInsight.restockMatches.isNotEmpty) {
      tradeoffs.add(
        ScoreFactor(
          label: copy.choose(
            'Needs pantry restock soon',
            'Necesita reposicion de despensa pronto',
          ),
          weight: 0.58,
          detail: accessInsight.restockMatches.take(3).join(', '),
        ),
      );
    }

    tradeoffs.sort((a, b) => b.weight.compareTo(a.weight));
    return tradeoffs.take(2).toList();
  }

  String? _accessSummary(FoodAccessInsight accessInsight) {
    final source = accessInsight.source == null
        ? null
        : _copy.lowerSourceLabel(accessInsight.source!);
    final minutes = accessInsight.typicalTravelMinutes;
    final localArea = accessInsight.localProfile?.communityLabel;
    final copy = _copy;

    if (user.access.emergencyMode && accessInsight.emergencyFriendly) {
      if (source != null && minutes != null) {
        return copy.choose(
          'Fast, cheap option for an emergency day through $source in about $minutes minutes.',
          'Opcion rapida y barata para un dia de emergencia por $source en unos $minutes minutos.',
        );
      }
      return copy.choose(
        'Fast, cheap option for an emergency day.',
        'Opcion rapida y barata para un dia de emergencia.',
      );
    }
    if (accessInsight.pantryReadyMatches.isNotEmpty) {
      return copy.choose(
        'Uses ingredients you already have at home.',
        'Usa ingredientes que ya tienes en casa.',
      );
    }
    if (accessInsight.pantryLowMatches.isNotEmpty) {
      return copy.choose(
        'Builds on staples you marked as running low, so it works best with a small restock.',
        'Se apoya en basicos que marcaste bajos, asi que funciona mejor con una pequena reposicion.',
      );
    }
    if (accessInsight.snapFriendly && accessInsight.lowTravel) {
      if (source != null) {
        return copy.choose(
          'Fits a lower-travel SNAP shopping trip through $source.',
          'Encaja con una compra SNAP de viaje corto por $source.',
        );
      }
      return copy.choose(
        'Fits a lower-travel SNAP shopping trip.',
        'Encaja con una compra SNAP de viaje corto.',
      );
    }
    if (accessInsight.wicStapleCandidate && source != null) {
      return copy.choose(
        'Looks like a realistic WIC staple candidate through $source.',
        'Parece un basico WIC realista por $source.',
      );
    }
    if (accessInsight.restockMatches.isNotEmpty) {
      return copy.choose(
        'Useful as part of a staple restock for the items you marked low or out.',
        'Sirve como parte de una reposicion para articulos que marcaste bajos o agotados.',
      );
    }
    if (accessInsight.lowTravel && source != null && minutes != null) {
      return copy.choose(
        'Your local snapshot points to $source as a more realistic route, around $minutes minutes away.',
        'Tu panorama local apunta a $source como una ruta mas realista, a unos $minutes minutos.',
      );
    }
    if (accessInsight.lowTravel) {
      return copy.choose(
        'Realistic from a lower-travel food source.',
        'Realista desde una fuente de viaje mas corto.',
      );
    }
    if (accessInsight.travelBurden == TravelBurden.high) {
      if (source != null && localArea != null) {
        return copy.choose(
          'Possible, but the $localArea snapshot suggests a harder $source trip than the best nearby options.',
          'Es posible, pero el panorama de $localArea sugiere un viaje por $source mas dificil que las mejores opciones cercanas.',
        );
      }
      return copy.choose(
        'Possible, but travel burden is higher than the best nearby options.',
        'Es posible, pero la carga del viaje es mayor que la de las mejores opciones cercanas.',
      );
    }
    return null;
  }

  List<String> _accessTags(FoodAccessInsight accessInsight) {
    final copy = _copy;
    final tags = <String>[];
    if (accessInsight.source != null) {
      tags.add(copy.sourceLabel(accessInsight.source!));
    }
    if (accessInsight.source == AvailabilityContext.foodPantry) {
      tags.add(copy.choose('No purchase needed', 'Sin compra necesaria'));
    }
    if (accessInsight.snapSupport != null) {
      tags.add(accessInsight.snapSupport!.label);
    }
    if (accessInsight.wicSupport != null) {
      tags.add(accessInsight.wicSupport!.label);
    }
    if (accessInsight.pantryReadyMatches.isNotEmpty) {
      tags.add(copy.choose('Pantry match', 'Coincide con despensa'));
    }
    if (accessInsight.pantryLowMatches.isNotEmpty) {
      tags.add(copy.choose('Pantry low', 'Despensa baja'));
    }
    if (accessInsight.restockMatches.isNotEmpty) {
      tags.add(copy.choose('Restock cue', 'Pide reposicion'));
    }
    if (user.access.emergencyMode && accessInsight.emergencyFriendly) {
      tags.add(copy.choose('Emergency fit', 'Ajuste de emergencia'));
    }
    if (accessInsight.zipAware) {
      if (accessInsight.matchType == LocalAccessMatchType.exact) {
        tags.add(copy.choose('Exact ZIP', 'ZIP exacto'));
      } else if (accessInsight.matchType == LocalAccessMatchType.prefix) {
        tags.add(copy.choose('ZIP area', 'Area ZIP'));
      } else {
        tags.add(copy.choose('Fallback', 'Respaldo'));
      }
    }
    return tags;
  }

  List<DecisionFact> _decisionFacts(
    Food food,
    FoodAccessInsight accessInsight,
  ) {
    final copy = _copy;
    final facts = <DecisionFact>[
      DecisionFact(
        label: copy.choose('Cost', 'Costo'),
        value: '\$${food.costEstimate.toStringAsFixed(2)}',
      ),
    ];

    if (accessInsight.source != null) {
      facts.add(
        DecisionFact(
          label: copy.choose('Source', 'Fuente'),
          value: copy.sourceLabel(accessInsight.source!),
        ),
      );
    }

    facts.add(
      DecisionFact(
        label: copy.choose('Trip', 'Viaje'),
        value: _tripFact(accessInsight),
      ),
    );

    facts.add(
      DecisionFact(
        label: copy.choose('Benefits', 'Beneficios'),
        value: _benefitFact(accessInsight),
      ),
    );

    facts.add(
      DecisionFact(
        label: copy.choose('From home', 'Desde casa'),
        value: _homeFact(accessInsight),
      ),
    );

    facts.add(
      DecisionFact(
        label: copy.choose('Evidence', 'Evidencia'),
        value: _evidenceFact(accessInsight),
      ),
    );

    facts.add(
      DecisionFact(
        label: copy.choose('Data used', 'Datos usados'),
        value: _dataSourceFact(accessInsight),
      ),
    );

    return facts;
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

  String _travelDetail(FoodAccessInsight accessInsight) {
    final source = accessInsight.source == null
        ? _copy.choose('this source', 'esta fuente')
        : _copy.lowerSourceLabel(accessInsight.source!);
    switch (accessInsight.travelBurden) {
      case TravelBurden.low:
        return _copy.choose(
          'Matches a shorter trip through $source',
          'Encaja con un viaje mas corto por $source',
        );
      case TravelBurden.medium:
        return _copy.choose(
          'May take a fuller trip to $source',
          'Puede pedir un viaje mas largo a $source',
        );
      case TravelBurden.high:
        return _copy.choose(
          'This source may be harder to reach today',
          'Esta fuente puede ser mas dificil de alcanzar hoy',
        );
    }
  }

  String _tripFact(FoodAccessInsight accessInsight) {
    final copy = _copy;
    final minutes = accessInsight.typicalTravelMinutes;
    switch (accessInsight.travelBurden) {
      case TravelBurden.low:
        return minutes == null
            ? copy.choose('Lower trip burden', 'Viaje mas corto')
            : copy.choose(
                '$minutes min, lower burden',
                '$minutes min, menor carga',
              );
      case TravelBurden.medium:
        return minutes == null
            ? copy.choose('Medium trip burden', 'Carga media de viaje')
            : copy.choose(
                '$minutes min, medium burden',
                '$minutes min, carga media',
              );
      case TravelBurden.high:
        return minutes == null
            ? copy.choose('Harder trip today', 'Viaje mas dificil hoy')
            : copy.choose(
                '$minutes min, harder trip',
                '$minutes min, viaje mas dificil',
              );
    }
  }

  String _benefitFact(FoodAccessInsight accessInsight) {
    final copy = _copy;
    if (accessInsight.noPurchaseNeeded) {
      return copy.choose('No purchase needed', 'Sin compra necesaria');
    }

    final positiveNotes = <String>[];
    final neutralNotes = <String>[];
    final cautionNotes = <String>[];

    if (accessInsight.snapSupport != null) {
      final bucket = accessInsight.snapSupport!.positive
          ? positiveNotes
          : accessInsight.snapSupport!.neutral
          ? neutralNotes
          : cautionNotes;
      bucket.add(accessInsight.snapSupport!.label);
    }
    if (accessInsight.wicSupport != null) {
      final bucket = accessInsight.wicSupport!.positive
          ? positiveNotes
          : accessInsight.wicSupport!.neutral
          ? neutralNotes
          : cautionNotes;
      bucket.add(accessInsight.wicSupport!.label);
    }

    if (positiveNotes.isNotEmpty || neutralNotes.isNotEmpty) {
      return [...positiveNotes, ...neutralNotes, ...cautionNotes].join(' | ');
    }

    if (accessInsight.benefitsCaution) {
      return copy.choose(
        'May not be benefits-friendly',
        'Puede no servir bien con beneficios',
      );
    }
    return copy.choose(
      'No clear benefits fit',
      'Sin ajuste claro para beneficios',
    );
  }

  String _homeFact(FoodAccessInsight accessInsight) {
    final copy = _copy;
    if (accessInsight.pantryReadyMatches.isNotEmpty) {
      return copy.choose(
        'Use ${accessInsight.pantryReadyMatches.take(2).join(' + ')} first',
        'Usa primero ${accessInsight.pantryReadyMatches.take(2).join(' + ')}',
      );
    }
    if (accessInsight.pantryLowMatches.isNotEmpty) {
      return copy.choose(
        'Low on ${accessInsight.pantryLowMatches.take(2).join(' + ')}',
        'Bajo en ${accessInsight.pantryLowMatches.take(2).join(' + ')}',
      );
    }
    if (accessInsight.restockMatches.isNotEmpty) {
      return copy.choose(
        'Restock ${accessInsight.restockMatches.take(2).join(' + ')}',
        'Repone ${accessInsight.restockMatches.take(2).join(' + ')}',
      );
    }
    return copy.choose('No pantry help yet', 'Todavia sin apoyo de despensa');
  }

  String _evidenceFact(FoodAccessInsight accessInsight) {
    final copy = _copy;
    switch (accessInsight.matchType) {
      case LocalAccessMatchType.exact:
        return copy.choose(
          'Higher-confidence bundled ZIP snapshot',
          'Panorama ZIP incluido de mayor confianza',
        );
      case LocalAccessMatchType.prefix:
        return copy.choose(
          'Broader bundled ZIP-area estimate',
          'Estimacion incluida mas amplia por area ZIP',
        );
      case LocalAccessMatchType.fallback:
        return copy.choose(
          'Lower-confidence bundled fallback estimate',
          'Estimacion incluida de respaldo con menor confianza',
        );
      case null:
        return copy.choose(
          'Profile-only match',
          'Coincidencia solo del perfil',
        );
    }
  }

  String _dataSourceFact(FoodAccessInsight accessInsight) {
    final copy = _copy;
    final store = user.feasibility.groceryStore;
    if (store != null) {
      if (accessInsight.source == AvailabilityContext.grocery) {
        return copy.choose(
          'Bundled ZIP access plus live grocery prices at ${store.name}',
          'Acceso ZIP incluido mas precios de comestibles en vivo en ${store.name}',
        );
      }
      return copy.choose(
        'Bundled access model only here; live grocery prices apply only to ${store.name}',
        'Aqui solo usa el modelo de acceso incluido; los precios en vivo solo aplican a ${store.name}',
      );
    }
    if (accessInsight.zipAware) {
      return copy.choose(
        'Bundled ZIP access model only',
        'Solo modelo ZIP incluido',
      );
    }
    return copy.choose('Saved profile only', 'Solo perfil guardado');
  }
}
