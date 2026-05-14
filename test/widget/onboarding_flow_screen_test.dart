import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_flow_screen.dart';

void main() {
  testWidgets('cuisine step keeps next action visible on a small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.cuisine,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
        ],
        child: const MaterialApp(home: OnboardingFlowScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Disliked\ningredients'), findsOneWidget);
  });

  testWidgets('final onboarding step shows recommendations CTA', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.targets,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
        ],
        child: const MaterialApp(home: OnboardingFlowScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('See recommendations'), findsOneWidget);
  });
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;

  @override
  Future<void> setStage(OnboardingStage stage) async {
    _profile = _profile.copyWith(
      onboardingStage: stage,
      onboardingComplete: false,
    );
    state = AsyncData(_profile);
  }

  @override
  Future<void> completeOnboarding() async {
    _profile = _profile.copyWith(
      onboardingComplete: true,
      onboardingStage: OnboardingStage.targets,
    );
    state = AsyncData(_profile);
  }
}
