import 'dart:math' as math;

import 'access_copy.dart';
import 'benefit_policy.dart';
import 'source_content_model.dart';
import '../entities/food.dart';
import '../entities/local_access.dart';
import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/benefit_program.dart';
import '../value_objects/transportation_mode.dart';

enum TravelBurden { low, medium, high }

enum BenefitSupportStrength { strong, caution, neutral }

class BenefitSupportNote {
  const BenefitSupportNote({
    required this.label,
    required this.detail,
    required this.strength,
  });

  final String label;
  final String detail;
  final BenefitSupportStrength strength;

  bool get positive => strength == BenefitSupportStrength.strong;
  bool get caution => strength == BenefitSupportStrength.caution;
  bool get neutral => strength == BenefitSupportStrength.neutral;
}

class FoodAccessInsight {
  const FoodAccessInsight({
    required this.source,
    required this.localProfile,
    required this.matchType,
    required this.modelConfidence,
    required this.sourceSnapshot,
    required this.snapSupport,
    required this.wicSupport,
    required this.travelBurden,
    required this.snapFriendly,
    required this.wicStapleCandidate,
    required this.emergencyFriendly,
    required this.pantryReadyMatches,
    required this.pantryLowMatches,
    required this.restockMatches,
  });

  final AvailabilityContext? source;
  final LocalAccessProfile? localProfile;
  final LocalAccessMatchType? matchType;
  final double modelConfidence;
  final SourceAccessSnapshot? sourceSnapshot;
  final BenefitSupportNote? snapSupport;
  final BenefitSupportNote? wicSupport;
  final TravelBurden travelBurden;
  final bool snapFriendly;
  final bool wicStapleCandidate;
  final bool emergencyFriendly;
  final List<String> pantryReadyMatches;
  final List<String> pantryLowMatches;
  final List<String> restockMatches;

  bool get lowTravel => travelBurden == TravelBurden.low;
  int get nearbyOptions => sourceSnapshot?.nearbyOptions ?? 0;
  int? get typicalTravelMinutes => sourceSnapshot?.typicalTravelMinutes;
  bool get zipAware => localProfile != null;
  bool get noPurchaseNeeded => source == AvailabilityContext.foodPantry;
  bool get benefitsCaution =>
      (snapSupport?.caution ?? false) || (wicSupport?.caution ?? false);
  bool get approximateAccessModel =>
      matchType != null && matchType != LocalAccessMatchType.exact;
  bool get lowerConfidenceAccessModel => modelConfidence < 0.7;
  List<String> get pantryMatches =>
      [...pantryReadyMatches, ...pantryLowMatches]..sort();
}

class FoodAccessAdvisor {
  const FoodAccessAdvisor({
    this.catalog,
    this.benefitPolicy = const BenefitPolicyCatalog(),
    this.contentModel = const SourceContentModel(),
  });

  final LocalAccessCatalog? catalog;
  final BenefitPolicyCatalog benefitPolicy;
  final SourceContentModel contentModel;

  BenefitSupportNote? snapSupportForSource({
    required Food food,
    required AvailabilityContext? source,
    required UserConstraints user,
  }) => _snapSupport(
    food: food,
    source: source,
    copy: AccessCopy(user.access),
    policy: benefitPolicy.resolve(
      user: user,
      profile: catalog?.resolve(user.access.postalCode).profile,
    ),
  );

  BenefitSupportNote? wicSupportForSource({
    required Food food,
    required AvailabilityContext? source,
    required UserConstraints user,
  }) => _wicSupport(
    food: food,
    source: source,
    copy: AccessCopy(user.access),
    policy: benefitPolicy.resolve(
      user: user,
      profile: catalog?.resolve(user.access.postalCode).profile,
    ),
  );

