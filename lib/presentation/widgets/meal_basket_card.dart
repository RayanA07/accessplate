import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import 'section_card.dart';

class MealBasketCard extends StatelessWidget {
  const MealBasketCard({super.key, required this.plan});

  final MealBasketPlan plan;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                      plan.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(plan.summary),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${plan.totalCost.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (plan.highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.highlights
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          for (final item in plan.items) ...[
            _BasketItemLine(item: item),
            if (item != plan.items.last) const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Text(
            '${plan.totalNutrients.caloriesKcal.toStringAsFixed(0)} kcal | ${plan.totalNutrients.proteinG.toStringAsFixed(0)}g protein | ${plan.totalNutrients.fiberG.toStringAsFixed(0)}g fiber',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BasketItemLine extends StatelessWidget {
  const _BasketItemLine({required this.item});

  final ScoredFood item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.food.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.food.servingLabel} | \$${item.food.costEstimate.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('${item.displayScore.round()}/100'),
      ],
    );
  }
}
