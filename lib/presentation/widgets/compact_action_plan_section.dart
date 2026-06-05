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
    final backup = _backupLabel(plan, trip);
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        borderRadius: 26,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: NihPalette.primaryDarkest,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _CompactActionRow(
              label: copy.actionPlanGoFirstLabel,
              value: trip?.title ?? plan?.title ?? copy.actionPlanNoBackupYet,
            ),
            const SizedBox(height: 6),
            _CompactActionRow(
              label: copy.actionPlanUseFromHomeLabel,
              value: _homeFact(plan),
            ),
            const SizedBox(height: 6),
            _CompactActionRow(
              label: copy.actionPlanBuyFirstLabel,
              value: buyFirst,
            ),
            const SizedBox(height: 6),
            _CompactActionRow(
              label: copy.actionPlanSkipFirstLabel,
              value: skipFirst,
            ),
            const SizedBox(height: 6),
            _CompactActionRow(
              label: copy.actionPlanBackupLabel,
              value: backup,
            ),
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
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: detailRows,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _homeFact(TodayPlan? plan) {
    final facts = plan?.leadRecommendation.explanation?.decisionFacts;
    if (facts != null) {
      final match = facts.where(
        (fact) => fact.label == copy.choose('From home', 'Desde casa'),
      );
      if (match.isNotEmpty) {
        return match.first.value;
      }
    }

    for (final step in plan?.steps ?? const <String>[]) {
      final lowered = step.toLowerCase();
      if (lowered.contains('home') || lowered.contains('casa')) {
        return step;
      }
    }
    return copy.actionPlanNoPantryStep;
  }

  String _purchaseLabels(
    TodayPlan? plan,
    PlannedPurchasePriority priority, {
    required String fallback,
  }) {
    final matches =
        plan?.purchases
            .where((item) => item.priority == priority)
            .take(2)
            .map((item) => item.label)
            .toList(growable: false) ??
        const <String>[];
    if (matches.isEmpty) {
      return fallback;
    }
    return matches.join(' | ');
  }

  String _backupLabel(TodayPlan? plan, SourceTripPlan? trip) {
    final backupAction = plan?.backupAction?.trim();
    if (backupAction != null && backupAction.isNotEmpty) {
      return backupAction;
    }
    if (trip?.backupSource != null) {
      return copy.sourceTripBackupStop(copy.sourceLabel(trip!.backupSource!));
    }
    return copy.actionPlanNoBackupYet;
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
      rows.add(
        _DetailBlock(title: copy.sourceTripTitle, body: trip!.summary),
      );
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

class _CompactActionRow extends StatelessWidget {
  const _CompactActionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: NihPalette.grayDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