  FoodAccessInsight inspect({
    required Food food,
    required UserConstraints user,
  }) {
    final copy = AccessCopy(user.access);
    final resolution = catalog?.resolve(user.access.postalCode);
    final source = _matchedSource(
      food,
      user,
      resolution?.profile,
      resolution?.matchType,
    );
    final sourceSnapshot = source == null
        ? null
        : resolution?.profile.sourceFor(source);
    final pantryReadyMatches =
        food.ingredients
            .where(
              (item) => user.pantry.stockFor(item) == PantryStockLevel.enough,
            )
            .toList()
          ..sort();
    final pantryLowMatches =
        food.ingredients
            .where((item) => user.pantry.stockFor(item) == PantryStockLevel.low)
            .toList()
          ..sort();
    final restockMatches =
        food.ingredients
            .where((item) => user.pantry.stockFor(item) == PantryStockLevel.out)
            .toList()
          ..sort();
    final policy = benefitPolicy.resolve(user: user, profile: resolution?.profile);
    final snapSupport = _snapSupport(
      food: food,
      source: source,
      copy: copy,
      policy: policy,
    );
    final wicSupport = _wicSupport(
      food: food,
      source: source,
      copy: copy,
      policy: policy,
    );
    final snapFriendly =
        user.access.benefitPrograms.contains(BenefitProgram.snap) &&
        (snapSupport?.positive ?? false);
    final wicStapleCandidate =
        user.access.benefitPrograms.contains(BenefitProgram.wic) &&
        (wicSupport?.positive ?? false);
    final travelBurden = _travelBurden(
      source: source,
      sourceSnapshot: sourceSnapshot,
      transportation: user.access.transportation,
      maxTravelMinutes: user.access.maxTravelMinutes,
      profile: resolution?.profile,
      matchType: resolution?.matchType,
    );
    final emergencyFriendly =
        food.costEstimate <= _emergencyBudget(user) &&
        (food.readyToEat || food.prepTimeMin <= 5) &&
        travelBurden != TravelBurden.high;

    return FoodAccessInsight(
      source: source,
      localProfile: resolution?.profile,
      matchType: resolution?.matchType,
      sourceSnapshot: sourceSnapshot,
      modelConfidence: resolution?.modeledConfidence ?? 0.42,
      snapSupport: snapSupport,
      wicSupport: wicSupport,
      travelBurden: travelBurden,
      snapFriendly: snapFriendly,
      wicStapleCandidate: wicStapleCandidate,
      emergencyFriendly: emergencyFriendly,
      pantryReadyMatches: pantryReadyMatches,
      pantryLowMatches: pantryLowMatches,
      restockMatches: restockMatches,
    );
  }

  double accessAdjustment({
    required FoodAccessInsight insight,
    required UserConstraints user,
  }) {
    if (insight.source == null) {
      return -0.18;
    }

    var adjustment = 0.0;
    final modelWeight = insight.zipAware ? insight.modelConfidence : 0.45;
    final burdenWeight = insight.zipAware ? math.max(0.55, modelWeight) : 0.5;

    switch (insight.travelBurden) {
      case TravelBurden.low:
        adjustment += 0.06 * burdenWeight;
      case TravelBurden.medium:
        adjustment -= 0.01 * burdenWeight;
      case TravelBurden.high:
        adjustment -= 0.12 * burdenWeight;
    }

    final sourceSnapshot = insight.sourceSnapshot;
    if (sourceSnapshot != null) {
      adjustment +=
          ((sourceSnapshot.sameDayConfidence - 0.5) * 0.12) * modelWeight;
      adjustment +=
          math.min(0.08, sourceSnapshot.nearbyOptions * 0.015) * modelWeight;
    }

    if (insight.pantryReadyMatches.isNotEmpty) {
      adjustment += math.min(0.07, insight.pantryReadyMatches.length * 0.025);
    }

    if (insight.pantryLowMatches.isNotEmpty) {
      adjustment += math.min(0.03, insight.pantryLowMatches.length * 0.012);
    }

    if (insight.snapFriendly) {
      adjustment += 0.03;
    }

    if (insight.wicStapleCandidate) {
      adjustment += 0.02;
    }

    if (user.access.emergencyMode && insight.emergencyFriendly) {
      adjustment += 0.08;
    }

    if (user.access.transportation.lowMobility && insight.lowTravel) {
      adjustment += 0.04;
    }

    if (insight.localProfile?.lowAccessArea == true &&
        insight.source == AvailabilityContext.grocery &&
        insight.travelBurden != TravelBurden.low) {
      adjustment -= 0.04;
    }

    if (insight.lowerConfidenceAccessModel && insight.sourceSnapshot != null) {
      adjustment -= 0.01;
    }

    return adjustment.clamp(-0.2, 0.2).toDouble();
  }

