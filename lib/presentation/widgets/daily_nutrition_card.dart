import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final todayTargets = _guidance.dailyTargetsFor(profile.constraints.demographics);
    final todayIntake = _effectiveIntake(profile);
    final controller = ref.read(profileControllerProvider.notifier);
    final referenceTablesAsync = ref.watch(referenceTablesProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.choose('Daily tracking', 'Seguimiento diario'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            copy.choose(
              'Based on USDA DRI energy guidance plus FDA-style daily limits. Log a meal below to update this.',
              'Basado en guias DRI del USDA y limites diarios tipo FDA. Registra una comida abajo para actualizar esto.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _ProgressLine(
            label: copy.caloriesLabel,
            current: todayIntake['calories_kcal'] ?? 0,
            target: todayTargets.calories,
            unit: 'kcal',
          ),
          _ProgressLine(
            label: copy.proteinLabel,
            current: todayIntake['protein_g'] ?? 0,
            target: todayTargets.proteinG,
            unit: 'g',
          ),
          _ProgressLine(
            label: copy.carbsLabel,
            current: todayIntake['carbs_g'] ?? 0,
            target: todayTargets.carbsG,
            unit: 'g',
          ),
          _ProgressLine(
            label: copy.fatLabel,
            current: todayIntake['fat_g'] ?? 0,
            target: todayTargets.fatG,
            unit: 'g',
          ),
          _ProgressLine(
            label: copy.choose('Fiber', 'Fibra'),
            current: todayIntake['fiber_g'] ?? 0,
            target: todayTargets.fiberG,
            unit: 'g',
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
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  copy.choose(
                    'Priority micronutrients',
                    'Micronutrientes prioritarios',
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  for (final entry in micros.entries)
                    _ProgressLine(
                      label: _micronutrientLabel(copy, entry.key),
                      current: todayIntake[entry.key] ?? 0,
                      target: entry.value,
                      unit: entry.key.contains('_mcg') ? 'mcg' : 'mg',
                    ),
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

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
