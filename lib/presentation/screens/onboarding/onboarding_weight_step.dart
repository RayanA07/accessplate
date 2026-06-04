import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';

class OnboardingWeightStep extends ConsumerStatefulWidget {
  const OnboardingWeightStep({super.key});

  @override
  ConsumerState<OnboardingWeightStep> createState() =>
      _OnboardingWeightStepState();
}

class _OnboardingWeightStepState extends ConsumerState<OnboardingWeightStep> {
  late FixedExtentScrollController _pickerController;
  int? _seedWeight;

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
    final pounds = ((demographics.weightKg ?? 180 / 2.20462) * 2.20462)
        .round()
        .clamp(80, 450);
    _seedController(pounds);

    return OnboardingStepLayout(
      title: copy.choose(
        'What is your\ncurrent weight?',
        'Cual es tu\npeso actual?',
      ),
      subtitle: copy.choose(
        'This helps estimate daily energy and macro needs.',
        'Esto ayuda a estimar tus necesidades diarias de energia y macros.',
      ),
      topSpacing: 54,
      children: [
        Text(
          '$pounds lbs',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
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
                demographics.copyWith(weightKg: (index + 80) / 2.20462),
              );
            },
            children: List.generate(
              371,
              (index) => Center(
                child: Text(
                  '${index + 80} lbs',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: NihPalette.base,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _seedController(int pounds) {
    if (_seedWeight == pounds) {
      return;
    }
    _seedWeight = pounds;
    _pickerController = FixedExtentScrollController(initialItem: pounds - 80);
  }
}
