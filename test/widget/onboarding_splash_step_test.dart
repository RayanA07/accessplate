import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_splash_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'splash screen shows prominent feature rows and a flat recommendation card',
    (tester) async {
      final profile = UserProfile.defaults().copyWith(
        onboardingStage: OnboardingStage.splash,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              () => _TestProfileController(profile),
            ),
          ],
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(child: OnboardingSplashStep()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Works offline'), findsOneWidget);
      expect(find.text('Explains every pick'), findsOneWidget);
      expect(find.text('Built for real budgets'), findsOneWidget);
      expect(find.text('Local-first'), findsNothing);
      expect(find.text('Explainable'), findsNothing);
      expect(find.text('Real-world access'), findsNothing);

      expect(
        find.byKey(const ValueKey('splash-feature-offline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('splash-feature-explainable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('splash-feature-budget')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('splash-recommendation-card')),
        findsOneWidget,
      );
      expect(find.text('Sample recommendation'), findsOneWidget);
      expect(find.text('Store: Save A Lot'), findsOneWidget);
      expect(find.text('Buy list preview'), findsOneWidget);
      expect(find.byIcon(Icons.phone_iphone_rounded), findsNothing);
    },
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
