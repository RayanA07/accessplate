import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';

class OnboardingTargetsStep extends ConsumerStatefulWidget {
  const OnboardingTargetsStep({super.key});

  @override
  ConsumerState<OnboardingTargetsStep> createState() =>
      _OnboardingTargetsStepState();
}

class _OnboardingTargetsStepState extends ConsumerState<OnboardingTargetsStep> {
  bool _manualTargets = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final demographics = profile.constraints.demographics;
    final targets = profile.constraints.targets;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Targets and health priorities',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your demographic context and meal targets. These power the micronutrient priorities and macro alignment score.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Sex',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: Sex.values.map((sex) {
            return ChoiceChip(
              selected: demographics.sex == sex,
              label: Text(sex == Sex.female ? 'Female' : 'Male'),
              onSelected: (_) {
                controller.updateDemographics(demographics.copyWith(sex: sex));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Age: ${demographics.ageYears}'),
        Slider(
          min: 14,
          max: 75,
          divisions: 61,
          value: demographics.ageYears.toDouble(),
          onChanged: (value) {
            controller.updateDemographics(
              demographics.copyWith(ageYears: value.round()),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Health concerns',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HealthConcern.values.map((concern) {
            final selected = demographics.concerns.contains(concern);
            return FilterChip(
              selected: selected,
              label: Text(concern.label),
              onSelected: (value) {
                final next = {...demographics.concerns};
                value ? next.add(concern) : next.remove(concern);
                controller.updateDemographics(
                  demographics.copyWith(concerns: next),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Meal calories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text('${targets.calories.toStringAsFixed(0)} kcal'),
        Slider(
          min: 250,
          max: 900,
          divisions: 13,
          value: targets.calories.clamp(250, 900),
          onChanged: (value) {
            if (_manualTargets) {
              controller.updateTargets(targets.copyWith(calories: value));
            } else {
              controller.updateTargets(
                _deriveTargets(
                  caloriesPerMeal: value,
                  currentMeal: profile.constraints.preference.mealType,
                ),
              );
            }
          },
        ),
        SwitchListTile(
          value: _manualTargets,
          title: const Text('Fine-tune macros manually'),
          subtitle: const Text('Leave this off to keep the default 20/50/30 split.'),
          onChanged: (value) {
            setState(() {
              _manualTargets = value;
            });
          },
        ),
        if (_manualTargets) ...[
          _MacroSlider(
            label: 'Protein',
            unit: 'g',
            value: targets.proteinG,
            min: 8,
            max: 60,
            onChanged: (value) {
              controller.updateTargets(targets.copyWith(proteinG: value));
            },
          ),
          _MacroSlider(
            label: 'Carbs',
            unit: 'g',
            value: targets.carbsG,
            min: 20,
            max: 120,
            onChanged: (value) {
              controller.updateTargets(targets.copyWith(carbsG: value));
            },
          ),
          _MacroSlider(
            label: 'Fat',
            unit: 'g',
            value: targets.fatG,
            min: 6,
            max: 40,
            onChanged: (value) {
              controller.updateTargets(targets.copyWith(fatG: value));
            },
          ),
          _MacroSlider(
            label: 'Fiber',
            unit: 'g',
            value: targets.fiberG,
            min: 2,
            max: 20,
            onChanged: (value) {
              controller.updateTargets(targets.copyWith(fiberG: value));
            },
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                controller.setStage(OnboardingStage.preference);
              },
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                controller.completeOnboarding();
              },
              child: const Text('See recommendations'),
            ),
          ],
        ),
      ],
    );
  }

  NutritionalTargets _deriveTargets({
    required double caloriesPerMeal,
    required MealType currentMeal,
  }) {
    final split = switch (currentMeal) {
      MealType.breakfast => 0.30,
      MealType.lunch => 0.35,
      MealType.dinner => 0.30,
      MealType.snack => 0.05,
      MealType.any => 0.30,
    };
    final adjustedCalories = caloriesPerMeal / split * split;
    return NutritionalTargets(
      calories: caloriesPerMeal,
      proteinG: (adjustedCalories * 0.20) / 4,
      carbsG: (adjustedCalories * 0.50) / 4,
      fatG: (adjustedCalories * 0.30) / 9,
      fiberG: (adjustedCalories / 1000) * 14,
    );
  }
}

class _MacroSlider extends StatelessWidget {
  const _MacroSlider({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(0)}$unit'),
          Slider(
            min: min,
            max: max,
            divisions: (max - min).round(),
            value: value.clamp(min, max),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
