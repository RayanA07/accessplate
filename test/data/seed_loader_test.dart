import 'package:access_plate/data/seed_loader.dart';
import 'package:access_plate/domain/entities/local_access.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
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

  test('seed loader resolves bundled local access snapshots by ZIP', () async {
    final catalog = await SeedLoader().loadLocalAccessCatalog();

    final exact = catalog.resolve('45211');
    final prefix = catalog.resolve('45299');
    final fallback = catalog.resolve('99999');

    expect(exact.matchType, LocalAccessMatchType.exact);
    expect(exact.profile.communityLabel, 'Westwood');
    expect(
      exact.profile
          .sourceFor(AvailabilityContext.grocery)
          ?.typicalTravelMinutes,
      greaterThan(
        exact.profile
                .sourceFor(AvailabilityContext.convenience)
                ?.typicalTravelMinutes ??
            0,
      ),
    );
    expect(prefix.matchType, LocalAccessMatchType.prefix);
    expect(prefix.profile.communityLabel, 'Greater Cincinnati');
    expect(prefix.profile.stateCode, 'OH');
    expect(fallback.matchType, LocalAccessMatchType.fallback);
    expect(fallback.profile.profileId, 'default_low_resource');
  });

  test(
    'exact ZIP matches carry more model confidence than prefix or fallback',
    () async {
      final catalog = await SeedLoader().loadLocalAccessCatalog();

      final exact = catalog.resolve('45211');
      final prefix = catalog.resolve('45299');
      final fallback = catalog.resolve('99999');

      expect(exact.modeledConfidence, greaterThan(prefix.modeledConfidence));
      expect(prefix.modeledConfidence, greaterThan(fallback.modeledConfidence));
      expect(exact.profile.sourceCoverageRatio, closeTo(1.0, 0.001));
      expect(catalog.resolve('90011').profile.stateCode, 'CA');
    },
  );

  test('hero demo ZIPs resolve to exact bundled snapshots', () async {
    final catalog = await SeedLoader().loadLocalAccessCatalog();
    const heroZips = ['45211', '19133', '77026', '90011', '60623'];

    for (final zip in heroZips) {
      final resolution = catalog.resolve(zip);
      expect(
        resolution.matchType,
        LocalAccessMatchType.exact,
        reason: 'Expected $zip to stay as an exact bundled demo ZIP.',
      );
      expect(
        resolution.profile.sources.isNotEmpty,
        isTrue,
        reason: 'Expected $zip to keep bundled source coverage.',
      );
    }
  });

  test(
    'ingredient availability catalog covers every bundled meal ingredient',
    () async {
      final loader = SeedLoader();
      final foods = await loader.loadFoods();
      final catalog = await loader.loadIngredientAvailabilityCatalog();

      for (final item in foods) {
        final rawIngredients = item['ingredients'] as List<dynamic>?;
        final ingredients = rawIngredients == null || rawIngredients.isEmpty
            ? _derivedIngredients(item['name'] as String)
            : rawIngredients
                  .map((value) => value.toString().trim().toLowerCase())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList(growable: false);
        for (final ingredient in ingredients) {
          expect(
            catalog.contextsFor(ingredient),
            isNotEmpty,
            reason:
                'Expected offline source coverage for ingredient $ingredient',
          );
        }
      }
    },
  );
}

List<String> _derivedIngredients(String name) {
  const stopWords = {
    'with',
    'and',
    'plain',
    'cup',
    'whole',
    'grain',
    'mixed',
    'small',
    'large',
  };
  return name
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty && token.length > 2)
      .where((token) => !stopWords.contains(token))
      .toSet()
      .toList(growable: false);
}
