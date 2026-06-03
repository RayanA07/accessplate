import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingPreferenceStep extends ConsumerWidget {
  const OnboardingPreferenceStep({super.key});

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
          'Preferences',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Use this screen for softer preferences and dietary style. These should feel intuitive, not medical.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dietary style',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This filter is preserved when the engine relaxes other preferences.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ...DietaryStyle.values.map((style) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectionTile(
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
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal timing',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MealType.values.map((mealType) {
                  return ChoiceChip(
                    selected: preference.mealType == mealType,
                    label: Text(mealType.label),
                    onSelected: (_) => controller.updateMealType(mealType),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
