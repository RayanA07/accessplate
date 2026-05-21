import 'dart:math' as math;

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
}

class FoodAccessInsight {
  const FoodAccessInsight({
    required this.source,
    required this.localProfile,
    required this.matchType,
    required this.sourceSnapshot,
    required this.snapSupport,
    required this.wicSupport,
    required this.travelBurden,
    required this.snapFriendly,
    required this.wicStapleCandidate,
    required this.emergencyFriendly,
    required this.pantryMatches,
  });

  final AvailabilityContext? source;
  final LocalAccessProfile? localProfile;
  final LocalAccessMatchType? matchType;
  final SourceAccessSnapshot? sourceSnapshot;
  final BenefitSupportNote? snapSupport;
  final BenefitSupportNote? wicSupport;
  final TravelBurden travelBurden;
  final bool snapFriendly;
  final bool wicStapleCandidate;
  final bool emergencyFriendly;
  final List<String> pantryMatches;

  bool get lowTravel => travelBurden == TravelBurden.low;
  int get nearbyOptions => sourceSnapshot?.nearbyOptions ?? 0;
  int? get typicalTravelMinutes => sourceSnapshot?.typicalTravelMinutes;
  bool get zipAware => localProfile != null;
}

class FoodAccessAdvisor {
  const FoodAccessAdvisor({this.catalog});

  final LocalAccessCatalog? catalog;

  FoodAccessInsight inspect({
    required Food food,
    required UserConstraints user,
  }) {
    final resolution = catalog?.resolve(user.access.postalCode);
    final source = _matchedSource(food, user, resolution?.profile);
    final sourceSnapshot = source == null
        ? null
        : resolution?.profile.sourceFor(source);
    final pantryMatches =
        food.ingredients.where(user.pantry.itemsOnHand.contains).toList()
          ..sort();
    final snapSupport = _snapSupport(food: food, source: source);
    final wicSupport = _wicSupport(food: food, source: source);
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
      snapSupport: snapSupport,
      wicSupport: wicSupport,
      travelBurden: travelBurden,
      snapFriendly: snapFriendly,
      wicStapleCandidate: wicStapleCandidate,
      emergencyFriendly: emergencyFriendly,
      pantryMatches: pantryMatches,
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

    switch (insight.travelBurden) {
      case TravelBurden.low:
        adjustment += 0.06;
      case TravelBurden.medium:
        adjustment -= 0.01;
      case TravelBurden.high:
        adjustment -= 0.12;
    }

    final sourceSnapshot = insight.sourceSnapshot;
    if (sourceSnapshot != null) {
      adjustment += (sourceSnapshot.sameDayConfidence - 0.5) * 0.12;
      adjustment += math.min(0.08, sourceSnapshot.nearbyOptions * 0.015);
    }

    if (insight.pantryMatches.isNotEmpty) {
      adjustment += math.min(0.07, insight.pantryMatches.length * 0.025);
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

    return adjustment.clamp(-0.2, 0.2).toDouble();
  }

  AvailabilityContext? _matchedSource(
    Food food,
    UserConstraints user,
    LocalAccessProfile? profile,
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
        context: left,
        user: user,
        profile: profile,
      );
      final rightScore = _sourceScore(
        context: right,
        user: user,
        profile: profile,
      );
      final byScore = leftScore.compareTo(rightScore);
      if (byScore != 0) {
        return byScore;
      }
      return _sourcePriority(user).indexOf(left).compareTo(
        _sourcePriority(user).indexOf(right),
      );
    });

    return candidates.first;
  }

  double _sourceScore({
    required AvailabilityContext context,
    required UserConstraints user,
    required LocalAccessProfile profile,
  }) {
    final snapshot = profile.sourceFor(context);
    if (snapshot == null || snapshot.nearbyOptions <= 0) {
      return 999;
    }

    final maxTravel = user.access.maxTravelMinutes <= 0
        ? 20
        : user.access.maxTravelMinutes;
    final travelRatio = snapshot.typicalTravelMinutes / maxTravel;
    var score = travelRatio * 100;
    score -= snapshot.nearbyOptions * 6;
    score -= snapshot.sameDayConfidence * 18;

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
      score += 25;
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
  }) {
    if (source == null) {
      return TravelBurden.high;
    }

    if (sourceSnapshot != null) {
      final travelMinutes = sourceSnapshot.typicalTravelMinutes;
      final limit = maxTravelMinutes <= 0 ? 20 : maxTravelMinutes;
      final ratio = travelMinutes / limit;

      if (ratio <= 0.65) {
        return TravelBurden.low;
      }
      if (ratio <= 1.0 || sourceSnapshot.sameDayConfidence >= 0.8) {
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

    if (transportation == TransportationMode.transit && maxTravelMinutes >= 30) {
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
  }) {
    if (source == null) {
      return null;
    }

    if (source == AvailabilityContext.foodPantry) {
      return const BenefitSupportNote(
        label: 'Pantry option',
        detail: 'No SNAP purchase is needed if this pantry item is available.',
        strength: BenefitSupportStrength.neutral,
      );
    }

    if (source == AvailabilityContext.fastFood) {
      return const BenefitSupportNote(
        label: 'SNAP varies',
        detail:
            'Restaurant Meals Program access varies by state and by user eligibility.',
        strength: BenefitSupportStrength.caution,
      );
    }

    if (_looksLikePreparedHotPurchase(food)) {
      return const BenefitSupportNote(
        label: 'SNAP may vary',
        detail: 'Hot or prepared items can be restricted at checkout.',
        strength: BenefitSupportStrength.caution,
      );
    }

    return const BenefitSupportNote(
      label: 'Likely SNAP item',
      detail: 'Staple grocery-style item for a SNAP-funded run.',
      strength: BenefitSupportStrength.strong,
    );
  }

  BenefitSupportNote? _wicSupport({
    required Food food,
    required AvailabilityContext? source,
  }) {
    if (source == null) {
      return null;
    }

    if (source != AvailabilityContext.grocery) {
      if (_looksLikeWicStaple(food) && source == AvailabilityContext.foodPantry) {
        return const BenefitSupportNote(
          label: 'Useful staple',
          detail: 'Helpful pantry staple, even though this is not a WIC store purchase.',
          strength: BenefitSupportStrength.neutral,
        );
      }
      return null;
    }

    if (_looksLikeWicStaple(food)) {
      return const BenefitSupportNote(
        label: 'WIC staple candidate',
        detail:
            'Final WIC approval still depends on brand, package size, and your state list.',
        strength: BenefitSupportStrength.strong,
      );
    }

    if (food.category == 'prepared_meal' || food.category == 'snack') {
      return const BenefitSupportNote(
        label: 'Not a typical WIC item',
        detail: 'Prepared meals and snack foods are usually outside WIC lists.',
        strength: BenefitSupportStrength.caution,
      );
    }

    return null;
  }

  bool _looksLikePreparedHotPurchase(Food food) {
    if (food.category != 'prepared_meal') {
      return false;
    }
    return food.readyToEat || food.prepTimeMin <= 2;
  }

  double _emergencyBudget(UserConstraints user) {
    final maxBudget = user.feasibility.maxCostPerMeal;
    if (user.access.emergencyMode) {
      return maxBudget <= 4 ? maxBudget : 4;
    }
    return maxBudget <= 0 ? 0 : maxBudget;
  }
}
