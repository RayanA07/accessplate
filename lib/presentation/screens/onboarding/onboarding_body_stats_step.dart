import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingBodyStatsStep extends ConsumerStatefulWidget {
  const OnboardingBodyStatsStep({super.key});

  @override
  ConsumerState<OnboardingBodyStatsStep> createState() =>
      _OnboardingBodyStatsStepState();
}

class _OnboardingBodyStatsStepState
    extends ConsumerState<OnboardingBodyStatsStep> {
  late FixedExtentScrollController _ageController;
  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;
  int? _seedAge;
  int? _seedHeightInches;
  int? _seedWeightPounds;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final demographics = profile.constraints.demographics;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(profile.constraints.access.language);
    final age = demographics.ageYears.clamp(14, 75);
    final heightInches = ((demographics.heightCm ?? 66 * 2.54) / 2.54)
        .round()
        .clamp(48, 84);
    final weightPounds = ((demographics.weightKg ?? 180 / 2.20462) * 2.20462)
        .round()
        .clamp(80, 450);
    _seedControllers(
      age: age,
      heightInches: heightInches,
      weightPounds: weightPounds,
    );

    return OnboardingStepLayout(
      title: copy.choose('Your body stats', 'Datos de tu cuerpo'),
      subtitle: copy.choose(
        'Used to calculate your daily calorie and macro targets.',
        'Se usa para calcular tus calorias diarias y metas de macros.',
      ),
      topSpacing: 24,
      children: [
        _BodyStatPickerCard(
          label: copy.choose('Age', 'Edad'),
          valueText: '$age',
          picker: CupertinoPicker(
            scrollController: _ageController,
            itemExtent: 38,
            useMagnifier: true,
            magnification: 1.06,
            diameterRatio: 1.3,
            selectionOverlay: _selectionOverlay(),
            onSelectedItemChanged: (index) {
              controller.updateDemographics(
                demographics.copyWith(ageYears: index + 14),
              );
            },
            children: List.generate(
              62,
              (index) => _pickerText('${index + 14}'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _BodyStatPickerCard(
          label: copy.choose('Height', 'Altura'),
          valueText: _formatHeight(heightInches),
          picker: CupertinoPicker(
            scrollController: _heightController,
            itemExtent: 38,
            useMagnifier: true,
            magnification: 1.06,
            diameterRatio: 1.3,
            selectionOverlay: _selectionOverlay(),
            onSelectedItemChanged: (index) {
              controller.updateDemographics(
                demographics.copyWith(heightCm: (index + 48) * 2.54),
              );
            },
            children: List.generate(
              37,
              (index) => _pickerText(_formatHeight(index + 48)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _BodyStatPickerCard(
          label: copy.choose('Weight', 'Peso'),
          valueText: '$weightPounds lbs',
          picker: CupertinoPicker(
            scrollController: _weightController,
            itemExtent: 38,
            useMagnifier: true,
            magnification: 1.06,
            diameterRatio: 1.3,
            selectionOverlay: _selectionOverlay(),
            onSelectedItemChanged: (index) {
              controller.updateDemographics(
                demographics.copyWith(weightKg: (index + 80) / 2.20462),
              );
            },
            children: List.generate(
              371,
              (index) => _pickerText('${index + 80} lbs'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          borderRadius: 26,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.profileSexLabel),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: Sex.values.map((sex) {
                  final selected = demographics.sex == sex;
                  return _ChoicePill(
                    selected: selected,
                    label: copy.sexLabel(sex),
                    onTap: () {
                      controller.updateDemographics(
                        demographics.copyWith(sex: sex),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              OnboardingMetaLabel(
                copy.choose('Activity level', 'Nivel de actividad'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ActivityLevel.values.map((level) {
                  final selected = demographics.activityLevel == level;
                  return _ChoicePill(
                    selected: selected,
                    label: _activityLabel(copy, level),
                    onTap: () {
                      controller.updateDemographics(
                        demographics.copyWith(activityLevel: level),
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

  String _activityLabel(AppCopy copy, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => copy.choose('Mostly sitting', 'Mayormente sentado'),
      ActivityLevel.light => copy.choose('Light movement', 'Movimiento ligero'),
      ActivityLevel.moderate => copy.choose('Moderately active', 'Moderadamente activo'),
      ActivityLevel.active => copy.choose('Very active', 'Muy activo'),
      ActivityLevel.veryActive => copy.choose(
        'Extremely active',
        'Actividad muy intensa',
      ),
    };
  }

  Widget _pickerText(String value) {
    return Center(
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: NihPalette.base,
        ),
      ),
    );
  }

  Widget _selectionOverlay() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: NihPalette.borderSoft),
          bottom: BorderSide(color: NihPalette.borderSoft),
        ),
      ),
    );
  }

  void _seedControllers({
    required int age,
    required int heightInches,
    required int weightPounds,
  }) {
    if (_seedAge != age) {
      _seedAge = age;
      _ageController = FixedExtentScrollController(initialItem: age - 14);
    }
    if (_seedHeightInches != heightInches) {
      _seedHeightInches = heightInches;
      _heightController = FixedExtentScrollController(
        initialItem: heightInches - 48,
      );
    }
    if (_seedWeightPounds != weightPounds) {
      _seedWeightPounds = weightPounds;
      _weightController = FixedExtentScrollController(
        initialItem: weightPounds - 80,
      );
    }
  }

  String _formatHeight(int inches) {
    final feet = inches ~/ 12;
    final remainder = inches % 12;
    return '$feet\'$remainder"';
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? NihPalette.primary : NihPalette.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? NihPalette.primary : NihPalette.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : NihPalette.base,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BodyStatPickerCard extends StatelessWidget {
  const _BodyStatPickerCard({
    required this.label,
    required this.valueText,
    required this.picker,
  });

  final String label;
  final String valueText;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingMetaLabel(label),
          const SizedBox(height: 8),
          Text(
            valueText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: NihPalette.primaryDarker,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 128, child: picker),
        ],
      ),
    );
  }
}
