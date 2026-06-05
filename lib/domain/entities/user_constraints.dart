import '../value_objects/allergen.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/benefit_program.dart';
import '../value_objects/dietary_style.dart';
import '../value_objects/meal_type.dart';
import '../value_objects/medical_restriction.dart';
import '../value_objects/prep_environment.dart';
import '../value_objects/religion.dart';
import '../value_objects/transportation_mode.dart';
import '../value_objects/user_language.dart';
import 'demo_location_seed.dart';
import 'demographics.dart';
import 'grocery.dart';
import 'store_search.dart';

class SafetyConstraints {
  const SafetyConstraints({
    this.allergens = const {},
    this.religion = Religion.none,
    this.medicalAvoid = const {},
    this.medicalLimit = const {},
  });

  final Set<Allergen> allergens;
  final Religion religion;
  final Set<MedicalRestriction> medicalAvoid;
  final Set<MedicalRestriction> medicalLimit;

  Set<Allergen> get effectiveAllergens {
    final derived = <Allergen>{...allergens};
    if (medicalAvoid.contains(
      MedicalRestriction.celiacDiseaseGlutenIntolerance,
    )) {
      derived.addAll(const {Allergen.gluten, Allergen.wheat});
    }
    return derived;
  }

  SafetyConstraints copyWith({
    Set<Allergen>? allergens,
    Religion? religion,
    Set<MedicalRestriction>? medicalAvoid,
    Set<MedicalRestriction>? medicalLimit,
  }) {
    return SafetyConstraints(
      allergens: allergens ?? this.allergens,
      religion: religion ?? this.religion,
      medicalAvoid: medicalAvoid ?? this.medicalAvoid,
      medicalLimit: medicalLimit ?? this.medicalLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergens': allergens.map((value) => value.code).toList(),
      'religion': religion.code,
      'medicalAvoid': medicalAvoid.map((value) => value.code).toList(),
      'medicalLimit': medicalLimit.map((value) => value.code).toList(),
    };
  }

  factory SafetyConstraints.fromJson(Map<String, dynamic> json) {
    return SafetyConstraints(
      allergens: ((json['allergens'] as List<dynamic>? ?? const []))
          .map((value) => Allergen.fromCode(value as String))
          .toSet(),
      religion: Religion.fromCode(json['religion'] as String? ?? 'none'),
      medicalAvoid: ((json['medicalAvoid'] as List<dynamic>? ?? const []))
          .map((value) => MedicalRestriction.fromCode(value as String))
          .toSet(),
      medicalLimit: ((json['medicalLimit'] as List<dynamic>? ?? const []))
          .map((value) => MedicalRestriction.fromCode(value as String))
          .toSet(),
    );
  }
}

class FeasibilityConstraints {
  const FeasibilityConstraints({
    this.maxCostPerMeal = 20,
    this.environment = PrepEnvironment.microwave,
    this.availability = const {
      AvailabilityContext.grocery,
      AvailabilityContext.convenience,
    },
    this.groceryStore,
  });

  final double maxCostPerMeal;
  final PrepEnvironment environment;
  final Set<AvailabilityContext> availability;
  final GroceryStore? groceryStore;

  FeasibilityConstraints copyWith({
    double? maxCostPerMeal,
    PrepEnvironment? environment,
    Set<AvailabilityContext>? availability,
    GroceryStore? groceryStore,
    bool clearGroceryStore = false,
  }) {
    return FeasibilityConstraints(
      maxCostPerMeal: maxCostPerMeal ?? this.maxCostPerMeal,
      environment: environment ?? this.environment,
      availability: availability ?? this.availability,
      groceryStore: clearGroceryStore
          ? null
          : groceryStore ?? this.groceryStore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxCostPerMeal': maxCostPerMeal,
      'environment': environment.code,
      'availability': availability.map((value) => value.code).toList(),
      'groceryStore': groceryStore?.toJson(),
    };
  }

