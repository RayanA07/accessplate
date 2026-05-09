import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../providers/profile_controller.dart';

class OnboardingFeasibilityStep extends ConsumerWidget {
  const OnboardingFeasibilityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feasibility comes next',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recommendations must fit your budget, prep setup, and where you can actually shop.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget per meal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        Slider(
          key: const Key('budgetSlider'),
          min: 1,
          max: 15,
          divisions: 14,
          value: feasibility.maxCostPerMeal.clamp(1, 15),
          onChanged: controller.updateBudget,
        ),
        const SizedBox(height: 16),
        Text(
          'Prep environment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PrepEnvironment.values.map((environment) {
            return ChoiceChip(
              selected: feasibility.environment == environment,
              label: Text(environment.label),
              onSelected: (_) => controller.updateEnvironment(environment),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Where food is available',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AvailabilityContext.values.map((contextValue) {
            final selected = feasibility.availability.contains(contextValue);
            return FilterChip(
              selected: selected,
              label: Text(contextValue.label),
              onSelected: (value) {
                final next = {...feasibility.availability};
                value ? next.add(contextValue) : next.remove(contextValue);
                if (next.isEmpty) {
                  next.add(contextValue);
                }
                controller.updateAvailability(next);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                controller.setStage(OnboardingStage.safety);
              },
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                controller.setStage(OnboardingStage.preference);
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