  AvailabilityContext? _matchedSource(
    Food food,
    UserConstraints user,
    LocalAccessProfile? profile,
    LocalAccessMatchType? matchType,
  ) {
    final candidates = food.availability
        .where(user.feasibility.availability.contains)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    if (profile == null) {
      final priority = _sourcePriority(user);
      for (final context in priority) {
        if (candidates.contains(context)) {
          return context;
        }
      }
      return candidates.first;
    }

    candidates.sort((left, right) {
      final leftScore = _sourceScore(
        food: food,
        context: left,
        user: user,
        profile: profile,
        matchType: matchType,
      );
      final rightScore = _sourceScore(
        food: food,
        context: right,
        user: user,
        profile: profile,
        matchType: matchType,
      );
      final byScore = leftScore.compareTo(rightScore);
      if (byScore != 0) {
        return byScore;
      }
      return _sourcePriority(
        user,
      ).indexOf(left).compareTo(_sourcePriority(user).indexOf(right));
    });

    return candidates.first;
  }

  double _sourceScore({
    required Food food,
    required AvailabilityContext context,
    required UserConstraints user,
    required LocalAccessProfile profile,
    required LocalAccessMatchType? matchType,
  }) {
    final snapshot = profile.sourceFor(context);
    if (snapshot == null || snapshot.nearbyOptions <= 0) {
      return 999;
    }

    final maxTravel = user.access.maxTravelMinutes <= 0
        ? 20
        : user.access.maxTravelMinutes;
    final travelRatio = snapshot.typicalTravelMinutes / maxTravel;
    final communityFit = profile.sourceFitFor(
      context,
      user.access.transportation,
    );
    final contentFit = contentModel.fitForFood(food, context);
    final modelWeight = _matchConfidence(matchType);
    final modeledTravelScore =
        (travelRatio * 100) -
        (snapshot.nearbyOptions * 6) -
        (snapshot.sameDayConfidence * 18) +
        ((1 - communityFit) * 24);
    var score = modeledTravelScore * modelWeight;
    score += travelRatio * (1 - modelWeight) * 44;
    score += (1 - contentFit) * 20;

    if (contentFit < 0.45) {
      score += 10;
    }

    if (user.access.emergencyMode) {
      if (context == AvailabilityContext.foodPantry ||
          context == AvailabilityContext.dollarStore ||
          context == AvailabilityContext.convenience) {
        score -= 14;
      }
      if (context == AvailabilityContext.grocery &&
          snapshot.typicalTravelMinutes > 15) {
        score += 10;
      }
    }

    if (user.access.transportation.lowMobility &&
        snapshot.typicalTravelMinutes > maxTravel) {
      score += (16 + (9 * modelWeight));
    }

    if (context == AvailabilityContext.grocery &&
        profile.groceryGapSeverity >= 0.65 &&
        !user.access.transportation.lowMobility) {
      score += profile.groceryGapSeverity * (3 + (3 * modelWeight));
    }

    if (context == AvailabilityContext.fastFood &&
        user.access.benefitPrograms.contains(BenefitProgram.snap)) {
      score += 8;
    }

    return score;
  }

