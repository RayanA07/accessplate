import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/benefit_program.dart';
import '../../../domain/value_objects/transportation_mode.dart';
import '../../../domain/value_objects/user_language.dart';
import '../../copy/app_copy.dart';
import '../../providers/nearby_store_providers.dart';
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
  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final access = profile.constraints.access;
    final copy = AppCopy(access.language);
    final controller = ref.read(profileControllerProvider.notifier);
    final locationState = ref.watch(shoppingLocationStateProvider);
    final location = locationState.location;

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
                OnboardingMetaLabel(
                  copy.choose('Current location', 'Ubicacion actual'),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.choose(
                    'Use your current location so nearby-store results are based on where you actually are.',
                    'Usa tu ubicacion actual para que las tiendas cercanas salgan segun donde si estas.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: locationState.loading
                      ? null
                      : () {
                          ref
                              .read(shoppingLocationControllerProvider.notifier)
                              .useDeviceLocation();
                        },
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(
                    copy.choose(
                      'Use current location',
                      'Usar ubicacion actual',
                    ),
                  ),
                ),
                if (locationState.loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (location != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NihPalette.secondaryLightest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: NihPalette.secondaryLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.choose(
                            'Location saved',
                            'Ubicacion guardada',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(location.label),
                        if (location.postalCode?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            'ZIP ${location.postalCode!}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (locationState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    locationState.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  copy.choose(
                    'If you skip this, nearby-store verification will stay limited until you allow location access.',
                    'Si omites esto, la verificacion de tiendas cercanas seguira limitada hasta que permitas la ubicacion.',
                  ),
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
            color: selected
                ? NihPalette.secondaryLightest
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: selected
                  ? NihPalette.secondaryLight
                  : NihPalette.borderSoft,
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
                color: selected ? NihPalette.primary : NihPalette.grayDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
