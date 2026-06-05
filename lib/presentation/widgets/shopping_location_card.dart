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
    final nearbyCount = availabilityMode.nearbyStores.length;
    final theme = Theme.of(context);
    final location = availabilityMode.location;

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
          if (availabilityMode.isOffline)
            Text(copy.nearbyStoresOfflineBody, style: theme.textTheme.bodySmall)
          else ...[
            Text(
              location == null
                  ? copy.nearbyStoresPendingBody
                  : _summaryLine(copy, location, nearbyCount),
              style: theme.textTheme.bodySmall,
            ),
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
                  _StatusChip(label: copy.nearbyStoresLiveChip),
              ],
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
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