  List<AvailabilityContext> _sourcePriority(UserConstraints user) {
    if (user.access.emergencyMode || user.access.transportation.lowMobility) {
      return const [
        AvailabilityContext.foodPantry,
        AvailabilityContext.dollarStore,
        AvailabilityContext.convenience,
        AvailabilityContext.fastFood,
        AvailabilityContext.grocery,
      ];
    }

    return const [
      AvailabilityContext.grocery,
      AvailabilityContext.foodPantry,
      AvailabilityContext.dollarStore,
      AvailabilityContext.convenience,
      AvailabilityContext.fastFood,
    ];
  }

  TravelBurden _travelBurden({
    required AvailabilityContext? source,
    required SourceAccessSnapshot? sourceSnapshot,
    required TransportationMode transportation,
    required int maxTravelMinutes,
    LocalAccessProfile? profile,
    LocalAccessMatchType? matchType,
  }) {
    if (source == null) {
      return TravelBurden.high;
    }

    if (sourceSnapshot != null) {
      final travelMinutes = sourceSnapshot.typicalTravelMinutes;
      final limit = maxTravelMinutes <= 0 ? 20 : maxTravelMinutes;
      final ratio = travelMinutes / limit;
      final communityFit = profile?.sourceFitFor(source, transportation) ?? 0.7;
      final confidence = _matchConfidence(matchType);
      final lowThreshold = confidence >= 0.9
          ? 0.65
          : confidence >= 0.75
          ? 0.58
          : 0.52;
      final mediumThreshold = confidence >= 0.75 ? 1.0 : 0.9;

      if (ratio <= lowThreshold && communityFit >= 0.72) {
        return TravelBurden.low;
      }
      if ((ratio <= mediumThreshold && communityFit >= 0.48) ||
          (sourceSnapshot.sameDayConfidence >= 0.8 && communityFit >= 0.58)) {
        return TravelBurden.medium;
      }
      return TravelBurden.high;
    }

    if (source == AvailabilityContext.foodPantry ||
        source == AvailabilityContext.dollarStore ||
        source == AvailabilityContext.convenience) {
      return TravelBurden.low;
    }

    if (transportation == TransportationMode.car && maxTravelMinutes >= 20) {
      return TravelBurden.low;
    }

    if (transportation == TransportationMode.transit &&
        maxTravelMinutes >= 30) {
      return TravelBurden.medium;
    }

    if (transportation.lowMobility) {
      return TravelBurden.high;
    }

    return source == AvailabilityContext.fastFood
        ? TravelBurden.medium
        : maxTravelMinutes >= 20
        ? TravelBurden.medium
        : TravelBurden.high;
  }

  bool _looksLikeWicStaple(Food food) {
    if (food.category == 'prepared_meal' || food.category == 'snack') {
      return false;
    }

    if (food.category == 'dairy' ||
        food.category == 'fruit' ||
        food.category == 'grain_whole' ||
        food.category == 'legume' ||
        food.category == 'vegetable_starchy') {
      return true;
    }

    const stapleTokens = {
      'banana',
      'beans',
      'bread',
      'cereal',
      'cheese',
      'eggs',
      'milk',
      'oatmeal',
      'oats',
      'peanut',
      'rice',
      'tortilla',
      'tuna',
      'yogurt',
    };
    return food.ingredients.any(stapleTokens.contains);
  }

