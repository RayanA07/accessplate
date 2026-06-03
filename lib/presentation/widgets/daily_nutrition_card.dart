import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/engine/government_nutrition_guidance.dart';
import '../../domain/entities/user_profile.dart';
import '../copy/app_copy.dart';
import '../providers/app_bootstrap.dart';
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
    final referenceTablesAsync = ref.watch(referenceTablesProvider);

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.choose('Daily tracking', 'Seguimiento diario'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
          Text(
            copy.choose(
              'Tracks what you have logged today against your daily nutrition targets.',
              'Sigue lo que has registrado hoy contra tus metas diarias.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          referenceTablesAsync.when(
            data: (tables) {
              final micros = _guidance.prioritizedMicronutrients(
                demographics: profile.constraints.demographics,
                dietaryStyle: profile.constraints.preference.dietaryStyle,
                rdaTable: tables.rdaTable,
                microPriorityElevations: tables.microPriorityElevations,
              );
              if (micros.isEmpty) {
                return const SizedBox.shrink();
              }

              return ExpansionTile(
                title: Text(
                  copy.choose(
                    'Priority micronutrients',
                    'Micronutrientes prioritarios',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                children: [
                  const SizedBox(height: 8),
                  for (final entry in micros.entries) ...[
                    _MicroLine(
                      label: _micronutrientLabel(copy, entry.key),
                      current: todayIntake[entry.key] ?? 0,
                      target: entry.value,
                      unit: entry.key.contains('_mcg') ? 'mcg' : 'mg',
                    ),
                    if (entry.key != micros.keys.last)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                copy.choose(
                  'Loading micronutrient targets...',
                  'Cargando metas de micronutrientes...',
                ),
              ),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: controller.resetDailyTracking,
              child: Text(copy.choose('Reset today', 'Reiniciar hoy')),
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

  String _micronutrientLabel(AppCopy copy, String key) {
    return switch (key) {
      'iron_mg' => copy.choose('Iron', 'Hierro'),
      'calcium_mg' => copy.choose('Calcium', 'Calcio'),
      'potassium_mg' => copy.choose('Potassium', 'Potasio'),
      'magnesium_mg' => copy.choose('Magnesium', 'Magnesio'),
      'zinc_mg' => copy.choose('Zinc', 'Zinc'),
      'vit_a_mcg_rae' => copy.choose('Vitamin A', 'Vitamina A'),
      'vit_c_mg' => copy.choose('Vitamin C', 'Vitamina C'),
      'vit_d_mcg' => copy.choose('Vitamin D', 'Vitamina D'),
      'vit_b12_mcg' => copy.choose('Vitamin B12', 'Vitamina B12'),
      'folate_mcg_dfe' => copy.choose('Folate', 'Folato'),
      _ => key,
    };
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
                    backgroundColor: const Color(0xFFE9E9EE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1E1E22),
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
                        fontWeight: FontWeight.w600,
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF0F0F4)),
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

class _MicroLine extends StatelessWidget {
  const _MicroLine({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  final String label;
  final double current;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D31),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress, minHeight: 7),
      ],
    );
  }
}
