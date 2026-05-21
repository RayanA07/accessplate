enum BenefitProgram {
  snap('snap', 'SNAP'),
  wic('wic', 'WIC');

  const BenefitProgram(this.code, this.label);

  final String code;
  final String label;

  static BenefitProgram fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => BenefitProgram.snap,
    );
  }
}
