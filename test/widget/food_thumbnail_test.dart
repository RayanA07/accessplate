import 'package:access_plate/domain/entities/food.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/presentation/widgets/food_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('food thumbnail uses the updated meal-specific icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FoodThumbnail(
                food: _food(
                  id: 179,
                  name: 'Trail mix snack pack',
                  ingredients: {'mixed_nuts', 'dried_fruit'},
                ),
                accent: Colors.green,
              ),
              FoodThumbnail(
                food: _food(
                  id: 96,
                  name: 'Bean and cheese wrap',
                  ingredients: {
                    'flour tortillas',
                    'refried beans',
                    'cheese slices',
                  },
                ),
                accent: Colors.green,
              ),
              FoodThumbnail(
                food: _food(
                  id: 108,
                  name: 'Fresh banana and peanut butter',
                  ingredients: {'banana', 'peanut butter'},
                ),
                accent: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lunch_dining_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_nature_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apple_rounded), findsNothing);
    expect(find.byIcon(Icons.ramen_dining_rounded), findsNothing);
  });
}

Food _food({
  required int id,
  required String name,
  required Set<String> ingredients,
}) {
  return Food(
    id: id,
    name: name,
    category: 'prepared_meal',
    servingG: 300,
    servingLabel: '1 serving',
    costEstimate: 3.0,
    costConfidence: 'medium',
    prepMethod: 'none',
    prepTimeMin: 0,
    mealTypes: const {MealType.lunch},
    availability: const {AvailabilityContext.grocery},
    allergens: const {},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: ingredients,
    source: 'test_fixture',
  );
}