  factory FeasibilityConstraints.fromJson(Map<String, dynamic> json) {
    final availabilityValues =
        ((json['availability'] as List<dynamic>? ?? const []))
            .map((value) => AvailabilityContext.fromCode(value as String))
            .toSet();

    return FeasibilityConstraints(
      maxCostPerMeal: (json['maxCostPerMeal'] as num?)?.toDouble() ?? 20,
      environment: PrepEnvironment.fromCode(
        json['environment'] as String? ?? PrepEnvironment.microwave.code,
      ),
      availability: availabilityValues.isEmpty
          ? const {AvailabilityContext.grocery, AvailabilityContext.convenience}
          : availabilityValues,
      groceryStore: json['groceryStore'] is Map
          ? GroceryStore.fromJson(
              Map<String, dynamic>.from(json['groceryStore'] as Map),
            )
          : null,
    );
  }
}

class PreferenceConstraints {
  const PreferenceConstraints({
    this.cuisinePreference,
    this.dislikedIngredients = const {},
    this.dietaryStyle = DietaryStyle.unrestricted,
    this.mealType = MealType.lunch,
    this.applyVariety = true,
  });

  final String? cuisinePreference;
  final Set<String> dislikedIngredients;
  final DietaryStyle dietaryStyle;
  final MealType mealType;
  final bool applyVariety;

  PreferenceConstraints copyWith({
    String? cuisinePreference,
    Set<String>? dislikedIngredients,
    DietaryStyle? dietaryStyle,
    MealType? mealType,
    bool? applyVariety,
    bool clearCuisinePreference = false,
  }) {
    return PreferenceConstraints(
      cuisinePreference: clearCuisinePreference
          ? null
          : cuisinePreference ?? this.cuisinePreference,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      dietaryStyle: dietaryStyle ?? this.dietaryStyle,
      mealType: mealType ?? this.mealType,
      applyVariety: applyVariety ?? this.applyVariety,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cuisinePreference': cuisinePreference,
      'dislikedIngredients': dislikedIngredients.toList(),
      'dietaryStyle': dietaryStyle.code,
      'mealType': mealType.code,
      'applyVariety': applyVariety,
    };
  }

  factory PreferenceConstraints.fromJson(Map<String, dynamic> json) {
    return PreferenceConstraints(
      cuisinePreference: json['cuisinePreference'] as String?,
      dislikedIngredients:
          ((json['dislikedIngredients'] as List<dynamic>? ?? const []))
              .map((value) => (value as String).toLowerCase())
              .toSet(),
      dietaryStyle: DietaryStyle.fromCode(
        json['dietaryStyle'] as String? ?? DietaryStyle.unrestricted.code,
      ),
      mealType: MealType.fromCode(json['mealType'] as String? ?? 'lunch'),
      applyVariety: json['applyVariety'] as bool? ?? true,
    );
  }
}

class AccessConstraints {
  const AccessConstraints({
    this.postalCode = '',
    this.transportation = TransportationMode.walk,
    this.maxTravelMinutes = 20,
    this.benefitPrograms = const {},
    this.emergencyMode = false,
    this.language = UserLanguage.english,
    this.plainLanguage = true,
  });

  final String postalCode;
  final TransportationMode transportation;
  final int maxTravelMinutes;
  final Set<BenefitProgram> benefitPrograms;
  final bool emergencyMode;
  final UserLanguage language;
  final bool plainLanguage;

  AccessConstraints copyWith({
    String? postalCode,
    TransportationMode? transportation,
    int? maxTravelMinutes,
    Set<BenefitProgram>? benefitPrograms,
    bool? emergencyMode,
    UserLanguage? language,
    bool? plainLanguage,
  }) {
    return AccessConstraints(
      postalCode: postalCode ?? this.postalCode,
      transportation: transportation ?? this.transportation,
      maxTravelMinutes: maxTravelMinutes ?? this.maxTravelMinutes,
      benefitPrograms: benefitPrograms ?? this.benefitPrograms,
      emergencyMode: emergencyMode ?? this.emergencyMode,
      language: language ?? this.language,
      plainLanguage: plainLanguage ?? this.plainLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postalCode': postalCode,
      'transportation': transportation.code,
      'maxTravelMinutes': maxTravelMinutes,
      'benefitPrograms': benefitPrograms.map((value) => value.code).toList(),
      'emergencyMode': emergencyMode,
      'language': language.code,
      'plainLanguage': plainLanguage,
    };
  }

