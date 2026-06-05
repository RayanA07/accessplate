import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/prep_environment.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_environment_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'preparation setup uses the stronger selected state and flame icon',
    (tester) async {
      final baseProfile = UserProfile.defaults();
      final controller = _TestProfileController(
        baseProfile.copyWith(
          onboardingStage: OnboardingStage.environment,
          constraints: baseProfile.constraints.copyWith(
            feasibility: baseProfile.constraints.feasibility.copyWith(
              environment: PrepEnvironment.stoveTop,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          controller: controller,
          child: const SingleChildScrollView(
            child: OnboardingEnvironmentStep(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preparation\nsetup'), findsOneWidget);
      expect(find.text('Stovetop + microwave'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == NihPalette.success,
        ),
        findsOneWidget,
      );

      final selectedDecoration = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .firstWhere(
            (decoration) => decoration.color == const Color(0xFFE8F5E9),
          );
      expect(selectedDecoration.color, const Color(0xFFE8F5E9));

      await tester.tap(find.text('Full kitchen'));
      await tester.pumpAndSettle();

      expect(
        controller.current.constraints.feasibility.environment,
        PrepEnvironment.fullKitchen,
      );
    },
  );
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
  Future<void> updateEnvironment(PrepEnvironment environment) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        feasibility: _profile.constraints.feasibility.copyWith(
          environment: environment,
        ),
      ),
    );
    state = AsyncData(_profile);
  }
}
