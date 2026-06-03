import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/explanation.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import 'live_store_match_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendation = widget.recommendation;
    final food = recommendation.food;
    final explanation = recommendation.explanation;
    final accent = _accentFor(food.id);
    final copy = AppCopy(widget.language);

    return Semantics(
      container: true,
      label: _semanticSummary(copy, recommendation, explanation),
      hint: copy.choose(
        'Open the card for decision details or log the meal to daily tracking.',
        'Abre la tarjeta para ver detalles o registrar la comida al seguimiento diario.',
      ),
      child: SectionCard(
        tintColor: accent.withValues(alpha: 0.06),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final overview = _CardOverview(
                  recommendation: recommendation,
                  explanation: explanation,
                  accent: accent,
                  language: widget.language,
                );
                final badge = _ScoreBadge(
                  score: recommendation.displayScore.round(),
                  color: accent,
                  qualityLabel: _qualityLabel(copy, recommendation.displayScore.round()),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      overview,
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerRight, child: badge),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: overview),
                    const SizedBox(width: 12),
                    badge,
                  ],
                );
              },
            ),
            if (explanation?.accessSummary?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _AccessSummaryStrip(summary: explanation!.accessSummary!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MacroMetric(
                    label: copy.caloriesLabel,
                    value: recommendation.nutrients.caloriesKcal.toStringAsFixed(0),
                    unit: 'CAL',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMetric(
                    label: copy.proteinLabel,
                    value: recommendation.nutrients.proteinG.toStringAsFixed(0),
                    unit: 'g',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMetric(
                    label: copy.carbsLabel,
                    value: recommendation.nutrients.carbsG.toStringAsFixed(0),
                    unit: 'g',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMetric(
                    label: copy.fatLabel,
                    value: recommendation.nutrients.fatG.toStringAsFixed(0),
                    unit: 'g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SourcePill(
                    label: _primarySourceLabel(copy, food),
                    detail: '
${food.prepTimeMin} min | ${_labelizePrep(copy, food.prepMethod)}'
                        .trim(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: widget.onExplain,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(copy.choose('Why this', 'Por que esta')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onTrack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                    child: Text(copy.choose('Log meal', 'Registrar comida')),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
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
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 16),
              if (explanation != null) ...[
                if (explanation.decisionFacts.isNotEmpty) ...[
                  _DecisionFactsGrid(
                    facts: explanation.decisionFacts,
                    language: widget.language,
                  ),
                  const SizedBox(height: 14),
                ],
                if (explanation.accessSummary?.isNotEmpty == true) ...[
                  _AccessBanner(
                    summary: explanation.accessSummary!,
                    tags: explanation.accessTags,
                    language: widget.language,
                  ),
                  const SizedBox(height: 14),
                ],
                if (explanation.satisfied.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: explanation.satisfied.take(4).map((item) {
                      return Chip(
                        avatar: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accent,
                        ),
                        label: Text(item.description),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                if (explanation.positives.isNotEmpty)
                  _ReasonLine(
                    icon: Icons.favorite_rounded,
                    color: accent,
                    text: _reasonText(explanation.positives.first),
                  ),
                if (explanation.tradeoffs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ReasonLine(
                    icon: Icons.tune_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    text: _reasonText(explanation.tradeoffs.first),
                    subdued: true,
                  ),
                ],
                const SizedBox(height: 14),
              ],
              LiveStorePreview(food: recommendation.food),
            ],
          ],
        ),
      ),
    );
  }

  String _reasonText(ScoreFactor item) {
    return item.detail == null ? item.label : '${item.label} | ${item.detail}';
  }

  Color _accentFor(int id) {
    const colors = [
      NihPalette.secondary,
      NihPalette.primaryAlt,
      NihPalette.warning,
      NihPalette.macroFat,
    ];
    return colors[id % colors.length];
  }

  String _semanticSummary(
    AppCopy copy,
    ScoredFood recommendation,
    Explanation? explanation,
  ) {
    final parts = <String>[
      recommendation.food.name,
      copy.choose(
        'Today fit ${recommendation.displayScore.round()}',
        'Ajuste hoy ${recommendation.displayScore.round()}',
      ),
      copy.choose(
        'Cost ${recommendation.food.costEstimate.toStringAsFixed(2)} dollars',
        'Costo ${recommendation.food.costEstimate.toStringAsFixed(2)} dolares',
      ),
    ];
    if (explanation?.accessSummary?.isNotEmpty == true) {
      parts.add(explanation!.accessSummary!);
    }
    return parts.join('. ');
  }

  String _qualityLabel(AppCopy copy, int score) {
    if (score >= 95) {
      return copy.choose('Excellent', 'Excelente');
    }
    if (score >= 85) {
      return copy.choose('Strong', 'Fuerte');
    }
    if (score >= 75) {
      return copy.choose('Solid', 'Solida');
    }
    return copy.choose('Fair', 'Aceptable');
  }

  String _primarySourceLabel(AppCopy copy, Food food) {
    final availability = food.availability.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    if (availability.isEmpty) {
      return copy.choose('Bundled source', 'Fuente incluida');
    }

    final primary = availability.first;
    return switch (primary) {
      AvailabilityContext.grocery => copy.choose('Grocery', 'Supermercado'),
      AvailabilityContext.convenience => copy.choose('Convenience', 'Conveniencia'),
      AvailabilityContext.fastFood => copy.choose('Fast food', 'Comida rapida'),
      AvailabilityContext.foodPantry => copy.choose('Food pantry', 'Despensa'),
      AvailabilityContext.dollarStore => copy.choose('Dollar store', 'Tienda de dolar'),
    };
  }

  String _labelizePrep(AppCopy copy, String value) {
    switch (value) {
      case 'none':
        return copy.choose('No prep', 'Sin preparar');
      case 'microwave':
        return copy.choose('Microwave', 'Microondas');
      case 'stove':
        return copy.choose('Stovetop', 'Estufa');
      case 'oven':
        return copy.choose('Oven', 'Horno');
      default:
        return value;
    }
  }
}

class _CardOverview extends StatelessWidget {
  const _CardOverview({
    required this.recommendation,
    required this.explanation,
    required this.accent,
    required this.language,
  });

  final ScoredFood recommendation;
  final Explanation? explanation;
  final Color accent;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(language);
    final theme = Theme.of(context);
    final food = recommendation.food;
    final subtitle = explanation?.accessSummary?.isNotEmpty == true
        ? explanation!.accessSummary!
        : '${food.servingLabel} | ${_prepLabel(copy, food.prepMethod)} | ${food.costEstimate.toStringAsFixed(2)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ArtworkTile(food: food, accent: accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6E6E76),
                  fontWeight: FontWeight.w500,
                  height: 1.32,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: copy.mealTimingLabel(food.mealTypes.firstOrNull ?? food.mealTypes.first)),
                  _InfoChip(label: '\$${food.costEstimate.toStringAsFixed(2)}'),
                  _InfoChip(label: '${food.prepTimeMin} min'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _prepLabel(AppCopy copy, String value) {
    switch (value) {
      case 'none':
        return copy.choose('No prep', 'Sin preparar');
      case 'microwave':
        return copy.choose('Microwave', 'Microondas');
      case 'stove':
        return copy.choose('Stovetop', 'Estufa');
      case 'oven':
        return copy.choose('Oven', 'Horno');
      default:
        return value;
    }
  }
}

class _ArtworkTile extends StatelessWidget {
  const _ArtworkTile({required this.food, required this.accent});

  final Food food;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _iconFor(food),
              size: 42,
              color: accent,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                food.category.replaceAll('_', ' '),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF54545B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Food food) {
    if (food.availability.contains(AvailabilityContext.fastFood)) {
      return Icons.lunch_dining_rounded;
    }
    if (food.availability.contains(AvailabilityContext.foodPantry)) {
      return Icons.inventory_2_rounded;
    }
    if (food.availability.contains(AvailabilityContext.dollarStore)) {
      return Icons.local_offer_rounded;
    }
    if (food.availability.contains(AvailabilityContext.convenience)) {
      return Icons.storefront_rounded;
    }
    if (food.category.contains('protein')) {
      return Icons.egg_alt_rounded;
    }
    if (food.category.contains('grain')) {
      return Icons.rice_bowl_rounded;
    }
    if (food.category.contains('produce')) {
      return Icons.eco_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF5F5F68),
        ),
      ),
    );
  }
}

