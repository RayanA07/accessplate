import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/meal_type.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingMealTimingStep extends ConsumerWidget {
  const OnboardingMealTimingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: 'Meal\ntiming',
      subtitle: 'Choose the kind of meal you want the shortlist to focus on.',
      children: [
        for (final mealType in MealType.values) ...[
          SelectionTile(
            title: mealType.label,
            subtitle: _descriptionFor(mealType),
            icon: _iconFor(mealType),
            selected: preference.mealType == mealType,
            onTap: () => controller.updateMealType(mealType),
          ),
          if (mealType != MealType.values.last) const SizedBox(height: 14),
        ],
      ],
    );
  }

  String _descriptionFor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Prioritize morning meals and breakfast-friendly options.';
      case MealType.lunch:
        return 'Focus on midday meals and quick lunch picks.';
      case MealType.dinner:
        return 'Favor more filling evening meals.';
      case MealType.snack:
        return 'Keep the shortlist centered on lighter snack options.';
      case MealType.any:
        return 'Allow the engine to match options regardless of meal timing.';
    }
  }

  IconData _iconFor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.lunch_dining_rounded;
      case MealType.dinner:
        return Icons.dinner_dining_rounded;
      case MealType.snack:
        return Icons.cookie_outlined;
      case MealType.any:
        return Icons.schedule_rounded;
    }
  }
}
