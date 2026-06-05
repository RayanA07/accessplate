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
                  id: 1020,
                  name: 'Taco Bell Power Menu Bowl',
                  ingredients: {'rice', 'beans', 'chicken'},
                  availability: {AvailabilityContext.fastFood},
                ),
                accent: Colors.green,
              ),
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
              FoodThumbnail(
                food: _food(
                  id: 133,
                  name: 'Tuna and cracker plate',
                  ingredients: {'tuna', 'crackers'},
                ),
                accent: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lunch_dining_rounded), findsOneWidget);
    expect(find.byIcon(Icons.food_bank_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dinner_dining_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ramen_dining_rounded), findsNothing);
  });
}

Food _food({
  required int id,
  required String name,
  required Set<String> ingredients,
  Set<AvailabilityContext> availability = const {AvailabilityContext.grocery},
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
    availability: availability,
    allergens: const {},
    religionExcluded: const [],
    medicalRules: const [],
    ingredients: ingredients,
    source: 'test_fixture',
  );
}
