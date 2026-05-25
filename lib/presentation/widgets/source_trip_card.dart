import 'package:flutter/material.dart';

import '../../domain/entities/recommendation.dart';
import '../../domain/value_objects/user_language.dart';
import '../copy/app_copy.dart';
import 'section_card.dart';

class SourceTripCard extends StatelessWidget {
  const SourceTripCard({
    super.key,
    required this.plan,
    this.language = UserLanguage.english,
  });

  final SourceTripPlan plan;
  final UserLanguage language;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(language);
    final contextRows = _contextRows(copy);
    return Semantics(
      container: true,
      label: '${plan.title}. ${plan.summary}',
      hint: plan.backupSource == null
          ? copy.choose(
              'Includes the main reasons for this first stop.',
              'Incluye las razones principales para esta primera parada.',
            )
          : copy.choose(
              'Includes the main reasons and a backup stop.',
              'Incluye las razones principales y una parada de respaldo.',
            ),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                plan.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(plan.summary),
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
            if (plan.bestFor.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                copy.sourceTripBestForLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.bestFor
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
            if (plan.reasons.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final reason in plan.reasons) ...[
                _ReasonLine(text: reason),
                if (reason != plan.reasons.last) const SizedBox(height: 8),
              ],
            ],
            if (plan.backupSource != null) ...[
              const SizedBox(height: 12),
              Text(
                copy.sourceTripBackupStop(copy.sourceLabel(plan.backupSource!)),
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
          copy.choose('Why this stop', 'Por que esta parada'),
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

class _ReasonLine extends StatelessWidget {
  const _ReasonLine({required this.text});

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
