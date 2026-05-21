enum UserLanguage {
  english('en', 'English'),
  spanish('es', 'Espanol');

  const UserLanguage(this.code, this.label);

  final String code;
  final String label;

  static UserLanguage fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => UserLanguage.english,
    );
  }
}
