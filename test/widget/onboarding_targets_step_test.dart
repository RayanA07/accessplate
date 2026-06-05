import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/engine/government_nutrition_guidance.dart';
import 'package:access_plate/domain/engine/score_config_provider.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/app_bootstrap.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_targets_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('targets screen shows row summaries, divider, and info callout', (
    tester,
  ) async {
    final profile = UserProfile.defaults().copyWith(
      onboardingStage: OnboardingStage.targets,
    );
    const guidance = GovernmentNutritionGuidance();
    final daily = guidance.dailyTargetsFor(profile.constraints.demographics);

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
        child: MaterialApp(
          theme: AccessPlateTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: OnboardingTargetsStep()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('targets-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('limits-summary-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('targets-limits-divider')),
      findsOneWidget,
    );
    expect(find.byType(Chip), findsNothing);

    expect(find.text('Calories'), findsOneWidget);
    expect(
      find.text('${daily.calories.toStringAsFixed(0)} kcal'),
      findsOneWidget,
    );
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('${daily.proteinG.toStringAsFixed(0)}g'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('${daily.carbsG.toStringAsFixed(0)}g'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('${daily.fatG.toStringAsFixed(0)}g'), findsOneWidget);
    expect(find.text('Fiber'), findsOneWidget);
    expect(find.text('${daily.fiberG.toStringAsFixed(0)}g'), findsOneWidget);

    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(3));

    final note = tester.widget<Container>(
      find.byKey(const ValueKey('micronutrient-note')),
    );
    final noteDecoration = note.decoration! as BoxDecoration;
    final noteText = tester.widget<Text>(
      find.text(
        'No extra micronutrient watchlist is turned on yet. If you mark anemia, pregnancy, bone density, or a plant-based pattern, AccessPlate will track the most relevant nutrients.',
      ),
    );

    expect(noteDecoration.color, const Color(0xFFE3F2FD));
    expect(noteText.style?.fontSize, 13);
  });
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
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
  microPriorityElevations: {},
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
