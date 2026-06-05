import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/medical_restriction.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingMedicalStep extends ConsumerWidget {
  const OnboardingMedicalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final safety = profile.constraints.safety;
    final copy = AppCopy(profile.constraints.access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.choose('Medical\nrestrictions', 'Restricciones\nmedicas'),
      subtitle: copy.choose(
        'Use Avoid for hard exclusions and Limit when something should count against the score.',
        'Usa Evitar para exclusiones fuertes y Limitar cuando algo solo debe contar en contra.',
      ),
      children: [
        for (final restriction in MedicalRestriction.values) ...[
          _RestrictionCard(
            copy: copy,
            restriction: restriction,
            currentMode: safety.medicalAvoid.contains(restriction)
                ? _RestrictionMode.avoid
                : safety.medicalLimit.contains(restriction)
                ? _RestrictionMode.limit
                : _RestrictionMode.off,
            onSelected: (mode) {
              controller.updateSafety(
                _applyRestrictionMode(
                  safety: safety,
                  restriction: restriction,
                  mode: mode,
                ),
              );
            },
          ),
          if (restriction != MedicalRestriction.values.last)
            const SizedBox(height: 14),
        ],
      ],
    );
  }

  SafetyConstraints _applyRestrictionMode({
    required SafetyConstraints safety,
    required MedicalRestriction restriction,
    required _RestrictionMode mode,
  }) {
    final avoid = {...safety.medicalAvoid}..remove(restriction);
    final limit = {...safety.medicalLimit}..remove(restriction);

    if (mode == _RestrictionMode.avoid) {
      avoid.add(restriction);
    } else if (mode == _RestrictionMode.limit) {
      limit.add(restriction);
    }

    return safety.copyWith(medicalAvoid: avoid, medicalLimit: limit);
  }
}

class _RestrictionCard extends StatelessWidget {
  const _RestrictionCard({
    required this.copy,
    required this.restriction,
    required this.currentMode,
    required this.onSelected,
  });

  final AppCopy copy;
  final MedicalRestriction restriction;
  final _RestrictionMode currentMode;
  final ValueChanged<_RestrictionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: ValueKey('medical-card-${restriction.code}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.medicalRestrictionLabel(restriction),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF232326),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.medicalRestrictionDetail(restriction),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8F8F95),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          OnboardingSegmentedControl<_RestrictionMode>(
            value: currentMode,
            options: _RestrictionMode.values,
            labelBuilder: (mode) => _modeLabel(mode),
            onChanged: onSelected,
            minOptionHeight: 40,
          ),
        ],
      ),
    );
  }

  String _modeLabel(_RestrictionMode mode) {
    switch (mode) {
      case _RestrictionMode.off:
        return copy.choose('Off', 'Apagado');
      case _RestrictionMode.limit:
        return copy.choose('Limit', 'Limitar');
      case _RestrictionMode.avoid:
        return copy.choose('Avoid', 'Evitar');
    }
  }
}

enum _RestrictionMode { off, limit, avoid }
