import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingFeasibilityStep extends ConsumerWidget {
  const OnboardingFeasibilityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feasibility',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Good recommendations are useless if they do not fit your budget, prep setup, or access points.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget per meal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preparation setup',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...PrepEnvironment.values.map((environment) {
                final selected = feasibility.environment == environment;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectionTile(
                    title: environment.label,
                    subtitle: switch (environment) {
                      PrepEnvironment.none => 'Ready to eat only.',
                      PrepEnvironment.microwave =>
                        'Microwave meals and ready-to-eat items.',
                      PrepEnvironment.stoveTop =>
                        'Stovetop, microwave, and most pantry meals.',
                      PrepEnvironment.fullKitchen =>
                        'All prep methods, including oven meals.',
                    },
                    icon: switch (environment) {
                      PrepEnvironment.none => Icons.flash_on_rounded,
                      PrepEnvironment.microwave => Icons.microwave_rounded,
                      PrepEnvironment.stoveTop => Icons.soup_kitchen_rounded,
                      PrepEnvironment.fullKitchen => Icons.kitchen_rounded,
                    },
                    selected: selected,
                    onTap: () => controller.updateEnvironment(environment),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where you can shop',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick every context that is realistic for you right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...AvailabilityContext.values.map((contextValue) {
                final selected = feasibility.availability.contains(
                  contextValue,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectionTile(
                    title: contextValue.label,
                    subtitle: _availabilityDescription(contextValue),
                    icon: _availabilityIcon(contextValue),
                    selected: selected,
                    onTap: () {
                      final next = {...feasibility.availability};
                      selected
                          ? next.remove(contextValue)
                          : next.add(contextValue);
                      if (next.isEmpty) {
                        next.add(contextValue);
                      }
                      controller.updateAvailability(next);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _availabilityDescription(AvailabilityContext contextValue) {
    switch (contextValue) {
      case AvailabilityContext.grocery:
        return 'Prepared foods, produce, and standard staples.';
      case AvailabilityContext.convenience:
        return 'Grab-and-go food and small essentials.';
      case AvailabilityContext.fastFood:
        return 'Restaurant and drive-thru options.';
      case AvailabilityContext.foodPantry:
        return 'Shelf-stable or donated basics.';
      case AvailabilityContext.dollarStore:
        return 'Low-cost pantry items and snacks.';
    }
  }

  IconData _availabilityIcon(AvailabilityContext contextValue) {
    switch (contextValue) {
      case AvailabilityContext.grocery:
        return Icons.local_grocery_store_rounded;
      case AvailabilityContext.convenience:
        return Icons.storefront_rounded;
      case AvailabilityContext.fastFood:
        return Icons.lunch_dining_rounded;
      case AvailabilityContext.foodPantry:
        return Icons.inventory_2_rounded;
      case AvailabilityContext.dollarStore:
        return Icons.attach_money_rounded;
    }
  }
}
