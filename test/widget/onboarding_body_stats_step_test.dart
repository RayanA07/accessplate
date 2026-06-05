import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/app_bootstrap.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_flow_screen.dart';

void main() {
  testWidgets('body-stats screen consolidates age height and weight', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.age,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceTablesProvider.overrideWith(
            (ref) async => _testReferenceTables,
          ),
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
        ],
        child: const MaterialApp(home: OnboardingFlowScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your body stats'), findsOneWidget);
    expect(
      find.text('Used to calculate your daily calorie and macro targets.'),
      findsOneWidget,
    );
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('How old are'), findsNothing);
    expect(find.textContaining('current weight'), findsNothing);
  });

  testWidgets(
    'legacy height stage renders the consolidated body-stats screen',
    (tester) async {
      final profile = UserProfile.defaults().copyWith(
        onboardingStage: OnboardingStage.height,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceTablesProvider.overrideWith(
              (ref) async => _testReferenceTables,
            ),
            profileControllerProvider.overrideWith(
              () => _TestProfileController(profile),
            ),
          ],
          child: const MaterialApp(home: OnboardingFlowScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your body stats'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsNWidgets(3));
    },
  );
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

const _testReferenceTables = ReferenceTables(
  rdaTable: {
    'female_19_50': {
      'iron_mg': 18,
      'calcium_mg': 1000,
      'potassium_mg': 2600,
      'magnesium_mg': 310,
      'zinc_mg': 8,
      'vit_a_mcg_rae': 700,
      'vit_c_mg': 75,
      'vit_d_mcg': 15,
      'vit_b12_mcg': 2.4,
      'folate_mcg_dfe': 400,
    },
  },
  medicalModifiers: {},
  microPriorityElevations: {
    'anemia': {'iron_mg': 2.0},
  },
  basePenaltyThresholds: {
    'sodium_mg': 750,
    'added_sugar_g': 12,
    'saturated_fat_g': 7,
  },
  basePenaltyWeights: {
    'sodium_mg': 0.4,
    'added_sugar_g': 0.3,
    'saturated_fat_g': 0.3,
  },
);
