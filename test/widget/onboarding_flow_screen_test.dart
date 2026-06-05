import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/user_language.dart';
import 'package:access_plate/presentation/providers/app_bootstrap.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_flow_screen.dart';

void main() {
  testWidgets(
    'food restrictions step keeps next action visible on a small viewport',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = UserProfile.defaults().copyWith(
        onboardingStage: OnboardingStage.dietaryStyle,
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

      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Medical\nrestrictions'), findsOneWidget);
    },
  );

  testWidgets('final onboarding step shows recommendations CTA', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.targets,
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

    expect(find.text('See my meal suggestions →'), findsOneWidget);
  });

  testWidgets('access step shows Spanish onboarding copy when selected', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.access,
      constraints: UserConstraints.defaults().copyWith(
        access: UserConstraints.defaults().access.copyWith(
          language: UserLanguage.spanish,
        ),
      ),
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

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Ubicacion actual'), findsOneWidget);
    expect(find.text('Usar ubicacion actual'), findsOneWidget);
    expect(find.text('Bus o tren'), findsOneWidget);
    expect(find.text('Ingles'), findsOneWidget);
    expect(find.text('Espanol'), findsOneWidget);
  });

  testWidgets('food restrictions step shows Spanish localized copy', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.dietaryStyle,
      constraints: UserConstraints.defaults().copyWith(
        access: UserConstraints.defaults().access.copyWith(
          language: UserLanguage.spanish,
        ),
      ),
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

    expect(find.text('Restricciones de comida'), findsOneWidget);
    expect(find.text('Dieta'), findsOneWidget);
    expect(find.text('Alergenos'), findsOneWidget);
    expect(find.text('Religion'), findsOneWidget);
    expect(find.text('Sin filtro de dieta'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
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
