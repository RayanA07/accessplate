import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/store_search.dart';
import '../providers/nearby_store_providers.dart';
import 'section_card.dart';

class ShoppingLocationCard extends ConsumerWidget {
  const ShoppingLocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingLocationStateProvider);
    final nearbyAsync = ref.watch(nearbyStoresProvider);
    final nearbyCount = nearbyAsync.valueOrNull?.length ?? 0;
    final theme = Theme.of(context);
    final location = state.location;

    return SectionCard(
      tintColor: NihPalette.secondaryLightest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified nearby stores',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !state.apiConfigured
                ? 'Nearby store search is unavailable right now.'
                : location == null
                ? 'Location is set during onboarding. Nearby store verification will appear here after that setup is complete.'
                : _summaryLine(location, nearbyCount),
            style: theme.textTheme.bodyMedium,
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: switch (location.kind) {
                    SearchLocationKind.device => 'Device location',
                    SearchLocationKind.address => 'Address search',
                    SearchLocationKind.zipCentroid => 'ZIP fallback',
                  },
                ),
                _StatusChip(
                  label: location.isApproximate ? 'Approximate' : 'Live',
                ),
                if (nearbyAsync.isLoading) const _StatusChip(label: 'Loading'),
                if (nearbyCount > 0) _StatusChip(label: '$nearbyCount stores'),
              ],
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (state.loading || nearbyAsync.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (location != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: state.loading
                    ? null
                    : () {
                        ref
                            .read(shoppingLocationControllerProvider.notifier)
                            .clear();
                      },
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summaryLine(SearchLocation location, int nearbyCount) {
    final countText = nearbyCount == 0
        ? 'No nearby stores verified yet.'
        : '$nearbyCount nearby stores verified.';
    if (location.isApproximate) {
      return '${location.label} is being used as an approximate search origin. $countText';
    }
    return '${location.label} is the live search origin. $countText';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NihPalette.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: NihPalette.primaryDarkest,
        ),
      ),
    );
  }
}
