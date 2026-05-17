import 'package:access_plate/domain/engine/scoring/macro_scorer.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact target match yields perfect agreement', () {
    expect(MacroScorer.agreement(25, 25), 1);
  });

  test('macro score stays within bounds', () {
    const scorer = MacroScorer(
      targets: NutritionalTargets(
        calories: 500,
        proteinG: 25,
        carbsG: 60,
        fatG: 16,
        fiberG: 8,
      ),
      weights: MacroWeights(),
    );

    final score = scorer.score(
      Nutrients(
        caloriesKcal: 480,
        proteinG: 24,
        carbsG: 62,
        fatG: 15,
        saturatedFatG: 3,
        fiberG: 8,
        sugarG: 5,
        addedSugarG: 2,
        sodiumMg: 250,
        potassiumMg: 300,
        calciumMg: 100,
        ironMg: 2,
        magnesiumMg: 30,
        zincMg: 1,
        vitAMcgRae: 30,
        vitCMg: 4,
        vitDMcg: 0,
        vitB12Mcg: 0,
        folateMcgDfe: 40,
      ),
    );

    expect(score, inInclusiveRange(0, 1));
  });

  test('minimum agreement keeps protein overshoot at full credit', () {
    expect(MacroScorer.minimumAgreement(25, 32), 1);
  });

  test('agreement treats a broad calorie range as good enough', () {
    expect(
      MacroScorer.agreement(
        500,
        580,
        lowerGoodRatio: 0.55,
        upperGoodRatio: 1.25,
        upperZeroRatio: 1.9,
      ),
      1,
    );
  });
}
