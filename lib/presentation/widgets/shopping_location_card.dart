import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/store_search.dart';
import '../providers/demo_meals_store_data.dart';
import 'section_card.dart';
import 'store_display_utils.dart';

class ShoppingLocationCard extends StatelessWidget {
  const ShoppingLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      tintColor: NihPalette.secondaryLightest,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby stores',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(demoMealsLocationLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(demoMealsStoresMatchedLine, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [_StatusChip(label: 'Live')],
          ),
          const SizedBox(height: 10),
          for (
            var index = 0;
            index < demoMealsNearbyStores.length;
            index++
          ) ...[
            _NearbyStorePreview(store: demoMealsNearbyStores[index]),
            if (index < demoMealsNearbyStores.length - 1)
              Divider(height: 14, color: NihPalette.borderSoft),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xB3FFFFFF);
    const borderColor = NihPalette.borderSoft;
    const textColor = NihPalette.primaryDarkest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _NearbyStorePreview extends StatelessWidget {
  const _NearbyStorePreview({required this.store});

  final NearbyStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeName = resolvedStoreDisplayName(store);
    if (storeName == null) {
      return const SizedBox.shrink();
    }
    final distanceLabel = compactStoreTravelLabel(store.travelMetric);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: NihPalette.secondaryLightest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.store_rounded,
              size: 16,
              color: NihPalette.primaryDarkest,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              distanceLabel == null ? storeName : '$storeName | $distanceLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
