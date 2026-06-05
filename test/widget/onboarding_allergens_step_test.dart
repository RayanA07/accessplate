import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_allergens_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'allergen onboarding shows fish, shellfish, and sesame between soy and wheat',
    (tester) async {
      final controller = _TestProfileController(
        UserProfile.defaults().copyWith(
          onboardingStage: OnboardingStage.allergens,
        ),
      );
      await tester.pumpWidget(_buildHarness(controller));
      await tester.pumpAndSettle();

      expect(find.text('Fish'), findsOneWidget);
      expect(find.text('Shellfish'), findsOneWidget);
      expect(find.text('Sesame'), findsOneWidget);
      expect(find.text('Exclude foods containing fish.'), findsOneWidget);
      expect(find.text('Exclude foods containing shellfish.'), findsOneWidget);
      expect(find.text('Exclude foods containing sesame.'), findsOneWidget);

      final soyY = tester.getTopLeft(find.text('Soy')).dy;
      final fishY = tester.getTopLeft(find.text('Fish')).dy;
      final shellfishY = tester.getTopLeft(find.text('Shellfish')).dy;
      final sesameY = tester.getTopLeft(find.text('Sesame')).dy;
      final wheatY = tester.getTopLeft(find.text('Wheat')).dy;

      expect(soyY, lessThan(fishY));
      expect(fishY, lessThan(shellfishY));
      expect(shellfishY, lessThan(sesameY));
      expect(sesameY, lessThan(wheatY));
    },
  );

  testWidgets(
    'allergen onboarding toggles fish with the existing card behavior',
    (tester) async {
      final controller = _TestProfileController(
        UserProfile.defaults().copyWith(
          onboardingStage: OnboardingStage.allergens,
        ),
      );
      await tester.pumpWidget(_buildHarness(controller));
      await tester.pumpAndSettle();

      expect(find.text('Fish'), findsOneWidget);
      expect(
        controller.current.constraints.safety.allergens.contains(Allergen.fish),
        isFalse,
      );

      await tester.ensureVisible(find.text('Fish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fish'));
      await tester.pumpAndSettle();

      expect(
        controller.current.constraints.safety.allergens.contains(Allergen.fish),
        isTrue,
      );
    },
  );
}

Widget _buildHarness(_TestProfileController controller) {
  return ProviderScope(
    overrides: [profileControllerProvider.overrideWith(() => controller)],
    child: MaterialApp(
      theme: AccessPlateTheme.light(),
      home: const Scaffold(
        body: SingleChildScrollView(child: OnboardingAllergensStep()),
      ),
    ),
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
