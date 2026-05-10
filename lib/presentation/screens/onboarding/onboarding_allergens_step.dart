import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/allergen.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class OnboardingAllergensStep extends ConsumerWidget {
  const OnboardingAllergensStep({super.key});

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
          'Allergens',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick any allergens that must never show up in your recommendations.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Wrap(
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
        ),
      ],
    );
  }
}
