import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/engine/government_nutrition_guidance.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/section_card.dart';

class MacroTargetsScreen extends ConsumerWidget {
  const MacroTargetsScreen({super.key});

  static const _guidance = GovernmentNutritionGuidance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final mealTargets = profile.constraints.targets;
    final dailyTargets = _guidance.dailyTargetsFor(
      profile.constraints.demographics,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NihPalette.lightContentBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Text(
              copy.choose('Macro targets', 'Metas de macros'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              copy.choose(
                'These are the nutrition targets your current recommendation scoring is using.',
                'Estas son las metas nutricionales que esta usando tu puntaje actual de recomendaciones.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SectionCard(
              tintColor: NihPalette.secondaryLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Current meal target', 'Meta de esta comida'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.choose(
                      'These are the per-meal targets driving the recommendation ranking right now.',
                      'Estas son las metas por comida que estan guiando el ranking de recomendaciones ahora.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _TargetSummaryLine(
                    label: copy.caloriesLabel,
                    value: '${mealTargets.calories.toStringAsFixed(0)} kcal',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.proteinLabel,
                    value: '${mealTargets.proteinG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.carbsLabel,
                    value: '${mealTargets.carbsG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.fatLabel,
                    value: '${mealTargets.fatG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.fiberTargetLabel,
                    value: '${mealTargets.fiberG.toStringAsFixed(0)} g',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Daily target', 'Meta diaria'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final macroColumn = Column(
                        children: [
                          _MacroLegendRow(
                            color: NihPalette.macroProtein,
                            label: copy.proteinLabel,
                            value:
                                '${dailyTargets.proteinG.toStringAsFixed(0)}g',
                          ),
                          const SizedBox(height: 10),
                          _MacroLegendRow(
                            color: NihPalette.macroCarbs,
                            label: copy.carbsLabel,
                            value: '${dailyTargets.carbsG.toStringAsFixed(0)}g',
                          ),
                          const SizedBox(height: 10),
                          _MacroLegendRow(
                            color: NihPalette.macroFat,
                            label: copy.fatLabel,
                            value: '${dailyTargets.fatG.toStringAsFixed(0)}g',
                          ),
                          const SizedBox(height: 10),
                          _MacroLegendRow(
                            color: NihPalette.secondary,
                            label: copy.choose('Fiber', 'Fibra'),
                            value: '${dailyTargets.fiberG.toStringAsFixed(0)}g',
                          ),
                        ],
                      );

                      if (constraints.maxWidth < 360) {
                        return Column(
                          children: [
                            _DailyCaloriesRing(calories: dailyTargets.calories),
                            const SizedBox(height: 18),
                            macroColumn,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DailyCaloriesRing(calories: dailyTargets.calories),
                          const SizedBox(width: 18),
                          Expanded(child: macroColumn),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Daily limits', 'Limites diarios'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TargetSummaryLine(
                    label: copy.choose('Saturated fat', 'Grasa saturada'),
                    value:
                        '${dailyTargets.saturatedFatLimitG.toStringAsFixed(0)} g max',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.choose('Added sugar', 'Azucar agregada'),
                    value:
                        '${dailyTargets.addedSugarLimitG.toStringAsFixed(0)} g max',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.choose('Sodium', 'Sodio'),
                    value:
                        '${dailyTargets.sodiumLimitMg.toStringAsFixed(0)} mg max',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.choose(
                      'These targets update automatically when your profile, activity level, or meal timing changes.',
                      'Estas metas cambian automaticamente cuando cambia tu perfil, actividad o momento de comida.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCaloriesRing extends StatelessWidget {
  const _DailyCaloriesRing({required this.calories});

  final double calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF232328), width: 6),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatCalories(calories),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'kcal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCalories(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _MacroLegendRow extends StatelessWidget {
  const _MacroLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _TargetSummaryLine extends StatelessWidget {
  const _TargetSummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
