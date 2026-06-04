import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/engine/government_nutrition_guidance.dart';
import '../../domain/entities/user_profile.dart';
import '../copy/app_copy.dart';
import '../providers/profile_controller.dart';
import 'section_card.dart';

class DailyNutritionCard extends ConsumerWidget {
  const DailyNutritionCard({super.key, required this.profile});

  static const _guidance = GovernmentNutritionGuidance();

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = AppCopy(profile.constraints.access.language);
    final todayTargets = _guidance.dailyTargetsFor(
      profile.constraints.demographics,
    );
    final todayIntake = _effectiveIntake(profile);
    final controller = ref.read(profileControllerProvider.notifier);
    final currentCalories = todayIntake['calories_kcal'] ?? 0;
    final caloriesRemaining = (todayTargets.calories - currentCalories).clamp(
      0,
      todayTargets.calories,
    );

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      tintColor: NihPalette.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.choose('Daily tracker', 'Seguimiento diario'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            copy.choose(
              'Log meals from the recommendations tab and this card will update here.',
              'Registra comidas desde recomendaciones y esta tarjeta cambiara aqui.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360;
              final summary = _CalorieRing(
                current: todayIntake['calories_kcal'] ?? 0,
                target: todayTargets.calories,
                label: copy.caloriesLabel,
              );
              final side = _MacroColumn(
                rows: [
                  _MacroRowData(
                    color: NihPalette.macroProtein,
                    label: copy.proteinLabel,
                    current: todayIntake['protein_g'] ?? 0,
                    target: todayTargets.proteinG,
                    unit: 'g',
                  ),
                  _MacroRowData(
                    color: NihPalette.macroCarbs,
                    label: copy.carbsLabel,
                    current: todayIntake['carbs_g'] ?? 0,
                    target: todayTargets.carbsG,
                    unit: 'g',
                  ),
                  _MacroRowData(
                    color: NihPalette.macroFat,
                    label: copy.fatLabel,
                    current: todayIntake['fat_g'] ?? 0,
                    target: todayTargets.fatG,
                    unit: 'g',
                  ),
                  _MacroRowData(
                    color: NihPalette.secondary,
                    label: copy.choose('Fiber', 'Fibra'),
                    current: todayIntake['fiber_g'] ?? 0,
                    target: todayTargets.fiberG,
                    unit: 'g',
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  children: [summary, const SizedBox(height: 18), side],
                );
              }

              return Row(
                children: [
                  summary,
                  const SizedBox(width: 18),
                  Expanded(child: side),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryBadge(
                label: copy.choose('Logged', 'Registrado'),
                value: '${currentCalories.toStringAsFixed(0)} kcal',
              ),
              _SummaryBadge(
                label: copy.choose('Target', 'Meta'),
                value: '${todayTargets.calories.toStringAsFixed(0)} kcal',
              ),
              _SummaryBadge(
                label: copy.choose('Left today', 'Falta hoy'),
                value: '${caloriesRemaining.toStringAsFixed(0)} kcal',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: controller.resetDailyTracking,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(copy.choose('Reset today', 'Reiniciar hoy')),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _effectiveIntake(UserProfile profile) {
    final intakeDate = profile.constraints.todayIntakeDate;
    if (intakeDate == null) {
      return const <String, double>{};
    }
    final now = DateTime.now();
    if (intakeDate.year != now.year ||
        intakeDate.month != now.month ||
        intakeDate.day != now.day) {
      return const <String, double>{};
    }
    return profile.constraints.todayIntake;
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.current,
    required this.target,
    required this.label,
  });

  final double current;
  final double target;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return SizedBox(
      width: 148,
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      NihPalette.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      current.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target ${target.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({required this.rows});

  final List<_MacroRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _MacroRingRow(data: rows[index]),
          if (index < rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MacroRowData {
  const _MacroRowData({
    required this.color,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  final Color color;
  final String label;
  final double current;
  final double target;
  final String unit;
}

class _MacroRingRow extends StatelessWidget {
  const _MacroRingRow({required this.data});

  final _MacroRowData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.target <= 0
        ? 0.0
        : (data.current / data.target).clamp(0.0, 1.0);
    final percentage = data.target <= 0
        ? 0
        : ((data.current / data.target) * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: data.color.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(data.color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.current.toStringAsFixed(0)}${data.unit} / ${data.target.toStringAsFixed(0)}${data.unit} - $percentage%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
