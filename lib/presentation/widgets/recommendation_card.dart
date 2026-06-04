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
        'Nearby store search is unavailable right now.',
        'La busqueda de tiendas cercanas no esta disponible ahora.',
      );
    }
    if (locationState.location == null) {
      return copy.choose(
        'Add a location to verify nearby stores and approximate distance.',
        'Agrega una ubicacion para verificar tiendas cercanas y distancia aproximada.',
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

class _ExpandedPlan extends StatelessWidget {
  const _ExpandedPlan({
    required this.plan,
    required this.copy,
    required this.shoppingLoading,
  });

  final MealShoppingPlan? plan;
  final AppCopy copy;
  final bool shoppingLoading;

  @override
  Widget build(BuildContext context) {
    final ingredientPlan = plan?.ingredients;
    final verifiedTotal = plan?.liveProductMatch?.lookup.verifiedTotalCost;
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
        if (plan?.chosenStore case final store?) ...[
          _LabelBlock(
            title: copy.choose('Go to', 'Ve a'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.name} | ${_travelLabel(store.travelMetric)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(store.address),
              ],
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
            title: copy.choose(
              'If still needed',
              'Si todavia hace falta',
            ),
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
        if (ingredientPlan?.atHome.isNotEmpty == true) ...[
          _LabelBlock(
            title: copy.choose('Use from home', 'Usa de casa'),
            child: Text(
              ingredientPlan!.atHome
                  .map(_displayIngredient)
                  .join(' | '),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (plan?.backupStores.isNotEmpty == true) ...[
          _LabelBlock(
            title: copy.choose('Backup store', 'Tienda de respaldo'),
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
          const SizedBox(height: 12),
        ],
        if (plan?.storeStatusNote case final note?) ...[
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: NihPalette.grayDark,
            ),
          ),
        ],
        if (verifiedTotal != null) ...[
          const SizedBox(height: 4),
          Text(
            copy.choose(
              'Matched total: \$${verifiedTotal.toStringAsFixed(2)}',
              'Total verificado: \$${verifiedTotal.toStringAsFixed(2)}',
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  String _storeName(MealShoppingPlan? plan) {
    return plan?.chosenStore?.name ??
        copy.choose('this store', 'esta tienda');
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
