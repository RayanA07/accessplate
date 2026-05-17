import 'package:access_plate/data/seed_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed loader merges the bundled fast-food menu snapshot', () async {
    final foods = await SeedLoader().loadFoods();
    final fastFood = foods
        .where(
          (item) =>
              (item['availability'] as List<dynamic>).contains('fast_food'),
        )
        .toList();
    final pantryCount = foods
        .where(
          (item) =>
              (item['availability'] as List<dynamic>).contains('food_pantry'),
        )
        .length;
    final dollarStoreCount = foods
        .where(
          (item) =>
              (item['availability'] as List<dynamic>).contains('dollar_store'),
        )
        .length;
    final cheapNoPrep = foods
        .where((item) => (item['cost'] as num).toDouble() < 5)
        .where((item) => item['prep'] == 'none')
        .where(
          (item) =>
              (item['availability'] as List<dynamic>).contains('food_pantry') ||
              (item['availability'] as List<dynamic>).contains(
                'dollar_store',
              ) ||
              (item['availability'] as List<dynamic>).contains('convenience'),
        )
        .length;

    expect(foods.length, greaterThanOrEqualTo(120));
    expect(fastFood.length, greaterThanOrEqualTo(60));
    expect(pantryCount, greaterThanOrEqualTo(20));
    expect(dollarStoreCount, greaterThanOrEqualTo(20));
    expect(cheapNoPrep, greaterThanOrEqualTo(28));
    expect(
      fastFood.any((item) => item['name'] == "McDonald's Big Mac"),
      isTrue,
    );
    expect(
      fastFood.any((item) => item['name'] == "Chipotle Chicken Burrito Bowl"),
      isTrue,
    );
    expect(
      fastFood.any(
        (item) => item['name'] == "Domino's Ultimate Pepperoni Pizza",
      ),
      isTrue,
    );
  });
}
