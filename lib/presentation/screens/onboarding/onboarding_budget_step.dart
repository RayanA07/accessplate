import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
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
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose(
        'What\u2019s your\nmeal budget?',
        'Cual es tu\npresupuesto?',
      ),
      subtitle: copy.choose(
        'Set the maximum you want the engine to spend on one meal.',
        'Pon el maximo que quieres gastar en una comida.',
      ),
      topSpacing: 18,
      children: [
        SectionCard(
          child: Column(
            children: [
              OnboardingMetaLabel(
                copy.choose('Budget per meal', 'Presupuesto por comida'),
              ),
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
                max: 30,
                divisions: 29,
                value: feasibility.maxCostPerMeal.clamp(1, 30),
                onChanged: controller.updateBudget,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      '\$1',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$30',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                copy.choose(
                  'The engine will favor foods at or below this cost target.',
                  'La app favorecera comida en este costo o menos.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8F8F95),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                copy.choose(
                  'Set to \$0-\$5 if you rely on a food pantry or SNAP.',
                  'Ponlo entre \$0 y \$5 si dependes de despensa de alimentos o SNAP.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
