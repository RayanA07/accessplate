import 'store_search.dart';

const demoSeedPostalCode = '60624';
const legacyDemoSeedPostalCode = '94043';
const legacyDemoSeedPostalCode2 = '60651';
const demoSeedLocationLabel = '3758 W Madison St, Chicago, IL 60624';
const demoSeedLocation = SearchLocation(
  kind: SearchLocationKind.address,
  label: demoSeedLocationLabel,
  latitude: 41.8798,
  longitude: -87.7272,
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
      normalized == legacyDemoSeedPostalCode2 ||
      normalized == demoSeedPostalCode) {
    return '';
  }
  return normalized;
}

SearchLocation? seededSearchLocationForPostalCode(String? postalCode) {
  return null;
}
