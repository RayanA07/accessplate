import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingCuisineStep extends ConsumerWidget {
  const OnboardingCuisineStep({super.key});

  static const _cuisines = <String>[
    'mexican',
    'mediterranean',
    'asian',
    'indian',
    'american',
    'italian',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(profile.constraints.access.language);

    return OnboardingStepLayout(
      title: copy.cuisineTitle,
      subtitle: copy.cuisineSubtitle,
      children: [
        SelectionTile(
          title: copy.cuisineNoPreferenceTitle,
          subtitle: copy.cuisineNoPreferenceSubtitle,
          icon: Icons.public_rounded,
          selected: preference.cuisinePreference == null,
          onTap: () {
            controller.updatePreference(
              preference.copyWith(clearCuisinePreference: true),
            );
          },
        ),
        const SizedBox(height: 14),
        for (final cuisine in _cuisines) ...[
          SelectionTile(
            title: copy.cuisineLabel(cuisine),
            icon: Icons.restaurant_menu_rounded,
            subtitle: copy.cuisineDetail(cuisine),
            selected: preference.cuisinePreference == cuisine,
            onTap: () {
              controller.updatePreference(
                preference.copyWith(cuisinePreference: cuisine),
              );
            },
          ),
          if (cuisine != _cuisines.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
