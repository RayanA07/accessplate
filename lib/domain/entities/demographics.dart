enum Sex { female, male }

enum ActivityLevel {
  sedentary('Sedentary'),
  light('Light'),
  moderate('Moderate'),
  active('Active'),
  veryActive('Very active');

  const ActivityLevel(this.label);

  final String label;
}

enum HealthConcern {
  anemia('Anemia'),
  pregnancy('Pregnancy'),
  lactating('Lactating'),
  boneDensity('Bone density'),
  vegetarian('Vegetarian'),
  vegan('Vegan'),
  postoperative('Postoperative recovery'),
  hypertension('Hypertension');

  const HealthConcern(this.label);

  final String label;

  String get code {
    switch (this) {
      case HealthConcern.boneDensity:
        return 'bone_density';
      case HealthConcern.postoperative:
        return 'postoperative';
      default:
        return name;
    }
  }

  static HealthConcern fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => HealthConcern.anemia,
    );
  }
}

class Demographics {
  const Demographics({
    required this.sex,
    required this.ageYears,
    this.concerns = const {},
    this.heightCm,
    this.weightKg,
    this.activityLevel = ActivityLevel.moderate,
  });

  final Sex sex;
  final int ageYears;
  final Set<HealthConcern> concerns;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel activityLevel;

  Demographics copyWith({
    Sex? sex,
    int? ageYears,
    Set<HealthConcern>? concerns,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
  }) {
    return Demographics(
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      concerns: concerns ?? this.concerns,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  String get demographicKey {
    final sexCode = sex == Sex.female ? 'female' : 'male';
    if (concerns.contains(HealthConcern.pregnancy)) {
      return 'pregnant_19_50';
    }
    if (concerns.contains(HealthConcern.lactating)) {
      return 'lactating_19_50';
    }
    if (ageYears <= 50) {
      return '${sexCode}_19_50';
    }
    return '${sexCode}_51_70';
  }

  Map<String, dynamic> toJson() {
    return {
      'sex': sex.name,
      'ageYears': ageYears,
      'concerns': concerns.map((value) => value.code).toList(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
    };
  }

  factory Demographics.fromJson(Map<String, dynamic> json) {
    return Demographics(
      sex: json['sex'] == 'male' ? Sex.male : Sex.female,
      ageYears: (json['ageYears'] as num?)?.toInt() ?? 30,
      concerns: ((json['concerns'] as List<dynamic>? ?? const []))
          .map((value) => HealthConcern.fromCode(value as String))
          .toSet(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (value) => value.name == json['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
    );
  }
}
