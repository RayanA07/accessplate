import 'store_search.dart';

const demoSeedPostalCode = '60651';
const legacyDemoSeedPostalCode = '94043';
const demoSeedLocationLabel = '4001 W Chicago Ave, Chicago, IL 60651';
const demoSeedLocation = SearchLocation(
  kind: SearchLocationKind.address,
  label: demoSeedLocationLabel,
  latitude: 41.895282,
  longitude: -87.726242,
  verification: DataVerification.approximate,
  postalCode: demoSeedPostalCode,
  query: demoSeedLocationLabel,
  detail: 'Default Chicago food-desert demo seed for nearby-store search',
);

String? normalizePostalCode(String? value) {
  if (value == null) {
    return null;
  }
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 5 ? digits.substring(0, 5) : null;
}

String resolvedAccessPostalCode(String? currentPostalCode) {
  final normalized = normalizePostalCode(currentPostalCode);
  if (normalized == null || normalized == legacyDemoSeedPostalCode) {
    return demoSeedPostalCode;
  }
  return normalized;
}

SearchLocation? seededSearchLocationForPostalCode(String? postalCode) {
  final normalized = normalizePostalCode(postalCode);
  if (normalized == null ||
      normalized == legacyDemoSeedPostalCode ||
      normalized == demoSeedPostalCode) {
    return demoSeedLocation;
  }
  return null;
}
