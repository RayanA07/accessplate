import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingProfileStep extends ConsumerWidget {
  const OnboardingProfileStep({super.key});

  static const _visibleConcerns = <HealthConcern>[
    HealthConcern.anemia,
    HealthConcern.pregnancy,
    HealthConcern.lactating,
    HealthConcern.boneDensity,
    HealthConcern.hypertension,
    HealthConcern.postoperative,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final demographics = profile.constraints.demographics;
    final controller = ref.read(profileControllerProvider.notifier);
    final age = demographics.ageYears.clamp(14, 75);

    return OnboardingStepLayout(
      title: 'Profile\ncontext',
      subtitle: 'This helps the scoring model prioritize the right nutrients.',
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingMetaLabel('Sex'),
              const SizedBox(height: 10),
              OnboardingSegmentedControl<Sex>(
                value: demographics.sex,
                options: Sex.values,
                labelBuilder: (sex) => sex == Sex.female ? 'Female' : 'Male',
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
              OnboardingMetaLabel('Age: $age'),
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
              const OnboardingMetaLabel('Health priorities'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _visibleConcerns.map((concern) {
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
            ],
          ),
        ),
      ],
    );
  }
}
