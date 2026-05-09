import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';

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
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'These are softer than safety and feasibility. The engine can relax them if the candidate pool gets too small.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Meal type now',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
        const SizedBox(height: 24),
        DropdownButtonFormField<String?>(
          key: ValueKey(preference.cuisinePreference),
          initialValue: preference.cuisinePreference,
          decoration: const InputDecoration(labelText: 'Cuisine preference'),
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
        const SizedBox(height: 24),
        Text(
          'Disliked ingredients',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                controller.setStage(OnboardingStage.feasibility);
              },
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                controller.setStage(OnboardingStage.targets);
              },
              child: const Text('Next'),
            ),
          ],
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
