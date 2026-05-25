import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/religion.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingReligionStep extends ConsumerWidget {
  const OnboardingReligionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose(
        'Religious\nrestrictions',
        'Restricciones\nreligiosas',
      ),
      subtitle: copy.choose(
        'Choose the food rules the app should always respect.',
        'Elige las reglas de comida que la app siempre debe respetar.',
      ),
      children: [
        for (final religion in Religion.values) ...[
          SelectionTile(
            title: copy.religionLabel(religion),
            subtitle: copy.religionDetail(religion),
            icon: _iconFor(religion),
            selected: safety.religion == religion,
            onTap: () {
              controller.updateSafety(safety.copyWith(religion: religion));
            },
          ),
          if (religion != Religion.values.last) const SizedBox(height: 14),
        ],
      ],
    );
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
