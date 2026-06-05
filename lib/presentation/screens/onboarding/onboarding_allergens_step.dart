import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/allergen.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingAllergensStep extends ConsumerWidget {
  const OnboardingAllergensStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose('Allergens', 'Alergenos'),
      subtitle: copy.choose(
        'Pick any allergens that must never show up in your food options.',
        'Marca cualquier alergeno que nunca deba aparecer en tus opciones de comida.',
      ),
      children: [
        for (final allergen in Allergen.displayOrder) ...[
          SelectionTile(
            title: copy.allergenLabel(allergen),
            subtitle: copy.choose(
              'Exclude foods containing ${copy.allergenLabel(allergen).toLowerCase()}.',
              'Excluye comida con ${copy.allergenLabel(allergen).toLowerCase()}.',
            ),
            icon: _iconFor(allergen),
            selected: safety.allergens.contains(allergen),
            indicatorStyle: SelectionTileIndicatorStyle.check,
            onTap: () {
              final next = {...safety.allergens};
              next.contains(allergen)
                  ? next.remove(allergen)
                  : next.add(allergen);
              controller.updateSafety(safety.copyWith(allergens: next));
            },
          ),
          if (allergen != Allergen.displayOrder.last)
            const SizedBox(height: 14),
        ],
      ],
    );
  }

  IconData _iconFor(Allergen allergen) {
    switch (allergen) {
      case Allergen.peanut:
        return Icons.local_florist_rounded;
      case Allergen.treeNut:
        return Icons.park_rounded;
      case Allergen.dairy:
        return Icons.water_drop_rounded;
      case Allergen.egg:
        return Icons.egg_alt_rounded;
      case Allergen.soy:
        return Icons.spa_outlined;
      case Allergen.wheat:
        return Icons.grain_rounded;
      case Allergen.gluten:
        return Icons.bakery_dining_outlined;
      case Allergen.fish:
        return Icons.set_meal_rounded;
      case Allergen.shellfish:
        return Icons.water_outlined;
      case Allergen.sesame:
        return Icons.scatter_plot_outlined;
    }
  }
}
