import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingPantryStep extends ConsumerStatefulWidget {
  const OnboardingPantryStep({super.key});

  @override
  ConsumerState<OnboardingPantryStep> createState() =>
      _OnboardingPantryStepState();
}

class _OnboardingPantryStepState extends ConsumerState<OnboardingPantryStep> {
  static const _commonStaples = <String>[
    'rice',
    'beans',
    'oats',
    'peanut butter',
    'bread',
    'tortillas',
    'eggs',
    'milk',
    'yogurt',
    'canned tuna',
    'canned chicken',
    'pasta',
    'ramen',
    'cheese',
    'bananas',
    'potatoes',
    'frozen vegetables',
    'cereal',
  ];

  late final TextEditingController _customItemController;

  @override
  void initState() {
    super.initState();
    _customItemController = TextEditingController();
  }

  @override
  void dispose() {
    _customItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final pantry = profile.constraints.pantry;
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);
    final selected = pantry.itemsOnHand.toList()..sort();

    return OnboardingStepLayout(
      title: copy.pantryTitle,
      subtitle: copy.pantrySubtitle,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingMetaLabel('Common pantry items'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonStaples.map((item) {
                  final active = pantry.itemsOnHand.contains(item);
                  return FilterChip(
                    selected: active,
                    label: Text(item),
                    onSelected: (value) {
                      final next = {...pantry.itemsOnHand};
                      value ? next.add(item) : next.remove(item);
                      controller.updatePantryItems(next);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customItemController,
                decoration: InputDecoration(
                  labelText: 'Add another item',
                  hintText: 'canned soup',
                  suffixIcon: IconButton(
                    onPressed: () => _addCustomItem(controller, pantry.itemsOnHand),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                onSubmitted: (_) => _addCustomItem(controller, pantry.itemsOnHand),
              ),
            ],
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingMetaLabel('Selected: ${selected.length}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selected.map((item) {
                    return InputChip(
                      label: Text(item),
                      onDeleted: () {
                        final next = {...pantry.itemsOnHand}..remove(item);
                        controller.updatePantryItems(next);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addCustomItem(
    ProfileController controller,
    Set<String> existingItems,
  ) {
    final normalized = _customItemController.text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    controller.updatePantryItems({...existingItems, normalized});
    _customItemController.clear();
  }
}
