import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import 'section_card.dart';

class MealBasketCard extends StatelessWidget {
  const MealBasketCard({
    super.key,
    required this.plan,
    this.language = UserLanguage.english,
    this.onTrack,
  });

  final MealBasketPlan plan;
  final UserLanguage language;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(language);
    return Semantics(
      container: true,
      label: '${plan.title}. ${plan.summary}',
      hint: copy.choose(
        'Includes total cost, meal coverage, and basket items.',
        'Incluye costo total, cobertura de comidas y articulos de la canasta.',
      ),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stacked = constraints.maxWidth < 320 || textScale > 1.15;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(plan.summary),
                  ],
                );
                final price = Text(
                  '\$${plan.totalCost.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [details, const SizedBox(height: 12), price],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    price,
                  ],
                );
              },
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
            if (plan.estimatedMealsCovered > 1 ||
                plan.pantrySupportItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (plan.estimatedMealsCovered > 1)
                Text(
                  copy.choose(
                    'Covers about ${plan.estimatedMealsCovered} meals from one trip.',
                    'Cubre unas ${plan.estimatedMealsCovered} comidas en un solo viaje.',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              if (plan.pantrySupportItems.isNotEmpty) ...[
                if (plan.estimatedMealsCovered > 1) const SizedBox(height: 6),
                Text(
                  copy.choose(
                    'Uses from home: ${plan.pantrySupportItems.take(3).join(' + ')}',
                    'Usa de casa: ${plan.pantrySupportItems.take(3).join(' + ')}',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
            const SizedBox(height: 14),
            for (final item in plan.items) ...[
              _BasketItemLine(item: item),
              if (item != plan.items.last) const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            Text(
              copy.choose(
                '${plan.totalNutrients.caloriesKcal.toStringAsFixed(0)} kcal | ${plan.totalNutrients.proteinG.toStringAsFixed(0)}g protein | ${plan.totalNutrients.fiberG.toStringAsFixed(0)}g fiber',
                '${plan.totalNutrients.caloriesKcal.toStringAsFixed(0)} kcal | ${plan.totalNutrients.proteinG.toStringAsFixed(0)}g de proteina | ${plan.totalNutrients.fiberG.toStringAsFixed(0)}g de fibra',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onTrack != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onTrack,
                child: Text(copy.choose('Log basket', 'Registrar canasta')),
              ),
            ],
          ],
        ),
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
