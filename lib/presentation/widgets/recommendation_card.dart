import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import '../providers/nearby_store_providers.dart';
import 'food_thumbnail.dart';
import 'section_card.dart';

class RecommendationCard extends ConsumerStatefulWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onExplain,
    required this.onTrack,
    this.language = UserLanguage.english,
  });

  final ScoredFood recommendation;
  final VoidCallback onExplain;
  final VoidCallback onTrack;
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
    final accent = _accentFor(food.id);
    final summaryPlan = ref.watch(mealShoppingSummaryProvider(food.id));
    final prefetchedPlans = ref
            .watch(prefetchedLiveMealShoppingPlansProvider)
            .valueOrNull ??
        const <int, MealShoppingPlan>{};
    final prefetchedPlan = prefetchedPlans[food.id];
    final locationState = ref.watch(shoppingLocationStateProvider);
    final livePlanAsync = _requestedLivePlan && prefetchedPlan == null
        ? ref.watch(liveMealShoppingPlanProvider(food.id))
        : null;
    final displayedPlan =
        livePlanAsync?.valueOrNull ?? prefetchedPlan ?? summaryPlan;

    return SectionCard(
      borderRadius: 28,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FoodThumbnail(food: food, accent: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _storeHeadline(
                          plan: displayedPlan,
                          locationState: locationState,
                          copy: copy,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NihPalette.grayDark,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabelBlock(
                        title: _collapsedBuyTitle(copy, displayedPlan),
                        child: _IngredientChipWrap(
                          items: _collapsedBuyItems(displayedPlan, food),
                        ),
                      ),
                      if (_collapsedLiveExample(displayedPlan) case final liveExample?) ...[
                        const SizedBox(height: 12),
                        Text(
                          liveExample,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NihPalette.grayDark,
                          ),
                        ),
                      ],
                      if (_backupSummary(displayedPlan) case final backupSummary?) ...[
                        const SizedBox(height: 12),
                        Text(
                          backupSummary,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NihPalette.grayDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                        ? copy.choose('Less', 'Menos')
                        : copy.choose('Details', 'Detalles'),
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
              _ExpandedDetails(
                plan: displayedPlan,
                copy: copy,
                onExplain: widget.onExplain,
                shoppingLoading: livePlanAsync?.isLoading ?? false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _storeHeadline({
    required MealShoppingPlan? plan,
    required ShoppingLocationState locationState,
    required AppCopy copy,
  }) {
    if (plan?.chosenStore case final store?) {
      return '${store.name} | ${_travelLabel(store.travelMetric)}';
    }
    if (!locationState.apiConfigured) {
      return copy.choose(
        'Nearby store verification is unavailable in this build.',
        'La verificacion de tiendas cercanas no esta disponible en esta version.',
      );
    }
    if (locationState.location == null) {
      return copy.choose(
        'Add a location to verify nearby stores and travel time.',
        'Agrega una ubicacion para verificar tiendas cercanas y tiempo de viaje.',
      );
    }
    if (plan?.storeStatusNote case final note?) {
      return note;
    }
    return copy.choose(
      'Store verification is still loading.',
      'La verificacion de tiendas sigue cargando.',
    );
  }

  String _collapsedBuyTitle(AppCopy copy, MealShoppingPlan? plan) {
    final ingredientPlan = plan?.ingredients;
    if (ingredientPlan?.isOrderOnly == true) {
      return copy.choose('Order', 'Pide');
    }
    if (ingredientPlan?.hasEstimatedToBuy == true) {
      return copy.choose('Estimated buy items', 'Compra estimada');
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

  String? _backupSummary(MealShoppingPlan? plan) {
    final backups = plan?.backupStores ?? const <NearbyStore>[];
    if (backups.isEmpty) {
      return null;
    }
    return 'Backups: ${backups.map((store) => store.name).join(' | ')}';
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.plan,
    required this.copy,
    required this.onExplain,
    required this.shoppingLoading,
  });

  final MealShoppingPlan? plan;
  final AppCopy copy;
  final VoidCallback onExplain;
  final bool shoppingLoading;

  @override
  Widget build(BuildContext context) {
    final ingredientPlan = plan?.ingredients;
    final structuredToBuy = ingredientPlan?.toBuy
            .where((item) => item.isStructured || item.isMenuItem)
            .toList(growable: false) ??
        const <IngredientRequirement>[];
    final estimatedToBuy = ingredientPlan?.toBuy
            .where((item) => item.isEstimated)
            .toList(growable: false) ??
        const <IngredientRequirement>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shoppingLoading) const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(),
        ),
        if (ingredientPlan?.atHome.isNotEmpty == true) ...[
          _LabelBlock(
            title: copy.choose('Already at home', 'Ya en casa'),
            child: _IngredientChipWrap(items: ingredientPlan!.atHome),
          ),
          const SizedBox(height: 12),
        ],
        if (structuredToBuy.isNotEmpty) ...[
          _LabelBlock(
            title: ingredientPlan?.isOrderOnly == true
                ? copy.choose('Order item', 'Articulo para pedir')
                : copy.choose('Buy list', 'Lista de compra'),
            child: _IngredientChipWrap(items: structuredToBuy),
          ),
          const SizedBox(height: 12),
        ],
        if (estimatedToBuy.isNotEmpty) ...[
          _LabelBlock(
            title: copy.choose(
              'Estimated fallback items',
              'Articulos estimados',
            ),
            child: _IngredientChipWrap(items: estimatedToBuy),
          ),
          const SizedBox(height: 12),
        ],
        if (plan?.chosenStore case final store?) ...[
          _LabelBlock(
            title: copy.choose('Chosen store', 'Tienda elegida'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(store.address),
                const SizedBox(height: 4),
                Text(_travelLabel(store.travelMetric)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (plan?.backupStores.isNotEmpty == true) ...[
          _LabelBlock(
            title: copy.choose('Backup stores', 'Tiendas de respaldo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan!.backupStores
                  .map(
                    (store) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${store.name} | ${_travelLabel(store.travelMetric)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (plan?.hasLiveProducts == true) ...[
          _LabelBlock(
            title: copy.choose('Verified live products', 'Productos verificados'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan!.liveProductMatch!.store.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...plan!.liveProductMatch!.lookup.matches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_expandedProductLine(match)),
                  ),
                ),
                if (plan!.liveProductMatch!.lookup.verifiedTotalCost case final total?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Verified total for matched items: \$${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Text(
                    'Only matched items have verified prices. Full verified total unavailable.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (plan?.storeStatusNote case final note?) ...[
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: NihPalette.grayDark,
            ),
          ),
          const SizedBox(height: 14),
        ],
        OutlinedButton.icon(
          onPressed: onExplain,
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(copy.choose('Open full details', 'Abrir detalles')),
        ),
      ],
    );
  }

  String _expandedProductLine(IngredientProductMatch match) {
    final product = match.cheapestProduct;
    if (product == null) {
      return match.ingredient.label;
    }
    final parts = <String>[
      match.ingredient.label,
      product.brandLabel,
      product.description,
      if (product.size?.isNotEmpty == true) product.size!,
      if (product.effectivePrice != null)
        '\$${product.effectivePrice!.toStringAsFixed(2)}',
    ];
    return parts.join(' | ');
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

List<IngredientRequirement> _fallbackBuyItems(Food food) {
  final tokens = food.ingredients.take(4).map((ingredient) {
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
  }).toList(growable: false);

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

String _travelLabel(TravelMetric metric) {
  final distance = metric.distanceMiles;
  final duration = metric.durationMinutes;
  if (metric.isLive) {
    if (duration != null && distance != null) {
      return '$duration min | ${distance.toStringAsFixed(1)} mi | live route';
    }
    if (duration != null) {
      return '$duration min | live route';
    }
    if (distance != null) {
      return '${distance.toStringAsFixed(1)} mi | live route';
    }
    return 'Live route';
  }

  if (metric.isApproximate) {
    if (distance != null) {
      return 'Approx. ${distance.toStringAsFixed(1)} mi';
    }
    return 'Approximate distance';
  }

  return 'Travel unavailable';
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
