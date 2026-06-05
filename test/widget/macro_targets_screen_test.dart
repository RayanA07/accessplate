import 'package:access_plate/core/theme/app_palette.dart';
import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/engine/government_nutrition_guidance.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/home/macro_targets_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('weekly tracker section stays hidden until any meal is logged', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(UserProfile.defaults()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weekly-tracker-section')), findsNothing);
  });

  testWidgets('weekly tracker section renders chart and summary stats', (
    tester,
  ) async {
    const guidance = GovernmentNutritionGuidance();
    final profile = UserProfile.defaults();
    final targetCalories = guidance
        .dailyTargetsFor(profile.constraints.demographics)
        .calories;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));
    final todayIndex = today.weekday - 1;
    final nonTodayIndexes = List<int>.generate(7, (index) => index)
      ..remove(todayIndex);
    final greenIndex = nonTodayIndexes.first;
    final yellowIndex = nonTodayIndexes[1];
    final greenDay = weekStart.add(Duration(days: greenIndex));
    final yellowDay = weekStart.add(Duration(days: yellowIndex));
    final expectedAverageCalories =
        (targetCalories + (targetCalories * 1.5) + (targetCalories * 0.9)) / 3;

    final trackerProfile = profile.copyWith(
      constraints: profile.constraints.copyWith(
        loggedMealHistory: [
          LoggedMealEntry(
            mealName: 'Tuna salad on whole-wheat',
            loggedAt: greenDay.add(const Duration(hours: 8)),
            caloriesKcal: targetCalories * 0.5,
            foodIds: const [1],
          ),
          LoggedMealEntry(
            mealName: 'Tuna salad on whole-wheat',
            loggedAt: greenDay.add(const Duration(hours: 13)),
            caloriesKcal: targetCalories * 0.5,
            foodIds: const [1],
          ),
          LoggedMealEntry(
            mealName: 'Bean and rice bowl',
            loggedAt: yellowDay.add(const Duration(hours: 12)),
            caloriesKcal: targetCalories * 1.5,
            foodIds: const [2],
          ),
          LoggedMealEntry(
            mealName: 'Tuna salad on whole-wheat',
            loggedAt: todayStart.add(const Duration(hours: 18)),
            caloriesKcal: targetCalories * 0.9,
            foodIds: const [1],
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildHarness(trackerProfile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('This week at a glance.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('weekly-tracker-section')),
      findsOneWidget,
    );
    expect(find.text('This week at a glance.'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('weekly-days-logged')),
        matching: find.text('3/7'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('weekly-average-calories')),
        matching: find.text('${expectedAverageCalories.round()}kcal'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('weekly-most-logged-meal')),
        matching: find.text('Tuna salad on whole-wheat'),
      ),
      findsOneWidget,
    );

    final chart = tester.widget<BarChart>(
      find.byKey(const ValueKey('weekly-calorie-chart')),
    );
    final groups = chart.data.barGroups;

    expect(groups, hasLength(7));
    expect(groups[greenIndex].barRods.first.color, NihPalette.success);
    expect(groups[yellowIndex].barRods.first.color, NihPalette.warning);
    expect(
      groups.firstWhere((group) => group.x == todayIndex).barRods.first.color,
      NihPalette.success,
    );
    expect(
      groups
          .firstWhere((group) => group.x == todayIndex)
          .barRods
          .first
          .borderSide
          .color,
      NihPalette.primaryDarkest,
    );
    final grayGroup = groups.firstWhere(
      (group) =>
          group.x != greenIndex &&
          group.x != yellowIndex &&
          group.x != todayIndex,
    );
    expect(grayGroup.barRods.first.color, NihPalette.grayLight);
  });
}

Widget _buildHarness(UserProfile profile) {
  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(profile),
      ),
    ],
    child: MaterialApp(
      theme: AccessPlateTheme.light(),
      home: const Scaffold(body: MacroTargetsScreen()),
    ),
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
