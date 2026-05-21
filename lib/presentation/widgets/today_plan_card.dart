import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import 'section_card.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key, required this.plan});

  final TodayPlan plan;

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
              if (plan.basket != null)
                Text(
                  '\$${plan.basket!.totalCost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Text(
                  '\$${plan.leadRecommendation.food.costEstimate.toStringAsFixed(2)}',
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
          for (final step in plan.steps) ...[
            _StepLine(text: step),
            if (step != plan.steps.last) const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          _LeadRow(plan: plan),
          if (plan.backupAction?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              plan.backupAction!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.plan});

  final TodayPlan plan;

  @override
  Widget build(BuildContext context) {
    final title = plan.basket != null ? 'Built around' : 'Lead option';
    final itemNames = plan.basket != null
        ? plan.basket!.items.map((item) => item.food.name).join(' | ')
        : plan.leadRecommendation.food.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(itemNames, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
