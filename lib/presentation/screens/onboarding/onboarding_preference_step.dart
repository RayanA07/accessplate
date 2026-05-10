import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingPreferenceStep extends ConsumerStatefulWidget {
  const OnboardingPreferenceStep({super.key});

  @override
  ConsumerState<OnboardingPreferenceStep> createState() =>
      _OnboardingPreferenceStepState();
}

class _OnboardingPreferenceStepState
    extends ConsumerState<OnboardingPreferenceStep> {
  final _dislikeController = TextEditingController();

  static const _cuisines = <String>[
    'mexican',
    'mediterranean',
    'asian',
    'indian',
    'american',
    'italian',
  ];

  @override
  void dispose() {
    _dislikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 18),
              DropdownButtonFormField<String?>(
                key: ValueKey(preference.cuisinePreference),
                initialValue: preference.cuisinePreference,
                decoration: const InputDecoration(
                  labelText: 'Cuisine preference',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No preference'),
                  ),
                  ..._cuisines.map(
                    (cuisine) => DropdownMenuItem<String?>(
                      value: cuisine,
                      child: Text(_labelize(cuisine)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  controller.updatePreference(
                    preference.copyWith(
                      cuisinePreference: value,
                      clearCuisinePreference: value == null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disliked ingredients',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'These are treated as exclusions, so only add ingredients you really want to avoid.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dislikeController,
                      decoration: const InputDecoration(
                        hintText: 'Add one ingredient',
                      ),
                      onSubmitted: (_) => _addDislike(preference),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _addDislike(preference),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (preference.dislikedIngredients.isEmpty)
                Text(
                  'Nothing excluded yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preference.dislikedIngredients.map((ingredient) {
                    return InputChip(
                      label: Text(_labelize(ingredient)),
                      onDeleted: () {
                        final next = {...preference.dislikedIngredients}
                          ..remove(ingredient);
                        controller.updatePreference(
                          preference.copyWith(dislikedIngredients: next),
                        );
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _addDislike(PreferenceConstraints preference) {
    final value = _dislikeController.text.trim().toLowerCase();
    if (value.isEmpty) {
      return;
    }
    final next = {...preference.dislikedIngredients, value};
    ref
        .read(profileControllerProvider.notifier)
        .updatePreference(preference.copyWith(dislikedIngredients: next));
    _dislikeController.clear();
  }

  static String _labelize(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
