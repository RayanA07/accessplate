import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingDietaryStyleStep extends ConsumerWidget {
  const OnboardingDietaryStyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'Dietary\nstyle',
      subtitle: 'Choose the diet style that should always stay in place.',
      children: [
        for (final style in DietaryStyle.values) ...[
          SelectionTile(
            title: style.label,
            subtitle: style.description,
            icon: switch (style) {
              DietaryStyle.unrestricted => Icons.restaurant_rounded,
              DietaryStyle.vegetarian => Icons.eco_rounded,
              DietaryStyle.vegan => Icons.spa_rounded,
            },
            selected: preference.dietaryStyle == style,
            onTap: () {
              controller.updatePreference(
                preference.copyWith(dietaryStyle: style),
              );
            },
          ),
          if (style != DietaryStyle.values.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
