import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import 'section_card.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({
    super.key,
    required this.plan,
    this.language = UserLanguage.english,
  });

  final TodayPlan plan;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(language);
    final contextRows = _contextRows(copy);
    return Semantics(
      container: true,
      label: '${plan.title}. ${plan.summary}',
      hint: copy.choose(
        'Includes what to do now, what to buy first, and what to do next.',
        'Incluye que hacer ahora, que comprar primero y que hacer despues.',
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
                  plan.basket != null
                      ? '\$${plan.basket!.totalCost.toStringAsFixed(2)}'
                      : '\$${plan.leadRecommendation.food.costEstimate.toStringAsFixed(2)}',
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
            if (contextRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var index = 0; index < contextRows.length; index++) ...[
                _ContextLine(
                  label: contextRows[index].label,
                  value: contextRows[index].value,
                ),
                if (index < contextRows.length - 1) const SizedBox(height: 8),
              ],
            ],
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
            if (plan.restockItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                copy.todayPlanRestockSoonLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.restockItems
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
            if (plan.checkpoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                copy.todayPlanNextMealsLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < plan.checkpoints.length; index++) ...[
                _CheckpointLine(checkpoint: plan.checkpoints[index]),
                if (index < plan.checkpoints.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
            if (plan.purchases.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PurchaseSection(
                title: copy.todayPlanBuyFirstLabel,
                items: plan.purchases
                    .where(
                      (item) =>
                          item.priority == PlannedPurchasePriority.buyFirst,
                    )
                    .toList(growable: false),
              ),
              _PurchaseSection(
                title: copy.todayPlanIfMoneyLeftLabel,
                items: plan.purchases
                    .where(
                      (item) =>
                          item.priority == PlannedPurchasePriority.ifBudgetLeft,
                    )
                    .toList(growable: false),
              ),
              _PurchaseSection(
                title: copy.todayPlanSkipTightBudgetLabel,
                items: plan.purchases
                    .where(
                      (item) =>
                          item.priority == PlannedPurchasePriority.skipFirst,
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 14),
            for (final step in plan.steps) ...[
              _StepLine(text: step),
              if (step != plan.steps.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            _LeadRow(plan: plan, copy: copy),
            if (plan.backupAction?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                plan.backupAction!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_ContextRowData> _contextRows(AppCopy copy) {
    return [
      if (plan.routeReason?.trim().isNotEmpty == true)
        _ContextRowData(
          copy.choose('Why this route', 'Por que esta ruta'),
          plan.routeReason!,
        ),
      if (plan.benefitSummary?.trim().isNotEmpty == true)
        _ContextRowData(
          copy.choose('Benefits fit', 'Ajuste con beneficios'),
          plan.benefitSummary!,
        ),
      if (plan.confidenceSummary?.trim().isNotEmpty == true)
        _ContextRowData(
          copy.choose('Access confidence', 'Confianza de acceso'),
          plan.confidenceSummary!,
        ),
      if (plan.dataSourceSummary?.trim().isNotEmpty == true)
        _ContextRowData(
          copy.choose('Data used', 'Datos usados'),
          plan.dataSourceSummary!,
        ),
    ];
  }
}

class _ContextRowData {
  const _ContextRowData(this.label, this.value);

  final String label;
  final String value;
}

class _PurchaseSection extends StatelessWidget {
  const _PurchaseSection({required this.title, required this.items});

  final String title;
  final List<PlannedPurchase> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < items.length; index++) ...[
            _PurchaseLine(item: items[index]),
            if (index < items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PurchaseLine extends StatelessWidget {
  const _PurchaseLine({required this.item});

  final PlannedPurchase item;

  @override
  Widget build(BuildContext context) {
    final costText = item.estimatedCost == null
        ? null
        : '\$${item.estimatedCost!.toStringAsFixed(2)}';
    final detailParts = <String>[
      ?costText,
      if (item.detail?.isNotEmpty == true) item.detail!,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label),
              if (detailParts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detailParts.join(' | '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckpointLine extends StatelessWidget {
  const _CheckpointLine({required this.checkpoint});

  final PlanCheckpoint checkpoint;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 280 || textScale > 1.15;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                checkpoint.title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                checkpoint.detail,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                checkpoint.title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                checkpoint.detail,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.plan, required this.copy});

  final TodayPlan plan;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final title = plan.basket != null
        ? copy.todayPlanBuiltAroundLabel
        : copy.todayPlanLeadOptionLabel;
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

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: theme.textTheme.bodyMedium),
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
