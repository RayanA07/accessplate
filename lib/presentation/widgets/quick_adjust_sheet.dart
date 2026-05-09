import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../providers/profile_controller.dart';

class QuickAdjustSheet extends ConsumerWidget {
  const QuickAdjustSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final controller = ref.read(profileControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick adjust',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Text('Budget: \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}'),
            Slider(
              min: 1,
              max: 15,
              divisions: 14,
              value: feasibility.maxCostPerMeal.clamp(1, 15),
              onChanged: controller.updateBudget,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PrepEnvironment>(
              key: ValueKey(feasibility.environment),
              initialValue: feasibility.environment,
              decoration: const InputDecoration(labelText: 'Environment'),
              items: PrepEnvironment.values.map((environment) {
                return DropdownMenuItem(
                  value: environment,
                  child: Text(environment.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateEnvironment(value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MealType>(
              key: ValueKey(preference.mealType),
              initialValue: preference.mealType,
              decoration: const InputDecoration(labelText: 'Meal'),
              items: MealType.values.map((mealType) {
                return DropdownMenuItem(
                  value: mealType,
                  child: Text(mealType.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateMealType(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
