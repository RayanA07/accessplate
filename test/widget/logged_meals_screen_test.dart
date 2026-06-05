import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/home/logged_meals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logged meals screen shows logged meal names and times', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final profile = UserProfile.defaults().copyWith(
      onboardingComplete: true,
      constraints: UserConstraints.defaults().copyWith(
        todayIntake: const {'calories_kcal': 390},
        todayIntakeDate: today,
        loggedMeals: [
          LoggedMealEntry(
            mealName: 'Tuna salad on whole-wheat',
            loggedAt: DateTime(today.year, today.month, today.day, 16, 26),
            foodIds: const [1],
          ),
          LoggedMealEntry(
            mealName: 'Bean chili bowl',
            loggedAt: DateTime(today.year, today.month, today.day, 12, 5),
            foodIds: const [2],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => _TestProfileController(profile),
          ),
        ],
        child: const MaterialApp(home: LoggedMealsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tuna salad on whole-wheat'), findsOneWidget);
    expect(find.text('Bean chili bowl'), findsOneWidget);
    expect(find.text('4:26 PM'), findsNWidgets(2));
    expect(find.text('12:05 PM'), findsOneWidget);
    expect(find.text('Meal logged'), findsNothing);
  });
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
