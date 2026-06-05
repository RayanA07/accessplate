import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/allergen.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../../domain/value_objects/religion.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/selection_tile.dart';

class OnboardingDietaryStyleStep extends ConsumerStatefulWidget {
  const OnboardingDietaryStyleStep({super.key});

  @override
  ConsumerState<OnboardingDietaryStyleStep> createState() =>
      _OnboardingDietaryStyleStepState();
}

class _OnboardingDietaryStyleStepState
    extends ConsumerState<OnboardingDietaryStyleStep> {
  _RestrictionTab _selectedTab = _RestrictionTab.diet;

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final preference = profile.constraints.preference;
    final safety = profile.constraints.safety;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(profile.constraints.access.language);

    return OnboardingStepLayout(
      title: copy.choose('Food restrictions', 'Restricciones de comida'),
      subtitle: copy.choose(
        'These are applied to every meal recommendation.',
        'Estas se aplican a cada recomendacion de comida.',
      ),
      topSpacing: 18,
      children: [
        _RestrictionTabs(
          selectedTab: _selectedTab,
          copy: copy,
          onChanged: (tab) {
            setState(() {
              _selectedTab = tab;
            });
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(_selectedTab),
            child: switch (_selectedTab) {
              _RestrictionTab.diet => _DietTabContent(
                copy: copy,
                preference: preference,
                onSelected: (style) {
                  controller.updatePreference(
                    preference.copyWith(dietaryStyle: style),
                  );
                },
              ),
              _RestrictionTab.allergens => _AllergenTabContent(
                copy: copy,
                safety: safety,
                onToggle: (allergen) {
                  final next = {...safety.allergens};
                  next.contains(allergen)
                      ? next.remove(allergen)
                      : next.add(allergen);
                  controller.updateSafety(safety.copyWith(allergens: next));
                },
              ),
              _RestrictionTab.religion => _ReligionTabContent(
                copy: copy,
                safety: safety,
                onSelected: (religion) {
                  controller.updateSafety(safety.copyWith(religion: religion));
                },
              ),
            },
          ),
        ),
      ],
    );
  }
}

enum _RestrictionTab { diet, allergens, religion }

class _RestrictionTabs extends StatelessWidget {
  const _RestrictionTabs({
    required this.selectedTab,
    required this.copy,
    required this.onChanged,
  });

  final _RestrictionTab selectedTab;
  final AppCopy copy;
  final ValueChanged<_RestrictionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final tab in _RestrictionTab.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: tab == selectedTab
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelFor(tab),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tab == selectedTab
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(_RestrictionTab tab) {
    return switch (tab) {
      _RestrictionTab.diet => copy.choose('Diet', 'Dieta'),
      _RestrictionTab.allergens => copy.choose('Allergens', 'Alergenos'),
      _RestrictionTab.religion => copy.choose('Religion', 'Religion'),
    };
  }
}

class _DietTabContent extends StatelessWidget {
  const _DietTabContent({
    required this.copy,
    required this.preference,
    required this.onSelected,
  });

  final AppCopy copy;
  final PreferenceConstraints preference;
  final ValueChanged<DietaryStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final style in DietaryStyle.values) ...[
          SelectionTile(
            title: copy.dietaryStyleLabel(style),
            subtitle: copy.dietaryStyleDetail(style),
            icon: switch (style) {
              DietaryStyle.unrestricted => Icons.restaurant_rounded,
              DietaryStyle.vegetarian => Icons.eco_rounded,
              DietaryStyle.vegan => Icons.spa_rounded,
            },
            selected: preference.dietaryStyle == style,
            onTap: () => onSelected(style),
          ),
          if (style != DietaryStyle.values.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AllergenTabContent extends StatelessWidget {
  const _AllergenTabContent({
    required this.copy,
    required this.safety,
    required this.onToggle,
  });

  final AppCopy copy;
  final SafetyConstraints safety;
  final ValueChanged<Allergen> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            onTap: () => onToggle(allergen),
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

class _ReligionTabContent extends StatelessWidget {
  const _ReligionTabContent({
    required this.copy,
    required this.safety,
    required this.onSelected,
  });

  final AppCopy copy;
  final SafetyConstraints safety;
  final ValueChanged<Religion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final religion in Religion.values) ...[
          SelectionTile(
            title: copy.religionLabel(religion),
            subtitle: copy.religionDetail(religion),
            icon: _iconFor(religion),
            selected: safety.religion == religion,
            onTap: () => onSelected(religion),
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
