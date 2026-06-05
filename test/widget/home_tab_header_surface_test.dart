import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/home/logged_meals_screen.dart';
import 'package:access_plate/presentation/screens/home/macro_targets_screen.dart';
import 'package:access_plate/presentation/widgets/home_tab_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logged tab header uses the standard white card surface', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const LoggedMealsScreen()));
    await tester.pumpAndSettle();

    expect(_headerSurfaceColor(tester), NihPalette.white);
  });

  testWidgets('tracker tab header uses the standard white card surface', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const MacroTargetsScreen()));
    await tester.pumpAndSettle();

    expect(_headerSurfaceColor(tester), NihPalette.white);
  });
}

Widget _buildHarness(Widget home) {
  final profile = UserProfile.defaults().copyWith(onboardingComplete: true);

  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
    ],
    child: MaterialApp(theme: AccessPlateTheme.light(), home: home),
  );
}

Color? _headerSurfaceColor(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(HomeTabHeader),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  final decoration = decoratedBox.decoration as BoxDecoration;
  return decoration.color;
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
