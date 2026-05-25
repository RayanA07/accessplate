import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingProfileStep extends ConsumerStatefulWidget {
  const OnboardingProfileStep({super.key});

  static const visibleConcerns = <HealthConcern>[
    HealthConcern.anemia,
    HealthConcern.pregnancy,
    HealthConcern.lactating,
    HealthConcern.boneDensity,
    HealthConcern.hypertension,
    HealthConcern.postoperative,
  ];

  @override
  ConsumerState<OnboardingProfileStep> createState() =>
      _OnboardingProfileStepState();
}

class _OnboardingProfileStepState extends ConsumerState<OnboardingProfileStep> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
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
    final age = demographics.ageYears.clamp(14, 75);
    final copy = AppCopy(profile.constraints.access.language);
    if (!_seeded) {
      _seedControllers(demographics);
    }

    return OnboardingStepLayout(
      title: copy.profileTitle,
      subtitle: copy.choose(
        'Set your health context so AccessPlate can build daily targets and watch nutrients without ignoring food access.',
        'Configura tu contexto de salud para que AccessPlate arme metas diarias y vigile nutrientes sin ignorar el acceso a comida.',
      ),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.profileSexLabel),
              const SizedBox(height: 10),
              OnboardingSegmentedControl<Sex>(
                value: demographics.sex,
                options: Sex.values,
                labelBuilder: copy.sexLabel,
                onChanged: (sex) {
                  controller.updateDemographics(
                    demographics.copyWith(sex: sex),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.ageLabel(age)),
              Slider(
                min: 14,
                max: 75,
                divisions: 61,
                value: age.toDouble(),
                onChanged: (value) {
                  controller.updateDemographics(
                    demographics.copyWith(ageYears: value.round()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Height and weight', 'Altura y peso'),
              ),
              const SizedBox(height: 8),
              Text(
                copy.choose(
                  'Used only for daily target estimates based on U.S. nutrition guidance.',
                  'Se usa solo para estimar metas diarias basadas en guias de nutricion de EE. UU.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: copy.choose(
                          'Height (inches)',
                          'Altura (pulgadas)',
                        ),
                      ),
                      onChanged: (value) =>
                          _updateHeightIfValid(value, demographics, controller),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: copy.choose(
                          'Weight (lb)',
                          'Peso (lb)',
                        ),
                      ),
                      onChanged: (value) =>
                          _updateWeightIfValid(value, demographics, controller),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Activity level', 'Nivel de actividad'),
              ),
              const SizedBox(height: 8),
              Text(
                copy.choose(
                  'Match the closest level from the USDA DRI calculator categories.',
                  'Elige el nivel mas cercano a las categorias de la calculadora DRI del USDA.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityLevel.values.map((level) {
                  final selected = demographics.activityLevel == level;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(_activityLabel(copy, level)),
                    onSelected: (_) {
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
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.healthPrioritiesLabel),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OnboardingProfileStep.visibleConcerns.map((concern) {
                  final selected = demographics.concerns.contains(concern);
                  return FilterChip(
                    selected: selected,
                    label: Text(copy.healthConcernLabel(concern)),
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
            ],
          ),
        ),
      ],
    );
  }

  void _seedControllers(Demographics demographics) {
    _seeded = true;
    if (demographics.heightCm != null) {
      _heightController.text = (demographics.heightCm! / 2.54).toStringAsFixed(0);
    }
    if (demographics.weightKg != null) {
      _weightController.text = (demographics.weightKg! * 2.20462)
          .toStringAsFixed(0);
    }
  }

  void _updateHeightIfValid(
    String value,
    Demographics demographics,
    ProfileController controller,
  ) {
    final inches = double.tryParse(value);
    if (inches == null || inches < 48 || inches > 84) {
      return;
    }
    controller.updateDemographics(
      demographics.copyWith(heightCm: inches * 2.54),
    );
  }

  void _updateWeightIfValid(
    String value,
    Demographics demographics,
    ProfileController controller,
  ) {
    final pounds = double.tryParse(value);
    if (pounds == null || pounds < 80 || pounds > 450) {
      return;
    }
    controller.updateDemographics(
      demographics.copyWith(weightKg: pounds / 2.20462),
    );
  }

  String _activityLabel(AppCopy copy, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => copy.choose('Inactive', 'Inactiva'),
      ActivityLevel.light => copy.choose('Low active', 'Poco activa'),
      ActivityLevel.moderate => copy.choose('Active', 'Activa'),
      ActivityLevel.active => copy.choose('High active', 'Muy activa'),
      ActivityLevel.veryActive => copy.choose(
        'Very active',
        'Actividad muy alta',
      ),
    };
  }
}
