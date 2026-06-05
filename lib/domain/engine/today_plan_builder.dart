import '../entities/food.dart';
import '../entities/local_access.dart';
import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/benefit_program.dart';
import 'access_advisor.dart';
import 'access_copy.dart';
import 'source_network_advisor.dart';

class TodayPlanBuilder {
  TodayPlanBuilder({
    required this.user,
    FoodAccessAdvisor? accessAdvisor,
    SourceNetworkAdvisor? sourceNetworkAdvisor,
  }) : _accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor(),
       _sourceNetworkAdvisor =
           sourceNetworkAdvisor ?? const SourceNetworkAdvisor();

  final UserConstraints user;
  final FoodAccessAdvisor _accessAdvisor;
  final SourceNetworkAdvisor _sourceNetworkAdvisor;

  AccessCopy get _copy => AccessCopy(user.access);

  TodayPlan? build({
    required List<ScoredFood> recommendations,
    required List<MealBasketPlan> baskets,
    SourceTripPlan? sourceTripPlan,
  }) {
    if (recommendations.isEmpty) {
      return null;
    }

    final inspectedFoods = recommendations
        .take(6)
        .map(
          (food) => _InspectedFood(
            food: food,
            insight: _accessAdvisor.inspect(food: food.food, user: user),
          ),
        )
        .toList(growable: false);
    final inspectedBaskets = baskets
        .map(
          (basket) => _BasketAssessment(
            basket: basket,
            itemInsights: basket.items
                .map(
                  (item) => _accessAdvisor.inspect(food: item.food, user: user),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    final restockItems = _prioritizedRestockItems(
      inspectedFoods,
      inspectedBaskets,
    );

    if (user.access.emergencyMode) {
      return _emergencyPlan(
        inspectedFoods,
        inspectedBaskets,
        restockItems,
        sourceTripPlan,
      );
    }

    final pantryBasket = inspectedBaskets.firstWhereOrNull(
      (entry) => entry.readyPantryMatches.isNotEmpty,
    );
    final pantryFood =
        pantryBasket?.readyPantryLead ??
        inspectedFoods.firstWhereOrNull(
          (entry) => entry.insight.pantryReadyMatches.isNotEmpty,
        );
    if (pantryFood != null || pantryBasket != null) {
      return _pantryPlan(
        pantryFood ?? pantryBasket!.leadFood,
        pantryBasket,
        inspectedFoods,
        restockItems,
        sourceTripPlan,
      );
    }

    if (_shouldPrioritizeRestock(restockItems)) {
      return _restockPlan(
        inspectedBaskets.firstOrNull,
        inspectedFoods,
        restockItems,
        sourceTripPlan,
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      final wicFood = inspectedFoods.where(
        (entry) => entry.insight.wicSupport?.positive ?? false,
      );
      if (wicFood.isNotEmpty) {
        return _wicPlan(
          wicFood.first,
          inspectedFoods,
          restockItems,
          sourceTripPlan,
        );
      }
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      final snapBasket = inspectedBaskets.where(
        (entry) => entry.snapSupportCount > 0,
      );
      if (snapBasket.isNotEmpty) {
        return _snapPlan(
          snapBasket.first.leadFood,
          inspectedFoods,
          restockItems: restockItems,
          basket: snapBasket.first,
          sourceTripPlan: sourceTripPlan,
        );
      }
      final snapFood = inspectedFoods.where(
        (entry) => entry.insight.snapSupport?.positive ?? false,
      );
      if (snapFood.isNotEmpty) {
        return _snapPlan(
          snapFood.first,
          inspectedFoods,
          restockItems: restockItems,
          sourceTripPlan: sourceTripPlan,
        );
      }
    }

    if (inspectedBaskets.isNotEmpty) {
      return _oneStopPlan(
        inspectedBaskets.first,
        inspectedFoods,
        restockItems,
        sourceTripPlan,
      );
    }

    return _fallbackPlan(inspectedFoods, restockItems, sourceTripPlan);
  }

  TodayPlan _emergencyPlan(
    List<_InspectedFood> foods,
    List<_BasketAssessment> baskets,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final basket = baskets
        .where((entry) => entry.emergencyFriendly)
        .cast<_BasketAssessment?>()
        .firstWhere((entry) => entry != null, orElse: () => null);
    final lead = foods
        .where((entry) => entry.insight.emergencyFriendly)
        .cast<_InspectedFood?>()
        .firstWhere((entry) => entry != null, orElse: () => foods.first)!;
    final usedBasket = basket?.basket;
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.emergency,
      fallbackSource: usedBasket?.primarySource ?? lead.insight.source,
    );
    final steps = <String>[
      if (lead.insight.pantryMatches.isNotEmpty)
        copy.choose(
          'Start with ${_listWords(lead.insight.pantryMatches.take(2).toList(growable: false))} that you already have.',
          'Empieza con ${_listWords(lead.insight.pantryMatches.take(2).toList(growable: false))} que ya tienes.',
        ),
      if (usedBasket != null)
        copy.choose(
          'Use ${_itemList(usedBasket.items)} and keep this run under \$${usedBasket.totalCost.toStringAsFixed(2)}.',
          'Usa ${_itemList(usedBasket.items)} y manten esta compra por debajo de \$${usedBasket.totalCost.toStringAsFixed(2)}.',
        )
      else
        copy.choose(
          'Choose ${lead.food.food.name} and keep this run under \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
          'Elige ${lead.food.food.name} y manten esta compra por debajo de \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
        ),
      copy.choose(
        'Skip the longest trip and favor ${preferredSource?.toLowerCase() ?? _fallbackSourceName()} today.',
        'Evita el viaje mas largo y favorece ${preferredSource?.toLowerCase() ?? _fallbackSourceName()} hoy.',
      ),
    ];

    return TodayPlan(
      type: TodayPlanType.emergency,
      title: copy.choose(
        'Today plan: emergency fallback',
        'Plan de hoy: respaldo de emergencia',
      ),
      summary: copy.choose(
        'Use the fastest low-travel option, buy the cheapest safe item first, and keep a backup ready.',
        'Usa la opcion mas rapida y de menor viaje, compra primero el articulo seguro mas barato y deja un respaldo listo.',
      ),
      steps: steps,
      highlights: <String>[
        copy.choose('Emergency mode', 'Modo de emergencia'),
        if (usedBasket != null)
          '\$${usedBasket.totalCost.toStringAsFixed(2)} total',
        if (lead.insight.snapSupport != null) lead.insight.snapSupport!.label,
      ],
      leadRecommendation: lead.food,
      basket: usedBasket,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.emergency,
      ),
      restockItems: _limitedRestockItems(restockItems, limit: 2),
      purchases: _buildPurchases(
        type: TodayPlanType.emergency,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: usedBasket,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.emergency,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: usedBasket,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.emergency,
        lead: lead,
        basket: usedBasket,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.emergency,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  TodayPlan _pantryPlan(
    _InspectedFood lead,
    _BasketAssessment? basket,
    List<_InspectedFood> foods,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final pantryItems = _pantryStepItems(lead: lead, basket: basket?.basket);
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.pantryStretch,
      fallbackSource: basket?.basket.primarySource ?? lead.insight.source,
    );
    final basketCostHighlight = basket == null
        ? null
        : '\$${basket.basket.totalCost.toStringAsFixed(2)} total';
    final addOnItems = basket == null
        ? const <ScoredFood>[]
        : basket.basket.items
              .where((item) => item.food.id != lead.food.food.id)
              .take(3)
              .toList(growable: false);
    final steps = <String>[
      pantryItems.isEmpty
          ? copy.choose(
              'Start with what you already have at home first.',
              'Empieza primero con lo que ya tienes en casa.',
            )
          : copy.choose(
              'Use ${_listWords(pantryItems)} from home first.',
              'Usa primero ${_listWords(pantryItems)} desde casa.',
            ),
      if (basket != null && addOnItems.isNotEmpty)
        copy.choose(
          'Buy only ${_itemList(addOnItems)} from ${preferredSource?.toLowerCase() ?? basket.primarySourceLabel.toLowerCase()}.',
          'Compra solo ${_itemList(addOnItems)} desde ${preferredSource?.toLowerCase() ?? basket.primarySourceLabel.toLowerCase()}.',
        )
      else
        copy.choose(
          'Buy only 1 to 3 add-ons from ${preferredSource?.toLowerCase() ?? _nearestSourceName()}.',
          'Compra solo 1 a 3 extras desde ${preferredSource?.toLowerCase() ?? _nearestSourceName()}.',
        ),
      if (restockItems.isNotEmpty)
        copy.choose(
          'If you can, restock ${_wordList(restockItems)} before the next larger meal.',
          'Si puedes, repone ${_wordList(restockItems)} antes de la siguiente comida grande.',
        ),
      copy.choose(
        'Keep the total low before opening a larger shopping trip.',
        'Mantiene el total bajo antes de abrir una compra mas grande.',
      ),
    ];

    return TodayPlan(
      type: TodayPlanType.pantryFirst,
      title: copy.choose(
        'Today plan: pantry-first',
        'Plan de hoy: primero la despensa',
      ),
      summary: copy.choose(
        'Stretch food you already have before spending on a full restock.',
        'Rinde la comida que ya tienes antes de gastar en una reposicion completa.',
      ),
      steps: steps,
      highlights: <String>[
        copy.choose('Pantry-first', 'Primero la despensa'),
        ?basketCostHighlight,
        ?preferredSource,
      ],
      leadRecommendation: lead.food,
      basket: basket?.basket,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.pantryFirst,
      ),
      restockItems: _limitedRestockItems(restockItems),
      purchases: _buildPurchases(
        type: TodayPlanType.pantryFirst,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: basket?.basket,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.pantryFirst,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: basket?.basket,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.pantryFirst,
        lead: lead,
        basket: basket?.basket,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.pantryFirst,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  TodayPlan _restockPlan(
    _BasketAssessment? basket,
    List<_InspectedFood> foods,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final lead = basket?.leadFood ?? foods.first;
    final sourceLabel = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.restock,
      fallbackSource: basket?.basket.primarySource ?? lead.insight.source,
      fallbackLabel: basket?.primarySourceLabel,
    );
    final sourceStep = sourceLabel == null
        ? null
        : copy.choose(
            'Favor ${sourceLabel.toLowerCase()} so the restock stays realistic for today.',
            'Favorece ${sourceLabel.toLowerCase()} para que la reposicion siga siendo realista hoy.',
          );
    return TodayPlan(
      type: TodayPlanType.restockRun,
      title: copy.choose(
        'Today plan: staple restock',
        'Plan de hoy: reposicion de basicos',
      ),
      summary: copy.choose(
        'Refill the staples you marked low or out so the next meal does not start from zero.',
        'Repone los basicos que marcaste bajos o agotados para que la siguiente comida no empiece desde cero.',
      ),
      steps: [
        copy.choose(
          'Restock ${_wordList(restockItems)} first.',
          'Repone primero ${_wordList(restockItems)}.',
        ),
        if (user.access.benefitPrograms.contains(BenefitProgram.snap))
          copy.choose(
            'Use SNAP on staple items before adding higher-cost extras.',
            'Usa SNAP en articulos basicos antes de agregar extras mas caros.',
          )
        else if (user.access.benefitPrograms.contains(BenefitProgram.wic))
          copy.choose(
            'Start with WIC staples where they overlap your restock list.',
            'Empieza con basicos de WIC cuando coincidan con tu lista de reposicion.',
          )
        else
          copy.choose(
            'Keep the trip focused on the lowest-cost basics first.',
            'Mantiene el viaje enfocado primero en los basicos de menor costo.',
          ),
        if (basket != null)
          copy.choose(
            'Build today\'s meal around ${_itemList(basket.basket.items)} so one trip covers both dinner and pantry basics.',
            'Arma la comida de hoy alrededor de ${_itemList(basket.basket.items)} para que un viaje cubra la comida y la despensa.',
          )
        else
          copy.choose(
            'Once the basics are covered, start with ${lead.food.food.name}.',
            'Cuando los basicos esten cubiertos, empieza con ${lead.food.food.name}.',
          ),
        ?sourceStep,
      ],
      highlights: <String>[
        copy.choose('Restock', 'Reposicion'),
        if (user.access.benefitPrograms.contains(BenefitProgram.snap))
          copy.choose('SNAP-aware', 'Con SNAP'),
        if (user.access.benefitPrograms.contains(BenefitProgram.wic))
          copy.choose('WIC-aware', 'Con WIC'),
        ?sourceLabel,
      ],
      leadRecommendation: lead.food,
      basket: basket?.basket,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.restockRun,
      ),
      restockItems: _limitedRestockItems(restockItems, limit: 4),
      purchases: _buildPurchases(
        type: TodayPlanType.restockRun,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: basket?.basket,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.restockRun,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: basket?.basket,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.restockRun,
        lead: lead,
        basket: basket?.basket,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.restockRun,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  TodayPlan _wicPlan(
    _InspectedFood lead,
    List<_InspectedFood> foods,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final wicSupport = lead.insight.wicSupport;
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.benefitsRun,
      fallbackSource: lead.insight.source,
    );
    return TodayPlan(
      type: TodayPlanType.wicStaples,
      title: copy.choose(
        'Today plan: WIC staples run',
        'Plan de hoy: compra de basicos WIC',
      ),
      summary: copy.choose(
        'Start with likely WIC staples, then add only one extra item if budget allows.',
        'Empieza con posibles basicos WIC y agrega solo un extra si el presupuesto alcanza.',
      ),
      steps: [
        copy.choose(
          'Look for a WIC-approved version of ${lead.food.food.name}.',
          'Busca una version aprobada por WIC de ${lead.food.food.name}.',
        ),
        if (wicSupport != null) wicSupport.detail,
        if (restockItems.isNotEmpty)
          copy.choose(
            'If budget allows, restock ${_wordList(restockItems)} after the WIC basics.',
            'Si el presupuesto alcanza, repone ${_wordList(restockItems)} despues de los basicos WIC.',
          ),
        copy.choose(
          'Add a non-WIC backup only if you still have room in today\'s budget.',
          'Agrega un respaldo fuera de WIC solo si todavia queda dinero hoy.',
        ),
      ],
      highlights: <String>[
        copy.choose('WIC-aware', 'Con WIC'),
        ?preferredSource,
        if (wicSupport != null) wicSupport.label,
      ],
      leadRecommendation: lead.food,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.wicStaples,
      ),
      restockItems: _limitedRestockItems(restockItems),
      purchases: _buildPurchases(
        type: TodayPlanType.wicStaples,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.wicStaples,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.wicStaples,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.wicStaples,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  TodayPlan _snapPlan(
    _InspectedFood lead,
    List<_InspectedFood> foods, {
    required List<String> restockItems,
    _BasketAssessment? basket,
    SourceTripPlan? sourceTripPlan,
  }) {
    final copy = _copy;
    final snapSupport = lead.insight.snapSupport;
    final usedBasket = basket?.basket;
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.benefitsRun,
      fallbackSource: usedBasket?.primarySource ?? lead.insight.source,
    );
    return TodayPlan(
      type: TodayPlanType.snapRun,
      title: copy.choose(
        'Today plan: SNAP-aware run',
        'Plan de hoy: compra con SNAP',
      ),
      summary: copy.choose(
        'Favor likely SNAP staples and avoid turning this into a more expensive restaurant stop.',
        'Favorece basicos probables de SNAP y evita convertir esto en una parada de restaurante mas cara.',
      ),
      steps: [
        if (usedBasket != null)
          copy.choose(
            'Use SNAP for ${_itemList(usedBasket.items)} in one stop at ${preferredSource?.toLowerCase() ?? _bestNearbySourceName()}.',
            'Usa SNAP para ${_itemList(usedBasket.items)} en una sola parada en ${preferredSource?.toLowerCase() ?? _bestNearbySourceName()}.',
          )
        else
          copy.choose(
            'Start with ${lead.food.food.name} as your likely SNAP staple.',
            'Empieza con ${lead.food.food.name} como posible basico de SNAP.',
          ),
        if (snapSupport != null) snapSupport.detail,
        if (restockItems.isNotEmpty)
          copy.choose(
            'Restock ${_wordList(restockItems)} before moving to higher-cost extras.',
            'Repone ${_wordList(restockItems)} antes de pasar a extras mas caros.',
          ),
        copy.choose(
          'If the exact item is missing, swap to another staple with a similar cost and prep burden.',
          'Si falta el articulo exacto, cambia a otro basico con costo y preparacion parecidos.',
        ),
      ],
      highlights: <String>[
        copy.choose('SNAP-aware', 'Con SNAP'),
        if (usedBasket != null)
          '\$${usedBasket.totalCost.toStringAsFixed(2)} total',
        if (snapSupport != null) snapSupport.label,
      ],
      leadRecommendation: lead.food,
      basket: usedBasket,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.snapRun,
      ),
      restockItems: _limitedRestockItems(restockItems),
      purchases: _buildPurchases(
        type: TodayPlanType.snapRun,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: usedBasket,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.snapRun,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
        basket: usedBasket,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.snapRun,
        lead: lead,
        basket: usedBasket,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.snapRun,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  TodayPlan _oneStopPlan(
    _BasketAssessment basket,
    List<_InspectedFood> foods,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.oneStopMeal,
      fallbackSource: basket.basket.primarySource,
      fallbackLabel: basket.primarySourceLabel,
    );
    return TodayPlan(
      type: TodayPlanType.oneStop,
      title: copy.choose(
        'Today plan: one-stop basket',
        'Plan de hoy: canasta de una parada',
      ),
      summary: copy.choose(
        'Take the shortest realistic trip and get the full meal in one stop.',
        'Haz el viaje realista mas corto y resuelve toda la comida en una sola parada.',
      ),
      steps: [
        copy.choose(
          'Go to ${preferredSource ?? basket.primarySourceLabel}.',
          'Ve a ${preferredSource ?? basket.primarySourceLabel}.',
        ),
        copy.choose(
          'Pick ${_itemList(basket.basket.items)}.',
          'Lleva ${_itemList(basket.basket.items)}.',
        ),
        if (restockItems.isNotEmpty)
          copy.choose(
            'If budget allows, add ${_wordList(restockItems)} while you are there.',
            'Si el presupuesto alcanza, agrega ${_wordList(restockItems)} mientras estas ahi.',
          ),
        copy.choose(
          'Stop once the basket is complete so the total stays near \$${basket.basket.totalCost.toStringAsFixed(2)}.',
          'Detente cuando la canasta este completa para que el total quede cerca de \$${basket.basket.totalCost.toStringAsFixed(2)}.',
        ),
      ],
      highlights: <String>[
        copy.choose('One stop', 'Una parada'),
        preferredSource ?? basket.primarySourceLabel,
        '\$${basket.basket.totalCost.toStringAsFixed(2)} total',
      ],
      leadRecommendation: basket.leadFood.food,
      basket: basket.basket,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.oneStop,
      ),
      restockItems: _limitedRestockItems(restockItems),
      purchases: _buildPurchases(
        type: TodayPlanType.oneStop,
        lead: basket.leadFood,
        foods: foods,
        restockItems: restockItems,
        basket: basket.basket,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.oneStop,
        lead: basket.leadFood,
        foods: foods,
        restockItems: restockItems,
        basket: basket.basket,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.oneStop,
        lead: basket.leadFood,
        basket: basket.basket,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.oneStop,
        lead: basket.leadFood,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: basket.leadFood,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: basket.leadFood,
      ),
    );
  }

  TodayPlan _fallbackPlan(
    List<_InspectedFood> foods,
    List<String> restockItems,
    SourceTripPlan? sourceTripPlan,
  ) {
    final copy = _copy;
    final lead = foods.first;
    final preferredSource = _preferredSourceLabel(
      sourceTripPlan: sourceTripPlan,
      mission: SourceTripMission.fallback,
      fallbackSource: lead.insight.source,
    );
    return TodayPlan(
      type: TodayPlanType.fallback,
      title: copy.choose(
        'Today plan: simplest safe option',
        'Plan de hoy: opcion segura mas simple',
      ),
      summary: copy.choose(
        'Use the top safe option now, then widen constraints only if you still need more choices.',
        'Usa ahora la opcion segura principal y amplia reglas solo si aun necesitas mas opciones.',
      ),
      steps: [
        copy.choose(
          'Start with ${lead.food.food.name}.',
          'Empieza con ${lead.food.food.name}.',
        ),
        copy.choose(
          'Keep the spend near \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
          'Mantiene el gasto cerca de \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
        ),
        copy.choose(
          'If it is unavailable, switch to the next closest option instead of restarting the full search.',
          'Si no esta disponible, cambia a la siguiente opcion cercana en vez de reiniciar toda la busqueda.',
        ),
      ],
      highlights: <String>[
        copy.choose('Fallback', 'Respaldo'),
        ?preferredSource,
      ],
      leadRecommendation: lead.food,
      backupAction: _backupAction(
        foods.skip(1).toList(),
        type: TodayPlanType.fallback,
      ),
      restockItems: _limitedRestockItems(restockItems),
      purchases: _buildPurchases(
        type: TodayPlanType.fallback,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
      ),
      checkpoints: _buildCheckpoints(
        type: TodayPlanType.fallback,
        lead: lead,
        foods: foods,
        restockItems: restockItems,
      ),
      routeReason: _planRouteReason(
        type: TodayPlanType.fallback,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      benefitSummary: _planBenefitSummary(
        type: TodayPlanType.fallback,
        lead: lead,
        sourceTripPlan: sourceTripPlan,
      ),
      confidenceSummary: _planConfidenceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
      dataSourceSummary: _planDataSourceSummary(
        sourceTripPlan: sourceTripPlan,
        lead: lead,
      ),
    );
  }

  String _planRouteReason({
    required TodayPlanType type,
    required _InspectedFood lead,
    SourceTripPlan? sourceTripPlan,
    MealBasketPlan? basket,
  }) {
    final sourceReason = _tripPlanForType(
      type: type,
      sourceTripPlan: sourceTripPlan,
    )?.routeReason?.trim();
    if (sourceReason != null && sourceReason.isNotEmpty) {
      return sourceReason;
    }

    switch (type) {
      case TodayPlanType.emergency:
        return _copy.choose(
          'This keeps the first stop fast, the first buy cheap, and the backup simple.',
          'Esto mantiene rapida la primera parada, barata la primera compra y simple el respaldo.',
        );
      case TodayPlanType.pantryFirst:
        return _copy.choose(
          'This is more realistic because it uses food from home first, then asks for only a few add-ons.',
          'Esto es mas realista porque usa primero comida de casa y luego pide solo unos pocos extras.',
        );
      case TodayPlanType.restockRun:
        return _copy.choose(
          'This is more realistic because it refills the basics before a larger shopping trip.',
          'Esto es mas realista porque repone los basicos antes de una compra mas grande.',
        );
      case TodayPlanType.wicStaples:
        return _copy.choose(
          'This is more realistic because it puts likely WIC staples ahead of weaker fallback buys.',
          'Esto es mas realista porque pone los posibles basicos WIC por delante de compras de respaldo mas debiles.',
        );
      case TodayPlanType.snapRun:
        return _copy.choose(
          'This is more realistic because it puts likely SNAP staples ahead of higher-cost extras.',
          'Esto es mas realista porque pone los posibles basicos SNAP por delante de extras mas caros.',
        );
      case TodayPlanType.oneStop:
        return basket == null
            ? _copy.choose(
                'This is more realistic because it keeps the trip to one practical stop.',
                'Esto es mas realista porque mantiene el viaje en una sola parada practica.',
              )
            : _copy.choose(
                'This is more realistic because one stop can still cover about ${basket.estimatedMealsCovered} meal${basket.estimatedMealsCovered == 1 ? '' : 's'}.',
                'Esto es mas realista porque una sola parada todavia puede cubrir unas ${basket.estimatedMealsCovered} comida${basket.estimatedMealsCovered == 1 ? '' : 's'}.',
              );
      case TodayPlanType.fallback:
        return _copy.choose(
          'This keeps ${lead.food.food.name} as the safest low-burden option still left on the board.',
          'Esto mantiene ${lead.food.food.name} como la opcion segura de menor carga que todavia queda disponible.',
        );
    }
  }

  String? _planBenefitSummary({
    required TodayPlanType type,
    required _InspectedFood lead,
    required SourceTripPlan? sourceTripPlan,
  }) {
    final tripSummary = _tripPlanForType(
      type: type,
      sourceTripPlan: sourceTripPlan,
    )?.benefitSummary?.trim();
    if (tripSummary != null && tripSummary.isNotEmpty) {
      return tripSummary;
    }
    if (lead.insight.noPurchaseNeeded) {
      return _copy.choose(
        'No purchase is needed if this pantry item is there today.',
        'No hace falta comprar si este articulo de despensa esta hoy disponible.',
      );
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        lead.insight.wicSupport != null) {
      return lead.insight.wicSupport!.detail;
    }
    if (user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        lead.insight.snapSupport != null) {
      return lead.insight.snapSupport!.detail;
    }
    if (type == TodayPlanType.pantryFirst &&
        lead.insight.pantryReadyMatches.isNotEmpty) {
      return _copy.choose(
        'Using food from home first lowers the amount you still need to buy.',
        'Usar primero comida de casa baja lo que todavia necesitas comprar.',
      );
    }
    return null;
  }

  String? _planConfidenceSummary({
    required SourceTripPlan? sourceTripPlan,
    required _InspectedFood lead,
  }) {
    final tripSummary = sourceTripPlan?.confidenceSummary?.trim();
    if (tripSummary != null && tripSummary.isNotEmpty) {
      return tripSummary;
    }
    switch (lead.insight.matchType) {
      case LocalAccessMatchType.exact:
        return _copy.choose(
          'Higher-confidence access read because this plan is using an exact bundled ZIP match.',
          'Lectura de acceso de mayor confianza porque este plan usa un ZIP incluido exacto.',
        );
      case LocalAccessMatchType.prefix:
        return _copy.choose(
          'Moderate-confidence access read because this plan uses a broader bundled ZIP-area estimate.',
          'Lectura de acceso de confianza media porque este plan usa una estimacion incluida mas amplia por area ZIP.',
        );
      case LocalAccessMatchType.fallback:
        return _copy.choose(
          'Lower-confidence access read because this plan falls back to the general bundled low-resource model.',
          'Lectura de acceso de menor confianza porque este plan cae al modelo general incluido de pocos recursos.',
        );
      case null:
        return null;
    }
  }

  String _planDataSourceSummary({
    required SourceTripPlan? sourceTripPlan,
    required _InspectedFood lead,
  }) {
    final tripSummary = sourceTripPlan?.dataSourceSummary?.trim();
    if (tripSummary != null && tripSummary.isNotEmpty) {
      return tripSummary;
    }
    final store = user.feasibility.groceryStore;
    if (store != null) {
      return _copy.choose(
        'Access burden still uses bundled ZIP data. Live grocery brands and prices only apply to ${store.name}.',
        'La carga de acceso todavia usa datos ZIP incluidos. Las marcas y precios de comestibles en vivo solo aplican a ${store.name}.',
      );
    }
    if (lead.insight.zipAware) {
      return _copy.choose(
        'Access burden here uses bundled ZIP access data, not live store inventory.',
        'La carga de acceso aqui usa datos ZIP incluidos, no inventario en vivo de tiendas.',
      );
    }
    return _copy.choose(
      'This plan is driven by your saved setup, not live inventory.',
      'Este plan se guia por tu configuracion guardada, no por inventario en vivo.',
    );
  }

  String? _preferredSourceLabel({
    required SourceTripPlan? sourceTripPlan,
    required SourceTripMission mission,
    AvailabilityContext? fallbackSource,
    String? fallbackLabel,
  }) {
    if (sourceTripPlan != null && sourceTripPlan.mission == mission) {
      return _copy.sourceLabel(sourceTripPlan.primarySource);
    }
    if (fallbackSource != null) {
      return _copy.sourceLabel(fallbackSource);
    }
    if (fallbackLabel != null) {
      return fallbackLabel;
    }
    final bestSource = _sourceNetworkAdvisor.bestSourceForMission(
      candidates: user.feasibility.availability,
      mission: mission,
      user: user,
      resolution: _sourceNetworkAdvisor.catalog?.resolve(
        user.access.postalCode,
      ),
    );
    return bestSource == null ? null : _copy.sourceLabel(bestSource);
  }

  List<String> _prioritizedRestockItems(
    List<_InspectedFood> foods,
    List<_BasketAssessment> baskets,
  ) {
    final priority = <String, double>{};

    void bump(Iterable<String> items, double value) {
      for (final item in items) {
        priority[item] = (priority[item] ?? 0) + value;
      }
    }

    for (final food in foods.take(3)) {
      bump(food.insight.restockMatches, 3);
      bump(food.insight.pantryLowMatches, 2);
    }
    for (final basket in baskets.take(2)) {
      bump(basket.restockMatches, 2.5);
      bump(basket.lowPantryMatches, 1.5);
    }
    bump(user.pantry.restockItems, 1);
    bump(user.pantry.lowStockItems, 0.5);

    final sorted = priority.entries.toList()
      ..sort((left, right) {
        final byScore = right.value.compareTo(left.value);
        if (byScore != 0) {
          return byScore;
        }
        return left.key.compareTo(right.key);
      });

    return sorted.map((entry) => entry.key).take(4).toList(growable: false);
  }

  bool _shouldPrioritizeRestock(List<String> restockItems) {
    if (restockItems.isEmpty) {
      return false;
    }
    final severeOutage = user.pantry.restockItems.length >= 2;
    final broadShortage =
        user.pantry.restockItems.length + user.pantry.lowStockItems.length >= 3;
    if (severeOutage) {
      return true;
    }
    if (user.access.benefitPrograms.isNotEmpty) {
      return broadShortage && user.pantry.enoughItems.length <= 1;
    }
    if (user.pantry.enoughItems.length <= 2) {
      return true;
    }
    return broadShortage;
  }

  SourceTripPlan? _tripPlanForType({
    required TodayPlanType type,
    required SourceTripPlan? sourceTripPlan,
  }) {
    if (sourceTripPlan == null) {
      return null;
    }
    final expectedMission = switch (type) {
      TodayPlanType.emergency => SourceTripMission.emergency,
      TodayPlanType.pantryFirst => SourceTripMission.pantryStretch,
      TodayPlanType.restockRun => SourceTripMission.restock,
      TodayPlanType.wicStaples ||
      TodayPlanType.snapRun => SourceTripMission.benefitsRun,
      TodayPlanType.oneStop => SourceTripMission.oneStopMeal,
      TodayPlanType.fallback => SourceTripMission.fallback,
    };
    return sourceTripPlan.mission == expectedMission ? sourceTripPlan : null;
  }

  List<PlannedPurchase> _buildPurchases({
    required TodayPlanType type,
    required _InspectedFood lead,
    required List<_InspectedFood> foods,
    required List<String> restockItems,
    MealBasketPlan? basket,
  }) {
    final selectedFoods = _selectedPurchaseFoods(
      type: type,
      lead: lead,
      foods: foods,
      basket: basket,
    );
    final purchases = <PlannedPurchase>[
      for (final item in _restockPurchases(type, restockItems)) item,
    ];
    final seenLabels = purchases
        .map((item) => item.label.trim().toLowerCase())
        .toSet();

    for (final entry in selectedFoods) {
      if (entry.insight.source == AvailabilityContext.foodPantry) {
        continue;
      }
      final label = entry.food.food.name;
      final normalized = label.trim().toLowerCase();
      if (seenLabels.contains(normalized)) {
        continue;
      }
      purchases.add(
        PlannedPurchase(
          label: label,
          priority: _purchasePriority(type: type, lead: lead, entry: entry),
          detail: _purchaseDetail(type: type, lead: lead, entry: entry),
          estimatedCost: entry.food.food.costEstimate,
        ),
      );
      seenLabels.add(normalized);
    }

    purchases.sort((left, right) {
      final byPriority = _priorityOrder(
        left.priority,
      ).compareTo(_priorityOrder(right.priority));
      if (byPriority != 0) {
        return byPriority;
      }
      final leftCost = left.estimatedCost ?? 0;
      final rightCost = right.estimatedCost ?? 0;
      final byCost = leftCost.compareTo(rightCost);
      if (byCost != 0) {
        return byCost;
      }
      return left.label.compareTo(right.label);
    });

    return purchases.take(5).toList(growable: false);
  }

  List<_InspectedFood> _selectedPurchaseFoods({
    required TodayPlanType type,
    required _InspectedFood lead,
    required List<_InspectedFood> foods,
    required MealBasketPlan? basket,
  }) {
    if (basket == null) {
      return [
        lead,
        ...foods
            .where((entry) => entry.food.food.id != lead.food.food.id)
            .take(2),
      ];
    }

    final selected = <_InspectedFood>[];
    for (final item in basket.items) {
      final existing = foods.where(
        (entry) => entry.food.food.id == item.food.id,
      );
      selected.add(
        existing.isEmpty
            ? _InspectedFood(
                food: item,
                insight: _accessAdvisor.inspect(food: item.food, user: user),
              )
            : existing.first,
      );
    }

    if (type == TodayPlanType.pantryFirst) {
      return selected
          .where((entry) => entry.food.food.id != lead.food.food.id)
          .toList(growable: false);
    }

    if (selected.length < 3 &&
        (type == TodayPlanType.snapRun ||
            type == TodayPlanType.emergency ||
            type == TodayPlanType.wicStaples ||
            type == TodayPlanType.restockRun)) {
      final selectedIds = selected.map((entry) => entry.food.food.id).toSet();
      selected.addAll(
        foods
            .where((entry) => !selectedIds.contains(entry.food.food.id))
            .take(3 - selected.length),
      );
    }

    return selected;
  }

  List<PlannedPurchase> _restockPurchases(
    TodayPlanType type,
    List<String> restockItems,
  ) {
    if (restockItems.isEmpty) {
      return const [];
    }

    final limit = switch (type) {
      TodayPlanType.restockRun => 4,
      TodayPlanType.snapRun || TodayPlanType.wicStaples => 3,
      _ => 2,
    };
    return _limitedRestockItems(restockItems, limit: limit)
        .map(
          (item) => PlannedPurchase(
            label: item,
            priority: switch (type) {
              TodayPlanType.restockRun ||
              TodayPlanType.snapRun => PlannedPurchasePriority.buyFirst,
              _ => PlannedPurchasePriority.ifBudgetLeft,
            },
            detail: switch (type) {
              TodayPlanType.wicStaples => _copy.choose(
                'Restock only after the core WIC staples are covered.',
                'Repone esto solo despues de cubrir los basicos WIC.',
              ),
              TodayPlanType.pantryFirst => _copy.choose(
                'Restock this only after the pantry-based meal is covered.',
                'Repone esto solo despues de cubrir la comida basada en despensa.',
              ),
              TodayPlanType.snapRun => _copy.choose(
                'Use benefits on the basic staple items first.',
                'Usa los beneficios primero en los articulos basicos.',
              ),
              TodayPlanType.emergency => _copy.choose(
                'Only restock this if the first low-burden meal is already covered.',
                'Repone esto solo si la primera comida de baja carga ya esta cubierta.',
              ),
              TodayPlanType.oneStop => _copy.choose(
                'Add this only if the basket still fits today\'s budget.',
                'Agrega esto solo si la canasta todavia cabe en el presupuesto de hoy.',
              ),
              TodayPlanType.fallback => _copy.choose(
                'Add this only if the first safe option still leaves room.',
                'Agrega esto solo si la primera opcion segura todavia deja margen.',
              ),
              _ => _copy.choose(
                'Basic pantry staple to restock first.',
                'Basico de despensa para reponer primero.',
              ),
            },
          ),
        )
        .toList(growable: false);
  }

  PlannedPurchasePriority _purchasePriority({
    required TodayPlanType type,
    required _InspectedFood lead,
    required _InspectedFood entry,
  }) {
    final food = entry.food.food;
    final isLead = food.id == lead.food.food.id;
    final stapleLike = _looksStapleLike(food);
    final snapPositive = entry.insight.snapSupport?.positive ?? false;
    final snapCaution = entry.insight.snapSupport?.caution ?? false;
    final wicPositive = entry.insight.wicSupport?.positive ?? false;
    final wicCaution = entry.insight.wicSupport?.caution ?? false;
    final highBudgetShare = _budgetShare(food.costEstimate) >= 0.45;

    switch (type) {
      case TodayPlanType.emergency:
        if (isLead || entry.insight.emergencyFriendly) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (snapCaution || wicCaution || highBudgetShare) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.pantryFirst:
        if (snapPositive || wicPositive || stapleLike) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (highBudgetShare && !stapleLike) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.restockRun:
        if (snapCaution || wicCaution) {
          return PlannedPurchasePriority.skipFirst;
        }
        if (stapleLike || snapPositive || wicPositive) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (highBudgetShare && !stapleLike) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.wicStaples:
        if (wicCaution) {
          return PlannedPurchasePriority.skipFirst;
        }
        if (wicPositive) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (highBudgetShare) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.snapRun:
        if (snapCaution) {
          return PlannedPurchasePriority.skipFirst;
        }
        if (snapPositive || stapleLike) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (highBudgetShare && !stapleLike) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.oneStop:
        if (isLead || (stapleLike && !highBudgetShare)) {
          return PlannedPurchasePriority.buyFirst;
        }
        if (snapCaution || wicCaution || highBudgetShare) {
          return PlannedPurchasePriority.skipFirst;
        }
        return PlannedPurchasePriority.ifBudgetLeft;
      case TodayPlanType.fallback:
        return isLead
            ? PlannedPurchasePriority.buyFirst
            : PlannedPurchasePriority.ifBudgetLeft;
    }
  }

  String? _purchaseDetail({
    required TodayPlanType type,
    required _InspectedFood lead,
    required _InspectedFood entry,
  }) {
    final food = entry.food.food;
    final isLead = food.id == lead.food.food.id;
    final stapleLike = _looksStapleLike(food);
    if (isLead) {
      if (entry.insight.noPurchaseNeeded) {
        return _copy.choose(
          'Start here. No purchase needed if stock is there today.',
          'Empieza aqui. No hace falta comprar si hay stock hoy.',
        );
      }
      final support = (entry.insight.wicSupport?.positive ?? false)
          ? entry.insight.wicSupport
          : (entry.insight.snapSupport?.positive ?? false)
          ? entry.insight.snapSupport
          : (entry.insight.snapSupport?.neutral ?? false)
          ? entry.insight.snapSupport
          : (entry.insight.wicSupport?.caution ?? false)
          ? entry.insight.wicSupport
          : entry.insight.snapSupport;
      if (support != null) {
        return '${_copy.choose('Start here.', 'Empieza aqui.')} ${support.detail}';
      }
      return _copy.choose('Start here.', 'Empieza aqui.');
    }
    if (entry.insight.wicSupport?.positive ?? false) {
      return entry.insight.wicSupport!.detail;
    }
    if (entry.insight.snapSupport?.positive ?? false) {
      return entry.insight.snapSupport!.detail;
    }
    if (entry.insight.snapSupport?.caution ?? false) {
      return entry.insight.snapSupport!.detail;
    }
    if (entry.insight.wicSupport?.caution ?? false) {
      return entry.insight.wicSupport!.detail;
    }
    if (entry.insight.snapSupport?.neutral ?? false) {
      return entry.insight.snapSupport!.detail;
    }
    if (type == TodayPlanType.restockRun && stapleLike) {
      return _copy.choose(
        'Useful shelf-stable staple.',
        'Basico util y estable en anaquel.',
      );
    }
    if (_budgetShare(food.costEstimate) >= 0.45) {
      return _copy.choose(
        'Higher-cost extra for this budget.',
        'Extra de costo alto para este presupuesto.',
      );
    }
    if (entry.insight.pantryLowMatches.isNotEmpty) {
      return _copy.choose(
        'Pairs with food you marked low at home.',
        'Combina con comida que marcaste baja en casa.',
      );
    }
    if (stapleLike) {
      return _copy.choose(
        'Lower-risk staple if stock is limited.',
        'Basico de menor riesgo si el stock es limitado.',
      );
    }
    return null;
  }

  int _priorityOrder(PlannedPurchasePriority priority) {
    switch (priority) {
      case PlannedPurchasePriority.buyFirst:
        return 0;
      case PlannedPurchasePriority.ifBudgetLeft:
        return 1;
      case PlannedPurchasePriority.skipFirst:
        return 2;
    }
  }

  List<PlanCheckpoint> _buildCheckpoints({
    required TodayPlanType type,
    required _InspectedFood lead,
    required List<_InspectedFood> foods,
    required List<String> restockItems,
    MealBasketPlan? basket,
  }) {
    return [
      PlanCheckpoint(
        title: _copy.choose('Now', 'Ahora'),
        detail: _nowCheckpointDetail(
          type: type,
          lead: lead,
          basket: basket,
          restockItems: restockItems,
        ),
      ),
      PlanCheckpoint(
        title: _copy.choose('Next meal', 'Siguiente comida'),
        detail: _nextMealCheckpointDetail(
          type: type,
          lead: lead,
          foods: foods,
          basket: basket,
          restockItems: restockItems,
        ),
      ),
      PlanCheckpoint(
        title: _copy.choose('After that', 'Despues'),
        detail: _afterThatCheckpointDetail(
          type: type,
          lead: lead,
          foods: foods,
          restockItems: restockItems,
        ),
      ),
    ];
  }

  String _nowCheckpointDetail({
    required TodayPlanType type,
    required _InspectedFood lead,
    required MealBasketPlan? basket,
    required List<String> restockItems,
  }) {
    final basketItems = basket == null ? null : _itemList(basket.items);
    switch (type) {
      case TodayPlanType.emergency:
        return basketItems == null
            ? _copy.choose(
                'Use ${lead.food.food.name} right away.',
                'Usa ${lead.food.food.name} de inmediato.',
              )
            : _copy.choose(
                'Use $basketItems right away.',
                'Usa $basketItems de inmediato.',
              );
      case TodayPlanType.pantryFirst:
        final pantryItems = _pantryStepItems(lead: lead, basket: basket);
        if (pantryItems.isNotEmpty) {
          return _copy.choose(
            'Start with ${_listWords(pantryItems)} from home.',
            'Empieza con ${_listWords(pantryItems)} desde casa.',
          );
        }
        return _copy.choose(
          'Start with ${lead.food.food.name}.',
          'Empieza con ${lead.food.food.name}.',
        );
      case TodayPlanType.restockRun:
        return _copy.choose(
          'Restock ${_wordList(_limitedRestockItems(restockItems, limit: 2))} first on this trip.',
          'Repone primero ${_wordList(_limitedRestockItems(restockItems, limit: 2))} en este viaje.',
        );
      case TodayPlanType.wicStaples:
        return _copy.choose(
          'Start with a WIC-approved version of ${lead.food.food.name}.',
          'Empieza con una version aprobada por WIC de ${lead.food.food.name}.',
        );
      case TodayPlanType.snapRun:
        return basketItems == null
            ? _copy.choose(
                'Buy ${lead.food.food.name} first with SNAP.',
                'Compra primero ${lead.food.food.name} con SNAP.',
              )
            : _copy.choose(
                'Buy $basketItems first with SNAP.',
                'Compra primero $basketItems con SNAP.',
              );
      case TodayPlanType.oneStop:
        return _copy.choose(
          'Pick up ${basketItems ?? lead.food.food.name} in one stop.',
          'Lleva ${basketItems ?? lead.food.food.name} en una sola parada.',
        );
      case TodayPlanType.fallback:
        return _copy.choose(
          'Start with ${lead.food.food.name}.',
          'Empieza con ${lead.food.food.name}.',
        );
    }
  }

  String _nextMealCheckpointDetail({
    required TodayPlanType type,
    required _InspectedFood lead,
    required List<_InspectedFood> foods,
    required MealBasketPlan? basket,
    required List<String> restockItems,
  }) {
    final backup = foods
        .where((entry) => entry.food.food.id != lead.food.food.id)
        .firstOrNull;
    final basketExtras = _basketExtraNames(lead: lead, basket: basket);

    switch (type) {
      case TodayPlanType.emergency:
        if (basketExtras.isNotEmpty) {
          return _copy.choose(
            'For the next meal, use ${_listWords(basketExtras)} if the day keeps going.',
            'Para la siguiente comida, usa ${_listWords(basketExtras)} si el dia sigue pesado.',
          );
        }
        if (backup != null) {
          return _copy.choose(
            'For the next meal, switch to ${backup.food.food.name}.',
            'Para la siguiente comida, cambia a ${backup.food.food.name}.',
          );
        }
        return _copy.choose(
          'Keep the next meal as simple as the first one.',
          'Mantiene la siguiente comida tan simple como la primera.',
        );
      case TodayPlanType.pantryFirst:
        if (basketExtras.isNotEmpty) {
          return _copy.choose(
            'For the next meal, add ${_listWords(basketExtras)} to what is already at home.',
            'Para la siguiente comida, agrega ${_listWords(basketExtras)} a lo que ya hay en casa.',
          );
        }
        if (backup != null) {
          return _copy.choose(
            'For the next meal, use ${backup.food.food.name} if you still need more food.',
            'Para la siguiente comida, usa ${backup.food.food.name} si todavia hace falta mas comida.',
          );
        }
        return _copy.choose(
          'Use another pantry-based meal before opening a bigger trip.',
          'Usa otra comida basada en despensa antes de abrir una compra mayor.',
        );
      case TodayPlanType.restockRun:
        if (basket != null) {
          return _copy.choose(
            'Build the next meal around ${_itemList(basket.items)}.',
            'Arma la siguiente comida alrededor de ${_itemList(basket.items)}.',
          );
        }
        return _copy.choose(
          'Build the next meal around ${lead.food.food.name}.',
          'Arma la siguiente comida alrededor de ${lead.food.food.name}.',
        );
      case TodayPlanType.wicStaples:
        if (backup != null) {
          return _copy.choose(
            'Pair the WIC staple with ${backup.food.food.name} for the next meal.',
            'Combina el basico WIC con ${backup.food.food.name} para la siguiente comida.',
          );
        }
        return _copy.choose(
          'Use the WIC staple again for the next meal if it keeps the cost low.',
          'Vuelve a usar el basico WIC en la siguiente comida si mantiene bajo el costo.',
        );
      case TodayPlanType.snapRun:
        if (backup != null) {
          return _copy.choose(
            'For the next meal, pair the staple buy with ${backup.food.food.name}.',
            'Para la siguiente comida, combina la compra basica con ${backup.food.food.name}.',
          );
        }
        return _copy.choose(
          'Use the staple buy again for the next meal before adding extras.',
          'Vuelve a usar la compra basica en la siguiente comida antes de agregar extras.',
        );
      case TodayPlanType.oneStop:
        if (basketExtras.isNotEmpty) {
          return _copy.choose(
            'Use ${_listWords(basketExtras)} for the next meal from the same trip.',
            'Usa ${_listWords(basketExtras)} para la siguiente comida del mismo viaje.',
          );
        }
        if (backup != null) {
          return _copy.choose(
            'Use ${backup.food.food.name} next if the basket runs short.',
            'Usa ${backup.food.food.name} despues si la canasta se queda corta.',
          );
        }
        return _copy.choose(
          'Reuse the same low-burden basket pattern for the next meal.',
          'Repite el mismo patron de canasta de baja carga para la siguiente comida.',
        );
      case TodayPlanType.fallback:
        if (backup != null) {
          return _copy.choose(
            'If you need another meal soon, switch to ${backup.food.food.name}.',
            'Si pronto necesitas otra comida, cambia a ${backup.food.food.name}.',
          );
        }
        return _copy.choose(
          'Keep the next meal close to the same cost and prep burden.',
          'Mantiene la siguiente comida con costo y preparacion parecidos.',
        );
    }
  }

  String _afterThatCheckpointDetail({
    required TodayPlanType type,
    required _InspectedFood lead,
    required List<_InspectedFood> foods,
    required List<String> restockItems,
  }) {
    final backup = foods
        .where((entry) => entry.food.food.id != lead.food.food.id)
        .firstOrNull;
    final topRestock = _limitedRestockItems(restockItems, limit: 2);

    switch (type) {
      case TodayPlanType.emergency:
        if (topRestock.isNotEmpty) {
          return _copy.choose(
            'Before tomorrow, restock ${_wordList(topRestock)} if you can.',
            'Antes de manana, repone ${_wordList(topRestock)} si puedes.',
          );
        }
        break;
      case TodayPlanType.pantryFirst:
        if (topRestock.isNotEmpty) {
          return _copy.choose(
            'Before tomorrow, restock ${_wordList(topRestock)} so home meals stay possible.',
            'Antes de manana, repone ${_wordList(topRestock)} para que las comidas en casa sigan siendo posibles.',
          );
        }
        break;
      case TodayPlanType.restockRun:
        if (backup != null) {
          return _copy.choose(
            'After the basics are covered, rotate into ${backup.food.food.name}.',
            'Cuando los basicos esten cubiertos, cambia a ${backup.food.food.name}.',
          );
        }
        break;
      case TodayPlanType.wicStaples:
        if (topRestock.isNotEmpty) {
          return _copy.choose(
            'If money is left after WIC staples, restock ${_wordList(topRestock)}.',
            'Si queda dinero despues de los basicos WIC, repone ${_wordList(topRestock)}.',
          );
        }
        break;
      case TodayPlanType.snapRun:
        if (topRestock.isNotEmpty) {
          return _copy.choose(
            'If SNAP balance and cash still allow it, restock ${_wordList(topRestock)}.',
            'Si el saldo de SNAP y el dinero todavia alcanzan, repone ${_wordList(topRestock)}.',
          );
        }
        break;
      case TodayPlanType.oneStop:
        if (topRestock.isNotEmpty) {
          return _copy.choose(
            'If this trip went under budget, add ${_wordList(topRestock)} before leaving.',
            'Si este viaje quedo bajo presupuesto, agrega ${_wordList(topRestock)} antes de salir.',
          );
        }
        break;
      case TodayPlanType.fallback:
        break;
    }

    if (backup != null) {
      return _copy.choose(
        'Keep ${backup.food.food.name} as the backup if the first option fails later.',
        'Guarda ${backup.food.food.name} como respaldo si la primera opcion falla despues.',
      );
    }
    return _copy.choose(
      'Repeat the lowest-burden option if you need another meal soon.',
      'Repite la opcion de menor carga si pronto necesitas otra comida.',
    );
  }

  List<String> _basketExtraNames({
    required _InspectedFood lead,
    required MealBasketPlan? basket,
  }) {
    if (basket == null) {
      return const [];
    }
    return basket.items
        .where((item) => item.food.id != lead.food.food.id)
        .map((item) => item.food.name)
        .take(2)
        .toList(growable: false);
  }

  List<String> _pantryStepItems({
    required _InspectedFood lead,
    required MealBasketPlan? basket,
  }) {
    final leadItems = lead.insight.pantryReadyMatches.take(2).toList();
    if (leadItems.isNotEmpty || basket == null) {
      return leadItems;
    }

    final basketItems = <String>{};
    for (final item in basket.items) {
      for (final ingredient in item.food.ingredients) {
        if (user.pantry.stockFor(ingredient) != PantryStockLevel.enough) {
          continue;
        }
        basketItems.add(ingredient);
        if (basketItems.length >= 2) {
          return basketItems.toList(growable: false);
        }
      }
    }
    return basketItems.toList(growable: false);
  }

  bool _looksStapleLike(Food food) {
    const stapleCategories = {
      'grain_whole',
      'legume',
      'dairy',
      'fruit',
      'vegetable_starchy',
    };
    const stapleTokens = {
      'banana',
      'beans',
      'bread',
      'cereal',
      'eggs',
      'milk',
      'oats',
      'pasta',
      'peanut',
      'potato',
      'ramen',
      'rice',
      'tortilla',
      'tuna',
      'yogurt',
    };
    return stapleCategories.contains(food.category) ||
        food.ingredients.any(stapleTokens.contains);
  }

  double _budgetShare(double cost) {
    final budget = user.feasibility.maxCostPerMeal;
    if (budget <= 0) {
      return 1;
    }
    return (cost / budget).clamp(0, 1).toDouble();
  }

  List<String> _limitedRestockItems(List<String> items, {int limit = 3}) {
    return items.take(limit).toList(growable: false);
  }

  String? _backupAction(
    List<_InspectedFood> foods, {
    required TodayPlanType type,
  }) {
    if (foods.isEmpty) {
      return null;
    }
    final backup = foods.first;
    final sourceName = backup.insight.source == null
        ? _anotherSourceName()
        : _copy.lowerSourceLabel(backup.insight.source!);
    switch (type) {
      case TodayPlanType.emergency:
        return _copy.choose(
          'Backup: if the first stop is thin, switch to ${backup.food.food.name} from $sourceName and keep the same low-cost plan.',
          'Respaldo: si la primera parada esta floja, cambia a ${backup.food.food.name} desde $sourceName y manten el mismo plan de bajo costo.',
        );
      case TodayPlanType.pantryFirst:
        return _copy.choose(
          'Backup: if home food runs short, buy only ${backup.food.food.name} from $sourceName.',
          'Respaldo: si la comida de casa se queda corta, compra solo ${backup.food.food.name} desde $sourceName.',
        );
      case TodayPlanType.restockRun:
        return _copy.choose(
          'Backup: if the restock stop is missing basics, switch to ${backup.food.food.name} from $sourceName before extras.',
          'Respaldo: si faltan basicos en la parada de reposicion, cambia a ${backup.food.food.name} desde $sourceName antes de extras.',
        );
      case TodayPlanType.wicStaples:
        return _copy.choose(
          'Backup: if the WIC version is missing, keep ${backup.food.food.name} from $sourceName as the next non-WIC fallback.',
          'Respaldo: si falta la version WIC, deja ${backup.food.food.name} desde $sourceName como el siguiente respaldo fuera de WIC.',
        );
      case TodayPlanType.snapRun:
        return _copy.choose(
          'Backup: if the first SNAP staple is missing, switch to ${backup.food.food.name} from $sourceName.',
          'Respaldo: si falta el primer basico SNAP, cambia a ${backup.food.food.name} desde $sourceName.',
        );
      case TodayPlanType.oneStop:
        return _copy.choose(
          'Backup: if the one-stop basket fails, switch to ${backup.food.food.name} from $sourceName and stop after the first needed item.',
          'Respaldo: si falla la canasta de una sola parada, cambia a ${backup.food.food.name} desde $sourceName y detente tras el primer articulo necesario.',
        );
      case TodayPlanType.fallback:
        return _copy.choose(
          'Backup: if the top option is out, switch to ${backup.food.food.name} from $sourceName instead of restarting the search.',
          'Respaldo: si la opcion principal se acaba, cambia a ${backup.food.food.name} desde $sourceName en vez de reiniciar la busqueda.',
        );
    }
  }

  String _itemList(List<ScoredFood> items) {
    final names = items.map((item) => item.food.name).toList(growable: false);
    if (names.isEmpty) {
      return _copy.choose('the top option', 'la opcion principal');
    }
    if (names.length == 1) {
      return names.first;
    }
    if (names.length == 2) {
      return _listWords(names);
    }
    return _listWords(names.take(3).toList(growable: false));
  }

  String _wordList(List<String> items) {
    if (items.isEmpty) {
      return _copy.choose('the basics', 'los basicos');
    }
    if (items.length == 1) {
      return items.first;
    }
    return _listWords(items.take(3).toList(growable: false));
  }

  String _listWords(List<String> items) {
    if (items.isEmpty) {
      return '';
    }
    if (items.length == 1) {
      return items.first;
    }
    if (items.length == 2) {
      final joiner = _copy.choose(' and ', ' y ');
      return '${items.first}$joiner${items.last}';
    }
    final joiner = _copy.choose(', and ', ', y ');
    return '${items[0]}, ${items[1]}$joiner${items[2]}';
  }

  String _fallbackSourceName() {
    return _copy.choose('the closest source', 'la fuente mas cercana');
  }

  String _nearestSourceName() {
    return _copy.choose('the nearest source', 'la fuente mas cercana');
  }

  String _bestNearbySourceName() {
    return _copy.choose('the best nearby source', 'la mejor fuente cercana');
  }

  String _anotherSourceName() {
    return _copy.choose('another source', 'otra fuente');
  }
}

class _InspectedFood {
  const _InspectedFood({required this.food, required this.insight});

  final ScoredFood food;
  final FoodAccessInsight insight;
}

class _BasketAssessment {
  const _BasketAssessment({required this.basket, required this.itemInsights});

  final MealBasketPlan basket;
  final List<FoodAccessInsight> itemInsights;

  bool get emergencyFriendly =>
      itemInsights.every((insight) => insight.emergencyFriendly);

  int get snapSupportCount => itemInsights
      .where((insight) => insight.snapSupport?.positive ?? false)
      .length;

  List<String> get pantryMatches =>
      {for (final insight in itemInsights) ...insight.pantryMatches}.toList()
        ..sort();

  List<String> get readyPantryMatches => {
    for (final insight in itemInsights) ...insight.pantryReadyMatches,
  }.toList()..sort();

  List<String> get lowPantryMatches =>
      {for (final insight in itemInsights) ...insight.pantryLowMatches}.toList()
        ..sort();

  List<String> get restockMatches =>
      {for (final insight in itemInsights) ...insight.restockMatches}.toList()
        ..sort();

  String get primarySourceLabel =>
      basket.primarySource?.label ??
      itemInsights
          .map((insight) => insight.source?.label)
          .whereType<String>()
          .toSet()
          .firstOrNull ??
      'the lowest-burden source';

  _InspectedFood get leadFood =>
      _InspectedFood(food: basket.items.first, insight: itemInsights.first);

  _InspectedFood? get readyPantryLead {
    for (var index = 0; index < itemInsights.length; index += 1) {
      final insight = itemInsights[index];
      if (insight.pantryReadyMatches.isEmpty) {
        continue;
      }
      return _InspectedFood(food: basket.items[index], insight: insight);
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
