import '../entities/local_access.dart';
import '../entities/user_constraints.dart';

enum SnapRestaurantMealsAvailability { none, participating, partial }

enum BenefitPolicySource { groceryStore, bundledAccessModel, unknown }

class BenefitPolicyContext {
  const BenefitPolicyContext({
    required this.stateCode,
    required this.stateName,
    required this.snapRestaurantMealsAvailability,
    required this.source,
  });

  final String? stateCode;
  final String? stateName;
  final SnapRestaurantMealsAvailability snapRestaurantMealsAvailability;
  final BenefitPolicySource source;

  bool get stateKnown => stateCode != null && stateCode!.isNotEmpty;
  bool get snapRestaurantMealsAvailable =>
      snapRestaurantMealsAvailability != SnapRestaurantMealsAvailability.none;
  bool get snapRestaurantMealsPartial =>
      snapRestaurantMealsAvailability == SnapRestaurantMealsAvailability.partial;

  String get stateDisplayName => stateName ?? stateCode ?? '';
}

class BenefitPolicyCatalog {
  const BenefitPolicyCatalog();

  BenefitPolicyContext resolve({
    required UserConstraints user,
    LocalAccessProfile? profile,
  }) {
    final storeState = _normalizeStateCode(
      user.feasibility.groceryStore?.state,
    );
    final bundledState = _normalizeStateCode(profile?.stateCode);
    final stateCode = storeState ?? bundledState;
    return BenefitPolicyContext(
      stateCode: stateCode,
      stateName: stateCode == null ? null : _stateNames[stateCode],
      snapRestaurantMealsAvailability: stateCode == null
          ? SnapRestaurantMealsAvailability.none
          : _snapRestaurantMealsStates[stateCode] ??
                SnapRestaurantMealsAvailability.none,
      source: storeState != null
          ? BenefitPolicySource.groceryStore
          : bundledState != null
          ? BenefitPolicySource.bundledAccessModel
          : BenefitPolicySource.unknown,
    );
  }

  String? _normalizeStateCode(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toUpperCase();
    return normalized.length == 2 ? normalized : null;
  }

  static const Map<String, SnapRestaurantMealsAvailability>
  _snapRestaurantMealsStates = {
    'AZ': SnapRestaurantMealsAvailability.participating,
    'CA': SnapRestaurantMealsAvailability.participating,
    'IL': SnapRestaurantMealsAvailability.partial,
    'MD': SnapRestaurantMealsAvailability.participating,
    'MA': SnapRestaurantMealsAvailability.participating,
    'MI': SnapRestaurantMealsAvailability.participating,
    'NY': SnapRestaurantMealsAvailability.participating,
    'RI': SnapRestaurantMealsAvailability.participating,
    'VA': SnapRestaurantMealsAvailability.participating,
  };

  static const Map<String, String> _stateNames = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'DC': 'District of Columbia',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming',
  };
}
