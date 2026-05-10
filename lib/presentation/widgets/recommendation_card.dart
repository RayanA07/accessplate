import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/explanation.dart';
import '../../domain/entities/recommendation.dart';
import 'section_card.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onExplain,
    required this.onSwap,
  });

  final ScoredFood recommendation;
  final VoidCallback onExplain;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = recommendation.explanation;
    final accent = _accentFor(recommendation.food.id);

    return SectionCard(
      tintColor: accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.food.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recommendation.food.servingLabel} | ${_labelizePrep(recommendation.food.prepMethod)} | \$${recommendation.food.costEstimate.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _ScoreBadge(
                score: recommendation.displayScore.round(),
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MacroStat(
                  label: 'Calories',
                  value: recommendation.nutrients.caloriesKcal.toStringAsFixed(
                    0,
                  ),
                ),
              ),
              Expanded(
                child: _MacroStat(
                  label: 'Protein',
                  value:
                      '${recommendation.nutrients.proteinG.toStringAsFixed(0)}g',
                ),
              ),
              Expanded(
                child: _MacroStat(
                  label: 'Carbs',
                  value:
                      '${recommendation.nutrients.carbsG.toStringAsFixed(0)}g',
                ),
              ),
              Expanded(
                child: _MacroStat(
                  label: 'Fat',
                  value: '${recommendation.nutrients.fatG.toStringAsFixed(0)}g',
                ),
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: explanation.satisfied.take(2).map((item) {
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
          const SizedBox(height: 18),
          OverflowBar(
            spacing: 10,
            overflowSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onExplain,
                child: const Text('Why this'),
              ),
              FilledButton(onPressed: onSwap, child: const Text('Adjust')),
            ],
          ),
        ],
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

  String _labelizePrep(String value) {
    switch (value) {
      case 'none':
        return 'No prep';
      case 'microwave':
        return 'Microwave';
      case 'stove':
        return 'Stovetop';
      case 'oven':
        return 'Oven';
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
  const _ScoreBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
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
              Text('Score', style: Theme.of(context).textTheme.labelMedium),
            ],
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