  BenefitSupportNote? _snapSupport({
    required Food food,
    required AvailabilityContext? source,
    required AccessCopy copy,
    required BenefitPolicyContext policy,
  }) {
    if (source == null) {
      return null;
    }

    if (source == AvailabilityContext.foodPantry) {
      return BenefitSupportNote(
        label: copy.choose('No purchase needed', 'Sin compra necesaria'),
        detail: copy.choose(
          'No SNAP purchase is needed if this pantry item is available.',
          'No necesitas comprar con SNAP si este articulo de despensa esta disponible.',
          englishDetailed:
              'No SNAP purchase is needed if this pantry item is available to you today.',
          spanishDetailed:
              'No necesitas comprar con SNAP si este articulo de despensa esta disponible hoy.',
        ),
        strength: BenefitSupportStrength.neutral,
      );
    }

    if (source == AvailabilityContext.fastFood) {
      final stateName = policy.stateDisplayName;
      if (policy.snapRestaurantMealsPartial && stateName.isNotEmpty) {
        return BenefitSupportNote(
          label: copy.choose(
            'Possible SNAP restaurant meal',
            'Posible comida de restaurante con SNAP',
          ),
          detail: copy.choose(
            '$stateName only allows Restaurant Meals Program restaurant purchases in limited areas, and only for eligible households.',
            '$stateName solo permite compras de restaurante con el programa de comidas en restaurantes en areas limitadas y solo para hogares elegibles.',
            englishDetailed:
                '$stateName only allows Restaurant Meals Program restaurant purchases in limited areas, and only for eligible households using participating restaurants.',
            spanishDetailed:
                '$stateName solo permite compras de restaurante con el programa de comidas en restaurantes en areas limitadas y solo para hogares elegibles en restaurantes participantes.',
          ),
          strength: BenefitSupportStrength.neutral,
        );
      }
      if (policy.snapRestaurantMealsAvailable && stateName.isNotEmpty) {
        return BenefitSupportNote(
          label: copy.choose(
            'Possible SNAP restaurant meal',
            'Posible comida de restaurante con SNAP',
          ),
          detail: copy.choose(
            '$stateName runs a Restaurant Meals Program, but only eligible households and participating restaurants will work at checkout.',
            '$stateName tiene un programa de comidas en restaurantes, pero solo funciona para hogares elegibles y restaurantes participantes.',
            englishDetailed:
                '$stateName runs a Restaurant Meals Program, but only eligible households and participating restaurants will work at checkout.',
            spanishDetailed:
                '$stateName tiene un programa de comidas en restaurantes, pero solo funciona para hogares elegibles y restaurantes participantes en caja.',
          ),
          strength: BenefitSupportStrength.neutral,
        );
      }
      if (stateName.isNotEmpty) {
        return BenefitSupportNote(
          label: copy.choose(
            'Likely not SNAP-friendly',
            'Probablemente no sirve bien para SNAP',
          ),
          detail: copy.choose(
            '$stateName does not generally allow restaurant SNAP purchases through Restaurant Meals Program rules.',
            '$stateName normalmente no permite compras SNAP en restaurantes bajo las reglas del programa de comidas en restaurantes.',
            englishDetailed:
                '$stateName does not generally allow restaurant SNAP purchases through Restaurant Meals Program rules.',
            spanishDetailed:
                '$stateName normalmente no permite compras SNAP en restaurantes bajo las reglas del programa de comidas en restaurantes.',
          ),
          strength: BenefitSupportStrength.caution,
        );
      }
      return BenefitSupportNote(
        label: copy.choose(
          'Likely not SNAP-friendly',
          'Probablemente no sirve bien para SNAP',
        ),
        detail: copy.choose(
          'Restaurant SNAP rules depend on your state and eligibility.',
          'Las reglas de SNAP para restaurantes dependen de tu estado y elegibilidad.',
          englishDetailed:
              'Restaurant Meals Program access varies by state and by user eligibility.',
          spanishDetailed:
              'El acceso al programa de comidas en restaurantes cambia segun el estado y la elegibilidad.',
        ),
        strength: BenefitSupportStrength.caution,
      );
    }

    if (_looksLikePreparedHotPurchase(food)) {
      return BenefitSupportNote(
        label: copy.choose(
          'Likely not SNAP-friendly',
          'Probablemente no sirve bien para SNAP',
        ),
        detail: copy.choose(
          'Hot or ready meals can be blocked at checkout.',
          'La comida caliente o lista puede bloquearse en caja.',
          englishDetailed:
              'Hot or prepared items can be restricted at checkout.',
          spanishDetailed:
              'Los articulos calientes o preparados pueden estar restringidos en caja.',
        ),
        strength: BenefitSupportStrength.caution,
      );
    }

    if (_looksLikePreparedColdPurchase(food)) {
      return BenefitSupportNote(
        label: copy.choose('SNAP check at checkout', 'Revisa SNAP en caja'),
        detail: copy.choose(
          'Cold prepared grocery items can vary by how the store rings them up.',
          'Los articulos frios preparados pueden variar segun como la tienda los cobre en caja.',
          englishDetailed:
              'Cold prepared grocery items can vary by how the store codes them at checkout.',
          spanishDetailed:
              'Los articulos frios preparados pueden variar segun como la tienda los codifique en caja.',
        ),
        strength: BenefitSupportStrength.neutral,
      );
    }

    return BenefitSupportNote(
      label: copy.choose(
        'Likely SNAP-compatible',
        'Probablemente compatible con SNAP',
      ),
      detail: copy.choose(
        'Basic grocery-style item for a SNAP run.',
        'Articulo basico de tienda para una compra con SNAP.',
        englishDetailed: 'Staple grocery-style item for a SNAP-funded run.',
        spanishDetailed:
            'Articulo basico tipo supermercado para una compra financiada con SNAP.',
      ),
      strength: BenefitSupportStrength.strong,
    );
  }

