import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile context',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps the scoring model prioritize the right nutrients.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sex', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: Sex.values.map((sex) {
                  return ChoiceChip(
                    selected: demographics.sex == sex,
                    label: Text(sex == Sex.female ? 'Female' : 'Male'),
                    onSelected: (_) {
                      controller.updateDemographics(
                        demographics.copyWith(sex: sex),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Age: $age',
                style: Theme.of(context).textTheme.labelLarge,
              ),
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
              const SizedBox(height: 8),
              Text(
                'Health priorities',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
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
