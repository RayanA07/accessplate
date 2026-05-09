import 'package:flutter/material.dart';

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

    return SectionCard(
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recommendation.food.servingLabel}  •  \$${recommendation.food.costEstimate.toStringAsFixed(2)}  •  ${recommendation.food.prepMethod}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${recommendation.displayScore.round()}/100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: explanation.satisfied.take(3).map((item) {
                return Chip(
                  avatar: const Icon(Icons.check_circle, size: 18),
                  label: Text(item.description),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ...explanation.positives.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Top reason: ${item.label}${item.detail == null ? '' : ' • ${item.detail}'}'),
              ),
            ),
            if (explanation.tradeoffs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...explanation.tradeoffs.take(2).map(
                (item) => Text(
                  'Tradeoff: ${item.label}${item.detail == null ? '' : ' • ${item.detail}'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              OutlinedButton(
                onPressed: onExplain,
                child: const Text('Explain'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onSwap,
                child: const Text('Swap'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
