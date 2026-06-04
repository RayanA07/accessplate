import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';

class OnboardingHeightStep extends ConsumerStatefulWidget {
  const OnboardingHeightStep({super.key});

  @override
  ConsumerState<OnboardingHeightStep> createState() =>
      _OnboardingHeightStepState();
}

class _OnboardingHeightStepState extends ConsumerState<OnboardingHeightStep> {
  late FixedExtentScrollController _pickerController;
  int? _seedInches;

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final demographics = profile.constraints.demographics;
    final controller = ref.read(profileControllerProvider.notifier);
    final copy = AppCopy(profile.constraints.access.language);
    final inches = ((demographics.heightCm ?? 66 * 2.54) / 2.54).round().clamp(
      48,
      84,
    );
    _seedController(inches);

    return OnboardingStepLayout(
      title: copy.choose('What is your\nheight?', 'Cual es tu\naltura?'),
      subtitle: copy.choose(
        'Used with age and weight to estimate daily targets.',
        'Se usa con edad y peso para estimar tus metas diarias.',
      ),
      topSpacing: 54,
      children: [
        Text(
          _formatHeight(inches),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
            color: NihPalette.primaryDarker,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 250,
          child: CupertinoPicker(
            scrollController: _pickerController,
            itemExtent: 44,
            useMagnifier: true,
            magnification: 1.08,
            selectionOverlay: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: NihPalette.borderSoft),
                  bottom: BorderSide(color: NihPalette.borderSoft),
                ),
              ),
            ),
            onSelectedItemChanged: (index) {
              controller.updateDemographics(
                demographics.copyWith(heightCm: (index + 48) * 2.54),
              );
            },
            children: List.generate(37, (index) {
              final current = index + 48;
              return Center(
                child: Text(
                  _formatHeight(current),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: NihPalette.base,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _seedController(int inches) {
    if (_seedInches == inches) {
      return;
    }
    _seedInches = inches;
    _pickerController = FixedExtentScrollController(initialItem: inches - 48);
  }

  String _formatHeight(int inches) {
    final feet = inches ~/ 12;
    final remainder = inches % 12;
    return '$feet\'$remainder"';
  }
}