class _AccessSummaryStrip extends StatelessWidget {
  const _AccessSummaryStrip({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        summary,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF53535B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MacroMetric extends StatelessWidget {
  const _MacroMetric({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value$unit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.color,
    required this.qualityLabel,
  });

  final int score;
  final Color color;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                qualityLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionFactsGrid extends StatelessWidget {
  const _DecisionFactsGrid({required this.facts, required this.language});

  final List<DecisionFact> facts;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = AppCopy(language);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final singleColumn = constraints.maxWidth < 360 || textScale > 1.2;
        final cardWidth = singleColumn
            ? constraints.maxWidth
            : ((constraints.maxWidth - 8) / 2).clamp(140.0, 220.0).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose('Decision snapshot', 'Resumen de decision'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facts
                  .map(
                    (fact) => SizedBox(
                      width: cardWidth,
                      child: _FactChip(fact: fact),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.fact});

  final DecisionFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F5F8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            fact.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B2B30),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonLine extends StatelessWidget {
  const _ReasonLine({
    required this.icon,
    required this.color,
    required this.text,
    this.subdued = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subdued
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({
    required this.summary,
    required this.tags,
    required this.language,
  });

  final String summary;
  final List<String> tags;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF5F5F8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppCopy(language).choose('Access read', 'Lectura de acceso'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2C31),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

extension on Set<Enum> {
  T? get firstOrNull => isEmpty ? null : first as T?;
}
