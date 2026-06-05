import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
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
                Container(
                  key: const ValueKey('pantry-cycle-hint'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: NihPalette.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: NihPalette.borderSoft),
                  ),
                  child: Text(
                    copy.pantryCycleHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                      color: NihPalette.base,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonStaples.map((item) {
                    final status = pantry.stockFor(item);
                    final semanticsLabel = status == null
                        ? '$item, ${copy.choose('not selected', 'sin marcar')}'
                        : '$item, ${_statusLabel(copy, status)}';
                    return _PantryStateChip(
                      item: item,
                      status: status,
                      semanticsLabel: semanticsLabel,
                      onTap: () => controller.updatePantryItemState(
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

class _PantryStateChip extends StatelessWidget {
  const _PantryStateChip({
    required this.item,
    required this.status,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String item;
  final PantryStockLevel? status;
  final String semanticsLabel;
  final VoidCallback onTap;

  static const _restockColor = Color(0xFFE57D22);

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          key: ValueKey('pantry-chip-$item'),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: style.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (style.icon != null) ...[
                Icon(style.icon, size: 16, color: style.textColor),
                const SizedBox(width: 8),
              ],
              Text(
                item,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: style.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PantryChipStyle _styleFor(PantryStockLevel? status) {
    return switch (status) {
      null => const _PantryChipStyle(
        backgroundColor: NihPalette.white,
        borderColor: NihPalette.borderSoft,
        textColor: NihPalette.grayDark,
      ),
      PantryStockLevel.enough => const _PantryChipStyle(
        backgroundColor: NihPalette.success,
        borderColor: NihPalette.success,
        textColor: NihPalette.white,
        icon: Icons.check_rounded,
      ),
      PantryStockLevel.low => const _PantryChipStyle(
        backgroundColor: NihPalette.warning,
        borderColor: NihPalette.warning,
        textColor: NihPalette.base,
        icon: Icons.warning_amber_rounded,
      ),
      PantryStockLevel.out => const _PantryChipStyle(
        backgroundColor: _restockColor,
        borderColor: _restockColor,
        textColor: NihPalette.white,
        icon: Icons.autorenew_rounded,
      ),
    };
  }
}

class _PantryChipStyle {
  const _PantryChipStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
}
