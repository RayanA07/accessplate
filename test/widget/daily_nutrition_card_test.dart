import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/engine/government_nutrition_guidance.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/widgets/daily_nutrition_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tracker card uses white surface and horizontal macro bars', (
    tester,
  ) async {
    final theme = AccessPlateTheme.light();
    const guidance = GovernmentNutritionGuidance();
    final baseProfile = UserProfile.defaults();
    final targets = guidance.dailyTargetsFor(
      baseProfile.constraints.demographics,
    );
    final today = DateTime.now();
    final profile = baseProfile.copyWith(
      constraints: baseProfile.constraints.copyWith(
        todayIntake: const {
          'calories_kcal': 620,
          'protein_g': 24,
          'carbs_g': 68,
          'fat_g': 19,
          'fiber_g': 9,
        },
        todayIntakeDate: DateTime(today.year, today.month, today.day),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: Scaffold(body: DailyNutritionCard(profile: profile)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('tracker-card')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.color, NihPalette.white);
    expect(decoration.border, isA<Border>());
    expect(decoration.boxShadow, isNotEmpty);

    expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    expect(find.text('Protein'), findsOneWidget);
    expect(
      find.text('24g / ${targets.proteinG.toStringAsFixed(0)}g'),
      findsOneWidget,
    );
    expect(find.text('Carbs'), findsOneWidget);
    expect(
      find.text('68g / ${targets.carbsG.toStringAsFixed(0)}g'),
      findsOneWidget,
    );
    expect(find.text('Fat'), findsOneWidget);
    expect(
      find.text('19g / ${targets.fatG.toStringAsFixed(0)}g'),
      findsOneWidget,
    );
    expect(find.text('Fiber'), findsOneWidget);
    expect(
      find.text('9g / ${targets.fiberG.toStringAsFixed(0)}g'),
      findsOneWidget,
    );

    final proteinBar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(const ValueKey('macro-bar-protein')),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('macro-bar-protein'))).height,
      8,
    );
    expect(proteinBar.backgroundColor, theme.colorScheme.outlineVariant);
    expect(proteinBar.valueColor?.value, NihPalette.success);
  });
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
