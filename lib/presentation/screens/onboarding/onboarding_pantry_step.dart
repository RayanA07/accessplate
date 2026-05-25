import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
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
    final trackedItems = pantry.stockByItem.keys.toList()..sort();

    return OnboardingStepLayout(
      title: copy.pantryTitle,
      subtitle: copy.pantrySubtitle,
      children: [
        SectionCard(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingMetaLabel(copy.pantryCommonItemsLabel),
                const SizedBox(height: 8),
                Text(copy.pantryCycleHint),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonStaples.map((item) {
                    final status = pantry.stockFor(item);
                    final label = status == null
                        ? item
                        : '$item - ${_statusLabel(copy, status)}';
                    return FilterChip(
                      selected: status != null,
                      label: Text(label),
                      onSelected: (_) => controller.updatePantryItemState(
                        item,
                        _nextStockLevel(status),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customItemController,
                  decoration: InputDecoration(
                    labelText: copy.pantryAddItemLabel,
                    hintText: copy.pantryAddItemHint,
                    suffixIcon: IconButton(
                      tooltip: copy.pantryAddItemLabel,
                      onPressed: () => _addCustomItem(controller),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  onSubmitted: (_) => _addCustomItem(controller),
                ),
              ],
            ),
          ),
        ),
        if (trackedItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionCard(
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingMetaLabel(
                    copy.pantryTrackedLabel(trackedItems.length),
                  ),
                  const SizedBox(height: 12),
                  if (pantry.enoughItems.isNotEmpty)
                    _InventorySection(
                      title: copy.pantryEnoughLabel,
                      items: pantry.enoughItems,
                      onRemove: (item) =>
                          controller.updatePantryItemState(item, null),
                    ),
                  if (pantry.lowStockItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _InventorySection(
                      title: copy.pantryLowLabel,
                      items: pantry.lowStockItems,
                      onRemove: (item) =>
                          controller.updatePantryItemState(item, null),
                    ),
                  ],
                  if (pantry.restockItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _InventorySection(
                      title: copy.pantryRestockLabel,
                      items: pantry.restockItems,
                      onRemove: (item) =>
                          controller.updatePantryItemState(item, null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  PantryStockLevel? _nextStockLevel(PantryStockLevel? current) {
    return switch (current) {
      null => PantryStockLevel.enough,
      PantryStockLevel.enough => PantryStockLevel.low,
      PantryStockLevel.low => PantryStockLevel.out,
      PantryStockLevel.out => null,
    };
  }

  String _statusLabel(AppCopy copy, PantryStockLevel status) {
    return switch (status) {
      PantryStockLevel.enough => copy.pantryEnoughLabel,
      PantryStockLevel.low => copy.pantryLowLabel,
      PantryStockLevel.out => copy.pantryRestockLabel,
    };
  }

  void _addCustomItem(ProfileController controller) {
    final normalized = _customItemController.text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    controller.updatePantryItemState(normalized, PantryStockLevel.enough);
    _customItemController.clear();
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.title,
    required this.items,
    required this.onRemove,
  });

  final String title;
  final Set<String> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final sortedItems = items.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingMetaLabel(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedItems.map((item) {
            return InputChip(
              label: Text(item),
              onDeleted: () => onRemove(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}
