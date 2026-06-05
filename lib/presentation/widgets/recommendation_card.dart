import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import '../providers/nearby_store_providers.dart';
import 'food_thumbnail.dart';
import 'section_card.dart';
import 'store_display_utils.dart';

class RecommendationCard extends ConsumerStatefulWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onExplain,
    required this.onTrack,
    this.constraints,
    this.language = UserLanguage.english,
  });

  final ScoredFood recommendation;
  final VoidCallback onExplain;
  final VoidCallback onTrack;
  final UserConstraints? constraints;
  final UserLanguage language;

  @override
  ConsumerState<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<RecommendationCard> {
  bool _expanded = false;
  bool _requestedLivePlan = false;

  @override
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;
    final food = recommendation.food;
    final copy = AppCopy(widget.language);
    final constraints = widget.constraints ?? UserConstraints.defaults();
    final accent = _accentFor(food.id);
    final summaryPlan = ref.watch(mealShoppingSummaryProvider(food.id));
    final prefetchedPlans =
        ref.watch(prefetchedLiveMealShoppingPlansProvider).valueOrNull ??
        const <int, MealShoppingPlan>{};
    final prefetchedPlan = prefetchedPlans[food.id];
    final availabilityMode = ref.watch(storeAvailabilityModeProvider);
    final livePlanAsync = _requestedLivePlan && prefetchedPlan == null
        ? ref.watch(liveMealShoppingPlanProvider(food.id))
        : null;
    final displayedPlan =
        livePlanAsync?.valueOrNull ?? prefetchedPlan ?? summaryPlan;
    final scoreBreakdown = _scoreBreakdownModelFor(
      recommendation: recommendation,
      plan: displayedPlan,
      constraints: constraints,
      copy: copy,
    );

    return SectionCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FoodThumbnail(
                  food: food,
                  accent: accent,
                  plan: displayedPlan,
                  constraints: constraints,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _ScoreBadge(
                            score: scoreBreakdown.overallScore.round(),
                            onTap: () => _showScoreBreakdownSheet(
                              context,
                              scoreBreakdown,
                            ),
                            semanticLabel: copy.choose(
                              'Open score breakdown',
                              'Abrir detalle del puntaje',
                            ),
                            key: ValueKey('score-badge-${food.id}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StoreSummary(
                        headline: _storeHeadline(
                          plan: displayedPlan,
                          availabilityMode: availabilityMode,
                          copy: copy,
                        ),
                        verified: false,
                        verifiedLabel: copy.choose('Verified', 'Verificado'),
                        textStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: NihPalette.grayDark,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _LabelBlock(
                        title: _collapsedBuyTitle(copy, displayedPlan),
                        child: _IngredientChipWrap(
                          items: _collapsedBuyItems(displayedPlan, food),
                        ),
                      ),
                      if (_collapsedLiveExample(displayedPlan)
                          case final liveExample?) ...[
                        const SizedBox(height: 12),
                        Text(
                          liveExample,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: NihPalette.grayDark),
                        ),
                      ],
                      if (_backupStoresFor(displayedPlan) case final backups?
                          when availabilityMode.isOnline) ...[
                        const SizedBox(height: 8),
                        _AlsoAvailableNearby(
                          label: copy.choose(
                            'Also available nearby:',
                            'Tambien disponible cerca:',
                          ),
                          storeNames: backups,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (!_requestedLivePlan) {
                        _requestedLivePlan = true;
                      }
                      _expanded = !_expanded;
                    });
                  },
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _expanded
                        ? copy.choose('Hide plan', 'Ocultar plan')
                        : copy.choose('Plan', 'Plan'),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: widget.onTrack,
                  style: FilledButton.styleFrom(
                    backgroundColor: NihPalette.primaryDarkest,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(124, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(copy.choose('Log meal', 'Registrar comida')),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 20),
              _ExpandedPlan(
                plan: displayedPlan,
                copy: copy,
                shoppingLoading: livePlanAsync?.isLoading ?? false,
                availabilityMode: availabilityMode,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _storeHeadline({
    required MealShoppingPlan? plan,
    required StoreAvailabilityModeState availabilityMode,
    required AppCopy copy,
  }) {
    if (availabilityMode.isOnline) {
      final store = plan?.chosenStore;
      final storeName = store == null ? null : resolvedStoreDisplayName(store);
      if (store != null && storeName != null) {
        final travel = compactStoreTravelLabel(store.travelMetric);
        return travel == null ? storeName : '$storeName | $travel';
      }
      if (plan != null && plan.isMerchantSpecific) {
        return _merchantUnverifiedHeadline(plan, copy);
      }
      if (plan?.storeStatusNote case final note?) {
        return note;
      }
      return copy.choose(
        'Live search found nearby stores, but this meal was not verified at one yet.',
        'La busqueda en vivo encontro tiendas cercanas, pero esta comida todavia no se verifico en una.',
      );
    }
    if (!availabilityMode.apiConfigured) {
      return copy.choose(
        'Nearby store search is unavailable right now.',
        'La busqueda de tiendas cercanas no esta disponible ahora.',
      );
    }
    if (availabilityMode.isSearching) {
      return copy.choose(
        'Searching nearby stores for this meal...',
        'Buscando tiendas cercanas para esta comida...',
      );
    }
    if (availabilityMode.fallbackReason ==
        StoreAvailabilityFallbackReason.noLocation) {
      return copy.choose(
        'Location is not set yet, so this meal is still using your saved access settings.',
        'Todavia no hay ubicacion guardada, asi que esta comida sigue usando tus ajustes guardados.',
      );
    }
    if (availabilityMode.isOffline) {
      if (availabilityMode.fallbackReason ==
          StoreAvailabilityFallbackReason.noStoresFound) {
        return plan?.storeStatusNote ??
            copy.choose(
              'No verified nearby store matched this meal for the current search.',
              'Ninguna tienda cercana verificada coincidió con esta comida para la busqueda actual.',
            );
      }
      if (availabilityMode.fallbackReason ==
          StoreAvailabilityFallbackReason.searchFailed) {
        return copy.choose(
          'Live store search is temporarily unavailable, so this meal is using saved access settings.',
          'La busqueda en vivo de tiendas no esta disponible por ahora, asi que esta comida usa los ajustes guardados.',
        );
      }
      final context = plan?.offlineAvailabilityContext;
      if (context != null) {
        return _offlineAvailabilityHeadline(context, copy);
      }
    }
    if (availabilityMode.location == null) {
      return copy.choose(
        'Offline — showing meals from your saved settings.',
        'Sin conexion: mostrando comidas segun tus ajustes guardados.',
      );
    }
    if (plan?.storeStatusNote case final note?) {
      return note;
    }
    return copy.choose(
      'Using your saved store access settings for this meal.',
      'Usando tus ajustes guardados de acceso para esta comida.',
    );
  }

  String _merchantUnverifiedHeadline(MealShoppingPlan plan, AppCopy copy) {
    final brand =
        plan.requiredMerchantName ?? copy.choose('this chain', 'esta cadena');
    final base = copy.choose(
      'No nearby $brand verified for this search.',
      'No se verifico ningun $brand cercano para esta busqueda.',
    );
    final alternatives = plan.merchantAlternatives
        .take(2)
        .map((store) => store.name)
        .toList(growable: false);
    if (alternatives.isEmpty) {
      return base;
    }
    final names = alternatives.join(', ');
    return '$base ${copy.choose('Nearest fast-food options nearby: $names.', 'Opciones de comida rapida mas cercanas: $names.')}';
  }

  String _offlineAvailabilityHeadline(
    AvailabilityContext context,
    AppCopy copy,
  ) {
    return switch (context) {
      AvailabilityContext.grocery => copy.choose(
        'Available at: Grocery store',
        'Disponible en: Supermercado',
      ),
      AvailabilityContext.convenience => copy.choose(
        'Available at: Corner store item',
        'Disponible en: Tienda de esquina',
      ),
      AvailabilityContext.dollarStore => copy.choose(
        'Available at: Dollar store',
        'Disponible en: Tienda de dolar',
      ),
      AvailabilityContext.foodPantry => copy.choose(
        'Available at: Food pantry',
        'Disponible en: Despensa de alimentos',
      ),
      AvailabilityContext.fastFood => copy.choose(
        'Available at: Fast-food counter',
        'Disponible en: Comida rapida',
      ),
    };
  }

  String _collapsedBuyTitle(AppCopy copy, MealShoppingPlan? plan) {
    final ingredientPlan = plan?.ingredients;
    if (ingredientPlan?.isOrderOnly == true) {
      return copy.choose('Order', 'Pide');
    }
    return copy.choose('Buy list', 'Lista de compra');
  }

  List<IngredientRequirement> _collapsedBuyItems(
    MealShoppingPlan? plan,
    Food food,
  ) {
    final planned = plan?.ingredients.toBuy ?? const <IngredientRequirement>[];
    if (planned.isNotEmpty) {
      return planned.take(4).toList(growable: false);
    }
    return _fallbackBuyItems(food);
  }

  String? _collapsedLiveExample(MealShoppingPlan? plan) {
    if (plan?.hasLiveProducts != true) {
      return null;
    }
    final firstMatch = plan!.liveProductMatch!.lookup.matches.first;
    final product = firstMatch.cheapestProduct;
    if (product == null) {
      return null;
    }
    final parts = <String>[
      firstMatch.ingredient.label,
      product.brandLabel,
      if (product.size?.isNotEmpty == true) product.size!,
      if (product.effectivePrice != null)
        '\$${product.effectivePrice!.toStringAsFixed(2)}',
    ];
    return parts.join(' | ');
  }

  List<String>? _backupStoresFor(MealShoppingPlan? plan) {
    final backups = plan?.backupStores ?? const <NearbyStore>[];
    if (backups.isEmpty) {
      return null;
    }
    final names = <String>[];
    final seen = <String>{};
    for (final store in backups) {
      final name = resolvedStoreDisplayName(store);
      if (name != null && seen.add(name)) {
        names.add(name);
      }
    }
    return names.isEmpty ? null : names;
  }

  Future<void> _showScoreBreakdownSheet(
    BuildContext context,
    _ScoreBreakdownModel model,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScoreBreakdownSheet(model: model),
    );
  }
}

class _StoreSummary extends StatelessWidget {
  const _StoreSummary({
    required this.headline,
    required this.verified,
    required this.verifiedLabel,
    this.textStyle,
  });

  final String headline;
  final bool verified;
  final String verifiedLabel;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    // Split "Store Name | 0.6 mi" so name can truncate but distance stays visible
    final pipeIndex = headline.indexOf(' | ');
    if (pipeIndex != -1) {
      final storeName = headline.substring(0, pipeIndex);
      final distancePart = headline.substring(pipeIndex); // " | 0.6 mi"
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          Text(distancePart, style: textStyle),
          if (verified) ...[
            const SizedBox(width: 8),
            _VerifiedBadge(label: verifiedLabel),
          ],
        ],
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: headline),
          if (verified) ...[
            const WidgetSpan(child: SizedBox(width: 8)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _VerifiedBadge(label: verifiedLabel),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: NihPalette.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AlsoAvailableNearby extends StatelessWidget {
  const _AlsoAvailableNearby({required this.label, required this.storeNames});

  final String label;
  final List<String> storeNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final name in storeNames) _StoreChip(label: name)],
        ),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NihPalette.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NearbyStoreList extends StatelessWidget {
  const _NearbyStoreList({required this.stores});

  final List<NearbyStore> stores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < stores.length; index++) ...[
          _NearbyStoreListRow(store: stores[index]),
          if (index < stores.length - 1)
            Divider(
              height: 16,
              color: NihPalette.borderSoft.withValues(alpha: 0.72),
            ),
        ],
      ],
    );
  }
}

