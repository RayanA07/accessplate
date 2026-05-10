import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class OnboardingMealTimingStep extends ConsumerWidget {
  const OnboardingMealTimingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal timing',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the kind of meal you want the shortlist to focus on.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Wrap(
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
        ),
      ],
    );
  }
}
