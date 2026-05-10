enum DietaryStyle {
  unrestricted(
    'unrestricted',
    'No diet filter',
    'Include all foods that fit your safety and feasibility settings.',
  ),
  vegetarian(
    'vegetarian',
    'Vegetarian',
    'Exclude meat, poultry, seafood, and fish.',
  ),
  vegan(
    'vegan',
    'Vegan',
    'Exclude all animal-derived foods, including dairy and eggs.',
  );

  const DietaryStyle(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  String? get microPriorityCode {
    switch (this) {
      case DietaryStyle.unrestricted:
        return null;
      case DietaryStyle.vegetarian:
        return 'vegetarian';
      case DietaryStyle.vegan:
        return 'vegan';
    }
  }

  static DietaryStyle fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => DietaryStyle.unrestricted,
    );
  }
}
