import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/engine/government_nutrition_guidance.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/daily_nutrition_card.dart';
import '../../widgets/home_tab_header.dart';
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
            HomeTabHeader(
              eyebrow: copy.choose('Live tracker', 'Seguimiento en vivo'),
              title: copy.choose('Daily progress', 'Progreso diario'),
              subtitle: copy.choose(
                'This chart updates when you log meals so you can see what is left before the day is done.',
                'Este grafico cambia cuando registras comidas para que veas lo que falta antes de terminar el dia.',
              ),
              icon: Icons.donut_large_rounded,
              tintColor: NihPalette.success,
            ),
            const SizedBox(height: 14),
            DailyNutritionCard(profile: profile),
            const SizedBox(height: 14),
            SectionCard(
              tintColor: NihPalette.secondaryLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.choose('Per-meal target', 'Meta por comida'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.choose(
                      'The recommendation list uses these meal targets when it ranks what to show you next.',
                      'La lista de recomendaciones usa estas metas por comida para decidir que mostrarte despues.',
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
                    label: copy.choose('Fiber', 'Fibra'),
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
                    copy.choose('Daily target reference', 'Referencia diaria'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.choose(
                      'Use this as the full-day goal while you log meals from the recommendations tab.',
                      'Usa esto como tu meta del dia mientras registras comidas desde la pantalla de recomendaciones.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _TargetSummaryLine(
                    label: copy.caloriesLabel,
                    value: '${dailyTargets.calories.toStringAsFixed(0)} kcal',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.proteinLabel,
                    value: '${dailyTargets.proteinG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.carbsLabel,
                    value: '${dailyTargets.carbsG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.fatLabel,
                    value: '${dailyTargets.fatG.toStringAsFixed(0)} g',
                  ),
                  const SizedBox(height: 10),
                  _TargetSummaryLine(
                    label: copy.choose('Fiber', 'Fibra'),
                    value: '${dailyTargets.fiberG.toStringAsFixed(0)} g',
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
