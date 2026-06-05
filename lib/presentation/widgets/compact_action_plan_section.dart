import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/recommendation.dart';
import '../copy/app_copy.dart';
import 'section_card.dart';

class CompactActionPlanSection extends StatelessWidget {
  const CompactActionPlanSection({
    super.key,
    required this.copy,
    required this.todayPlan,
    required this.sourceTripPlan,
    required this.emergencyMode,
  });

  final AppCopy copy;
  final TodayPlan? todayPlan;
  final SourceTripPlan? sourceTripPlan;
  final bool emergencyMode;

  @override
  Widget build(BuildContext context) {
    if (todayPlan == null && sourceTripPlan == null) {
      return const SizedBox.shrink();
    }

    final plan = todayPlan;
    final trip = sourceTripPlan;
    final buyFirst = _purchaseLabels(
      plan,
      PlannedPurchasePriority.buyFirst,
      fallback: copy.actionPlanNoPurchaseYet,
    );
    final skipFirst = _purchaseLabels(
      plan,
      PlannedPurchasePriority.skipFirst,
      fallback: copy.actionPlanNoSkipYet,
    );
    final buyItems = _purchaseItemList(plan, PlannedPurchasePriority.buyFirst);
    final skipItems = _purchaseItemList(
      plan,
      PlannedPurchasePriority.skipFirst,
    );
    final skipItem = skipItems.isEmpty ? null : skipItems.first;
    final bestStop =
        _bestStopDetail(trip?.title) ??
        plan?.title ??
        copy.choose('your nearest stop', 'tu parada mas cercana');
    final detailRows = _detailRows(plan, trip, buyFirst, skipFirst);

    return Semantics(
      container: true,
      label: emergencyMode
          ? copy.actionPlanDoThisNowTitle
          : copy.actionPlanDoThisFirstTitle,
      child: SectionCard(
        tintColor: emergencyMode
            ? NihPalette.warning.withValues(alpha: 0.16)
            : NihPalette.primaryAltLight,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        borderRadius: 26,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: NihPalette.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
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
                              emergencyMode
                                  ? copy.actionPlanDoThisNowTitle
                                  : copy.actionPlanDoThisFirstTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              emergencyMode
                                  ? copy.actionPlanEmergencyHint
                                  : copy.actionPlanDefaultHint,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (emergencyMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NihPalette.warning.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            copy.emergencyModeTitle,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: NihPalette.primaryDarkest,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${copy.actionPlanBestStopLabel}: $bestStop',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanChipsRow(
                    label: copy.actionPlanBuyLabel,
                    items: buyItems,
                    emptyText: copy.actionPlanNoPurchaseYet,
                  ),
                  if (skipItem != null) ...[
                    const SizedBox(height: 10),
                    _PlanSkipRow(
                      label: copy.actionPlanSkipLabel,
                      item: skipItem,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (detailRows.isNotEmpty)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          copy.actionPlanDetailsTitle,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        children: detailRows,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _bestStopDetail(String? rawValue) {
    if (rawValue == null) {
      return null;
    }
    final cleaned = rawValue
        .replaceFirst(
          RegExp(
            r'^\s*(best first stop|mejor primera parada):\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String _purchaseLabels(
    TodayPlan? plan,
    PlannedPurchasePriority priority, {
    required String fallback,
  }) {
    final matches = _purchaseItemList(plan, priority).take(2).toList();
    if (matches.isEmpty) {
      return fallback;
    }
    return matches.join(' | ');
  }

  List<String> _purchaseItemList(
    TodayPlan? plan,
    PlannedPurchasePriority priority,
  ) {
    return plan?.purchases
            .where((item) => item.priority == priority)
            .map((item) => item.label)
            .toList(growable: false) ??
        const <String>[];
  }

  List<Widget> _detailRows(
    TodayPlan? plan,
    SourceTripPlan? trip,
    String buyFirst,
    String skipFirst,
  ) {
    final rows = <Widget>[];

    if (plan?.summary.trim().isNotEmpty == true) {
      rows.add(_DetailBlock(title: copy.todayPlanTitle, body: plan!.summary));
    }
    if (trip?.summary.trim().isNotEmpty == true) {
      rows.add(_DetailBlock(title: copy.sourceTripTitle, body: trip!.summary));
    }
    if (trip?.routeReason?.trim().isNotEmpty == true) {
      rows.add(
        _DetailBlock(
          title: copy.choose('Why this stop', 'Por que esta parada'),
          body: trip!.routeReason!,
        ),
      );
    }
    if (buyFirst != copy.actionPlanNoPurchaseYet) {
      rows.add(
        _DetailBlock(title: copy.actionPlanBuyFirstLabel, body: buyFirst),
      );
    }
    if (skipFirst != copy.actionPlanNoSkipYet) {
      rows.add(
        _DetailBlock(title: copy.actionPlanSkipFirstLabel, body: skipFirst),
      );
    }

    return rows;
  }
}

class _PlanChipsRow extends StatelessWidget {
  const _PlanChipsRow({
    required this.label,
    required this.items,
    required this.emptyText,
  });

  final String label;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: NihPalette.grayDark,
          ),
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(
            emptyText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: NihPalette.grayDark,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final item in items) _ActionChip(label: item)],
          ),
      ],
    );
  }
}

class _PlanSkipRow extends StatelessWidget {
  const _PlanSkipRow({required this.label, required this.item});

  final String label;
  final String item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: NihPalette.grayDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: NihPalette.grayDark,
            decoration: TextDecoration.lineThrough,
            decorationColor: NihPalette.grayDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NihPalette.warmSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NihPalette.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
