import '../value_objects/allergen.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/dietary_style.dart';
import '../value_objects/meal_type.dart';
import '../value_objects/medical_restriction.dart';
import '../value_objects/prep_environment.dart';
import '../value_objects/religion.dart';
import 'demographics.dart';

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
    this.maxCostPerMeal = 8,
    this.environment = PrepEnvironment.microwave,
    this.availability = const {
      AvailabilityContext.grocery,
      AvailabilityContext.convenience,
    },
  });

  final double maxCostPerMeal;
  final PrepEnvironment environment;
  final Set<AvailabilityContext> availability;

  FeasibilityConstraints copyWith({
    double? maxCostPerMeal,
    PrepEnvironment? environment,
    Set<AvailabilityContext>? availability,
  }) {
    return FeasibilityConstraints(
      maxCostPerMeal: maxCostPerMeal ?? this.maxCostPerMeal,
      environment: environment ?? this.environment,
      availability: availability ?? this.availability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxCostPerMeal': maxCostPerMeal,
      'environment': environment.code,
      'availability': availability.map((value) => value.code).toList(),
    };
  }

  factory FeasibilityConstraints.fromJson(Map<String, dynamic> json) {
    final availabilityValues =
        ((json['availability'] as List<dynamic>? ?? const []))
            .map((value) => AvailabilityContext.fromCode(value as String))
            .toSet();

    return FeasibilityConstraints(
      maxCostPerMeal: (json['maxCostPerMeal'] as num?)?.toDouble() ?? 8,
      environment: PrepEnvironment.fromCode(
        json['environment'] as String? ?? PrepEnvironment.microwave.code,
      ),
      availability: availabilityValues.isEmpty
          ? const {
              AvailabilityContext.grocery,
              AvailabilityContext.convenience,
            }
          : availabilityValues,
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

class UserConstraints {
  const UserConstraints({
    required this.safety,
    required this.feasibility,
    required this.preference,
    required this.targets,
    required this.demographics,
    this.todayIntake = const {},
    this.recentlyActed = const {},
  });

  final SafetyConstraints safety;
  final FeasibilityConstraints feasibility;
  final PreferenceConstraints preference;
  final NutritionalTargets targets;
  final Demographics demographics;
  final Map<String, double> todayIntake;
  final Map<int, DateTime> recentlyActed;

  factory UserConstraints.defaults() {
    return UserConstraints(
      safety: const SafetyConstraints(),
      feasibility: const FeasibilityConstraints(),
      preference: const PreferenceConstraints(),
      targets: const NutritionalTargets(),
      demographics: const Demographics(sex: Sex.female, ageYears: 30),
    );
  }

  UserConstraints copyWith({
    SafetyConstraints? safety,
    FeasibilityConstraints? feasibility,
    PreferenceConstraints? preference,
    NutritionalTargets? targets,
    Demographics? demographics,
    Map<String, double>? todayIntake,
    Map<int, DateTime>? recentlyActed,
  }) {
    return UserConstraints(
      safety: safety ?? this.safety,
      feasibility: feasibility ?? this.feasibility,
      preference: preference ?? this.preference,
      targets: targets ?? this.targets,
      demographics: demographics ?? this.demographics,
      todayIntake: todayIntake ?? this.todayIntake,
      recentlyActed: recentlyActed ?? this.recentlyActed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'safety': safety.toJson(),
      'feasibility': feasibility.toJson(),
      'preference': preference.toJson(),
      'targets': targets.toJson(),
      'demographics': demographics.toJson(),
      'todayIntake': todayIntake,
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

    return UserConstraints(
      safety: SafetyConstraints.fromJson(
        Map<String, dynamic>.from(json['safety'] as Map? ?? const {}),
      ),
      feasibility: FeasibilityConstraints.fromJson(
        Map<String, dynamic>.from(json['feasibility'] as Map? ?? const {}),
      ),
      preference: preference.copyWith(dietaryStyle: migratedDietaryStyle),
      targets: NutritionalTargets.fromJson(
        Map<String, dynamic>.from(json['targets'] as Map? ?? const {}),
      ),
      demographics: demographics.copyWith(concerns: normalizedConcerns),
      todayIntake: (json['todayIntake'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      recentlyActed:
          (json['recentlyActed'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) =>
                MapEntry(int.parse(key), DateTime.parse(value as String)),
          ),
    );
  }
}
