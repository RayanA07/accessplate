import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/religion.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';
import '../../widgets/selection_tile.dart';

class OnboardingReligionStep extends ConsumerWidget {
  const OnboardingReligionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final controller = ref.read(profileControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Religious restrictions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the rule set the app should always respect.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: Religion.values.map((religion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectionTile(
                  title: religion.label,
                  subtitle: _descriptionFor(religion),
                  icon: _iconFor(religion),
                  selected: safety.religion == religion,
                  onTap: () {
                    controller.updateSafety(safety.copyWith(religion: religion));
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _descriptionFor(Religion religion) {
    switch (religion) {
      case Religion.none:
        return 'Do not apply any religion-based filtering.';
      case Religion.halal:
        return 'Hide foods that conflict with halal restrictions.';
      case Religion.kosher:
        return 'Hide foods that conflict with kosher restrictions.';
      case Religion.hinduVeg:
        return 'Keep recommendations vegetarian for Hindu users.';
      case Religion.jain:
        return 'Hide foods that conflict with Jain restrictions.';
    }
  }

  IconData _iconFor(Religion religion) {
    switch (religion) {
      case Religion.none:
        return Icons.restaurant_rounded;
      case Religion.halal:
        return Icons.verified_rounded;
      case Religion.kosher:
        return Icons.shield_rounded;
      case Religion.hinduVeg:
        return Icons.eco_rounded;
      case Religion.jain:
        return Icons.spa_rounded;
    }
  }
}
