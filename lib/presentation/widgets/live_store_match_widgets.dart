import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/grocery.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../providers/live_grocery_providers.dart';
import '../providers/profile_controller.dart';
import 'section_card.dart';

class LiveStorePreview extends ConsumerWidget {
  const LiveStorePreview({super.key, required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final store = feasibility.groceryStore;
    if (store == null ||
        !feasibility.availability.contains(AvailabilityContext.grocery) ||
        !food.availability.contains(AvailabilityContext.grocery)) {
      return const SizedBox.shrink();
    }

    final matchesAsync = ref.watch(liveGroceryMatchesProvider);
    return matchesAsync.when(
      data: (matches) {
        final lookup = matches[food.id];
        if (lookup == null || lookup.products.isEmpty) {
          return const SizedBox.shrink();
        }
        final products = lookup.products.take(2).toList(growable: false);
        final cheapest = lookup.cheapestPrice;

        return Container(
          padding: const EdgeInsets.only(top: 18, bottom: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cheapest == null
                      ? '${lookup.products.length} ${lookup.plan.displayLabel} brands at ${store.name}'
                      : '${lookup.products.length} ${lookup.plan.displayLabel} brands at ${store.name} from \$${cheapest.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final product in products) ...[
                  _ProductLine(product: product),
                  if (product != products.last) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class LiveStoreProductsSection extends ConsumerWidget {
  const LiveStoreProductsSection({
    super.key,
    required this.food,
    required this.emptyFallback,
  });

  final Food food;
  final bool emptyFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final feasibility = profile.constraints.feasibility;
    final store = feasibility.groceryStore;
    if (store == null ||
        !feasibility.availability.contains(AvailabilityContext.grocery) ||
        !food.availability.contains(AvailabilityContext.grocery)) {
      return const SizedBox.shrink();
    }

    final matchesAsync = ref.watch(liveGroceryMatchesProvider);
    return matchesAsync.when(
      data: (matches) {
        final lookup = matches[food.id];
        if (lookup == null || lookup.products.isEmpty) {
          if (!emptyFallback) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SectionCard(
              child: Text(
                'No clear store-specific brand match was available for this suggestion.',
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At your store',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '${lookup.store.name} | Search term: ${lookup.plan.displayLabel}',
                ),
                if (!lookup.plan.exactMatch) ...[
                  const SizedBox(height: 8),
                  Text(
                    lookup.plan.rationale,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                ...lookup.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DetailedProductTile(product: product),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Checking live store products...'),
              SizedBox(height: 10),
              LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      error: (_, _) => emptyFallback
          ? const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SectionCard(
                child: Text('Live store products are unavailable right now.'),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.product});

  final GroceryProduct product;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${product.brandLabel} | ${_priceLabel(product)}',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _priceLabel(GroceryProduct product) {
    final price = product.effectivePrice;
    if (price == null) {
      return product.size ?? 'Price unavailable';
    }
    if (product.size?.isNotEmpty == true) {
      return '\$${price.toStringAsFixed(2)} | ${product.size}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}

class _DetailedProductTile extends StatelessWidget {
  const _DetailedProductTile({required this.product});

  final GroceryProduct product;

  @override
  Widget build(BuildContext context) {
    final detailParts = <String>[];
    final price = product.effectivePrice;
    if (price != null) {
      detailParts.add('\$${price.toStringAsFixed(2)}');
    }
    if (product.size?.isNotEmpty == true) {
      detailParts.add(product.size!);
    }
    if (product.aisle?.isNotEmpty == true) {
      detailParts.add(product.aisle!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brandLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(product.description),
        if (detailParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(detailParts.join(' | ')),
        ],
      ],
    );
  }
}
