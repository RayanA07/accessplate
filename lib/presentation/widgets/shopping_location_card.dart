import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/store_search.dart';
import '../providers/nearby_store_providers.dart';
import 'section_card.dart';

class ShoppingLocationCard extends ConsumerStatefulWidget {
  const ShoppingLocationCard({super.key});

  @override
  ConsumerState<ShoppingLocationCard> createState() =>
      _ShoppingLocationCardState();
}

class _ShoppingLocationCardState extends ConsumerState<ShoppingLocationCard> {
  Future<void> _openManualSearch() async {
    final initialValue =
        ref.read(shoppingLocationControllerProvider).lastQuery ?? '';
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManualLocationSheet(initialValue: initialValue),
    );
    if (!mounted || query == null || query.trim().isEmpty) {
      return;
    }
    await ref
        .read(shoppingLocationControllerProvider.notifier)
        .search(query.trim());
  }

  @override
  Widget build(BuildContext context) {
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
                ? 'This build has no live map key. Nearby store search is unavailable until GOOGLE_MAPS_API_KEY is configured.'
                : location == null
                ? 'Use your device location or enter an address or ZIP to verify what is actually nearby.'
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: !state.apiConfigured || state.loading
                    ? null
                    : () {
                        ref
                            .read(shoppingLocationControllerProvider.notifier)
                            .useDeviceLocation();
                      },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Use current location'),
              ),
              OutlinedButton.icon(
                onPressed: !state.apiConfigured || state.loading
                    ? null
                    : _openManualSearch,
                icon: const Icon(Icons.place_rounded),
                label: const Text('Address or ZIP'),
              ),
              if (location != null)
                TextButton(
                  onPressed: state.loading
                      ? null
                      : () {
                          ref
                              .read(shoppingLocationControllerProvider.notifier)
                              .clear();
                        },
                  child: const Text('Clear'),
                ),
            ],
          ),
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

class _ManualLocationSheet extends StatefulWidget {
  const _ManualLocationSheet({required this.initialValue});

  final String initialValue;

  @override
  State<_ManualLocationSheet> createState() => _ManualLocationSheetState();
}

class _ManualLocationSheetState extends State<_ManualLocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 20),
        child: SectionCard(
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search from address or ZIP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Street addresses use live geocoding. A 5-digit ZIP uses an approximate ZIP centroid fallback.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Address or ZIP',
                  hintText: '45211 or 123 Main St, Cincinnati, OH',
                ),
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_controller.text.trim());
                  },
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
