import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
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

    return OnboardingStepLayout(
      title: 'Shopping\naccess',
      subtitle: 'Pick every food source that is realistic for you right now.',
      children: [
        for (final contextValue in AvailabilityContext.values) ...[
          SelectionTile(
            title: contextValue.label,
            subtitle: _descriptionFor(contextValue),
            icon: _iconFor(contextValue),
            selected: feasibility.availability.contains(contextValue),
            indicatorStyle: SelectionTileIndicatorStyle.check,
            onTap: () {
              final selected = feasibility.availability.contains(contextValue);
              final next = {...feasibility.availability};
              selected ? next.remove(contextValue) : next.add(contextValue);
              if (next.isEmpty) {
                next.add(contextValue);
              }
              controller.updateAvailability(next);
            },
          ),
          if (contextValue != AvailabilityContext.values.last)
            const SizedBox(height: 14),
        ],
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
