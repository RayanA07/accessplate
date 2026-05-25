import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../copy/app_copy.dart';
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
    final copy = AppCopy(profile.constraints.access.language);

    return OnboardingStepLayout(
      title: copy.dietaryStyleTitle,
      subtitle: copy.dietaryStyleSubtitle,
      children: [
        for (final style in DietaryStyle.values) ...[
          SelectionTile(
            title: copy.dietaryStyleLabel(style),
            subtitle: copy.dietaryStyleDetail(style),
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
