import 'package:flutter/material.dart';

import '../../../domain/entities/recommendation.dart';
import '../../widgets/section_card.dart';

class ExplainDetailScreen extends StatelessWidget {
  const ExplainDetailScreen({
    super.key,
    required this.recommendation,
    required this.allRecommendations,
  });

  final ScoredFood recommendation;
  final List<ScoredFood> allRecommendations;

  @override
  Widget build(BuildContext context) {
    final explanation = recommendation.explanation;
    final comparables = <ScoredFood>[
      for (final id in explanation?.compareWithIds ?? const <int>[])
        ...allRecommendations.where((item) => item.food.id == id).take(1),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Why this food')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.food.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${recommendation.displayScore.round()}/100  •  \$${recommendation.food.costEstimate.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (explanation != null) ...[
            SectionCard(
              child: _ExplanationSection(
                title: 'Satisfied constraints',
                children: explanation.satisfied
                    .map((item) => Text('• ${item.description}'))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: 'Top reasons',
                children: explanation.positives
                    .map(
                      (item) => Text(
                        '• ${item.label}${item.detail == null ? '' : ' — ${item.detail}'}',
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: 'Tradeoffs',
                children: explanation.tradeoffs.isEmpty
                    ? const [Text('• No major tradeoffs surfaced for this profile.')]
                    : explanation.tradeoffs
                        .map(
                          (item) => Text(
                            '• ${item.label}${item.detail == null ? '' : ' — ${item.detail}'}',
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            child: _ExplanationSection(
              title: 'Nutrition snapshot',
              children: [
                Text('Protein: ${recommendation.nutrients.proteinG.toStringAsFixed(0)}g'),
                Text('Fiber: ${recommendation.nutrients.fiberG.toStringAsFixed(0)}g'),
                Text('Sodium: ${recommendation.nutrients.sodiumMg.toStringAsFixed(0)}mg'),
                Text('Iron: ${recommendation.nutrients.ironMg.toStringAsFixed(1)}mg'),
                Text('Calories: ${recommendation.nutrients.caloriesKcal.toStringAsFixed(0)} kcal'),
              ],
            ),
          ),
          if (comparables.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: 'Comparable alternatives',
                children: comparables
                    .map(
                      (item) => Text(
                        '• ${item.food.name} (${item.displayScore.round()}/100, \$${item.food.costEstimate.toStringAsFixed(2)})',
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
