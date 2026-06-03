import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import 'onboarding_allergens_step.dart';
import 'onboarding_access_step.dart';
import 'onboarding_availability_step.dart';
import 'onboarding_budget_step.dart';
import 'onboarding_cuisine_step.dart';
import 'onboarding_dietary_style_step.dart';
import 'onboarding_dislikes_step.dart';
import 'onboarding_environment_step.dart';
import 'onboarding_meal_timing_step.dart';
import 'onboarding_medical_step.dart';
import 'onboarding_pantry_step.dart';
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
  OnboardingStage.access,
  OnboardingStage.dietaryStyle,
  OnboardingStage.mealTiming,
  OnboardingStage.cuisine,
  OnboardingStage.dislikes,
  OnboardingStage.pantry,
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
    final copy = AppCopy(profile.constraints.access.language);
    final progress =
        (_orderedStages.indexOf(stage) + 1) / _orderedStages.length;
    final compact = MediaQuery.sizeOf(context).height < 760;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 10 : 14, 20, 20),
              child: Column(
                children: [
                  _FlowHeader(
                    progress: progress,
                    canGoBack: stage != _orderedStages.first,
                    onBack: () => _goBack(controller, stage),
                  ),
                  SizedBox(height: compact ? 24 : 32),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(stage),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 20),
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
                            OnboardingStage.access =>
                              const OnboardingAccessStep(),
                            OnboardingStage.dietaryStyle =>
                              const OnboardingDietaryStyleStep(),
                            OnboardingStage.mealTiming =>
                              const OnboardingMealTimingStep(),
                            OnboardingStage.cuisine =>
                              const OnboardingCuisineStep(),
                            OnboardingStage.dislikes =>
                              const OnboardingDislikesStep(),
                            OnboardingStage.pantry =>
                              const OnboardingPantryStep(),
                            OnboardingStage.profile =>
                              const OnboardingProfileStep(),
                            OnboardingStage.targets =>
                              const OnboardingTargetsStep(),
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  _ContinueButton(
                    label: switch (stage) {
                      OnboardingStage.splash => copy.choose(
                        'Get started',
                        'Empezar',
                      ),
                      OnboardingStage.targets => copy.choose(
                        'See recommendations',
                        'Ver opciones',
                      ),
                      _ => copy.choose('Continue', 'Continuar'),
                    },
                    onPressed: () => _goForward(controller, stage),
                  ),
                ],
              ),
            ),
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
          width: 36,
          height: 36,
          child: canGoBack
              ? Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEEEEF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x09000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF8A8A90),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFF1F1F4)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: const Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
