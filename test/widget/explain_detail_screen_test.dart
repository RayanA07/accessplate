import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/explanation.dart';
import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/user_language.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/explain/explain_detail_screen.dart';

void main() {
  testWidgets(
    'explain detail screen shows quick-read copy in plain-language mode',
    (tester) async {
      final profile = UserProfile.defaults().copyWith(
        constraints: UserConstraints.defaults().copyWith(
          access: const AccessConstraints(
            language: UserLanguage.english,
            plainLanguage: true,
          ),
        ),
      );
      final top = _food(1).copyWith(
        explanation: const Explanation(
          satisfied: [
            SatisfiedConstraint(
              category: 'budget',
              description: 'Fits a lower-cost breakfast run.',
            ),
          ],
          positives: [
            ScoreFactor(
              label: 'Low cost',
              weight: 0.4,
              detail: 'Keeps the first buy small.',
            ),
          ],
          tradeoffs: [
            ScoreFactor(
              label: 'Protein is modest',
              weight: 0.1,
              detail: 'Pair with another staple if needed.',
            ),
          ],
          compareWithIds: [2],
          accessSummary: 'Short trip with pantry-friendly staples.',
          decisionFacts: [
            DecisionFact(label: 'Trip', value: 'Short'),
            DecisionFact(label: 'Benefits', value: 'Likely SNAP-compatible'),
            DecisionFact(label: 'From home', value: 'Oats already on hand'),
          ],
        ),
      );
      final backup = _food(2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              () => _TestProfileController(profile),
            ),
          ],
          child: MaterialApp(
            home: ExplainDetailScreen(
              recommendation: top,
              allRecommendations: [top, backup],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick read'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Works for you because'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Works for you because'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Backups'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Backups'), findsOneWidget);
      expect(find.text('Watch for'), findsWidgets);
    },
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}

ScoredFood _food(int id) {
  return ScoredFood(
    food: Food(
      id: id,
      name: id == 1 ? 'Oatmeal cup' : 'Banana',
      category: id == 1 ? 'grain_whole' : 'fruit',
      servingG: 80,
      servingLabel: '1 serving',
      costEstimate: id == 1 ? 1.25 : 0.45,
      costConfidence: 'medium',
      prepMethod: 'none',
      prepTimeMin: 0,
      mealTypes: const {MealType.breakfast},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: id == 1 ? const {'oats'} : const {'banana'},
      source: 'bundled_reference',
    ),
    nutrients: Nutrients(
      caloriesKcal: id == 1 ? 220 : 105,
      proteinG: id == 1 ? 6 : 1,
      carbsG: id == 1 ? 39 : 27,
      fatG: id == 1 ? 4 : 0,
      saturatedFatG: 0,
      fiberG: id == 1 ? 5 : 3,
      sugarG: id == 1 ? 7 : 14,
      addedSugarG: 0,
      sodiumMg: id == 1 ? 180 : 1,
      potassiumMg: 120,
      calciumMg: 40,
      ironMg: 1.2,
      magnesiumMg: 30,
      zincMg: 1,
      vitAMcgRae: 0,
      vitCMg: 0,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 20,
    ),
    composite: 0.72,
    displayScore: 87,
    breakdown: const ScoreBreakdown(
      macro: 0.7,
      micro: 0.44,
      penalty: 0.05,
      cost: 0.12,
      preference: 0.5,
    ),
  );
}
