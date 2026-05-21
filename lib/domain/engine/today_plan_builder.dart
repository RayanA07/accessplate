import '../entities/recommendation.dart';
import '../entities/user_constraints.dart';
import '../value_objects/benefit_program.dart';
import 'access_advisor.dart';

class TodayPlanBuilder {
  TodayPlanBuilder({
    required this.user,
    FoodAccessAdvisor? accessAdvisor,
  }) : _accessAdvisor = accessAdvisor ?? const FoodAccessAdvisor();

  final UserConstraints user;
  final FoodAccessAdvisor _accessAdvisor;

  TodayPlan? build({
    required List<ScoredFood> recommendations,
    required List<MealBasketPlan> baskets,
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

    if (user.access.emergencyMode) {
      return _emergencyPlan(inspectedFoods, inspectedBaskets);
    }

    final pantryFood = inspectedFoods.firstWhere(
      (entry) => entry.insight.pantryMatches.isNotEmpty,
      orElse: () => inspectedFoods.first,
    );
    final pantryBasket = inspectedBaskets.where(
      (entry) => entry.pantryMatches.isNotEmpty,
    );
    if (pantryFood.insight.pantryMatches.isNotEmpty || pantryBasket.isNotEmpty) {
      return _pantryPlan(
        pantryFood,
        pantryBasket.isEmpty ? null : pantryBasket.first,
        inspectedFoods,
      );
    }

    if (user.access.benefitPrograms.contains(BenefitProgram.wic)) {
      final wicFood = inspectedFoods.where(
        (entry) => entry.insight.wicSupport?.positive ?? false,
      );
      if (wicFood.isNotEmpty) {
        return _wicPlan(wicFood.first, inspectedFoods);
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
          basket: snapBasket.first,
        );
      }
      final snapFood = inspectedFoods.where(
        (entry) => entry.insight.snapSupport?.positive ?? false,
      );
      if (snapFood.isNotEmpty) {
        return _snapPlan(snapFood.first, inspectedFoods);
      }
    }

    if (inspectedBaskets.isNotEmpty) {
      return _oneStopPlan(inspectedBaskets.first, inspectedFoods);
    }

    return _fallbackPlan(inspectedFoods);
  }

