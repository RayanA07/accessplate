import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine preference',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a softer preference and can be relaxed when the result pool gets too small.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 10),
              ..._cuisines.map((cuisine) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectionTile(
                    title: _labelize(cuisine),
                    icon: Icons.restaurant_menu_rounded,
                    selected: preference.cuisinePreference == cuisine,
                    onTap: () {
                      controller.updatePreference(
                        preference.copyWith(cuisinePreference: cuisine),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
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
