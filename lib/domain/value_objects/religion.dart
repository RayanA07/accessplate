enum Religion {
  none('none', 'No restriction'),
  halal('halal', 'Halal'),
  kosher('kosher', 'Kosher'),
  hinduVeg('hindu_veg', 'Hindu vegetarian'),
  jain('jain', 'Jain');

  const Religion(this.code, this.label);

  final String code;
  final String label;

  static Religion fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => Religion.none,
    );
  }
}
