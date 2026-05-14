import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingEnvironmentStep extends ConsumerWidget {
  const OnboardingEnvironmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'Preparation\nsetup',
      subtitle:
          'Tell the app what cooking equipment is realistically available.',
      children: [
        for (final environment in PrepEnvironment.values) ...[
          SelectionTile(
            title: environment.label,
            subtitle: switch (environment) {
              PrepEnvironment.none => 'Ready-to-eat foods only.',
              PrepEnvironment.microwave =>
                'Microwave meals and simple reheating.',
              PrepEnvironment.stoveTop => 'Stovetop plus microwave meals.',
              PrepEnvironment.fullKitchen =>
                'All standard home cooking methods.',
            },
            icon: switch (environment) {
              PrepEnvironment.none => Icons.flash_on_rounded,
              PrepEnvironment.microwave => Icons.microwave_rounded,
              PrepEnvironment.stoveTop => Icons.soup_kitchen_rounded,
              PrepEnvironment.fullKitchen => Icons.kitchen_rounded,
            },
            selected: feasibility.environment == environment,
            onTap: () => controller.updateEnvironment(environment),
          ),
          if (environment != PrepEnvironment.values.last)
            const SizedBox(height: 14),
        ],
      ],
    );
  }
}
