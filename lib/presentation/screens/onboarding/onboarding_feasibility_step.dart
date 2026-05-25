import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../copy/app_copy.dart';
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
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.choose('Feasibility', 'Factibilidad'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          copy.choose(
            'Good food choices are useless if they do not fit your budget, prep setup, or access points.',
            'Buenas opciones de comida no sirven si no encajan con tu presupuesto, tu cocina o tus puntos de acceso.',
          ),
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
                    copy.choose(
                      'Budget per meal',
                      'Presupuesto por comida',
                    ),
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
                copy.choose('Preparation setup', 'Equipo de cocina'),
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
                    title: copy.prepEnvironmentLabel(environment),
                    subtitle: copy.prepEnvironmentDetail(environment),
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
                copy.choose('Where you can shop', 'Donde puedes comprar'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                copy.choose(
                  'Pick every food source that is realistic for you right now.',
                  'Marca cada fuente de comida que si es realista para ti ahorita.',
                ),
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
                    title: copy.sourceLabel(contextValue),
                    subtitle: copy.availabilityDetail(contextValue),
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
