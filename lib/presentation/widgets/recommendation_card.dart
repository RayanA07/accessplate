import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/explanation.dart';
import '../../domain/entities/recommendation.dart';
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
    final explanation = widget.recommendation.explanation;
    final accent = _accentFor(widget.recommendation.food.id);
    final copy = AppCopy(widget.language);

    return Semantics(
      container: true,
      label: _semanticSummary(copy, explanation),
      hint: copy.choose(
        'Expand for more detail or log this meal to daily tracking.',
        'Abre para ver mas detalle o registra esta comida en el seguimiento diario.',
      ),
      child: SectionCard(
        tintColor: accent.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stacked = constraints.maxWidth < 330 || textScale > 1.2;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.recommendation.food.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.recommendation.food.servingLabel} | ${_labelizePrep(copy, widget.recommendation.food.prepMethod)} | \$${widget.recommendation.food.costEstimate.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (explanation?.accessSummary?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        explanation!.accessSummary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
                final badge = _ScoreBadge(
                  score: widget.recommendation.displayScore.round(),
                  color: accent,
                  language: widget.language,
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerLeft, child: badge),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 16),
                    badge,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MacroStat(
                    label: copy.caloriesLabel,
                    value: widget.recommendation.nutrients.caloriesKcal
                        .toStringAsFixed(0),
                  ),
                ),
                Expanded(
                  child: _MacroStat(
                    label: copy.proteinLabel,
                    value:
                        '${widget.recommendation.nutrients.proteinG.toStringAsFixed(0)}g',
                  ),
                ),
                Expanded(
                  child: _MacroStat(
                    label: copy.choose('Fiber', 'Fibra'),
                    value:
                        '${widget.recommendation.nutrients.fiberG.toStringAsFixed(0)}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
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
                        ? copy.choose('Hide details', 'Ocultar detalles')
                        : copy.choose('Show details', 'Mostrar detalles'),
                  ),
                ),
                OutlinedButton(
                  onPressed: widget.onExplain,
                  child: Text(copy.choose('Why this', 'Por que esta')),
                ),
                FilledButton.tonal(
                  onPressed: widget.onTrack,
                  child: Text(copy.choose('Log meal', 'Registrar comida')),
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
              ],
              LiveStorePreview(food: widget.recommendation.food),
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
      NihPalette.primaryAltDark,
      NihPalette.success,
      NihPalette.warning,
    ];
    return colors[id % colors.length];
  }

  String _semanticSummary(AppCopy copy, Explanation? explanation) {
    final parts = <String>[
      widget.recommendation.food.name,
      copy.choose(
        'Today fit ${widget.recommendation.displayScore.round()}',
        'Ajuste hoy ${widget.recommendation.displayScore.round()}',
      ),
      copy.choose(
        'Cost \$${widget.recommendation.food.costEstimate.toStringAsFixed(2)}',
        'Costo \$${widget.recommendation.food.costEstimate.toStringAsFixed(2)}',
      ),
    ];
    if (explanation?.accessSummary?.isNotEmpty == true) {
      parts.add(explanation!.accessSummary!);
    }
    return parts.join('. ');
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

class _MacroStat extends StatelessWidget {
  const _MacroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.color,
    required this.language,
  });

  final int score;
  final Color color;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final badgeSize = textScale > 1.2 ? 88.0 : 72.0;
    final labelStyle =
        (textScale > 1.2
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.labelMedium)
            ?.copyWith(height: 1.0);

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: badgeSize,
            height: badgeSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppCopy(language).choose('Today fit', 'Ajuste hoy'),
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppCopy(language).choose('Access read', 'Lectura de acceso'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
