import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import 'onboarding_allergens_step.dart';
import 'onboarding_availability_step.dart';
import 'onboarding_budget_step.dart';
import 'onboarding_cuisine_step.dart';
import 'onboarding_dietary_style_step.dart';
import 'onboarding_dislikes_step.dart';
import 'onboarding_environment_step.dart';
import 'onboarding_meal_timing_step.dart';
import 'onboarding_medical_step.dart';
import 'onboarding_profile_step.dart';
import 'onboarding_religion_step.dart';
import 'onboarding_splash_step.dart';
import 'onboarding_targets_step.dart';

const _orderedStages = <OnboardingStage>[
  OnboardingStage.splash,
  OnboardingStage.allergens,
  OnboardingStage.religion,
  OnboardingStage.medical,
  OnboardingStage.budget,
  OnboardingStage.environment,
  OnboardingStage.availability,
  OnboardingStage.dietaryStyle,
  OnboardingStage.mealTiming,
  OnboardingStage.cuisine,
  OnboardingStage.dislikes,
  OnboardingStage.profile,
  OnboardingStage.targets,
];

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final controller = ref.read(profileControllerProvider.notifier);
    final stage = profile.onboardingStage;
    final progress = (_orderedStages.indexOf(stage) + 1) / _orderedStages.length;
    final isFirst = stage == _orderedStages.first;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NihPalette.lightBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 12 : 18,
                      compact ? 18 : 22,
                      compact ? 14 : 18,
                    ),
                    child: Column(
                      children: [
                        _FlowHeader(
                          progress: progress,
                          canGoBack: !isFirst,
                          onBack: () => _goBack(controller, stage),
                        ),
                        SizedBox(height: compact ? 18 : 26),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: compact ? 16 : 24),
                            child: switch (stage) {
                              OnboardingStage.splash =>
                                const OnboardingSplashStep(),
                              OnboardingStage.allergens =>
                                const OnboardingAllergensStep(),
                              OnboardingStage.religion =>
                                const OnboardingReligionStep(),
                              OnboardingStage.medical =>
                                const OnboardingMedicalStep(),
                              OnboardingStage.budget =>
                                const OnboardingBudgetStep(),
                              OnboardingStage.environment =>
                                const OnboardingEnvironmentStep(),
                              OnboardingStage.availability =>
                                const OnboardingAvailabilityStep(),
                              OnboardingStage.dietaryStyle =>
                                const OnboardingDietaryStyleStep(),
                              OnboardingStage.mealTiming =>
                                const OnboardingMealTimingStep(),
                              OnboardingStage.cuisine =>
                                const OnboardingCuisineStep(),
                              OnboardingStage.dislikes =>
                                const OnboardingDislikesStep(),
                              OnboardingStage.profile =>
                                const OnboardingProfileStep(),
                              OnboardingStage.targets =>
                                const OnboardingTargetsStep(),
                            },
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        _OnboardingActions(
                          stage: stage,
                          onBack: () => _goBack(controller, stage),
                          onNext: () => _goForward(controller, stage),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goBack(ProfileController controller, OnboardingStage stage) {
    final index = _orderedStages.indexOf(stage);
    if (index > 0) {
      controller.setStage(_orderedStages[index - 1]);
    }
  }

  void _goForward(ProfileController controller, OnboardingStage stage) {
    final index = _orderedStages.indexOf(stage);
    if (index == _orderedStages.length - 1) {
      controller.completeOnboarding();
      return;
    }

    controller.setStage(_orderedStages[index + 1]);
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.progress,
    required this.canGoBack,
    required this.onBack,
  });

  final double progress;
  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: canGoBack
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.stage,
    required this.onBack,
    required this.onNext,
  });

  final OnboardingStage stage;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final nextLabel = switch (stage) {
      OnboardingStage.splash => 'Get started',
      OnboardingStage.targets => 'See recommendations',
      _ => 'Continue',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(onPressed: onNext, child: Text(nextLabel)),
        if (stage != OnboardingStage.splash) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onBack, child: const Text('Back')),
        ],
      ],
    );
  }
}
