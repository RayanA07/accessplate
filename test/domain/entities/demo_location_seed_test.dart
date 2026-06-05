import 'package:access_plate/domain/entities/demo_location_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy demo ZIP migrates to an unset ZIP', () {
    expect(resolvedAccessPostalCode(legacyDemoSeedPostalCode), isEmpty);
  });

  test('blank or demo ZIPs do not force a seeded search location', () {
    expect(resolvedAccessPostalCode(null), isEmpty);
    expect(resolvedAccessPostalCode(demoSeedPostalCode), isEmpty);
    expect(seededSearchLocationForPostalCode(null), isNull);
    expect(seededSearchLocationForPostalCode(demoSeedPostalCode), isNull);
  });

  test(
    'non-demo ZIPs stay user-specific and do not force the seed location',
    () {
      expect(resolvedAccessPostalCode('45202'), '45202');
      expect(seededSearchLocationForPostalCode('45202'), isNull);
    },
  );
}
