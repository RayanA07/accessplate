import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_pantry_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pantry instruction copy is readable and padded', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final instruction = tester.widget<Text>(
      find.text(
        'Tap once for have enough, again for running low, again for restock, and once more to remove it.',
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('pantry-cycle-hint')),
    );

    expect(instruction.style?.fontSize, greaterThanOrEqualTo(14));
    expect(
      container.padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  });

  testWidgets('pantry chips cycle through distinct visual states', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    final riceChip = find.byKey(const ValueKey('pantry-chip-rice'));

    expect(_chipDecoration(tester, 'rice').color, NihPalette.white);
    expect(
      find.descendant(of: riceChip, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );

    await tester.tap(riceChip);
    await tester.pumpAndSettle();

    expect(_chipDecoration(tester, 'rice').color, NihPalette.success);
    expect(
      find.descendant(of: riceChip, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );

    await tester.tap(riceChip);
    await tester.pumpAndSettle();

    expect(_chipDecoration(tester, 'rice').color, NihPalette.warning);
    expect(
      find.descendant(
        of: riceChip,
        matching: find.byIcon(Icons.warning_amber_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(riceChip);
    await tester.pumpAndSettle();

    expect(_chipDecoration(tester, 'rice').color, const Color(0xFFE57D22));
    expect(
      find.descendant(
        of: riceChip,
        matching: find.byIcon(Icons.autorenew_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(riceChip);
    await tester.pumpAndSettle();

    expect(_chipDecoration(tester, 'rice').color, NihPalette.white);
    expect(
      find.descendant(
        of: riceChip,
        matching: find.byIcon(Icons.autorenew_rounded),
      ),
      findsNothing,
    );
  });
}

BoxDecoration _chipDecoration(WidgetTester tester, String item) {
  final chip = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('pantry-chip-$item')),
  );
  return chip.decoration! as BoxDecoration;
}

Widget _buildHarness() {
  final profile = UserProfile.defaults().copyWith(
    onboardingStage: OnboardingStage.pantry,
  );

  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
    ],
    child: MaterialApp(
      theme: AccessPlateTheme.light(),
      home: const Scaffold(
        body: SingleChildScrollView(child: OnboardingPantryStep()),
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
  Future<void> updatePantryItemState(
    String item,
    PantryStockLevel? level,
  ) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        pantry: _profile.constraints.pantry.withItem(item, level),
      ),
    );
    state = AsyncData(_profile);
  }
}