class _NearbyStoreListRow extends StatelessWidget {
  const _NearbyStoreListRow({required this.store});

  final NearbyStore store;

  @override
  Widget build(BuildContext context) {
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedPlan extends StatelessWidget {
  const _ExpandedPlan({
    required this.plan,
    required this.copy,
    required this.shoppingLoading,
    required this.availabilityMode,
  });

  final MealShoppingPlan? plan;
  final AppCopy copy;
  final bool shoppingLoading;
  final StoreAvailabilityModeState availabilityMode;

  @override
  Widget build(BuildContext context) {
    final ingredientPlan = plan?.ingredients;
    final preparationSteps = _preparationStepsFor(plan?.food.name);
    final verifiedTotal = plan?.liveProductMatch?.lookup.verifiedTotalCost;
    final structuredToBuy =
        ingredientPlan?.toBuy
            .where((item) => item.isStructured || item.isMenuItem)
            .toList(growable: false) ??
        const <IngredientRequirement>[];
    final estimatedToBuy =
        ingredientPlan?.toBuy
            .where((item) => item.isEstimated)
            .toList(growable: false) ??
        const <IngredientRequirement>[];
    final chosenStore = plan?.chosenStore;
    final chosenStoreName = chosenStore == null
        ? null
        : resolvedStoreDisplayName(chosenStore);
    final visibleBackupStores = (plan?.backupStores ?? const <NearbyStore>[])
        .where((store) => resolvedStoreDisplayName(store) != null)
        .toList(growable: false);
    final offlineContext = plan?.offlineAvailabilityContext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shoppingLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (availabilityMode.isOnline &&
            chosenStore != null &&
            chosenStoreName != null) ...[
          _LabelBlock(
            title: copy.choose('Go to', 'Ve a'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    chosenStoreName,
                    ?compactStoreTravelLabel(chosenStore.travelMetric),
                  ].join(' | '),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(chosenStore.address),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (availabilityMode.isOffline && offlineContext != null) ...[
          _LabelBlock(
            title: copy.choose('Available at', 'Disponible en'),
            child: Text(
              _offlineAvailabilityLabel(offlineContext),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (structuredToBuy.isNotEmpty) ...[
          _LabelBlock(
            title: ingredientPlan?.isOrderOnly == true
                ? copy.choose(
                    'Order from ${_storeName(plan)}',
                    'Pide en ${_storeName(plan)}',
                  )
                : copy.choose(
                    'Buy at ${_storeName(plan)}',
                    'Compra en ${_storeName(plan)}',
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in structuredToBuy) ...[
                  _PlanLine(text: _plannedItemLine(item)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (estimatedToBuy.isNotEmpty) ...[
          _LabelBlock(
            title: copy.choose('If still needed', 'Si todavia hace falta'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in estimatedToBuy) ...[
                  _PlanLine(text: _estimatedItemLine(item)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (preparationSteps.isNotEmpty) ...[
          _LabelBlock(
            title: copy.choose('How to prepare', 'Como prepararlo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var index = 0;
                  index < preparationSteps.length;
                  index++
                ) ...[
                  _NumberedPlanLine(
                    number: index + 1,
                    text: preparationSteps[index],
                  ),
                  if (index < preparationSteps.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ingredientPlan?.atHome.isNotEmpty == true) ...[
          _LabelBlock(
            title: copy.choose('Use from home', 'Usa de casa'),
            child: Text(
              ingredientPlan!.atHome.map(_displayIngredient).join(' | '),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (availabilityMode.isOnline && visibleBackupStores.isNotEmpty) ...[
          _LabelBlock(
            title: copy.choose('Backup store', 'Tienda de respaldo'),
            child: _NearbyStoreList(stores: visibleBackupStores),
          ),
          const SizedBox(height: 12),
        ],
        if (plan?.storeStatusNote case final note?) ...[
          Text(
            _storeGuidance(note),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: NihPalette.grayDark),
          ),
        ],
        if (verifiedTotal != null) ...[
          const SizedBox(height: 4),
          Text(
            copy.choose(
              'Matched total: \$${verifiedTotal.toStringAsFixed(2)}',
              'Total verificado: \$${verifiedTotal.toStringAsFixed(2)}',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  String _storeName(MealShoppingPlan? plan) {
    if (availabilityMode.isOffline &&
        plan?.offlineAvailabilityContext != null) {
      final context = plan!.offlineAvailabilityContext!;
      return _offlineAvailabilityLabel(context);
    }
    final chosenStore = plan?.chosenStore;
    final storeName = chosenStore == null
        ? null
        : resolvedStoreDisplayName(chosenStore);
    return storeName ?? copy.choose('this store', 'esta tienda');
  }

  String _plannedItemLine(IngredientRequirement item) {
    final match = _matchFor(item);
    if (match != null) {
      final product = match.cheapestProduct;
      if (product != null) {
        final parts = <String>[
          item.label,
          product.brandLabel,
          if (product.size?.isNotEmpty == true) product.size!,
          if (product.effectivePrice != null)
            '\$${product.effectivePrice!.toStringAsFixed(2)}',
        ];
        return parts.join(' | ');
      }
    }
    return _displayIngredient(item);
  }

  String _estimatedItemLine(IngredientRequirement item) {
    return copy.choose(
      '${_displayIngredient(item)} | brand not verified',
      '${_displayIngredient(item)} | marca no verificada',
    );
  }

  IngredientProductMatch? _matchFor(IngredientRequirement item) {
    final matches = plan?.liveProductMatch?.lookup.matches ?? const [];
    for (final match in matches) {
      if (match.ingredient.key == item.key) {
        return match;
      }
    }
    return null;
  }

  String _displayIngredient(IngredientRequirement item) {
    if (item.quantityLabel == null || item.quantityLabel!.trim().isEmpty) {
      return item.label;
    }
    return '${item.label} | ${item.quantityLabel}';
  }

  String _offlineStoreGuidance() {
    return copy.choose(
      'Store data unavailable offline. Use your access settings to find this at a nearby store.',
      'Datos de tienda no disponibles sin conexion. Usa tu configuracion de acceso para encontrar esto en una tienda cercana.',
    );
  }

  String _storeGuidance(String note) {
    if (plan?.chosenStore != null) {
      return note;
    }
    return switch (availabilityMode.fallbackReason) {
      StoreAvailabilityFallbackReason.noInternet => _offlineStoreGuidance(),
      StoreAvailabilityFallbackReason.noLocation => copy.choose(
        'Location is not set yet. Use access setup to verify a nearby store for this meal.',
        'Todavia no hay ubicacion guardada. Usa la configuracion de acceso para verificar una tienda cercana para esta comida.',
      ),
      StoreAvailabilityFallbackReason.noStoresFound => note,
      StoreAvailabilityFallbackReason.searchFailed => copy.choose(
        'Live store search is temporarily unavailable. Saved access settings are being used until store lookup recovers.',
        'La busqueda en vivo de tiendas no esta disponible por ahora. Se usan los ajustes guardados hasta que se recupere la busqueda.',
      ),
      StoreAvailabilityFallbackReason.apiUnavailable => copy.choose(
        'Nearby store search is unavailable right now.',
        'La busqueda de tiendas cercanas no esta disponible ahora.',
      ),
      null => availabilityMode.isOnline ? note : _offlineStoreGuidance(),
    };
  }

  String _offlineAvailabilityLabel(AvailabilityContext context) {
    return switch (context) {
      AvailabilityContext.grocery => copy.choose(
        'Grocery store',
        'Supermercado',
      ),
      AvailabilityContext.convenience => copy.choose(
        'Corner store item',
        'Tienda de esquina',
      ),
      AvailabilityContext.dollarStore => copy.choose(
        'Dollar store',
        'Tienda de dolar',
      ),
      AvailabilityContext.foodPantry => copy.choose(
        'Food pantry',
        'Despensa de alimentos',
      ),
      AvailabilityContext.fastFood => copy.choose(
        'Fast-food counter',
        'Comida rapida',
      ),
    };
  }

  List<String> _preparationStepsFor(String? foodName) {
    final normalized = (foodName ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    if (normalized == 'tuna salad on whole-wheat') {
      return const [
        'Open tuna pouch and drain',
        'Mix with any available condiment (mayo, mustard, or hot sauce)',
        'Spread on whole-wheat bread',
        'Serve immediately - no cooking needed',
      ];
    }
    if (_isBeanAndRiceMeal(normalized)) {
      return const [
        'Cook instant rice per packet (microwave: 90 seconds)',
        'Open and drain canned beans',
        'Combine in bowl',
        'Season with salt if available',
      ];
    }
    if (_isPeanutButterSandwichMeal(normalized)) {
      return const ['Spread peanut butter on bread', 'No cooking needed'];
    }
    return const [];
  }

  bool _isBeanAndRiceMeal(String normalizedName) {
    final hasBean =
        normalizedName.contains('bean') || normalizedName.contains('beans');
    final hasRice = normalizedName.contains('rice');
    final hasBowlOrCup =
        normalizedName.contains('bowl') ||
        normalizedName.contains('cup') ||
        normalizedName.contains('bag');
    return hasBean && hasRice && hasBowlOrCup;
  }

  bool _isPeanutButterSandwichMeal(String normalizedName) {
    return normalizedName.contains('peanut butter') &&
        (normalizedName.contains('sandwich') ||
            normalizedName.contains('whole wheat') ||
            normalizedName.contains('whole-wheat'));
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: NihPalette.primaryDarker),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NihPalette.primaryDarkest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberedPlanLine extends StatelessWidget {
  const _NumberedPlanLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NihPalette.primaryDarkest,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NihPalette.primaryDarkest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    super.key,
    required this.score,
    required this.onTap,
    required this.semanticLabel,
  });

  final int score;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF1B4332),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBreakdownSheet extends StatelessWidget {
  const _ScoreBreakdownSheet({required this.model});

  final _ScoreBreakdownModel model;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: NihPalette.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: NihPalette.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  key: const ValueKey('score-sheet-title'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var index = 0;
                          index < model.dimensions.length;
                          index++
                        ) ...[
                          _ScoreBreakdownRow(
                            dimension: model.dimensions[index],
                          ),
                          if (index < model.dimensions.length - 1)
                            const SizedBox(height: 14),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text(
                          model.overallLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: NihPalette.grayDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${model.overallScore.round()}',
                              key: const ValueKey('score-sheet-overall-score'),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                model.overallDetail,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: NihPalette.grayDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(model.closeLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({required this.dimension});

  final _ScoreDimension dimension;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dimension.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${dimension.score.round()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: dimension.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: (dimension.score / 100).clamp(0.0, 1.0),
              backgroundColor: NihPalette.grayLight,
              valueColor: AlwaysStoppedAnimation<Color>(dimension.color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dimension.detail,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NihPalette.grayDark),
        ),
      ],
    );
  }
}

class _ScoreBreakdownModel {
  const _ScoreBreakdownModel({
    required this.title,
    required this.dimensions,
    required this.overallScore,
    required this.overallLabel,
    required this.overallDetail,
    required this.closeLabel,
  });

  final String title;
  final List<_ScoreDimension> dimensions;
  final double overallScore;
  final String overallLabel;
  final String overallDetail;
  final String closeLabel;
}

class _ScoreDimension {
  const _ScoreDimension({
    required this.label,
    required this.detail,
    required this.score,
    required this.weight,
    required this.color,
  });

  final String label;
  final String detail;
  final double score;
  final double weight;
  final Color color;

  _ScoreDimension copyWith({double? score}) {
    return _ScoreDimension(
      label: label,
      detail: detail,
      score: score ?? this.score,
      weight: weight,
      color: color,
    );
  }
}

class _LabelBlock extends StatelessWidget {
  const _LabelBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: NihPalette.primaryDarkest,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _IngredientChipWrap extends StatelessWidget {
  const _IngredientChipWrap({required this.items});

  final List<IngredientRequirement> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: NihPalette.warmSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NihPalette.borderSoft),
              ),
              child: Text(
                item.quantityLabel == null
                    ? item.label
                    : '${item.label} | ${item.quantityLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
    );
  }
}

_ScoreBreakdownModel _scoreBreakdownModelFor({
  required ScoredFood recommendation,
  required MealShoppingPlan? plan,
  required UserConstraints constraints,
  required AppCopy copy,
}) {
  final nutritionScore = _nutritionFitScore(recommendation.breakdown) * 100;
  final budgetScore =
      (1 - recommendation.breakdown.cost).clamp(0.0, 1.0).toDouble() * 100;
  final accessScore =
      _baseAccessScore(
        recommendation: recommendation,
        plan: plan,
        constraints: constraints,
      ) *
      100;
  final safetyScore =
      (_isFullySafe(food: recommendation.food, constraints: constraints)
      ? 100.0
      : 0.0);
  final pantryScore =
      (_pantryOverlapScore(
        food: recommendation.food,
        plan: plan,
        constraints: constraints,
      ) *
      100);

  final dimensions = <_ScoreDimension>[
    _ScoreDimension(
      label: copy.choose('Nutrition fit', 'Ajuste nutricional'),
      detail: _nutritionDetail(copy, nutritionScore),
      score: nutritionScore,
      weight: 0.40,
      color: NihPalette.primaryAltDark,
    ),
    _ScoreDimension(
      label: copy.choose('Budget fit', 'Ajuste al presupuesto'),
      detail: copy.choose(
        '\$${recommendation.food.costEstimate.toStringAsFixed(2)} against your \$${constraints.feasibility.maxCostPerMeal.toStringAsFixed(0)} meal limit.',
        '\$${recommendation.food.costEstimate.toStringAsFixed(2)} contra tu limite de \$${constraints.feasibility.maxCostPerMeal.toStringAsFixed(0)} por comida.',
      ),
      score: budgetScore,
      weight: 0.20,
      color: const Color(0xFFC98734),
    ),
    _ScoreDimension(
      label: copy.choose('Access fit', 'Ajuste de acceso'),
      detail: _accessDetail(copy, plan: plan),
      score: accessScore,
      weight: 0.20,
      color: NihPalette.primary,
    ),
    _ScoreDimension(
      label: copy.choose('Dietary safety', 'Seguridad alimentaria'),
      detail: _safetyDetail(copy, safe: safetyScore >= 100),
      score: safetyScore,
      weight: 0.10,
      color: NihPalette.success,
    ),
    _ScoreDimension(
      label: copy.choose('Pantry overlap', 'Coincidencia con despensa'),
      detail: _pantryDetail(
        copy,
        food: recommendation.food,
        plan: plan,
        constraints: constraints,
      ),
      score: pantryScore,
      weight: 0.10,
      color: NihPalette.secondaryDark,
    ),
  ];

  final targetOverall = recommendation.displayScore > 0
      ? recommendation.displayScore.clamp(0.0, 100.0).toDouble()
      : _weightedAverageScore(dimensions);
  final normalized = _normalizeDimensionsToOverall(
    dimensions,
    targetOverall: targetOverall,
  );
  final overallScore = _weightedAverageScore(normalized);

  return _ScoreBreakdownModel(
    title: copy.choose('How this was scored.', 'Como se calculo este puntaje.'),
    dimensions: normalized,
    overallScore: overallScore,
    overallLabel: copy.choose(
      'Overall fit score.',
      'Puntaje general de ajuste.',
    ),
    overallDetail: copy.choose(
      'Weighted average of the five fit checks above.',
      'Promedio ponderado de las cinco revisiones de arriba.',
    ),
    closeLabel: copy.choose('Got it.', 'Entendido.'),
  );
}

List<_ScoreDimension> _normalizeDimensionsToOverall(
  List<_ScoreDimension> dimensions, {
  required double targetOverall,
}) {
  final scores = dimensions
      .map((item) => item.score.clamp(0.0, 100.0))
      .toList();
  final currentOverall = _weightedAverageScore([
    for (var index = 0; index < dimensions.length; index++)
      dimensions[index].copyWith(score: scores[index]),
  ]);
  final delta = targetOverall - currentOverall;
  if (delta.abs() < 0.25) {
    return [
      for (var index = 0; index < dimensions.length; index++)
        dimensions[index].copyWith(score: scores[index]),
    ];
  }

  const lockedIndexes = {3};
  if (delta > 0) {
    var availableGain = 0.0;
    for (var index = 0; index < dimensions.length; index++) {
      if (lockedIndexes.contains(index)) {
        continue;
      }
      availableGain += dimensions[index].weight * (100 - scores[index]);
    }
    if (availableGain > 0) {
      final factor = (delta / availableGain).clamp(0.0, 1.0);
      for (var index = 0; index < dimensions.length; index++) {
        if (lockedIndexes.contains(index)) {
          continue;
        }
        scores[index] = scores[index] + ((100 - scores[index]) * factor);
      }
    }
  } else {
    var availableDrop = 0.0;
    for (var index = 0; index < dimensions.length; index++) {
      if (lockedIndexes.contains(index)) {
        continue;
      }
      availableDrop += dimensions[index].weight * scores[index];
    }
    if (availableDrop > 0) {
      final factor = ((-delta) / availableDrop).clamp(0.0, 1.0);
      for (var index = 0; index < dimensions.length; index++) {
        if (lockedIndexes.contains(index)) {
          continue;
        }
        scores[index] = scores[index] - (scores[index] * factor);
      }
    }
  }

  return [
    for (var index = 0; index < dimensions.length; index++)
      dimensions[index].copyWith(score: scores[index].clamp(0.0, 100.0)),
  ];
}

double _weightedAverageScore(List<_ScoreDimension> dimensions) {
  var totalWeight = 0.0;
  var weightedSum = 0.0;
  for (final dimension in dimensions) {
    totalWeight += dimension.weight;
    weightedSum += dimension.score * dimension.weight;
  }
  if (totalWeight <= 0) {
    return 0.0;
  }
  return weightedSum / totalWeight;
}

double _baseAccessScore({
  required ScoredFood recommendation,
  required MealShoppingPlan? plan,
  required UserConstraints constraints,
}) {
  return recommendation.breakdown.access.clamp(0.0, 1.0).toDouble();
}

double _nutritionFitScore(ScoreBreakdown breakdown) {
  final macroFit = breakdown.macro.clamp(0.0, 1.0).toDouble();
  final microFit = breakdown.micro.clamp(0.0, 1.0).toDouble();
  final penaltyRelief = (1 - breakdown.penalty).clamp(0.0, 1.0).toDouble();
  return ((macroFit * 0.50) + (microFit * 0.20) + (penaltyRelief * 0.30))
      .clamp(0.0, 1.0)
      .toDouble();
}

bool _isFullySafe({required Food food, required UserConstraints constraints}) {
  final allergenConflict = food.allergens.any(
    constraints.safety.effectiveAllergens.contains,
  );
  if (allergenConflict) {
    return false;
  }

  final religion = constraints.safety.religion;
  if (religion.code != 'none' &&
      food.religionExcluded.any((rule) => rule.religion == religion)) {
    return false;
  }

  final medicalConflict = food.medicalRules.any(
    (rule) =>
        rule.severity == MedicalRuleSeverity.avoid &&
        constraints.safety.medicalAvoid.contains(rule.restriction),
  );
  return !medicalConflict;
}

double _pantryOverlapScore({
  required Food food,
  required MealShoppingPlan? plan,
  required UserConstraints constraints,
}) {
  final ingredientPlan = plan?.ingredients;
  if (ingredientPlan != null) {
    final total = ingredientPlan.atHome.length + ingredientPlan.toBuy.length;
    if (total > 0) {
      return (ingredientPlan.atHome.length / total).clamp(0.0, 1.0);
    }
  }

  final ingredients = food.ingredients;
  if (ingredients.isEmpty) {
    return 0.0;
  }
  final onHandCount = ingredients.where((item) {
    final stock = constraints.pantry.stockFor(item);
    return stock == PantryStockLevel.enough || stock == PantryStockLevel.low;
  }).length;
  return (onHandCount / ingredients.length).clamp(0.0, 1.0);
}

String _nutritionDetail(AppCopy copy, double nutritionScore) {
  if (nutritionScore >= 85) {
    return copy.choose(
      'Macros land close to your saved meal target.',
      'Los macros quedan cerca de tu meta guardada por comida.',
    );
  }
  if (nutritionScore >= 65) {
    return copy.choose(
      'Macros are usable but not a perfect target match.',
      'Los macros sirven, pero no coinciden por completo con tu meta.',
    );
  }
  return copy.choose(
    'Macros drift away from your saved meal target.',
    'Los macros se alejan de tu meta guardada por comida.',
  );
}

String _accessDetail(AppCopy copy, {required MealShoppingPlan? plan}) {
  if (plan?.chosenStore case final store?) {
    if (store.travelMetric.durationMinutes case final minutes?) {
      return copy.choose(
        '${store.name} fits within your current travel settings at about $minutes minutes away.',
        '${store.name} encaja con tu configuracion actual de viaje a unos $minutes minutos.',
      );
    }
    return copy.choose(
      '${store.name} matches your current store and transport settings.',
      '${store.name} coincide con tu configuracion actual de tiendas y transporte.',
    );
  }
  if (plan?.storeStatusNote != null) {
    return copy.choose(
      'Live store verification is unavailable, so reachability is estimated from your settings.',
      'La verificacion en vivo de tiendas no esta disponible, asi que el acceso se estima con tu configuracion.',
    );
  }
  return copy.choose(
    'Access is estimated from your enabled food sources and travel limit.',
    'El acceso se estima con tus fuentes de comida activadas y tu limite de viaje.',
  );
}

String _safetyDetail(AppCopy copy, {required bool safe}) {
  return safe
      ? copy.choose(
          'No allergen, religious, or medical restriction conflicts were detected.',
          'No se detectaron conflictos con alergias ni restricciones religiosas o medicas.',
        )
      : copy.choose(
          'This meal conflicts with a saved safety restriction.',
          'Esta comida entra en conflicto con una restriccion de seguridad guardada.',
        );
}

String _pantryDetail(
  AppCopy copy, {
  required Food food,
  required MealShoppingPlan? plan,
  required UserConstraints constraints,
}) {
  final ingredientPlan = plan?.ingredients;
  if (ingredientPlan != null) {
    final total = ingredientPlan.atHome.length + ingredientPlan.toBuy.length;
    if (total > 0) {
      return copy.choose(
        '${ingredientPlan.atHome.length} of $total needed items are already at home.',
        '${ingredientPlan.atHome.length} de $total articulos necesarios ya estan en casa.',
      );
    }
  }

  final totalIngredients = food.ingredients.length;
  final overlapCount = food.ingredients.where((item) {
    final stock = constraints.pantry.stockFor(item);
    return stock == PantryStockLevel.enough || stock == PantryStockLevel.low;
  }).length;
  return copy.choose(
    '$overlapCount of $totalIngredients ingredients are already marked in your pantry.',
    '$overlapCount de $totalIngredients ingredientes ya estan marcados en tu despensa.',
  );
}

List<IngredientRequirement> _fallbackBuyItems(Food food) {
  final tokens = food.ingredients
      .take(4)
      .map((ingredient) {
        final label = ingredient
            .split(RegExp(r'[_ ]+'))
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
        return IngredientRequirement(
          key: ingredient,
          label: label,
          searchTerms: [ingredient],
          pantryAliases: [ingredient],
          evidence: IngredientEvidence.estimated,
        );
      })
      .toList(growable: false);

  if (tokens.isNotEmpty) {
    return tokens;
  }

  return [
    IngredientRequirement(
      key: 'meal',
      label: food.name,
      searchTerms: const [],
      pantryAliases: const [],
      evidence: IngredientEvidence.estimated,
      quantityLabel: food.servingLabel,
    ),
  ];
}

Color _accentFor(int id) {
  const palette = [
    NihPalette.primaryDarker,
    NihPalette.secondaryDark,
    Color(0xFF7A8B3B),
    Color(0xFFB76E3C),
  ];
  return palette[id.abs() % palette.length];
}
