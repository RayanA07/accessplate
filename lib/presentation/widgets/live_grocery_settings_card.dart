import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/grocery.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../providers/app_bootstrap.dart';
import '../providers/profile_controller.dart';
import 'section_card.dart';

class LiveGrocerySettingsCard extends ConsumerStatefulWidget {
  const LiveGrocerySettingsCard({super.key});

  @override
  ConsumerState<LiveGrocerySettingsCard> createState() =>
      _LiveGrocerySettingsCardState();
}

class _LiveGrocerySettingsCardState
    extends ConsumerState<LiveGrocerySettingsCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final bootstrap = ref.watch(appBootstrapProvider).valueOrNull;
    final isConfigured =
        bootstrap?.groceryCatalogRepository.isConfigured ?? false;
    final feasibility = profile.constraints.feasibility;
    final selectedStore = feasibility.groceryStore;
    final groceryEnabled = feasibility.availability.contains(
      AvailabilityContext.grocery,
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live grocery lookup',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isConfigured
                ? 'Attach Kroger brand names, aisle hints, and local prices to grocery recommendations without changing the offline ranking engine.'
                : 'This build is still offline-only. Add Kroger API credentials with --dart-define=KROGER_CLIENT_ID=... and --dart-define=KROGER_CLIENT_SECRET=... to turn on store-specific brands.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(isConfigured ? 'Kroger enabled' : 'Offline only'),
              ),
              Chip(
                label: Text(
                  groceryEnabled
                      ? 'Grocery context active'
                      : 'Grocery context off',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedStore == null)
            const Text('No grocery store selected yet.')
          else
            _SelectedStoreSummary(store: selectedStore),
          if (!groceryEnabled) ...[
            const SizedBox(height: 10),
            const Text(
              'Turn on Grocery store in your availability settings to surface live store brands in recommendations.',
            ),
          ],
          const SizedBox(height: 14),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: !isConfigured || _busy ? null : _selectStore,
                icon: const Icon(Icons.store_mall_directory_rounded),
                label: Text(
                  selectedStore == null
                      ? 'Choose Kroger store'
                      : 'Change store',
                ),
              ),
              if (selectedStore != null)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          ref
                              .read(profileControllerProvider.notifier)
                              .updateGroceryStore(null);
                        },
                  child: const Text('Clear store'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStore() async {
    setState(() {
      _busy = true;
    });
    final currentStore = ref
        .read(profileControllerProvider)
        .valueOrNull
        ?.constraints
        .feasibility
        .groceryStore;
    final selected = await showModalBottomSheet<GroceryStore>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroceryStorePickerSheet(initialStore: currentStore),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
    });
    if (selected != null) {
      final controller = ref.read(profileControllerProvider.notifier);
      await controller.updateGroceryStore(selected);
      await controller.updatePostalCode(selected.postalCode);
    }
  }
}

class _SelectedStoreSummary extends StatelessWidget {
  const _SelectedStoreSummary({required this.store});

  final GroceryStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(store.addressLabel),
          if (store.phone?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(store.phone!),
          ],
        ],
      ),
    );
  }
}

class _GroceryStorePickerSheet extends ConsumerStatefulWidget {
  const _GroceryStorePickerSheet({this.initialStore});

  final GroceryStore? initialStore;

  @override
  ConsumerState<_GroceryStorePickerSheet> createState() =>
      _GroceryStorePickerSheetState();
}

class _GroceryStorePickerSheetState
    extends ConsumerState<_GroceryStorePickerSheet> {
  late final TextEditingController _postalCodeController;
  bool _searching = false;
  String? _error;
  List<GroceryStore> _stores = const [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _postalCodeController = TextEditingController(
      text:
          widget.initialStore?.postalCode ??
          profile?.constraints.access.postalCode ??
          '',
    );
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
        child: SectionCard(
          borderRadius: 30,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a Kroger store',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Search by ZIP code, then AccessPlate will use that store for live grocery brand lookups.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ZIP code',
                  hintText: '45211',
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find stores'),
              ),
              if (_searching) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_stores.isNotEmpty) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _stores.length,
                    separatorBuilder: (_, _) => const Divider(height: 18),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(store.name),
                        subtitle: Text(store.addressLabel),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(store),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _search() async {
    final postalCode = _postalCodeController.text.trim();
    if (postalCode.length < 5) {
      setState(() {
        _error = 'Enter a 5-digit ZIP code.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _stores = const [];
    });

    try {
      final bootstrap = await ref.read(appBootstrapProvider.future);
      final stores = await bootstrap.searchGroceryStoresUseCase.execute(
        postalCode: postalCode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stores = stores;
        _error = stores.isEmpty
            ? 'No Kroger stores came back for that ZIP code.'
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Store search failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }
}
