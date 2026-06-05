enum MedicalRestriction {
  diabetic('diabetic', 'Diabetes-aware'),
  lowSodium('low_sodium', 'Low sodium'),
  lowPotassiumCkd('low_potassium_ckd', 'Low potassium (CKD)'),
  hypertension('hypertension', 'Hypertension'),
  highCholesterol('high_cholesterol', 'High cholesterol'),
  heartDiseaseCardiovascularRisk(
    'heart_disease_cardiovascular_risk',
    'Heart disease / cardiovascular risk',
  ),
  celiacDiseaseGlutenIntolerance(
    'celiac_gluten_intolerance',
    'Celiac disease / gluten intolerance',
  );

  const MedicalRestriction(this.code, this.label);

  final String code;
  final String label;

  static MedicalRestriction fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => MedicalRestriction.diabetic,
    );
  }
}
