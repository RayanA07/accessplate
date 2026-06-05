import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../../domain/value_objects/prep_environment.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingShoppingSetupStep extends ConsumerWidget {
  const OnboardingShoppingSetupStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose('Shopping\nsetup', 'Compras y\ncocina'),
      subtitle: copy.choose(
        'Budget, cooking setup, and store types in one place.',
        'Presupuesto, cocina y tipos de tienda en un solo paso.',
      ),
      topSpacing: 18,
      children: [
        SectionCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Budget per meal', 'Presupuesto por comida'),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Slider(
                value: feasibility.maxCostPerMeal.clamp(3, 20),
                min: 3,
                max: 20,
                divisions: 17,
                label: '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                onChanged: controller.updateBudget,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Cooking setup', 'Equipo para cocinar'),
              ),
              const SizedBox(height: 8),
              for (final environment in PrepEnvironment.values) ...[
                SelectionTile(
                  title: copy.prepEnvironmentLabel(environment),
                  subtitle: copy.prepEnvironmentDetail(environment),
                  icon: switch (environment) {
                    PrepEnvironment.none => Icons.flash_on_rounded,
                    PrepEnvironment.microwave => Icons.microwave_rounded,
                    PrepEnvironment.stoveTop =>
                      Icons.local_fire_department_rounded,
                    PrepEnvironment.fullKitchen => Icons.kitchen_rounded,
                  },
                  selected: feasibility.environment == environment,
                  onTap: () => controller.updateEnvironment(environment),
                ),
                if (environment != PrepEnvironment.values.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Store types you can reach', 'Tiendas que si alcanzas'),
              ),
              const SizedBox(height: 8),
              for (final contextValue in AvailabilityContext.values) ...[
                SelectionTile(
                  title: copy.sourceLabel(contextValue),
                  subtitle: copy.availabilityDetail(contextValue),
                  icon: _iconFor(contextValue),
                  selected: feasibility.availability.contains(contextValue),
                  indicatorStyle: SelectionTileIndicatorStyle.check,
                  onTap: () {
                    final selected = feasibility.availability.contains(
                      contextValue,
                    );
                    final next = {...feasibility.availability};
                    selected ? next.remove(contextValue) : next.add(contextValue);
                    controller.updateAvailability(next);
                  },
                ),
                if (contextValue != AvailabilityContext.values.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(AvailabilityContext context) {
    return switch (context) {
      AvailabilityContext.grocery => Icons.storefront_rounded,
      AvailabilityContext.dollarStore => Icons.savings_outlined,
      AvailabilityContext.convenience => Icons.local_convenience_store_rounded,
      AvailabilityContext.fastFood => Icons.fastfood_rounded,
      AvailabilityContext.foodPantry => Icons.volunteer_activism_rounded,
    };
  }
}
