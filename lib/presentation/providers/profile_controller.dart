import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/scoring/composite_scorer.dart';
import '../../domain/entities/demographics.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/prep_environment.dart';
import 'app_bootstrap.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final bootstrap = await ref.watch(appBootstrapProvider.future);
    return bootstrap.updateProfileUseCase.loadOrDefault();
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
    OnboardingStage stage = OnboardingStage.allergens,
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
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(preference: preference),
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
    return _persist(
      current.copyWith(
        constraints: current.constraints.copyWith(demographics: demographics),
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
    );
    return updateFeasibility(feasibility);
  }

  Future<void> updateMealType(MealType mealType) {
    final preference = current.constraints.preference.copyWith(
      mealType: mealType,
    );
    return updatePreference(preference);
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
}
