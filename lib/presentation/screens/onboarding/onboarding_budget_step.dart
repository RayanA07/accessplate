import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingBudgetStep extends ConsumerWidget {
  const OnboardingBudgetStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'What\u2019s your\nmeal budget?',
      subtitle: 'Set the maximum you want the engine to spend on one meal.',
      topSpacing: 44,
      children: [
        SectionCard(
          child: Column(
            children: [
              const OnboardingMetaLabel('Budget per meal'),
              const SizedBox(height: 10),
              Text(
                '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                key: const Key('budgetSlider'),
                min: 1,
                max: 15,
                divisions: 14,
                value: feasibility.maxCostPerMeal.clamp(1, 15),
                onChanged: controller.updateBudget,
              ),
              const SizedBox(height: 8),
              Text(
                'The engine will favor foods at or below this cost target.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8F8F95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
