import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import 'onboarding_access_step.dart';
import 'onboarding_body_stats_step.dart';
import 'onboarding_dietary_style_step.dart';
import 'onboarding_medical_step.dart';
import 'onboarding_name_step.dart';
import 'onboarding_pantry_step.dart';
import 'onboarding_shopping_setup_step.dart';
import 'onboarding_splash_step.dart';
import 'onboarding_targets_step.dart';

const _orderedStages = <OnboardingStage>[
  OnboardingStage.splash,
  OnboardingStage.name,
  OnboardingStage.age,
  OnboardingStage.budget,
  OnboardingStage.access,
  OnboardingStage.dietaryStyle,
  OnboardingStage.medical,
  OnboardingStage.pantry,
  OnboardingStage.targets,
];

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.valueOrNull;
    if (profile == null) {
      return const Scaffold(
        backgroundColor: NihPalette.mist,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final controller = ref.read(profileControllerProvider.notifier);
    final stage = _displayStage(profile.onboardingStage);
    final copy = AppCopy(profile.constraints.access.language);
    final progress = stage == OnboardingStage.splash
        ? 0.0
        : _orderedStages.indexOf(stage) / (_orderedStages.length - 1);
    final compact = MediaQuery.sizeOf(context).height < 760;
    final canContinue = _canContinue(profile, stage);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NihPalette.lightBackground),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, compact ? 10 : 14, 20, 20),
                child: Column(
                  children: [
                    if (stage != OnboardingStage.splash) ...[
                      _FlowHeader(
                        progress: progress,
                        canGoBack: stage != _orderedStages.first,
                        onBack: () => _goBack(controller, stage),
                      ),
                      SizedBox(height: compact ? 24 : 32),
                    ] else
                      SizedBox(height: compact ? 10 : 16),
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
                              OnboardingStage.name =>
                                const OnboardingNameStep(),
                              OnboardingStage.age ||
                              OnboardingStage.height ||
                              OnboardingStage.weight =>
                                const OnboardingBodyStatsStep(),
                              OnboardingStage.budget ||
                              OnboardingStage.environment ||
                              OnboardingStage.availability =>
                                const OnboardingShoppingSetupStep(),
                              OnboardingStage.access =>
                                const OnboardingAccessStep(),
                              OnboardingStage.dietaryStyle ||
                              OnboardingStage.allergens ||
                              OnboardingStage.religion ||
                              OnboardingStage.mealTiming =>
                                const OnboardingDietaryStyleStep(),
                              OnboardingStage.medical =>
                                const OnboardingMedicalStep(),
                              OnboardingStage.pantry =>
                                const OnboardingPantryStep(),
                              OnboardingStage.targets =>
                                const OnboardingTargetsStep(),
                              OnboardingStage.profile =>
                                const OnboardingBodyStatsStep(),
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    if (stage == OnboardingStage.splash) ...[
                      _ContinueButton(
                        label: copy.choose('Get started', 'Empezar'),
                        onPressed: () => _goForward(controller, stage),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            controller.applyEmergencyQuickSetup(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(copy.onboardingEmergencySetupLabel),
                      ),
                    ] else
                      _ContinueButton(
                        label: switch (stage) {
                          OnboardingStage.targets => copy.choose(
                            'See my meal suggestions →',
                            'Ver mis sugerencias de comidas →',
                          ),
                          _ => copy.choose('Continue', 'Continuar'),
                        },
                        onPressed: canContinue
                            ? () => _goForward(controller, stage)
                            : null,
                      ),
                  ],
                ),
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

  bool _canContinue(UserProfile profile, OnboardingStage stage) {
    switch (stage) {
      case OnboardingStage.name:
        return profile.localLogin.displayName.trim().isNotEmpty;
      default:
        return true;
    }
  }

  OnboardingStage _displayStage(OnboardingStage stage) {
    return switch (stage) {
      OnboardingStage.height || OnboardingStage.weight => OnboardingStage.age,
      OnboardingStage.environment ||
      OnboardingStage.availability => OnboardingStage.budget,
      OnboardingStage.profile => OnboardingStage.age,
      OnboardingStage.allergens ||
      OnboardingStage.religion ||
      OnboardingStage.mealTiming => OnboardingStage.dietaryStyle,
      _ => stage,
    };
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
                    color: NihPalette.warmSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: NihPalette.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: NihPalette.primary.withValues(alpha: 0.06),
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
                      color: NihPalette.primaryDarker,
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
                  Container(color: NihPalette.sandDark),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: NihPalette.primary),
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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: NihPalette.primary,
          disabledBackgroundColor: NihPalette.grayLight,
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
