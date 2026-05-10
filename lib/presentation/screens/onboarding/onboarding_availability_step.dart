import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingAvailabilityStep extends ConsumerWidget {
  const OnboardingAvailabilityStep({super.key});

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
          'Shopping access',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick every food source that is realistic for you right now.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AvailabilityContext.values.map((contextValue) {
              final selected = feasibility.availability.contains(contextValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectionTile(
                  title: contextValue.label,
                  subtitle: _descriptionFor(contextValue),
                  icon: _iconFor(contextValue),
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
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _descriptionFor(AvailabilityContext contextValue) {
    switch (contextValue) {
      case AvailabilityContext.grocery:
        return 'Prepared foods, staples, and produce.';
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

  IconData _iconFor(AvailabilityContext contextValue) {
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
