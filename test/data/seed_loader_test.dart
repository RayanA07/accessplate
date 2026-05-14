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

    expect(foods.length, greaterThanOrEqualTo(100));
    expect(fastFood.length, greaterThanOrEqualTo(60));
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
