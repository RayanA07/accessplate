import 'explanation.dart';
import 'food.dart';
import 'nutrients.dart';
import '../value_objects/availability_context.dart';

enum BlockingConstraint {
  safety('Safety profile'),
  budget('Budget'),
  environment('Preparation environment'),
  availability('Availability context'),
  preference('Preferences');

  const BlockingConstraint(this.label);

  final String label;
}

class InsufficientCandidatesAnalysis {
  const InsufficientCandidatesAnalysis({
    required this.currentCount,
    required this.minimumDesired,
    required this.mostRestrictive,
    required this.suggestion,
  });

  final int currentCount;
  final int minimumDesired;
  final BlockingConstraint mostRestrictive;
  final String suggestion;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.macro,
    required this.micro,
    required this.penalty,
    required this.cost,
    required this.preference,
    this.access = 0,
  });

  final double macro;
  final double micro;
  final double penalty;
  final double cost;
  final double preference;
  final double access;
}

class ScoredFood {
  const ScoredFood({
    required this.food,
    required this.nutrients,
    required this.composite,
    required this.breakdown,
    this.displayScore = 0,
    this.explanation,
  });

  final Food food;
  final Nutrients nutrients;
  final double composite;
  final ScoreBreakdown breakdown;
  final double displayScore;
  final Explanation? explanation;

  ScoredFood copyWith({
    Food? food,
    Nutrients? nutrients,
    double? composite,
    ScoreBreakdown? breakdown,
    double? displayScore,
    Explanation? explanation,
  }) {
    return ScoredFood(
      food: food ?? this.food,
      nutrients: nutrients ?? this.nutrients,
      composite: composite ?? this.composite,
      breakdown: breakdown ?? this.breakdown,
      displayScore: displayScore ?? this.displayScore,
      explanation: explanation ?? this.explanation,
    );
  }
}

class MealBasketPlan {
  const MealBasketPlan({
    required this.title,
    required this.summary,
    required this.items,
    required this.totalNutrients,
    required this.totalCost,
    required this.totalPrepMinutes,
    required this.highlights,
    this.estimatedMealsCovered = 1,
    this.pantrySupportItems = const [],
    this.primarySource,
    this.sourceTravelMinutes,
  });

  final String title;
  final String summary;
  final List<ScoredFood> items;
  final Nutrients totalNutrients;
  final double totalCost;
  final int totalPrepMinutes;
  final List<String> highlights;
  final int estimatedMealsCovered;
  final List<String> pantrySupportItems;
  final AvailabilityContext? primarySource;
  final int? sourceTravelMinutes;
}

enum TodayPlanType {
  emergency,
  pantryFirst,
  restockRun,
  wicStaples,
  snapRun,
  oneStop,
  fallback,
}

enum PlannedPurchasePriority { buyFirst, ifBudgetLeft, skipFirst }

class PlannedPurchase {
  const PlannedPurchase({
    required this.label,
    required this.priority,
    this.detail,
    this.estimatedCost,
  });

  final String label;
  final PlannedPurchasePriority priority;
  final String? detail;
  final double? estimatedCost;
}

class PlanCheckpoint {
  const PlanCheckpoint({required this.title, required this.detail});

  final String title;
  final String detail;
}

enum SourceTripMission {
  emergency,
  pantryStretch,
  restock,
  benefitsRun,
  oneStopMeal,
  fallback,
}

class SourceTripPlan {
  const SourceTripPlan({
    required this.mission,
    required this.primarySource,
    required this.title,
    required this.summary,
    required this.reasons,
    required this.highlights,
    this.bestFor = const [],
    this.backupSource,
    this.communityLabel,
    this.travelMinutes,
    this.snapshotNote,
    this.routeReason,
    this.benefitSummary,
    this.confidenceSummary,
    this.dataSourceSummary,
  });

  final SourceTripMission mission;
  final AvailabilityContext primarySource;
  final AvailabilityContext? backupSource;
  final String title;
  final String summary;
  final List<String> reasons;
  final List<String> highlights;
  final List<String> bestFor;
  final String? communityLabel;
  final int? travelMinutes;
  final String? snapshotNote;
  final String? routeReason;
  final String? benefitSummary;
  final String? confidenceSummary;
  final String? dataSourceSummary;
}

class TodayPlan {
  const TodayPlan({
    required this.type,
    required this.title,
    required this.summary,
    required this.steps,
    required this.highlights,
    required this.leadRecommendation,
    this.basket,
    this.backupAction,
    this.restockItems = const [],
    this.purchases = const [],
    this.checkpoints = const [],
    this.routeReason,
    this.benefitSummary,
    this.confidenceSummary,
    this.dataSourceSummary,
  });

  final TodayPlanType type;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> highlights;
  final ScoredFood leadRecommendation;
  final MealBasketPlan? basket;
  final String? backupAction;
  final List<String> restockItems;
  final List<PlannedPurchase> purchases;
  final List<PlanCheckpoint> checkpoints;
  final String? routeReason;
  final String? benefitSummary;
  final String? confidenceSummary;
  final String? dataSourceSummary;
}

class RecommendationResult {
  const RecommendationResult({
    required this.recommendations,
    required this.preferenceRelaxed,
    required this.candidatePoolSize,
    required this.elapsedMs,
    this.baskets = const [],
    this.sourceTripPlan,
    this.todayPlan,
    this.diagnostic,
  });

  final List<ScoredFood> recommendations;
  final bool preferenceRelaxed;
  final int candidatePoolSize;
  final int elapsedMs;
  final List<MealBasketPlan> baskets;
  final SourceTripPlan? sourceTripPlan;
  final TodayPlan? todayPlan;
  final InsufficientCandidatesAnalysis? diagnostic;

  bool get isEmpty => recommendations.isEmpty;
}
