enum TransportationMode {
  limited('limited', 'Very limited travel'),
  walk('walk', 'Walking'),
  transit('transit', 'Bus or train'),
  car('car', 'Car access');

  const TransportationMode(this.code, this.label);

  final String code;
  final String label;

  static TransportationMode fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => TransportationMode.walk,
    );
  }

  bool get lowMobility =>
      this == TransportationMode.limited || this == TransportationMode.walk;
}
