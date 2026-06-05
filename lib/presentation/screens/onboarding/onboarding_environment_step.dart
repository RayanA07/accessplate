import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../copy/app_copy.dart';
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
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose('Preparation\nsetup', 'Equipo de\ncocina'),
      subtitle: copy.choose(
        'Tell the app what cooking equipment is realistically available.',
        'Dile a la app que equipo de cocina si esta disponible de verdad.',
      ),
      children: [
        for (final environment in PrepEnvironment.values) ...[
          SelectionTile(
            title: copy.prepEnvironmentLabel(environment),
            subtitle: copy.prepEnvironmentDetail(environment),
            icon: switch (environment) {
              PrepEnvironment.none => Icons.flash_on_rounded,
              PrepEnvironment.microwave => Icons.microwave_rounded,
              PrepEnvironment.stoveTop => Icons.local_fire_department_rounded,
              PrepEnvironment.fullKitchen => Icons.kitchen_rounded,
            },
            selected: feasibility.environment == environment,
            visualStyle: SelectionTileVisualStyle.prominentRadio,
            onTap: () => controller.updateEnvironment(environment),
          ),
          if (environment != PrepEnvironment.values.last)
            const SizedBox(height: 14),
        ],
      ],
    );
  }
}
