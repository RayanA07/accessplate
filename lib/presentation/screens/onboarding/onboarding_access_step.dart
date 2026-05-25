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
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingMetaLabel(copy.accessZipCodeLabel),
                const SizedBox(height: 10),
                TextField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '45211',
                    labelText: copy.accessZipFieldLabel,
                  ),
                  onChanged: (value) {
                    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits != value) {
                      _postalCodeController.value = TextEditingValue(
                        text: digits,
                        selection: TextSelection.collapsed(
                          offset: digits.length,
                        ),
                      );
                    }
                    controller.updatePostalCode(digits);
                  },
                ),
                const SizedBox(height: 12),
                Text(copy.accessZipHelp),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingMetaLabel(copy.accessTransportationLabel),
                const SizedBox(height: 12),
                for (final mode in TransportationMode.values) ...[
                  _InlineChoiceTile(
                    title: copy.transportationLabel(mode),
                    subtitle: copy.transportDetail(mode.code),
                    selected: access.transportation == mode,
                    onTap: () => controller.updateTransportation(mode),
                  ),
                  if (mode != TransportationMode.values.last)
                    const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                OnboardingMetaLabel(
                  copy.accessTripTimeLabel(access.maxTravelMinutes),
                ),
                Text(
                  copy.choose(
                    'Keep this low if long trips are not realistic most days.',
                    'Manten esto bajo si los viajes largos no son realistas la mayoria de los dias.',
                  ),
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
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingMetaLabel(copy.accessBenefitsModeLabel),
                const SizedBox(height: 8),
                Text(
                  copy.choose(
                    'Pick any benefits you use and turn on emergency mode for severe time, money, or travel pressure.',
                    'Marca los beneficios que usas y activa modo de emergencia cuando hay mucha presion por tiempo, dinero o viaje.',
                  ),
                ),
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
                  title: Text(copy.emergencyModeTitle),
                  subtitle: Text(copy.emergencyModeSubtitle),
                  onChanged: controller.updateEmergencyMode,
                ),
                SwitchListTile(
                  value: access.plainLanguage,
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.plainLanguageSettingTitle),
                  subtitle: Text(copy.plainLanguageSettingSubtitle),
                  onChanged: controller.updatePlainLanguage,
                ),
                const SizedBox(height: 8),
                OnboardingSegmentedControl<UserLanguage>(
                  value: access.language,
                  options: UserLanguage.values,
                  labelBuilder: copy.languageChoiceLabel,
                  onChanged: controller.updateLanguage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle.isEmpty ? title : '$title. $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected ? const Color(0xFFF0F0F3) : const Color(0xFFF9F9FB),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD1D1D8)
                  : const Color(0xFFE8E8EE),
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
                color: selected
                    ? const Color(0xFF2E2E33)
                    : const Color(0xFF9C9CA3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
