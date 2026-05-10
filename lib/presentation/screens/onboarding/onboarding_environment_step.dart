import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preparation setup',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell the app what cooking equipment is realistically available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: PrepEnvironment.values.map((environment) {
              final selected = feasibility.environment == environment;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectionTile(
                  title: environment.label,
                  subtitle: switch (environment) {
                    PrepEnvironment.none => 'Ready-to-eat foods only.',
                    PrepEnvironment.microwave =>
                      'Microwave meals and simple reheating.',
                    PrepEnvironment.stoveTop =>
                      'Stovetop plus microwave meals.',
                    PrepEnvironment.fullKitchen =>
                      'All standard home cooking methods.',
                  },
                  icon: switch (environment) {
                    PrepEnvironment.none => Icons.flash_on_rounded,
                    PrepEnvironment.microwave => Icons.microwave_rounded,
                    PrepEnvironment.stoveTop => Icons.soup_kitchen_rounded,
                    PrepEnvironment.fullKitchen => Icons.kitchen_rounded,
                  },
                  selected: selected,
                  onTap: () => controller.updateEnvironment(environment),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
