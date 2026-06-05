import 'package:access_plate/domain/entities/demo_location_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy Google demo ZIP migrates to the Chicago demo seed', () {
    expect(
      resolvedAccessPostalCode(legacyDemoSeedPostalCode),
      demoSeedPostalCode,
    );
  });

  test('blank or demo ZIPs resolve to the seeded Chicago search location', () {
    expect(seededSearchLocationForPostalCode(null), demoSeedLocation);
    expect(
      seededSearchLocationForPostalCode(demoSeedPostalCode),
      demoSeedLocation,
    );
  });

  test(
    'non-demo ZIPs stay user-specific and do not force the seed location',
    () {
      expect(resolvedAccessPostalCode('45202'), '45202');
      expect(seededSearchLocationForPostalCode('45202'), isNull);
    },
  );
}