  factory AccessConstraints.fromJson(Map<String, dynamic> json) {
    return AccessConstraints(
      postalCode: resolvedAccessPostalCode(json['postalCode'] as String?),
      transportation: TransportationMode.fromCode(
        json['transportation'] as String? ?? TransportationMode.walk.code,
      ),
      maxTravelMinutes: (json['maxTravelMinutes'] as num?)?.toInt() ?? 20,
      benefitPrograms: ((json['benefitPrograms'] as List<dynamic>? ?? const []))
          .map((value) => BenefitProgram.fromCode(value as String))
          .toSet(),
      emergencyMode: json['emergencyMode'] as bool? ?? false,
      language: UserLanguage.fromCode(
        json['language'] as String? ?? UserLanguage.english.code,
      ),
      plainLanguage: json['plainLanguage'] as bool? ?? true,
    );
  }
}

enum PantryStockLevel {
  enough('enough', 'Have enough', 'Enough'),
  low('low', 'Running low', 'Low'),
  out('out', 'Need restock', 'Restock');

  const PantryStockLevel(this.code, this.label, this.shortLabel);

  final String code;
  final String label;
  final String shortLabel;

  static PantryStockLevel fromCode(String code) {
    return PantryStockLevel.values.firstWhere(
      (value) => value.code == code,
      orElse: () => PantryStockLevel.enough,
    );
  }
}

class PantryConstraints {
  const PantryConstraints({this.stockByItem = const {}});

  final Map<String, PantryStockLevel> stockByItem;

  Set<String> get itemsOnHand =>
      itemsFor(const {PantryStockLevel.enough, PantryStockLevel.low});
  Set<String> get enoughItems => itemsFor(const {PantryStockLevel.enough});
  Set<String> get lowStockItems => itemsFor(const {PantryStockLevel.low});
  Set<String> get restockItems => itemsFor(const {PantryStockLevel.out});
  int get trackedItemCount => stockByItem.length;

  PantryStockLevel? stockFor(String item) => stockByItem[_normalizeItem(item)];

  Set<String> itemsFor(Set<PantryStockLevel> levels) {
    return stockByItem.entries
        .where((entry) => levels.contains(entry.value))
        .map((entry) => entry.key)
        .toSet();
  }

  PantryConstraints copyWith({Map<String, PantryStockLevel>? stockByItem}) {
    return PantryConstraints(stockByItem: stockByItem ?? this.stockByItem);
  }

  PantryConstraints withItem(String item, PantryStockLevel? level) {
    final normalized = _normalizeItem(item);
    final next = <String, PantryStockLevel>{...stockByItem};
    if (normalized.isEmpty) {
      return this;
    }
    if (level == null) {
      next.remove(normalized);
    } else {
      next[normalized] = level;
    }
    return copyWith(stockByItem: next);
  }

  Map<String, dynamic> toJson() {
    final sortedKeys = stockByItem.keys.toList()..sort();
    return {
      'itemsOnHand': itemsOnHand.toList()..sort(),
      'stockByItem': {
        for (final key in sortedKeys) key: stockByItem[key]!.code,
      },
    };
  }

  factory PantryConstraints.fromJson(Map<String, dynamic> json) {
    final stockByItem = <String, PantryStockLevel>{};
    final rawStockByItem = json['stockByItem'];
    if (rawStockByItem is Map) {
      for (final entry in rawStockByItem.entries) {
        final key = _normalizeItem(entry.key.toString());
        if (key.isEmpty) {
          continue;
        }
        stockByItem[key] = PantryStockLevel.fromCode(entry.value.toString());
      }
    }

    final legacyItems = ((json['itemsOnHand'] as List<dynamic>? ?? const []))
        .map((value) => _normalizeItem(value.toString()))
        .where((value) => value.isNotEmpty);
    for (final item in legacyItems) {
      stockByItem.putIfAbsent(item, () => PantryStockLevel.enough);
    }

    return PantryConstraints(stockByItem: stockByItem);
  }

  static String _normalizeItem(String item) => item.trim().toLowerCase();
}

