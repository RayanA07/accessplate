import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
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

    return OnboardingStepLayout(
      title: 'Cuisine\npreference',
      subtitle:
          'This is a softer preference and can be relaxed when the result pool gets too small.',
      children: [
        SelectionTile(
          title: 'No preference',
          subtitle: 'Do not favor one cuisine family.',
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
            title: _labelize(cuisine),
            icon: Icons.restaurant_menu_rounded,
            subtitle:
                'Favor ${_labelize(cuisine).toLowerCase()} options when possible.',
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

  static String _labelize(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
