import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          SectionCard(
            tintColor: NihPalette.primaryAltLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.food.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${recommendation.displayScore.round()}/100 • \$${recommendation.food.costEstimate.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
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
                    .map((item) => _BulletText(item.description))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: 'Top reasons',
                children: explanation.positives
                    .map(
                      (item) => _BulletText(
                        item.detail == null
                            ? item.label
                            : '${item.label} • ${item.detail}',
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
                    ? const [
                        _BulletText(
                          'No major tradeoffs surfaced for this profile.',
                        ),
                      ]
                    : explanation.tradeoffs
                          .map(
                            (item) => _BulletText(
                              item.detail == null
                                  ? item.label
                                  : '${item.label} • ${item.detail}',
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
                _BulletText(
                  'Protein: ${recommendation.nutrients.proteinG.toStringAsFixed(0)}g',
                ),
                _BulletText(
                  'Fiber: ${recommendation.nutrients.fiberG.toStringAsFixed(0)}g',
                ),
                _BulletText(
                  'Sodium: ${recommendation.nutrients.sodiumMg.toStringAsFixed(0)}mg',
                ),
                _BulletText(
                  'Iron: ${recommendation.nutrients.ironMg.toStringAsFixed(1)}mg',
                ),
                _BulletText(
                  'Calories: ${recommendation.nutrients.caloriesKcal.toStringAsFixed(0)} kcal',
                ),
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
                      (item) => _BulletText(
                        '${item.food.name} (${item.displayScore.round()}/100, \$${item.food.costEstimate.toStringAsFixed(2)})',
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
  const _ExplanationSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: NihPalette.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
