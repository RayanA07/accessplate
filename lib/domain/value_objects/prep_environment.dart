enum PrepEnvironment {
  none('none', 'No prep'),
  microwave('microwave', 'Microwave only'),
  stoveTop('stove', 'Stovetop + microwave'),
  fullKitchen('full_kitchen', 'Full kitchen');

  const PrepEnvironment(this.code, this.label);

  final String code;
  final String label;

  static PrepEnvironment fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => PrepEnvironment.microwave,
    );
  }

  bool canHandle(String required) {
    switch (this) {
      case PrepEnvironment.none:
        return required == 'none';
      case PrepEnvironment.microwave:
        return required == 'none' || required == 'microwave';
      case PrepEnvironment.stoveTop:
        return required != 'oven';
      case PrepEnvironment.fullKitchen:
        return true;
    }
  }

  List<String> get allowedPrepMethods {
    switch (this) {
      case PrepEnvironment.none:
        return const ['none'];
      case PrepEnvironment.microwave:
        return const ['none', 'microwave'];
      case PrepEnvironment.stoveTop:
        return const ['none', 'microwave', 'stove'];
      case PrepEnvironment.fullKitchen:
        return const ['none', 'microwave', 'stove', 'oven'];
    }
  }
}
