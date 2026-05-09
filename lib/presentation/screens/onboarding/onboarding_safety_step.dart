import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/allergen.dart';
import '../../../domain/value_objects/medical_restriction.dart';
import '../../../domain/value_objects/religion.dart';
import '../../providers/profile_controller.dart';

class OnboardingSafetyStep extends ConsumerWidget {
  const OnboardingSafetyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety first',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'These constraints are hard rules. Foods that violate them never appear.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Allergens',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Allergen.values.map((allergen) {
            final selected = safety.allergens.contains(allergen);
            return FilterChip(
              selected: selected,
              label: Text(allergen.label),
              onSelected: (value) {
                final next = {...safety.allergens};
                value ? next.add(allergen) : next.remove(allergen);
                controller.updateSafety(safety.copyWith(allergens: next));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Religious restrictions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Religion.values.map((religion) {
            return ChoiceChip(
              selected: safety.religion == religion,
              label: Text(religion.label),
              onSelected: (_) {
                controller.updateSafety(safety.copyWith(religion: religion));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Medical restrictions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...MedicalRestriction.values.map((restriction) {
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
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                controller.setStage(OnboardingStage.splash);
              },
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                controller.setStage(OnboardingStage.feasibility);
              },
              child: const Text('Next'),
            ),
          ],
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

    return safety.copyWith(
      medicalAvoid: avoid,
      medicalLimit: limit,
    );
  }
}

enum _RestrictionMode {
  off('Off'),
  limit('Limit'),
  avoid('Avoid');

  const _RestrictionMode(this.label);

  final String label;
}
