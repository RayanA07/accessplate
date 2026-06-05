import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/dietary_style.dart';
import 'package:access_plate/domain/value_objects/religion.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_budget_step.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_dietary_style_step.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:access_plate/presentation/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('food restrictions screen switches freely across tabs', (
    tester,
  ) async {
    final controller = _TestProfileController(
      UserProfile.defaults().copyWith(
        onboardingStage: OnboardingStage.dietaryStyle,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        controller: controller,
        child: const SingleChildScrollView(child: OnboardingDietaryStyleStep()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Food restrictions'), findsOneWidget);
    expect(
      find.text('These are applied to every meal recommendation.'),
      findsOneWidget,
    );
    expect(find.text('Diet'), findsOneWidget);
    expect(find.text('Allergens'), findsOneWidget);
    expect(find.text('Religion'), findsOneWidget);
    expect(find.text('No diet filter'), findsOneWidget);
    expect(find.text('Fish'), findsNothing);

    await tester.tap(find.text('Allergens'));
    await tester.pumpAndSettle();

    expect(find.text('Fish'), findsOneWidget);
    expect(find.text('Exclude foods containing fish.'), findsOneWidget);

    await tester.ensureVisible(find.text('Fish'));
    await tester.tap(find.text('Fish'));
    await tester.pumpAndSettle();

    expect(
      controller.current.constraints.safety.allergens.contains(Allergen.fish),
      isTrue,
    );

    await tester.ensureVisible(find.text('Religion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Religion'));
    await tester.pumpAndSettle();

    expect(find.text('No restriction'), findsOneWidget);
    expect(find.text('Halal'), findsOneWidget);

    await tester.tap(find.text('Halal'));
    await tester.pumpAndSettle();

    expect(controller.current.constraints.safety.religion, Religion.halal);

    await tester.ensureVisible(find.text('Diet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diet'));
    await tester.pumpAndSettle();

    expect(find.text('Vegetarian'), findsOneWidget);
    await tester.tap(find.text('Vegan'));
    await tester.pumpAndSettle();

    expect(
      controller.current.constraints.preference.dietaryStyle,
      DietaryStyle.vegan,
    );
  });

  testWidgets(
    'legacy allergen stage renders the combined food restrictions screen',
    (tester) async {
      final controller = _TestProfileController(
        UserProfile.defaults().copyWith(
          onboardingStage: OnboardingStage.allergens,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileControllerProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: AccessPlateTheme.light(),
            home: const OnboardingFlowScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food restrictions'), findsOneWidget);
      expect(find.text('Diet'), findsOneWidget);
    },
  );

  testWidgets('budget screen shows tighter layout with range guidance', (
    tester,
  ) async {
    final controller = _TestProfileController(
      UserProfile.defaults().copyWith(onboardingStage: OnboardingStage.budget),
    );

    await tester.pumpWidget(
      _buildHarness(
        controller: controller,
        child: const SingleChildScrollView(child: OnboardingBudgetStep()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('\$1'), findsOneWidget);
    expect(find.text('\$30'), findsOneWidget);
    expect(
      find.text('Set to \$0-\$5 if you rely on a food pantry or SNAP.'),
      findsOneWidget,
    );

    final subtitleBottom = tester
        .getBottomLeft(
          find.text(
            'Set the maximum you want the engine to spend on one meal.',
          ),
        )
        .dy;
    final cardTop = tester.getTopLeft(find.byType(SectionCard)).dy;
    expect(cardTop - subtitleBottom, lessThan(30));
  });
}

Widget _buildHarness({
  required _TestProfileController controller,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [profileControllerProvider.overrideWith(() => controller)],
    child: MaterialApp(
      theme: AccessPlateTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;

  @override
  Future<void> updatePreference(PreferenceConstraints preference) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(preference: preference),
    );
    state = AsyncData(_profile);
  }

  @override
  Future<void> updateSafety(SafetyConstraints safety) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(safety: safety),
    );
    state = AsyncData(_profile);
  }

  @override
  Future<void> updateBudget(double budget) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        feasibility: _profile.constraints.feasibility.copyWith(
          maxCostPerMeal: budget,
        ),
      ),
    );
    state = AsyncData(_profile);
  }
}
