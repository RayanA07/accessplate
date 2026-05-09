import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import 'onboarding_feasibility_step.dart';
import 'onboarding_preference_step.dart';
import 'onboarding_safety_step.dart';
import 'onboarding_splash_step.dart';
import 'onboarding_targets_step.dart';

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final stage = profile.onboardingStage;
    final progress = switch (stage) {
      OnboardingStage.splash => 0.0,
      OnboardingStage.safety => 0.25,
      OnboardingStage.feasibility => 0.5,
      OnboardingStage.preference => 0.75,
      OnboardingStage.targets => 1.0,
    };

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF17324D), Color(0xFF4A7BA0), Color(0xFFF0F6FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const _OnboardingHeader(),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SectionCard(
                        child: SingleChildScrollView(
                          child: switch (stage) {
                            OnboardingStage.splash =>
                              const OnboardingSplashStep(),
                            OnboardingStage.safety =>
                              const OnboardingSafetyStep(),
                            OnboardingStage.feasibility =>
                              const OnboardingFeasibilityStep(),
                            OnboardingStage.preference =>
                              const OnboardingPreferenceStep(),
                            OnboardingStage.targets =>
                              const OnboardingTargetsStep(),
                          },
                        ),
                      ),
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
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AccessPlate',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Offline dietary decision support for real-world constraints.',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
