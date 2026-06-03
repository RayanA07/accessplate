import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';

class OnboardingAgeStep extends ConsumerStatefulWidget {
  const OnboardingAgeStep({super.key});

  @override
  ConsumerState<OnboardingAgeStep> createState() => _OnboardingAgeStepState();
}

class _OnboardingAgeStepState extends ConsumerState<OnboardingAgeStep> {
  late FixedExtentScrollController _pickerController;
  int? _seedAge;

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
    final age = demographics.ageYears.clamp(14, 75);
    _seedController(age);

    return OnboardingStepLayout(
      title: copy.choose('How old are\nyou?', 'Cuantos anos\ntienes?'),
      subtitle: copy.choose(
        'This calibrates your daily calories and macro targets.',
        'Esto calibra tus calorias diarias y metas de macros.',
      ),
      topSpacing: 54,
      children: [
        Text(
          '$age',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            color: Color(0xFF121212),
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
                  top: BorderSide(color: Color(0xFFE8E8EC)),
                  bottom: BorderSide(color: Color(0xFFE8E8EC)),
                ),
              ),
            ),
            onSelectedItemChanged: (index) {
              controller.updateDemographics(
                demographics.copyWith(ageYears: index + 14),
              );
            },
            children: List.generate(
              62,
              (index) => Center(
                child: Text(
                  '${index + 14}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222226),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _seedController(int age) {
    if (_seedAge == age) {
      return;
    }
    _seedAge = age;
    _pickerController = FixedExtentScrollController(initialItem: age - 14);
  }
}
