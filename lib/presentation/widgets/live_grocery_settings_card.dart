import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/grocery.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/availability_context.dart';
import '../copy/app_copy.dart';
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
    final copy = AppCopy(profile.constraints.access.language);

    return SectionCard(
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose(
                'Live grocery lookup',
                'Busqueda de supermercado en vivo',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isConfigured
                  ? copy.choose(
                      'Attach Kroger brand names, aisle hints, and local prices to grocery recommendations without changing the offline ranking engine.',
                      'Agrega marcas Kroger, pistas de pasillo y precios locales a las recomendaciones de supermercado sin cambiar el motor sin conexion.',
                    )
                  : copy.choose(
                      'This build is still offline-only. Add Kroger API credentials with --dart-define to turn on store-specific grocery brands.',
                      'Esta version sigue siendo solo sin conexion. Agrega credenciales de la API de Kroger con --dart-define para activar marcas especificas de tienda.',
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.choose(
                'Only grocery brands and prices are live. Pantry, convenience, dollar-store, and travel-burden logic still come from bundled modeled access data.',
                'Solo las marcas y precios de supermercado son en vivo. La despensa, conveniencia, tienda de dolar y la carga de viaje siguen viniendo de datos modelados incluidos.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    isConfigured
                        ? copy.choose('Kroger enabled', 'Kroger activo')
                        : copy.choose('Offline only', 'Solo sin conexion'),
                  ),
                ),
                Chip(
                  label: Text(
                    groceryEnabled
                        ? copy.choose(
                            'Grocery context active',
                            'Supermercado activo',
                          )
                        : copy.choose(
                            'Grocery context off',
                            'Supermercado apagado',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedStore == null)
              Text(
                copy.choose(
                  'No grocery store selected yet.',
                  'Todavia no hay supermercado seleccionado.',
                ),
              )
            else ...[
              _SelectedStoreSummary(store: selectedStore),
              const SizedBox(height: 10),
              Text(
                copy.choose(
                  'When a store state is known, some SNAP restaurant-meal and WIC reminders can use state-specific program rules.',
                  'Cuando se conoce el estado de la tienda, algunos avisos de SNAP para restaurantes y WIC pueden usar reglas especificas del estado.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (!groceryEnabled) ...[
              const SizedBox(height: 10),
              Text(
                copy.choose(
                  'Turn on Grocery store in your availability settings to surface live store brands in recommendations.',
                  'Activa Supermercado en disponibilidad para mostrar marcas en vivo dentro de las recomendaciones.',
                ),
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
                        ? copy.choose(
                            'Choose Kroger store',
                            'Elegir tienda Kroger',
                          )
                        : copy.choose('Change store', 'Cambiar tienda'),
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
                    child: Text(copy.choose('Clear store', 'Quitar tienda')),
                  ),
              ],
            ),
          ],
        ),
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
    final language = ref
        .read(profileControllerProvider)
        .valueOrNull
        ?.constraints
        .access
        .language;
    final copy = AppCopy(
      language ?? UserProfile.defaults().constraints.access.language,
    );
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
                copy.choose('Choose a Kroger store', 'Elige una tienda Kroger'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                copy.choose(
                  'Search by ZIP code, then AccessPlate will use that store for live grocery brand lookups.',
                  'Busca por codigo postal y AccessPlate usara esa tienda para buscar marcas de supermercado en vivo.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: copy.choose('ZIP code', 'Codigo postal'),
                  hintText: '60651',
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search_rounded),
                label: Text(copy.choose('Find stores', 'Buscar tiendas')),
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
    final language = ref
        .read(profileControllerProvider)
        .valueOrNull
        ?.constraints
        .access
        .language;
    final copy = AppCopy(
      language ?? UserProfile.defaults().constraints.access.language,
    );
    if (postalCode.length < 5) {
      setState(() {
        _error = copy.choose(
          'Enter a 5-digit ZIP code.',
          'Escribe un codigo postal de 5 digitos.',
        );
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
            ? copy.choose(
                'No Kroger stores came back for that ZIP code.',
                'No aparecieron tiendas Kroger para ese codigo postal.',
              )
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = copy.choose(
          'Store search failed: $error',
          'La busqueda de tiendas fallo: $error',
        );
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
