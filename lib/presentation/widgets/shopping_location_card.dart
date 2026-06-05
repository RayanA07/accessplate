import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/entities/user_profile.dart';
import '../copy/app_copy.dart';
import '../providers/nearby_store_providers.dart';
import '../providers/profile_controller.dart';
import 'section_card.dart';

class ShoppingLocationCard extends ConsumerWidget {
  const ShoppingLocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final state = ref.watch(shoppingLocationStateProvider);
    final availabilityMode = ref.watch(storeAvailabilityModeProvider);
    final theme = Theme.of(context);
    final location = availabilityMode.location;
    final nearbyStores = availabilityMode.nearbyStores
        .take(3)
        .toList(growable: false);

    return SectionCard(
      tintColor: NihPalette.secondaryLightest,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.nearbyStoresTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _bodyText(copy, availabilityMode, location),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          const _LocationSearchControls(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (availabilityMode.usingDeviceLocation)
                _StatusChip(label: copy.nearbyStoresDeviceLocationChip),
              if (availabilityMode.isSearching)
                _StatusChip(
                  label: copy.nearbyStoresSearchingChip,
                  spinner: true,
                )
              else
                _StatusChip(label: _statusLabel(copy, availabilityMode)),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (availabilityMode.lookupError?.trim().isNotEmpty == true &&
              availabilityMode.lookupError != state.error) ...[
            const SizedBox(height: 8),
            Text(
              availabilityMode.lookupError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (nearbyStores.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final store in nearbyStores) ...[
              _NearbyStorePreview(store: store),
              if (store != nearbyStores.last) const SizedBox(height: 6),
            ],
          ],
          if (location != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: state.loading
                    ? null
                    : () {
                        ref
                            .read(shoppingLocationControllerProvider.notifier)
                            .clear();
                      },
                child: Text(copy.nearbyStoresClearAction),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summaryLine(AppCopy copy, SearchLocation location, int nearbyCount) {
    if (location.isApproximate) {
      return copy.nearbyStoresApproximateLine(location.label, nearbyCount);
    }
    return copy.nearbyStoresLiveLine(location.label, nearbyCount);
  }

  String _bodyText(
    AppCopy copy,
    StoreAvailabilityModeState availabilityMode,
    SearchLocation? location,
  ) {
    if (location == null) {
      return copy.nearbyStoresPendingBody;
    }

    final summary = _summaryLine(
      copy,
      location,
      availabilityMode.nearbyStores.length,
    );
    return switch (availabilityMode.fallbackReason) {
      StoreAvailabilityFallbackReason.apiUnavailable =>
        copy.nearbyStoresOfflineBody,
      StoreAvailabilityFallbackReason.noInternet => copy.choose(
        '$summary Live store verification is paused until internet is available again.',
        '$summary La verificacion en vivo de tiendas esta pausada hasta que vuelva el internet.',
      ),
      StoreAvailabilityFallbackReason.noLocation =>
        copy.nearbyStoresPendingBody,
      StoreAvailabilityFallbackReason.noStoresFound => copy.choose(
        '$summary No verified nearby stores matched this search yet.',
        '$summary Todavia no se encontraron tiendas cercanas verificadas para esta busqueda.',
      ),
      StoreAvailabilityFallbackReason.searchFailed => copy.choose(
        '$summary Live store lookup hit a service issue, so saved access settings stay in place for now.',
        '$summary La busqueda en vivo de tiendas tuvo un problema de servicio, asi que por ahora se mantienen los ajustes guardados.',
      ),
      null => summary,
    };
  }

  String _statusLabel(
    AppCopy copy,
    StoreAvailabilityModeState availabilityMode,
  ) {
    return switch (availabilityMode.fallbackReason) {
      StoreAvailabilityFallbackReason.apiUnavailable => copy.choose(
        'Unavailable',
        'No disponible',
      ),
      StoreAvailabilityFallbackReason.noInternet => copy.choose(
        'Saved settings',
        'Ajustes guardados',
      ),
      StoreAvailabilityFallbackReason.noLocation => copy.choose(
        'Setup needed',
        'Falta configurar',
      ),
      StoreAvailabilityFallbackReason.noStoresFound => copy.choose(
        'No stores matched',
        'Sin coincidencias',
      ),
      StoreAvailabilityFallbackReason.searchFailed => copy.choose(
        'Search issue',
        'Problema de busqueda',
      ),
      null => copy.nearbyStoresLiveChip,
    };
  }
}

class _LocationSearchControls extends ConsumerStatefulWidget {
  const _LocationSearchControls();

  @override
  ConsumerState<_LocationSearchControls> createState() =>
      _LocationSearchControlsState();
}

class _LocationSearchControlsState
    extends ConsumerState<_LocationSearchControls> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(shoppingLocationStateProvider).lastQuery;
    _queryController = TextEditingController(text: initialQuery ?? '');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final state = ref.watch(shoppingLocationStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          enabled: !state.loading,
          decoration: InputDecoration(
            hintText: copy.nearbyStoresSearchHint,
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => _search(context),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: state.loading ? null : () => _search(context),
              child: Text(copy.nearbyStoresSearchAction),
            ),
            OutlinedButton.icon(
              onPressed: state.loading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      ref
                          .read(shoppingLocationControllerProvider.notifier)
                          .useDeviceLocation();
                    },
              icon: const Icon(Icons.my_location_rounded),
              label: Text(copy.nearbyStoresUseLocationAction),
            ),
          ],
        ),
      ],
    );
  }

  void _search(BuildContext context) {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    ref.read(shoppingLocationControllerProvider.notifier).search(query);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.spinner = false});

  final String label;
  final bool spinner;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinner) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
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
    final distanceMiles = store.travelMetric.distanceMiles;
    final distanceLabel = distanceMiles == null
        ? null
        : distanceMiles < 0.1
        ? '<0.1 mi'
        : '${distanceMiles.toStringAsFixed(1)} mi';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(
            Icons.storefront_rounded,
            size: 16,
            color: NihPalette.primaryDarkest,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            distanceLabel == null
                ? store.name
                : '${store.name} | $distanceLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
