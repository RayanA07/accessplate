import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final progress =
        (_orderedStages.indexOf(stage) + 1) / _orderedStages.length;
    final compact = MediaQuery.sizeOf(context).height < 760;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, compact ? 8 : 10, 16, 0),
          child: Column(
            children: [
              _MockStatusBar(meta: _statusMetaFor(stage)),
              SizedBox(height: compact ? 10 : 14),
              _FlowHeader(
                progress: progress,
                canGoBack: stage != _orderedStages.first,
                onBack: () => _goBack(controller, stage),
              ),
              SizedBox(height: compact ? 18 : 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(stage),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: switch (stage) {
                        OnboardingStage.splash => const OnboardingSplashStep(),
                        OnboardingStage.allergens =>
                          const OnboardingAllergensStep(),
                        OnboardingStage.religion =>
                          const OnboardingReligionStep(),
                        OnboardingStage.medical =>
                          const OnboardingMedicalStep(),
                        OnboardingStage.budget => const OnboardingBudgetStep(),
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
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              _ContinueButton(
                label: switch (stage) {
                  OnboardingStage.splash => 'Get started',
                  OnboardingStage.targets => 'See recommendations',
                  _ => 'Continue',
                },
                onPressed: () => _goForward(controller, stage),
              ),
              SizedBox(height: compact ? 14 : 18),
              const _HomeIndicator(),
              SizedBox(height: compact ? 8 : 10),
            ],
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

  _StatusMeta _statusMetaFor(OnboardingStage stage) {
    switch (stage) {
      case OnboardingStage.splash:
        return const _StatusMeta(timer: '0:08', battery: '23');
      case OnboardingStage.allergens:
        return const _StatusMeta(timer: '0:16', battery: '23');
      case OnboardingStage.religion:
        return const _StatusMeta(timer: '0:47', battery: '22');
      case OnboardingStage.medical:
        return const _StatusMeta(timer: '0:49', battery: '22');
      case OnboardingStage.budget:
        return const _StatusMeta(timer: '0:38', battery: '22');
      case OnboardingStage.environment:
        return const _StatusMeta(timer: '0:33', battery: '22');
      case OnboardingStage.availability:
        return const _StatusMeta(timer: '0:41', battery: '22');
      case OnboardingStage.dietaryStyle:
        return const _StatusMeta(timer: '0:27', battery: '22');
      case OnboardingStage.mealTiming:
        return const _StatusMeta(timer: '0:20', battery: '22');
      case OnboardingStage.cuisine:
        return const _StatusMeta(timer: '0:25', battery: '22');
      case OnboardingStage.dislikes:
        return const _StatusMeta(timer: '0:18', battery: '22');
      case OnboardingStage.profile:
        return const _StatusMeta(timer: '0:15', battery: '22');
      case OnboardingStage.targets:
        return const _StatusMeta(timer: '0:12', battery: '22');
    }
  }
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar({required this.meta});

  final _StatusMeta meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '6:18',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA84A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, size: 11, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(
                  meta.timer,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF69FF72),
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                    7,
                    (index) => Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1.2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9C55E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE39C1A),
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 9, height: 9),
        ),
        const SizedBox(width: 8),
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              meta.battery,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B70),
              ),
            ),
          ),
        ),
      ],
    );
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
          width: 34,
          height: 34,
          child: canGoBack
              ? Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                  Container(color: const Color(0xFFF1F1F3)),
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({required this.timer, required this.battery});

  final String timer;
  final String battery;
}
