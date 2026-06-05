import 'package:access_plate/domain/value_objects/merchant_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const catalog = MerchantBrandCatalog.defaults;

  group('MerchantBrandCatalog.matchKey', () {
    test('resolves a brand from a bundled meal name prefix', () {
      expect(
        catalog.matchKey('Taco Bell Power Menu Bowl', requirePrefix: true),
        'taco_bell',
      );
      expect(
        catalog.matchKey("McDonald's Egg McMuffin", requirePrefix: true),
        'mcdonalds',
      );
      expect(
        catalog.matchKey('Chick-fil-A Egg White Grill', requirePrefix: true),
        'chick_fil_a',
      );
      expect(
        catalog.matchKey("Wendy's Chili", requirePrefix: true),
        'wendys',
      );
    });

    test('does not match when the brand is only mentioned mid-name in prefix mode',
        () {
      expect(
        catalog.matchKey('Homemade taco bowl', requirePrefix: true),
        isNull,
      );
    });

    test('recognizes a brand anywhere in a store name', () {
      expect(catalog.matchKey('Taco Bell #4821'), 'taco_bell');
      expect(catalog.matchKey('TACO BELL'), 'taco_bell');
      expect(catalog.matchKey("Marco's Pizza"), 'marcos_pizza');
    });

    test('returns null for unknown or independent venues', () {
      expect(catalog.matchKey("Tony's Tacos"), isNull);
      expect(catalog.matchKey('Corner Grocery'), isNull);
      expect(catalog.matchKey(null), isNull);
      expect(catalog.matchKey(''), isNull);
    });

    test('never confuses one chain for another', () {
      // The exact reported bug: a Marco's Pizza store must not resolve as the
      // Taco Bell brand a Taco Bell meal requires.
      expect(catalog.matchKey("Marco's Pizza"), isNot('taco_bell'));
      expect(catalog.matchKey('Subway'), isNot('taco_bell'));
    });
  });

  test('brandForKey returns the display name', () {
    expect(catalog.brandForKey('taco_bell')?.displayName, 'Taco Bell');
    expect(catalog.brandForKey('mcdonalds')?.displayName, "McDonald's");
    expect(catalog.brandForKey('unknown_key'), isNull);
    expect(catalog.brandForKey(null), isNull);
  });
}