  BenefitSupportNote? _wicSupport({
    required Food food,
    required AvailabilityContext? source,
    required AccessCopy copy,
    required BenefitPolicyContext policy,
  }) {
    if (source == null) {
      return null;
    }

    final stateName = policy.stateDisplayName;
    final hasStateName = stateName.isNotEmpty;

    if (source != AvailabilityContext.grocery) {
      if (_looksLikeWicStaple(food) &&
          source == AvailabilityContext.foodPantry) {
        return BenefitSupportNote(
          label: copy.choose(
            'Useful staple from home',
            'Basico util desde casa',
          ),
          detail: copy.choose(
            'Helpful pantry staple even though this is not a WIC store purchase.',
            'Basico util de despensa aunque no sea una compra en tienda WIC.',
            englishDetailed:
                'Helpful pantry staple, even though this is not a WIC store purchase.',
            spanishDetailed:
                'Basico util de despensa, aunque esto no sea una compra WIC en tienda.',
          ),
          strength: BenefitSupportStrength.neutral,
        );
      }
      if (_looksLikeWicStaple(food)) {
        return BenefitSupportNote(
          label: copy.choose(
            'Likely not a WIC stop',
            'Probablemente no es una parada WIC',
          ),
          detail: copy.choose(
            hasStateName
                ? 'WIC staples are more reliable at a grocery store that follows the $stateName WIC list.'
                : 'WIC staples are more reliable at a grocery store that follows your state list.',
            hasStateName
                ? 'Los basicos WIC son mas confiables en una tienda que siga la lista WIC de $stateName.'
                : 'Los basicos WIC son mas confiables en una tienda que siga la lista de tu estado.',
            englishDetailed: hasStateName
                ? 'WIC staples are more reliable at a grocery store that follows the $stateName approved-food list.'
                : 'WIC staples are more reliable at a grocery store that follows your state-approved list.',
            spanishDetailed: hasStateName
                ? 'Los basicos WIC son mas confiables en una tienda que siga la lista aprobada de alimentos de $stateName.'
                : 'Los basicos WIC son mas confiables en una tienda que siga la lista aprobada de tu estado.',
          ),
          strength: BenefitSupportStrength.caution,
        );
      }
      return BenefitSupportNote(
        label: copy.choose(
          'Likely not WIC-friendly',
          'Probablemente no sirve bien para WIC',
        ),
        detail: copy.choose(
          'This source type is not a strong WIC match for this item.',
          'Este tipo de lugar no es una buena opcion WIC para este articulo.',
          englishDetailed:
              'This source type is not a strong WIC match for this item today.',
          spanishDetailed:
              'Este tipo de lugar no es una buena opcion WIC para este articulo hoy.',
        ),
        strength: BenefitSupportStrength.caution,
      );
    }

    if (_looksLikeWicStaple(food)) {
      return BenefitSupportNote(
        label: copy.choose(
          'Likely WIC candidate',
          'Probable candidato para WIC',
        ),
        detail: copy.choose(
          hasStateName
              ? 'Final WIC approval still depends on brand, size, and the $stateName WIC list.'
              : 'Final WIC approval still depends on brand, size, and your state list.',
          hasStateName
              ? 'La aprobacion final de WIC depende de la marca, el tamano y la lista WIC de $stateName.'
              : 'La aprobacion final de WIC depende de la marca, el tamano y la lista de tu estado.',
          englishDetailed: hasStateName
              ? 'Final WIC approval still depends on brand, package size, and the $stateName approved-food list.'
              : 'Final WIC approval still depends on brand, package size, and your state list.',
          spanishDetailed: hasStateName
              ? 'La aprobacion final de WIC todavia depende de la marca, el tamano del paquete y la lista aprobada de alimentos de $stateName.'
              : 'La aprobacion final de WIC todavia depende de la marca, el tamano del paquete y la lista de tu estado.',
        ),
        strength: BenefitSupportStrength.strong,
      );
    }

    if (food.category == 'prepared_meal' || food.category == 'snack') {
      return BenefitSupportNote(
        label: copy.choose(
          'Likely not WIC-friendly',
          'Probablemente no sirve bien para WIC',
        ),
        detail: copy.choose(
          'Prepared meals and snacks are usually outside WIC.',
          'Las comidas preparadas y botanas normalmente quedan fuera de WIC.',
          englishDetailed:
              'Prepared meals and snack foods are usually outside WIC lists.',
          spanishDetailed:
              'Las comidas preparadas y las botanas normalmente estan fuera de las listas de WIC.',
        ),
        strength: BenefitSupportStrength.caution,
      );
    }

    return BenefitSupportNote(
      label: copy.choose(
        'Likely not WIC-friendly',
        'Probablemente no sirve bien para WIC',
      ),
      detail: copy.choose(
        hasStateName
            ? 'This item is not a strong match for core WIC foods in $stateName.'
            : 'This item is not a strong WIC staple match.',
        hasStateName
            ? 'Este articulo no es una buena coincidencia con los alimentos basicos de WIC en $stateName.'
            : 'Este articulo no es un buen basico para WIC.',
        englishDetailed: hasStateName
            ? 'This item is not a strong match for the core WIC staple lists used in $stateName.'
            : 'This item is not a strong match for the core WIC staple lists.',
        spanishDetailed: hasStateName
            ? 'Este articulo no es una buena coincidencia con las listas basicas de WIC usadas en $stateName.'
            : 'Este articulo no es una buena coincidencia con las listas basicas de WIC.',
      ),
      strength: BenefitSupportStrength.caution,
    );
  }

  bool _looksLikePreparedHotPurchase(Food food) {
    if (food.category != 'prepared_meal') {
      return false;
    }
    return food.readyToEat || food.prepTimeMin <= 2;
  }

  bool _looksLikePreparedColdPurchase(Food food) {
    if (food.category != 'prepared_meal') {
      return false;
    }
    return !_looksLikePreparedHotPurchase(food);
  }

  double _emergencyBudget(UserConstraints user) {
    final maxBudget = user.feasibility.maxCostPerMeal;
    if (user.access.emergencyMode) {
      return maxBudget <= 4 ? maxBudget : 4;
    }
    return maxBudget <= 0 ? 0 : maxBudget;
  }

  double _matchConfidence(LocalAccessMatchType? matchType) {
    switch (matchType) {
      case LocalAccessMatchType.exact:
        return 0.96;
      case LocalAccessMatchType.prefix:
        return 0.78;
      case LocalAccessMatchType.fallback:
        return 0.56;
      case null:
        return 0.42;
    }
  }
}