class NutritionalTargets {
  const NutritionalTargets({
    this.calories = 700,
    this.proteinG = 35,
    this.carbsG = 88,
    this.fatG = 23,
    this.fiberG = 10,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  NutritionalTargets copyWith({
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
  }) {
    return NutritionalTargets(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'fiberG': fiberG,
    };
  }

  factory NutritionalTargets.fromJson(Map<String, dynamic> json) {
    return NutritionalTargets(
      calories: (json['calories'] as num?)?.toDouble() ?? 700,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 35,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 88,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 23,
      fiberG: (json['fiberG'] as num?)?.toDouble() ?? 10,
    );
  }
}

class LoggedMealEntry {
  const LoggedMealEntry({
    required this.mealName,
    required this.loggedAt,
    this.caloriesKcal = 0,
    this.foodIds = const [],
  });

  final String mealName;
  final DateTime loggedAt;
  final double caloriesKcal;
  final List<int> foodIds;

  static String normalizeMealName(String rawMealName) {
    final trimmed = rawMealName.trim();
    switch (trimmed.toLowerCase()) {
      case 'convenience banana bunch':
        return 'Fresh banana and peanut butter';
      default:
        return trimmed;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'mealName': mealName,
      'loggedAt': loggedAt.toIso8601String(),
      'caloriesKcal': caloriesKcal,
      'foodIds': foodIds,
    };
  }

  static LoggedMealEntry? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final mealName = normalizeMealName(json['mealName'] as String? ?? '');
    final loggedAtRaw = json['loggedAt'] as String?;
    final loggedAt = loggedAtRaw == null
        ? null
        : DateTime.tryParse(loggedAtRaw);
    if (mealName.isEmpty || loggedAt == null) {
      return null;
    }
    final foodIds = (json['foodIds'] as List<dynamic>? ?? const [])
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>()
        .toList(growable: false);
    return LoggedMealEntry(
      mealName: mealName,
      loggedAt: loggedAt,
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble() ?? 0,
      foodIds: foodIds,
    );
  }
}

class UserConstraints {
  const UserConstraints({
    required this.safety,
    required this.feasibility,
    required this.preference,
    required this.access,
    required this.pantry,
    required this.targets,
    required this.demographics,
    this.todayIntake = const {},
    this.todayIntakeDate,
    this.loggedMeals = const [],
    this.loggedMealHistory = const [],
    this.cachedNearbyStoreLookup,
    this.recentlyActed = const {},
  });

  final SafetyConstraints safety;
  final FeasibilityConstraints feasibility;
  final PreferenceConstraints preference;
  final AccessConstraints access;
  final PantryConstraints pantry;
  final NutritionalTargets targets;
  final Demographics demographics;
  final Map<String, double> todayIntake;
  final DateTime? todayIntakeDate;
  final List<LoggedMealEntry> loggedMeals;
  final List<LoggedMealEntry> loggedMealHistory;
  final CachedNearbyStoreLookup? cachedNearbyStoreLookup;
  final Map<int, DateTime> recentlyActed;

  factory UserConstraints.defaults() {
    return UserConstraints(
      safety: const SafetyConstraints(),
      feasibility: const FeasibilityConstraints(),
      preference: const PreferenceConstraints(),
      access: const AccessConstraints(),
      pantry: const PantryConstraints(),
      targets: const NutritionalTargets(),
      demographics: const Demographics(sex: Sex.female, ageYears: 30),
    );
  }

