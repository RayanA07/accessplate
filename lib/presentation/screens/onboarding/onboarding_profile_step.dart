import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/demographics.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingProfileStep extends ConsumerWidget {
  const OnboardingProfileStep({super.key});

  static const visibleConcerns = <HealthConcern>[
    HealthConcern.anemia,
    HealthConcern.pregnancy,
    HealthConcern.lactating,
    HealthConcern.boneDensity,
    HealthConcern.hypertension,
    HealthConcern.postoperative,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final demographics = profile.constraints.demographics;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(profile.constraints.access.language);

    return OnboardingStepLayout(
      title: copy.choose('A few more\ndetails', 'Algunos detalles\nmas'),
      subtitle: copy.choose(
        'We use these to personalize daily targets and nutrient priorities.',
        'Usamos esto para personalizar metas diarias y prioridades de nutrientes.',
      ),
      topSpacing: 38,
      children: [
        _DetailSection(
          label: copy.profileSexLabel,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: Sex.values.map((sex) {
              final selected = demographics.sex == sex;
              return _ChoicePill(
                selected: selected,
                label: copy.sexLabel(sex),
                onTap: () {
                  controller.updateDemographics(
                    demographics.copyWith(sex: sex),
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          label: copy.choose('Activity level', 'Nivel de actividad'),
          helper: copy.choose(
            'Pick the closest fit for most weeks.',
            'Elige la opcion mas cercana para la mayoria de tus semanas.',
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ActivityLevel.values.map((level) {
              final selected = demographics.activityLevel == level;
              return _ChoicePill(
                selected: selected,
                label: _activityLabel(copy, level),
                onTap: () {
                  controller.updateDemographics(
                    demographics.copyWith(activityLevel: level),
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          label: copy.healthPrioritiesLabel,
          helper: copy.choose(
            'Only select concerns that really apply right now.',
            'Solo selecciona prioridades que de verdad apliquen ahora.',
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleConcerns.map((concern) {
              final selected = demographics.concerns.contains(concern);
              return _ChoicePill(
                selected: selected,
                label: copy.healthConcernLabel(concern),
                onTap: () {
                  final next = {...demographics.concerns};
                  selected ? next.remove(concern) : next.add(concern);
                  controller.updateDemographics(
                    demographics.copyWith(concerns: next),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _activityLabel(AppCopy copy, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => copy.choose('Inactive', 'Inactiva'),
      ActivityLevel.light => copy.choose('Low active', 'Poco activa'),
      ActivityLevel.moderate => copy.choose('Active', 'Activa'),
      ActivityLevel.active => copy.choose('High active', 'Muy activa'),
      ActivityLevel.veryActive => copy.choose(
        'Very active',
        'Actividad muy alta',
      ),
    };
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.child, this.helper});

  final String label;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 30,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingMetaLabel(label),
          if (helper != null) ...[
            const SizedBox(height: 8),
            Text(helper!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fillColor = selected
        ? NihPalette.primary
        : Theme.of(context).colorScheme.surface;
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: fillColor,
            border: Border.all(
              color: selected ? NihPalette.primary : NihPalette.borderSoft,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : NihPalette.base,
            ),
          ),
        ),
      ),
    );
  }
}
