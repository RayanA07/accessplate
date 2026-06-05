import 'store_search.dart';

const demoSeedPostalCode = '60651';
const legacyDemoSeedPostalCode = '94043';
const demoSeedLocationLabel = '4001 W Chicago Ave, Chicago, IL 60651';
const demoSeedLocation = SearchLocation(
  kind: SearchLocationKind.address,
  label: demoSeedLocationLabel,
  latitude: 41.8953,
  longitude: -87.7239,
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
  if (normalized == null ||
      normalized == legacyDemoSeedPostalCode ||
      normalized == demoSeedPostalCode) {
    return '';
  }
  return normalized;
}

SearchLocation? seededSearchLocationForPostalCode(String? postalCode) {
  return null;
}

bool isDemoSeedLocation(SearchLocation? location) {
  if (location == null) {
    return false;
  }

  return location.kind == demoSeedLocation.kind &&
      location.verification == demoSeedLocation.verification &&
      location.postalCode == demoSeedPostalCode &&
      (location.latitude - demoSeedLocation.latitude).abs() < 0.0001 &&
      (location.longitude - demoSeedLocation.longitude).abs() < 0.0001;
}
