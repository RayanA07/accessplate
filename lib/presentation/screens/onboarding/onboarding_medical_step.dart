import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/medical_restriction.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class OnboardingMedicalStep extends ConsumerWidget {
  const OnboardingMedicalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical restrictions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Use Avoid for hard exclusions and Limit when something should count against the score.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: MedicalRestriction.values.map((restriction) {
              final currentMode = safety.medicalAvoid.contains(restriction)
                  ? _RestrictionMode.avoid
                  : safety.medicalLimit.contains(restriction)
                  ? _RestrictionMode.limit
                  : _RestrictionMode.off;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restriction.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _RestrictionMode.values.map((mode) {
                        return ChoiceChip(
                          selected: currentMode == mode,
                          label: Text(mode.label),
                          onSelected: (_) {
                            controller.updateSafety(
                              _applyRestrictionMode(
                                safety: safety,
                                restriction: restriction,
                                mode: mode,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  SafetyConstraints _applyRestrictionMode({
    required SafetyConstraints safety,
    required MedicalRestriction restriction,
    required _RestrictionMode mode,
  }) {
    final avoid = {...safety.medicalAvoid}..remove(restriction);
    final limit = {...safety.medicalLimit}..remove(restriction);

    if (mode == _RestrictionMode.avoid) {
      avoid.add(restriction);
    } else if (mode == _RestrictionMode.limit) {
      limit.add(restriction);
    }

    return safety.copyWith(medicalAvoid: avoid, medicalLimit: limit);
  }
}

enum _RestrictionMode {
  off('Off'),
  limit('Limit'),
  avoid('Avoid');

  const _RestrictionMode(this.label);

  final String label;
}
