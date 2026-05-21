import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/entities/nutrients.dart';
import 'package:access_plate/domain/entities/recommendation.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/widgets/section_card.dart';
import 'package:access_plate/presentation/widgets/selection_tile.dart';
import 'package:access_plate/presentation/widgets/today_plan_card.dart';

void main() {
  testWidgets('section card renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionCard(child: Text('AccessPlate'))),
      ),
    );

    expect(find.text('AccessPlate'), findsOneWidget);
  });

  testWidgets('selection tile gives selected items a darker surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SelectionTile(title: 'Selected', selected: true, onTap: () {}),
              SelectionTile(title: 'Unselected', selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    final inks = tester.widgetList<Ink>(find.byType(Ink)).toList();
    final selectedDecoration = inks.first.decoration! as BoxDecoration;
    final unselectedDecoration = inks.last.decoration! as BoxDecoration;

    expect(selectedDecoration.color, const Color(0xFFE3E3E8));
    expect(unselectedDecoration.color, Colors.white);
  });

  testWidgets('today plan card renders summary and steps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayPlanCard(
            plan: TodayPlan(
              type: TodayPlanType.snapRun,
              title: 'Today plan: SNAP-aware run',
              summary: 'Use likely SNAP staples first.',
              steps: const [
                'Start with oatmeal and bananas.',
                'Keep the total under \$4.00.',
                'Use a backup staple if the first item is out.',
              ],
              highlights: const ['SNAP-aware', 'Grocery store'],
              leadRecommendation: _sampleFood(1),
              backupAction: 'Backup: yogurt cup from grocery store.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Today plan: SNAP-aware run'), findsOneWidget);
    expect(find.text('Use likely SNAP staples first.'), findsOneWidget);
    expect(find.text('Start with oatmeal and bananas.'), findsOneWidget);
    expect(find.text('Backup: yogurt cup from grocery store.'), findsOneWidget);
  });
}

ScoredFood _sampleFood(int id) {
  return ScoredFood(
    food: Food(
      id: id,
      name: 'Oatmeal cup',
      category: 'grain_whole',
      servingG: 64,
      servingLabel: '1 cup',
      costEstimate: 1.25,
      costConfidence: 'medium',
      prepMethod: 'microwave',
      prepTimeMin: 2,
      mealTypes: const {MealType.breakfast},
      availability: const {
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      },
      allergens: const {},
      religionExcluded: const [],
      medicalRules: const [],
      ingredients: const {'oatmeal', 'oats'},
      source: 'bundled_reference',
    ),
    nutrients: const Nutrients(
      caloriesKcal: 220,
      proteinG: 6,
      carbsG: 39,
      fatG: 4,
      saturatedFatG: 1,
      fiberG: 5,
      sugarG: 7,
      addedSugarG: 4,
      sodiumMg: 180,
      potassiumMg: 160,
      calciumMg: 40,
      ironMg: 1.6,
      magnesiumMg: 38,
      zincMg: 1.2,
      vitAMcgRae: 0,
      vitCMg: 0,
      vitDMcg: 0,
      vitB12Mcg: 0,
      folateMcgDfe: 18,
    ),
    composite: 0.7,
    displayScore: 88,
    breakdown: const ScoreBreakdown(
      macro: 0.72,
      micro: 0.44,
      penalty: 0.08,
      cost: 0.12,
      preference: 0.5,
    ),
  );
}
