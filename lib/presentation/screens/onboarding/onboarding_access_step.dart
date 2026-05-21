import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/benefit_program.dart';
import '../../../domain/value_objects/transportation_mode.dart';
import '../../../domain/value_objects/user_language.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingAccessStep extends ConsumerStatefulWidget {
  const OnboardingAccessStep({super.key});

  @override
  ConsumerState<OnboardingAccessStep> createState() =>
      _OnboardingAccessStepState();
}

class _OnboardingAccessStepState extends ConsumerState<OnboardingAccessStep> {
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _postalCodeController = TextEditingController(
      text: profile?.constraints.access.postalCode ?? '',
    );
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final access = profile.constraints.access;
    final copy = AppCopy(access.language);
    final controller = ref.read(profileControllerProvider.notifier);

    return OnboardingStepLayout(
      title: copy.accessSetupTitle,
      subtitle: copy.accessSetupSubtitle,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingMetaLabel('ZIP code'),
              const SizedBox(height: 10),
              TextField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '45211',
                  labelText: 'Home or usual shopping ZIP',
                ),
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits != value) {
                    _postalCodeController.value = TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }
                  controller.updatePostalCode(digits);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Used for local grocery lookup and bundled ZIP-based access realism.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingMetaLabel('Transportation'),
              const SizedBox(height: 12),
              for (final mode in TransportationMode.values) ...[
                _InlineChoiceTile(
                  title: mode.label,
                  subtitle: _transportDetail(mode),
                  selected: access.transportation == mode,
                  onTap: () => controller.updateTransportation(mode),
                ),
                if (mode != TransportationMode.values.last)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              OnboardingMetaLabel(
                'Trip time you can usually manage: ${access.maxTravelMinutes} min',
              ),
              Slider(
                min: 5,
                max: 60,
                divisions: 11,
                value: access.maxTravelMinutes.clamp(5, 60).toDouble(),
                onChanged: (value) {
                  controller.updateMaxTravelMinutes(value.round());
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
              const OnboardingMetaLabel('Benefits and mode'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BenefitProgram.values.map((program) {
                  final selected = access.benefitPrograms.contains(program);
                  return FilterChip(
                    selected: selected,
                    label: Text(program.label),
                    onSelected: (value) {
                      final next = {...access.benefitPrograms};
                      value ? next.add(program) : next.remove(program);
                      controller.updateBenefitPrograms(next);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                value: access.emergencyMode,
                contentPadding: EdgeInsets.zero,
                title: const Text('Emergency mode'),
                subtitle: const Text(
                  'Push the engine toward the fastest, cheapest, easiest options when the day is falling apart.',
                ),
                onChanged: controller.updateEmergencyMode,
              ),
              SwitchListTile(
                value: access.plainLanguage,
                contentPadding: EdgeInsets.zero,
                title: const Text('Plain-language explanations'),
                subtitle: const Text(
                  'Keep recommendation reasons short and direct.',
                ),
                onChanged: controller.updatePlainLanguage,
              ),
              const SizedBox(height: 8),
              OnboardingSegmentedControl<UserLanguage>(
                value: access.language,
                options: UserLanguage.values,
                labelBuilder: (language) => language.label,
                onChanged: controller.updateLanguage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _transportDetail(TransportationMode mode) {
    switch (mode) {
      case TransportationMode.limited:
        return 'Best for pantry, corner-store, and near-home options.';
      case TransportationMode.walk:
        return 'Favor shorter trips and fewer stops.';
      case TransportationMode.transit:
        return 'Public transit is possible, but long detours still matter.';
      case TransportationMode.car:
        return 'Broader store access is realistic if the trip is worth it.';
    }
  }
}

class _InlineChoiceTile extends StatelessWidget {
  const _InlineChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? const Color(0xFFF0F0F3) : const Color(0xFFF9F9FB),
          border: Border.all(
            color: selected ? const Color(0xFFD1D1D8) : const Color(0xFFE8E8EE),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  selected ? const Color(0xFF2E2E33) : const Color(0xFF9C9CA3),
            ),
          ],
        ),
      ),
    );
  }
}