  UserConstraints copyWith({
    SafetyConstraints? safety,
    FeasibilityConstraints? feasibility,
    PreferenceConstraints? preference,
    AccessConstraints? access,
    PantryConstraints? pantry,
    NutritionalTargets? targets,
    Demographics? demographics,
    Map<String, double>? todayIntake,
    DateTime? todayIntakeDate,
    List<LoggedMealEntry>? loggedMeals,
    List<LoggedMealEntry>? loggedMealHistory,
    CachedNearbyStoreLookup? cachedNearbyStoreLookup,
    bool clearCachedNearbyStoreLookup = false,
    Map<int, DateTime>? recentlyActed,
  }) {
    return UserConstraints(
      safety: safety ?? this.safety,
      feasibility: feasibility ?? this.feasibility,
      preference: preference ?? this.preference,
      access: access ?? this.access,
      pantry: pantry ?? this.pantry,
      targets: targets ?? this.targets,
      demographics: demographics ?? this.demographics,
      todayIntake: todayIntake ?? this.todayIntake,
      todayIntakeDate: todayIntakeDate ?? this.todayIntakeDate,
      loggedMeals: loggedMeals ?? this.loggedMeals,
      loggedMealHistory: loggedMealHistory ?? this.loggedMealHistory,
      cachedNearbyStoreLookup: clearCachedNearbyStoreLookup
          ? null
          : cachedNearbyStoreLookup ?? this.cachedNearbyStoreLookup,
      recentlyActed: recentlyActed ?? this.recentlyActed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'safety': safety.toJson(),
      'feasibility': feasibility.toJson(),
      'preference': preference.toJson(),
      'access': access.toJson(),
      'pantry': pantry.toJson(),
      'targets': targets.toJson(),
      'demographics': demographics.toJson(),
      'todayIntake': todayIntake,
      'todayIntakeDate': todayIntakeDate?.toIso8601String(),
      'loggedMeals': loggedMeals.map((entry) => entry.toJson()).toList(),
      'loggedMealHistory': loggedMealHistory
          .map((entry) => entry.toJson())
          .toList(),
      'cachedNearbyStoreLookup': cachedNearbyStoreLookup?.toJson(),
      'recentlyActed': recentlyActed.map(
        (key, value) => MapEntry(key.toString(), value.toIso8601String()),
      ),
    };
  }

  factory UserConstraints.fromJson(Map<String, dynamic> json) {
    final demographics = Demographics.fromJson(
      Map<String, dynamic>.from(json['demographics'] as Map? ?? const {}),
    );
    final preference = PreferenceConstraints.fromJson(
      Map<String, dynamic>.from(json['preference'] as Map? ?? const {}),
    );
    final migratedDietaryStyle =
        preference.dietaryStyle != DietaryStyle.unrestricted
        ? preference.dietaryStyle
        : demographics.concerns.contains(HealthConcern.vegan)
        ? DietaryStyle.vegan
        : demographics.concerns.contains(HealthConcern.vegetarian)
        ? DietaryStyle.vegetarian
        : DietaryStyle.unrestricted;
    final normalizedConcerns = demographics.concerns
        .where(
          (value) =>
              value != HealthConcern.vegetarian && value != HealthConcern.vegan,
        )
        .toSet();

    final loggedMeals = (json['loggedMeals'] as List<dynamic>? ?? const [])
        .map(LoggedMealEntry.maybeFromJson)
        .whereType<LoggedMealEntry>()
        .toList(growable: false);
    final loggedMealHistory =
        (json['loggedMealHistory'] as List<dynamic>? ?? const [])
            .map(LoggedMealEntry.maybeFromJson)
            .whereType<LoggedMealEntry>()
            .toList(growable: false);

    return UserConstraints(
      safety: SafetyConstraints.fromJson(
        Map<String, dynamic>.from(json['safety'] as Map? ?? const {}),
      ),
      feasibility: FeasibilityConstraints.fromJson(
        Map<String, dynamic>.from(json['feasibility'] as Map? ?? const {}),
      ),
      preference: preference.copyWith(dietaryStyle: migratedDietaryStyle),
      access: AccessConstraints.fromJson(
        Map<String, dynamic>.from(json['access'] as Map? ?? const {}),
      ),
      pantry: PantryConstraints.fromJson(
        Map<String, dynamic>.from(json['pantry'] as Map? ?? const {}),
      ),
      targets: NutritionalTargets.fromJson(
        Map<String, dynamic>.from(json['targets'] as Map? ?? const {}),
      ),
      demographics: demographics.copyWith(concerns: normalizedConcerns),
      todayIntake: (json['todayIntake'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      todayIntakeDate: (json['todayIntakeDate'] as String?) == null
          ? null
          : DateTime.tryParse(json['todayIntakeDate'] as String),
      loggedMeals: loggedMeals,
      loggedMealHistory: loggedMealHistory.isEmpty
          ? loggedMeals
          : loggedMealHistory,
      cachedNearbyStoreLookup: CachedNearbyStoreLookup.maybeFromJson(
        json['cachedNearbyStoreLookup'],
      ),
      recentlyActed:
          (json['recentlyActed'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) =>
                MapEntry(int.parse(key), DateTime.parse(value as String)),
          ),
    );
  }
}
