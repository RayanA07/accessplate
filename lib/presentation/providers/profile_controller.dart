import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/scoring/composite_scorer.dart';
import '../../domain/engine/government_nutrition_guidance.dart';
import '../../domain/entities/demographics.dart';
import '../../domain/entities/grocery.dart';
import '../../domain/entities/local_login.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/benefit_program.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../../domain/value_objects/transportation_mode.dart';
import '../../domain/value_objects/user_language.dart';
import 'app_bootstrap.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile> {
  static const _guidance = GovernmentNutritionGuidance();

  @override
  Future<UserProfile> build() async {
    final bootstrap = await ref.watch(appBootstrapProvider.future);
    final profile = await bootstrap.updateProfileUseCase.loadOrDefault();
    final normalized = _normalizedProfile(profile);
    if (normalized != profile) {
      await bootstrap.updateProfileUseCase.save(normalized);
    }
    return normalized;
  }

  Future<void> setStage(OnboardingStage stage) async {
    await _persist(
      current.copyWith(onboardingStage: stage, onboardingComplete: false),
    );
  }

  Future<void> completeOnboarding() async {
    await _persist(
      current.copyWith(
        onboardingComplete: true,
        onboardingStage: OnboardingStage.targets,
      ),
    );
  }

  Future<void> reopenOnboarding({
    OnboardingStage stage = OnboardingStage.splash,
  }) {
    return _persist(
      current.copyWith(onboardingComplete: false, onboardingStage: stage),
    );
  }

  Future<void> updateSafety(SafetyConstraints safety) {
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(safety: safety),
      ),
    );
  }

  Future<void> updateFeasibility(FeasibilityConstraints feasibility) {
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(feasibility: feasibility),
      ),
    );
  }

  Future<void> updatePreference(PreferenceConstraints preference) {
    final normalizedPreference = _normalizedPreference(preference);
    final nextConstraints = _syncedConstraints(
      current.constraints.copyWith(preference: normalizedPreference),
    );
    return _persist(current.copyWith(constraints: nextConstraints));
  }

  Future<void> updateAccess(AccessConstraints access) {
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(access: access),
      ),
    );
  }

  Future<void> updatePantry(PantryConstraints pantry) {
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(pantry: pantry),
      ),
    );
  }

  Future<void> updateTargets(NutritionalTargets targets) {
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(targets: targets),
      ),
    );
  }

  Future<void> updateDemographics(Demographics demographics) {
    final nextConstraints = _syncedConstraints(
      current.constraints.copyWith(demographics: demographics),
    );
    return _persist(current.copyWith(constraints: nextConstraints));
  }

  Future<void> updateDisplayName(String displayName) {
    return _persist(
      current.copyWith(
        localLogin: current.localLogin.copyWith(
          displayName: displayName.trim(),
        ),
      ),
    );
  }

  Future<void> updateBudget(double budget) {
    final feasibility = current.constraints.feasibility.copyWith(
      maxCostPerMeal: budget,
    );
    return updateFeasibility(feasibility);
  }

  Future<void> updateEnvironment(PrepEnvironment environment) {
    final feasibility = current.constraints.feasibility.copyWith(
      environment: environment,
    );
    return updateFeasibility(feasibility);
  }

  Future<void> updateAvailability(Set<AvailabilityContext> availability) {
    final feasibility = current.constraints.feasibility.copyWith(
      availability: availability,
      clearGroceryStore: !availability.contains(AvailabilityContext.grocery),
    );
    return updateFeasibility(feasibility);
  }

  Future<void> updateGroceryStore(GroceryStore? groceryStore) {
    final feasibility = current.constraints.feasibility.copyWith(
      groceryStore: groceryStore,
      clearGroceryStore: groceryStore == null,
    );
    return updateFeasibility(feasibility);
  }

  Future<void> updatePostalCode(String postalCode) {
    final access = current.constraints.access.copyWith(postalCode: postalCode);
    return updateAccess(access);
  }

  Future<void> updateTransportation(TransportationMode transportation) {
    final access = current.constraints.access.copyWith(
      transportation: transportation,
    );
    return updateAccess(access);
  }

  Future<void> updateMaxTravelMinutes(int maxTravelMinutes) {
    final access = current.constraints.access.copyWith(
      maxTravelMinutes: maxTravelMinutes,
    );
    return updateAccess(access);
  }

  Future<void> updateBenefitPrograms(Set<BenefitProgram> benefitPrograms) {
    final access = current.constraints.access.copyWith(
      benefitPrograms: benefitPrograms,
    );
    return updateAccess(access);
  }

  Future<void> updateEmergencyMode(bool emergencyMode) {
    final access = current.constraints.access.copyWith(
      emergencyMode: emergencyMode,
    );
    return updateAccess(access);
  }

  Future<void> updateLanguage(UserLanguage language) {
    final access = current.constraints.access.copyWith(language: language);
    return updateAccess(access);
  }

  Future<void> updatePlainLanguage(bool plainLanguage) {
    final access = current.constraints.access.copyWith(
      plainLanguage: plainLanguage,
    );
    return updateAccess(access);
  }

  Future<void> updatePantryItems(Set<String> itemsOnHand) {
    final currentPantry = current.constraints.pantry;
    final next = <String, PantryStockLevel>{
      for (final entry in currentPantry.stockByItem.entries)
        if (entry.value == PantryStockLevel.out) entry.key: entry.value,
    };
    for (final item in itemsOnHand) {
      final normalized = item.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      next[normalized] =
          currentPantry.stockFor(normalized) == PantryStockLevel.low
          ? PantryStockLevel.low
          : PantryStockLevel.enough;
    }
    return updatePantryStock(next);
  }

  Future<void> updatePantryStock(Map<String, PantryStockLevel> stockByItem) {
    final pantry = current.constraints.pantry.copyWith(
      stockByItem: stockByItem,
    );
    return updatePantry(pantry);
  }

  Future<void> updatePantryItemState(String item, PantryStockLevel? level) {
    final pantry = current.constraints.pantry.withItem(item, level);
    return updatePantry(pantry);
  }

  Future<void> updateMealType(MealType mealType) {
    final preference = current.constraints.preference.copyWith(
      mealType: mealType,
    );
    return updatePreference(preference);
  }

  Future<void> configureLocalLogin({
    required String displayName,
    required String pin,
  }) {
    return _persist(
      current.copyWith(
        localLogin: LocalLogin.create(displayName: displayName, pin: pin),
      ),
    );
  }

  Future<void> logRecommendation(ScoredFood recommendation) {
    final next = _withLoggedNutrients(
      current.constraints,
      nutrients: recommendation.nutrients,
      actedIds: {recommendation.food.id},
    );
    return _persist(current.copyWith(constraints: next));
  }

  Future<void> logBasket(MealBasketPlan basket) {
    final actedIds = basket.items.map((item) => item.food.id).toSet();
    final next = _withLoggedNutrients(
      current.constraints,
      nutrients: basket.totalNutrients,
      actedIds: actedIds,
    );
    return _persist(current.copyWith(constraints: next));
  }

  Future<void> resetDailyTracking() {
    final now = DateTime.now();
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(
          todayIntake: const {},
          todayIntakeDate: DateTime(now.year, now.month, now.day),
        ),
      ),
    );
  }

  Future<void> updateWeights(CompositeWeights weights) {
    return _persist(current.copyWith(scoringWeights: weights.normalized()));
  }

  Future<void> updateThemePreference(AppThemePreference themePreference) {
    return _persist(current.copyWith(themePreference: themePreference));
  }

  Future<void> resetProfile() async {
    final bootstrap = await ref.read(appBootstrapProvider.future);
    final fresh = UserProfile.defaults();
    state = AsyncData(fresh);
    await bootstrap.updateProfileUseCase.clear();
  }

  UserProfile get current => state.value ?? UserProfile.defaults();

  Future<void> _persist(UserProfile next) async {
    state = AsyncData(next);
    final bootstrap = await ref.read(appBootstrapProvider.future);
    await bootstrap.updateProfileUseCase.save(next);
  }

  UserProfile _normalizedProfile(UserProfile profile) {
    final baseConstraints = _normalizedBudget(
      _normalizedTracking(profile.constraints),
    );
    final normalizedPreference = _normalizedPreference(
      baseConstraints.preference,
    );
    final normalizedConstraints = _syncedConstraints(
      normalizedPreference == baseConstraints.preference
          ? baseConstraints
          : baseConstraints.copyWith(preference: normalizedPreference),
    );
    final normalizedStage = _normalizedOnboardingStage(profile.onboardingStage);
    if (normalizedConstraints == profile.constraints &&
        normalizedStage == profile.onboardingStage) {
      return profile;
    }
    return profile.copyWith(
      constraints: normalizedConstraints,
      onboardingStage: normalizedStage,
    );
  }

  UserConstraints _syncedConstraints(UserConstraints constraints) {
    if (!_guidance.hasPersonalizedInputs(constraints.demographics)) {
      return constraints;
    }
    final mealTargets = _guidance.mealTargetsFor(
      demographics: constraints.demographics,
      mealType: constraints.preference.mealType,
    );
    if (_sameTargets(constraints.targets, mealTargets)) {
      return constraints;
    }
    return constraints.copyWith(targets: mealTargets);
  }

  UserConstraints _normalizedTracking(UserConstraints constraints) {
    final trackingDate = constraints.todayIntakeDate;
    if (trackingDate == null ||
        _sameCalendarDay(trackingDate, DateTime.now())) {
      return constraints;
    }
    final today = DateTime.now();
    return constraints.copyWith(
      todayIntake: const {},
      todayIntakeDate: DateTime(today.year, today.month, today.day),
    );
  }

  PreferenceConstraints _normalizedPreference(
    PreferenceConstraints preference,
  ) {
    if (preference.cuisinePreference == null &&
        preference.dislikedIngredients.isEmpty) {
      return preference;
    }
    return preference.copyWith(
      clearCuisinePreference: true,
      dislikedIngredients: const {},
    );
  }

  UserConstraints _normalizedBudget(UserConstraints constraints) {
    final budget = constraints.feasibility.maxCostPerMeal;
    if (budget > 0 && budget != 5) {
      return constraints;
    }
    return constraints.copyWith(
      feasibility: constraints.feasibility.copyWith(maxCostPerMeal: 20),
    );
  }

  OnboardingStage _normalizedOnboardingStage(OnboardingStage stage) {
    switch (stage) {
      case OnboardingStage.splash:
      case OnboardingStage.name:
      case OnboardingStage.age:
      case OnboardingStage.height:
      case OnboardingStage.weight:
      case OnboardingStage.profile:
      case OnboardingStage.budget:
      case OnboardingStage.environment:
      case OnboardingStage.availability:
      case OnboardingStage.access:
      case OnboardingStage.dietaryStyle:
      case OnboardingStage.pantry:
      case OnboardingStage.allergens:
      case OnboardingStage.religion:
      case OnboardingStage.medical:
      case OnboardingStage.targets:
        return stage;
      case OnboardingStage.mealTiming:
        return OnboardingStage.allergens;
    }
  }

  UserConstraints _withLoggedNutrients(
    UserConstraints constraints, {
    required Nutrients nutrients,
    required Set<int> actedIds,
  }) {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final isFreshDay =
        constraints.todayIntakeDate != null &&
        _sameCalendarDay(constraints.todayIntakeDate!, now);
    final currentIntake = isFreshDay
        ? constraints.todayIntake
        : const <String, double>{};
    final merged = <String, double>{...currentIntake};
    for (final entry in nutrients.toIntakeMap().entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    final recentlyActed = <int, DateTime>{...constraints.recentlyActed};
    for (final id in actedIds) {
      recentlyActed[id] = now;
    }
    return constraints.copyWith(
      todayIntake: merged,
      todayIntakeDate: baseDate,
      recentlyActed: recentlyActed,
    );
  }

  bool _sameTargets(NutritionalTargets a, NutritionalTargets b) {
    return a.calories == b.calories &&
        a.proteinG == b.proteinG &&
        a.carbsG == b.carbsG &&
        a.fatG == b.fatG &&
        a.fiberG == b.fiberG;
  }

  bool _sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
