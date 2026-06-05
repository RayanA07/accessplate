import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/engine/government_nutrition_guidance.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../core/theme/app_palette.dart';
import '../../copy/app_copy.dart';
import '../../providers/app_bootstrap.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingTargetsStep extends ConsumerWidget {
  const OnboardingTargetsStep({super.key});

  static const _guidance = GovernmentNutritionGuidance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final daily = _guidance.dailyTargetsFor(profile.constraints.demographics);
    final meal = _guidance.mealTargetsFor(
      demographics: profile.constraints.demographics,
      mealType: profile.constraints.preference.mealType,
    );
    final referenceTablesAsync = ref.watch(referenceTablesProvider);

    return OnboardingStepLayout(
      title: copy.choose(
        'Daily nutrition targets',
        'Metas diarias de nutricion',
      ),
      subtitle: copy.choose(
        'These targets are derived from U.S. DRI and FDA guidance. AccessPlate still uses meal-sized targets for recommendations, but daily tracking follows these daily totals.',
        'Estas metas salen de guias DRI y FDA de EE. UU. AccessPlate sigue usando metas por comida para recomendar, pero el seguimiento diario usa estos totales diarios.',
      ),
      children: [
        SectionCard(
          key: const ValueKey('targets-summary-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose('Daily targets', 'Metas diarias'),
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                label: copy.choose('Calories', 'Calorias'),
                value: '${daily.calories.toStringAsFixed(0)} kcal',
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: copy.proteinLabel,
                value: '${daily.proteinG.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: copy.carbsLabel,
                value: '${daily.carbsG.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                label: copy.fatLabel,
                value: '${daily.fatG.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: copy.choose('Fiber', 'Fibra'),
                value: '${daily.fiberG.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 14),
              Text(
                copy.choose(
                  'Current meal target for ${copy.mealTimingLabel(profile.constraints.preference.mealType).toLowerCase()}: ${meal.calories.toStringAsFixed(0)} kcal | ${meal.proteinG.toStringAsFixed(0)}g protein | ${meal.fiberG.toStringAsFixed(0)}g fiber',
                  'Meta actual para ${copy.mealTimingLabel(profile.constraints.preference.mealType).toLowerCase()}: ${meal.calories.toStringAsFixed(0)} kcal | ${meal.proteinG.toStringAsFixed(0)}g proteina | ${meal.fiberG.toStringAsFixed(0)}g fibra',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(key: ValueKey('targets-limits-divider'), height: 1),
        ),
        const SizedBox(height: 14),
        SectionCard(
          key: const ValueKey('limits-summary-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(
                copy.choose(
                  'Daily limits to watch',
                  'Limites diarios a cuidar',
                ),
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                icon: Icons.warning_amber_rounded,
                label: copy.choose('Saturated fat', 'Grasa saturada'),
                value: '${daily.saturatedFatLimitG.toStringAsFixed(0)}g',
                iconColor: NihPalette.warning,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: Icons.warning_amber_rounded,
                label: copy.choose('Added sugars', 'Azucares agregados'),
                value: '${daily.addedSugarLimitG.toStringAsFixed(0)}g',
                iconColor: NihPalette.warning,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: Icons.warning_amber_rounded,
                label: copy.choose('Sodium', 'Sodio'),
                value: '${daily.sodiumLimitMg.toStringAsFixed(0)}mg',
                iconColor: NihPalette.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        referenceTablesAsync.when(
          data: (tables) {
            final prioritizedMicros = _guidance.prioritizedMicronutrients(
              demographics: profile.constraints.demographics,
              dietaryStyle: profile.constraints.preference.dietaryStyle,
              rdaTable: tables.rdaTable,
              microPriorityElevations: tables.microPriorityElevations,
            );
            if (prioritizedMicros.isEmpty) {
              return Container(
                key: const ValueKey('micronutrient-note'),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  copy.choose(
                    'No extra micronutrient watchlist is turned on yet. If you mark anemia, pregnancy, bone density, or a plant-based pattern, AccessPlate will track the most relevant nutrients.',
                    'Todavia no hay una lista extra de micronutrientes. Si marcas anemia, embarazo, salud osea o una alimentacion basada en plantas, AccessPlate seguira los nutrientes mas relevantes.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: NihPalette.base,
                  ),
                ),
              );
            }

            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingMetaLabel(
                    copy.choose(
                      'Priority micronutrients',
                      'Micronutrientes prioritarios',
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in prioritizedMicros.entries) ...[
                    _SummaryRow(
                      label: _micronutrientLabel(copy, entry.key),
                      value: _formatMicroValue(entry.key, entry.value),
                    ),
                    if (entry.key != prioritizedMicros.keys.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          },
          loading: () => SectionCard(
            child: Text(
              copy.choose(
                'Loading micronutrient targets...',
                'Cargando metas de micronutrientes...',
              ),
            ),
          ),
          error: (error, stackTrace) => SectionCard(
            child: Text(
              copy.choose(
                'Micronutrient targets could not load right now.',
                'Las metas de micronutrientes no se pudieron cargar ahora.',
              ),
            ),
          ),
        ),
      ],
    );
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

  String _formatMicroValue(String key, double value) {
    if (key.contains('_mcg')) {
      return '${value.toStringAsFixed(0)} mcg';
    }
    return '${value.toStringAsFixed(0)} mg';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor ?? NihPalette.grayDark),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: NihPalette.base,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: NihPalette.base,
          ),
        ),
      ],
    );
  }
}
