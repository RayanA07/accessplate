import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../copy/app_copy.dart';
import '../providers/profile_controller.dart';
import 'section_card.dart';

class QuickAdjustSheet extends ConsumerWidget {
  const QuickAdjustSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final access = profile.constraints.access;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(access.language);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Semantics(
          container: true,
          child: SectionCard(
            borderRadius: 34,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.choose('Quick adjust', 'Ajuste rapido'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  copy.choose(
                    'Open one rule and refresh the list without restarting onboarding.',
                    'Abre una regla y actualiza la lista sin volver a empezar el registro.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  copy.choose('Budget', 'Presupuesto'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  copy.choose(
                    '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)} per meal',
                    '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)} por comida',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                  decoration: InputDecoration(
                    labelText: copy.choose(
                      'Preparation setup',
                      'Forma de preparacion',
                    ),
                  ),
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
                  decoration: InputDecoration(
                    labelText: copy.choose('Meal timing', 'Momento de comida'),
                  ),
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
                const SizedBox(height: 12),
                SwitchListTile(
                  value: access.emergencyMode,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    copy.choose('Emergency mode', 'Modo de emergencia'),
                  ),
                  subtitle: Text(
                    copy.choose(
                      'Push toward the fastest, cheapest, easiest options right now.',
                      'Empuja hacia opciones mas rapidas, baratas y faciles ahora mismo.',
                    ),
                  ),
                  onChanged: controller.updateEmergencyMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
