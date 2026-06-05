import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/medical_restriction.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_medical_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'medical restrictions screen shows new conditions and taller mode pills',
    (tester) async {
      final controller = _TestProfileController(
        UserProfile.defaults().copyWith(
          onboardingStage: OnboardingStage.medical,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileControllerProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(child: OnboardingMedicalStep()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('High cholesterol'), findsOneWidget);
      expect(
        find.text('Limit saturated fat and dietary cholesterol.'),
        findsOneWidget,
      );
      expect(find.text('Heart disease / cardiovascular risk'), findsOneWidget);
      expect(
        find.text(
          'Favor heart-healthy options low in sodium and saturated fat.',
        ),
        findsOneWidget,
      );
      expect(find.text('Celiac disease / gluten intolerance'), findsOneWidget);
      expect(
        find.text(
          'Avoid all gluten-containing foods including wheat, barley, and rye.',
        ),
        findsOneWidget,
      );

      final celiacCard = find.byKey(
        const ValueKey('medical-card-celiac_gluten_intolerance'),
      );
      final celiacControls = find.descendant(
        of: celiacCard,
        matching: find.byType(AnimatedContainer),
      );
      expect(
        tester.getSize(celiacControls.first).height,
        greaterThanOrEqualTo(40),
      );

      await tester.ensureVisible(
        find.descendant(of: celiacCard, matching: find.text('Avoid')),
      );
      await tester.tap(
        find.descendant(of: celiacCard, matching: find.text('Avoid')),
      );
      await tester.pumpAndSettle();

      expect(
        controller.current.constraints.safety.medicalAvoid,
        contains(MedicalRestriction.celiacDiseaseGlutenIntolerance),
      );
    },
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;

  @override
  Future<void> updateSafety(SafetyConstraints safety) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(safety: safety),
    );
    state = AsyncData(_profile);
  }
}