  TodayPlan _emergencyPlan(
    List<_InspectedFood> foods,
    List<_BasketAssessment> baskets,
  ) {
    final basket = baskets
        .where((entry) => entry.emergencyFriendly)
        .cast<_BasketAssessment?>()
        .firstWhere((entry) => entry != null, orElse: () => null);
    final lead = foods
        .where((entry) => entry.insight.emergencyFriendly)
        .cast<_InspectedFood?>()
        .firstWhere((entry) => entry != null, orElse: () => foods.first)!;
    final usedBasket = basket?.basket;
    final steps = <String>[
      if (lead.insight.pantryMatches.isNotEmpty)
        'Start with ${lead.insight.pantryMatches.take(2).join(' and ')} that you already have.',
      if (usedBasket != null)
        'Use ${_itemList(usedBasket.items)} and keep this run under \$${usedBasket.totalCost.toStringAsFixed(2)}.'
      else
        'Choose ${lead.food.food.name} and keep this run under \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
      'Skip the longest trip and favor ${lead.insight.source?.label.toLowerCase() ?? 'the closest source'} today.',
    ];

    return TodayPlan(
      type: TodayPlanType.emergency,
      title: 'Today plan: emergency fallback',
      summary:
          'Use the fastest low-travel option that still fits your safety rules and budget.',
      steps: steps,
      highlights: <String>[
        'Emergency mode',
        if (usedBasket != null) '\$${usedBasket.totalCost.toStringAsFixed(2)} total',
        if (lead.insight.snapSupport != null) lead.insight.snapSupport!.label,
      ],
      leadRecommendation: lead.food,
      basket: usedBasket,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  TodayPlan _pantryPlan(
    _InspectedFood lead,
    _BasketAssessment? basket,
    List<_InspectedFood> foods,
  ) {
    final steps = <String>[
      'Use ${lead.insight.pantryMatches.take(2).join(' and ')} from home first.',
      if (basket != null)
        'Add ${_itemList(basket.basket.items.where((item) => item.food.id != lead.food.food.id).toList())} from ${basket.primarySourceLabel}.'
      else
        'Add only what you still need from ${lead.insight.source?.label.toLowerCase() ?? 'the nearest source'}.',
      'Keep the total low before opening a larger shopping trip.',
    ];

    return TodayPlan(
      type: TodayPlanType.pantryFirst,
      title: 'Today plan: pantry-first',
      summary: 'Stretch food you already have before spending on a full restock.',
      steps: steps,
      highlights: <String>[
        'Pantry-first',
        if (basket != null) '\$${basket.basket.totalCost.toStringAsFixed(2)} total',
        if (lead.insight.source != null) lead.insight.source!.label,
      ],
      leadRecommendation: lead.food,
      basket: basket?.basket,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  TodayPlan _wicPlan(_InspectedFood lead, List<_InspectedFood> foods) {
    final wicSupport = lead.insight.wicSupport;
    return TodayPlan(
      type: TodayPlanType.wicStaples,
      title: 'Today plan: WIC staples run',
      summary: 'Start with likely WIC staples, then add only one extra item if budget allows.',
      steps: [
        'Look for a WIC-approved version of ${lead.food.food.name}.',
        if (wicSupport != null) wicSupport.detail,
        'Add a non-WIC backup only if you still have room in today\'s budget.',
      ],
      highlights: <String>[
        'WIC-aware',
        if (lead.insight.source != null) lead.insight.source!.label,
        if (wicSupport != null) wicSupport.label,
      ],
      leadRecommendation: lead.food,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  TodayPlan _snapPlan(
    _InspectedFood lead,
    List<_InspectedFood> foods, {
    _BasketAssessment? basket,
  }) {
    final snapSupport = lead.insight.snapSupport;
    final usedBasket = basket?.basket;
    return TodayPlan(
      type: TodayPlanType.snapRun,
      title: 'Today plan: SNAP-aware run',
      summary:
          'Favor likely SNAP staples and avoid turning this into a more expensive restaurant stop.',
      steps: [
        if (usedBasket != null)
          'Use SNAP for ${_itemList(usedBasket.items)} in one stop.'
        else
          'Start with ${lead.food.food.name} as your likely SNAP staple.',
        if (snapSupport != null) snapSupport.detail,
        'If the exact item is missing, swap to another staple with a similar cost and prep burden.',
      ],
      highlights: <String>[
        'SNAP-aware',
        if (usedBasket != null) '\$${usedBasket.totalCost.toStringAsFixed(2)} total',
        if (snapSupport != null) snapSupport.label,
      ],
      leadRecommendation: lead.food,
      basket: usedBasket,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  TodayPlan _oneStopPlan(
    _BasketAssessment basket,
    List<_InspectedFood> foods,
  ) {
    return TodayPlan(
      type: TodayPlanType.oneStop,
      title: 'Today plan: one-stop basket',
      summary:
          'Take the shortest realistic trip and get the full meal in one stop.',
      steps: [
        'Go to ${basket.primarySourceLabel}.',
        'Pick ${_itemList(basket.basket.items)}.',
        'Stop once the basket is complete so the total stays near \$${basket.basket.totalCost.toStringAsFixed(2)}.',
      ],
      highlights: <String>[
        'One stop',
        basket.primarySourceLabel,
        '\$${basket.basket.totalCost.toStringAsFixed(2)} total',
      ],
      leadRecommendation: basket.leadFood.food,
      basket: basket.basket,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  TodayPlan _fallbackPlan(List<_InspectedFood> foods) {
    final lead = foods.first;
    return TodayPlan(
      type: TodayPlanType.fallback,
      title: 'Today plan: simplest safe option',
      summary: 'Use the top safe option now, then widen constraints only if you still need more choices.',
      steps: [
        'Start with ${lead.food.food.name}.',
        'Keep the spend near \$${lead.food.food.costEstimate.toStringAsFixed(2)}.',
        'If it is unavailable, switch to the next closest option instead of restarting the full search.',
      ],
      highlights: <String>[
        'Fallback',
        if (lead.insight.source != null) lead.insight.source!.label,
      ],
      leadRecommendation: lead.food,
      backupAction: _backupAction(foods.skip(1).toList()),
    );
  }

  String? _backupAction(List<_InspectedFood> foods) {
    if (foods.isEmpty) {
      return null;
    }
    final backup = foods.first;
    return 'Backup: ${backup.food.food.name} from ${backup.insight.source?.label.toLowerCase() ?? 'another source'}.';
  }

  String _itemList(List<ScoredFood> items) {
    final names = items.map((item) => item.food.name).toList(growable: false);
    if (names.isEmpty) {
      return 'the top option';
    }
    if (names.length == 1) {
      return names.first;
    }
    if (names.length == 2) {
      return '${names.first} and ${names.last}';
    }
    return '${names[0]}, ${names[1]}, and ${names[2]}';
  }
}

class _InspectedFood {
  const _InspectedFood({required this.food, required this.insight});

  final ScoredFood food;
  final FoodAccessInsight insight;
}

class _BasketAssessment {
  const _BasketAssessment({
    required this.basket,
    required this.itemInsights,
  });

  final MealBasketPlan basket;
  final List<FoodAccessInsight> itemInsights;

  bool get emergencyFriendly =>
      itemInsights.every((insight) => insight.emergencyFriendly);

  int get snapSupportCount =>
      itemInsights.where((insight) => insight.snapSupport?.positive ?? false).length;

  List<String> get pantryMatches => {
    for (final insight in itemInsights) ...insight.pantryMatches,
  }.toList()
    ..sort();

  String get primarySourceLabel =>
      itemInsights
          .map((insight) => insight.source?.label)
          .whereType<String>()
          .toSet()
          .firstOrNull ??
      'the lowest-burden source';

  _InspectedFood get leadFood => _InspectedFood(
    food: basket.items.first,
    insight: itemInsights.first,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
