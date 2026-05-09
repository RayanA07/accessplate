enum MealType {
  breakfast('breakfast', 'Breakfast'),
  lunch('lunch', 'Lunch'),
  dinner('dinner', 'Dinner'),
  snack('snack', 'Snack'),
  any('any', 'Any time');

  const MealType(this.code, this.label);

  final String code;
  final String label;

  static MealType fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => MealType.any,
    );
  }
}
