import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class OnboardingTargetsStep extends ConsumerStatefulWidget {
  const OnboardingTargetsStep({super.key});

  @override
  ConsumerState<OnboardingTargetsStep> createState() =>
      _OnboardingTargetsStepState();
}

class _OnboardingTargetsStepState extends ConsumerState<OnboardingTargetsStep> {
  static const _defaultProteinPercent = 20.0;
  static const _defaultCarbPercent = 50.0;
  static const _minProteinPercent = 10.0;
  static const _maxProteinPercent = 40.0;
  static const _minCarbPercent = 20.0;
  static const _maxCarbPercent = 65.0;
  static const _minFatPercent = 15.0;

  bool _didSeedValues = false;
  double _calories = 700;
  double _proteinPercent = _defaultProteinPercent;
  double _carbPercent = _defaultCarbPercent;
  double _fiberTarget = 10;

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final targets = profile.constraints.targets;
    final controller = ref.read(profileControllerProvider.notifier);

    if (!_didSeedValues) {
      _seedFromTargets(targets);
    }

    final fatPercent = _fatPercent;
    final derivedTargets = _buildTargets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal targets',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a calorie goal, then set the meal balance as percentages instead of a fixed preset.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_calories.toStringAsFixed(0)} kcal',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Slider(
                min: 250,
                max: 900,
                divisions: 13,
                value: _calories.clamp(250, 900),
                onChanged: (value) {
                  setState(() {
                    _calories = value;
                  });
                  controller.updateTargets(_buildTargets());
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
                'Macronutrient mix',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'The three shares always add up to 100%.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Protein ${_proteinPercent.round()}%')),
                  Chip(label: Text('Carbs ${_carbPercent.round()}%')),
                  Chip(label: Text('Fat ${fatPercent.round()}%')),
                ],
              ),
              const SizedBox(height: 16),
              _PercentSlider(
                label: 'Protein share',
                value: _proteinPercent,
                min: _minProteinPercent,
                max: _maxProteinFor(_carbPercent),
                onChanged: (value) {
                  setState(() {
                    _proteinPercent = value;
                    _carbPercent = _carbPercent.clamp(
                      _minCarbPercent,
                      _maxCarbFor(_proteinPercent),
                    );
                  });
                  controller.updateTargets(_buildTargets());
                },
              ),
              _PercentSlider(
                label: 'Carb share',
                value: _carbPercent,
                min: _minCarbPercent,
                max: _maxCarbFor(_proteinPercent),
                onChanged: (value) {
                  setState(() {
                    _carbPercent = value;
                  });
                  controller.updateTargets(_buildTargets());
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Derived targets: ${derivedTargets.proteinG.toStringAsFixed(0)}g protein | ${derivedTargets.carbsG.toStringAsFixed(0)}g carbs | ${derivedTargets.fatG.toStringAsFixed(0)}g fat',
                style: Theme.of(context).textTheme.bodyMedium,
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
                'Fiber target',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${_fiberTarget.toStringAsFixed(0)} g',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Slider(
                min: 2,
                max: 20,
                divisions: 18,
                value: _fiberTarget.clamp(2, 20),
                onChanged: (value) {
                  setState(() {
                    _fiberTarget = value;
                  });
                  controller.updateTargets(_buildTargets());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  double get _fatPercent => 100 - _proteinPercent - _carbPercent;

  NutritionalTargets _buildTargets() {
    return NutritionalTargets(
      calories: _calories,
      proteinG: (_calories * (_proteinPercent / 100)) / 4,
      carbsG: (_calories * (_carbPercent / 100)) / 4,
      fatG: (_calories * (_fatPercent / 100)) / 9,
      fiberG: _fiberTarget,
    );
  }

  void _seedFromTargets(NutritionalTargets targets) {
    _didSeedValues = true;
    _calories = targets.calories.clamp(250, 900);
    _fiberTarget = targets.fiberG.clamp(2, 20);

    final macroCalories =
        targets.proteinG * 4 + targets.carbsG * 4 + targets.fatG * 9;
    if (macroCalories <= 0) {
      _proteinPercent = _defaultProteinPercent;
      _carbPercent = _defaultCarbPercent;
      return;
    }

    final proteinShare = (targets.proteinG * 4 / macroCalories) * 100;
    final carbShare = (targets.carbsG * 4 / macroCalories) * 100;
    _proteinPercent = proteinShare.clamp(
      _minProteinPercent,
      _maxProteinPercent,
    );
    _carbPercent = carbShare.clamp(
      _minCarbPercent,
      _maxCarbFor(_proteinPercent),
    );

    final remainingFat = 100 - _proteinPercent - _carbPercent;
    if (remainingFat < _minFatPercent) {
      _carbPercent = (100 - _proteinPercent - _minFatPercent).clamp(
        _minCarbPercent,
        _maxCarbPercent,
      );
    }
  }

  double _maxProteinFor(double carbPercent) {
    return (100 - carbPercent - _minFatPercent).clamp(
      _minProteinPercent,
      _maxProteinPercent,
    );
  }

  double _maxCarbFor(double proteinPercent) {
    return (100 - proteinPercent - _minFatPercent).clamp(
      _minCarbPercent,
      _maxCarbPercent,
    );
  }
}

class _PercentSlider extends StatelessWidget {
  const _PercentSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
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
          Text(
            '$label: ${value.round()}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
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
