class Nutrients {
  const Nutrients({
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.saturatedFatG,
    required this.fiberG,
    required this.sugarG,
    required this.addedSugarG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.calciumMg,
    required this.ironMg,
    required this.magnesiumMg,
    required this.zincMg,
    required this.vitAMcgRae,
    required this.vitCMg,
    required this.vitDMcg,
    required this.vitB12Mcg,
    required this.folateMcgDfe,
  });

  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double saturatedFatG;
  final double fiberG;
  final double sugarG;
  final double addedSugarG;
  final double sodiumMg;
  final double potassiumMg;
  final double calciumMg;
  final double ironMg;
  final double magnesiumMg;
  final double zincMg;
  final double vitAMcgRae;
  final double vitCMg;
  final double vitDMcg;
  final double vitB12Mcg;
  final double folateMcgDfe;

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      caloriesKcal:
          (json['calories'] as num?)?.toDouble() ??
          (json['calories_kcal'] as num?)?.toDouble() ??
          0,
      proteinG:
          (json['protein'] as num?)?.toDouble() ??
          (json['protein_g'] as num?)?.toDouble() ??
          0,
      carbsG:
          (json['carbs'] as num?)?.toDouble() ??
          (json['carbs_g'] as num?)?.toDouble() ??
          0,
      fatG:
          (json['fat'] as num?)?.toDouble() ??
          (json['fat_g'] as num?)?.toDouble() ??
          0,
      saturatedFatG:
          (json['saturatedFat'] as num?)?.toDouble() ??
          (json['saturated_fat_g'] as num?)?.toDouble() ??
          0,
      fiberG:
          (json['fiber'] as num?)?.toDouble() ??
          (json['fiber_g'] as num?)?.toDouble() ??
          0,
      sugarG:
          (json['sugar'] as num?)?.toDouble() ??
          (json['sugar_g'] as num?)?.toDouble() ??
          0,
      addedSugarG:
          (json['addedSugar'] as num?)?.toDouble() ??
          (json['added_sugar_g'] as num?)?.toDouble() ??
          0,
      sodiumMg:
          (json['sodium'] as num?)?.toDouble() ??
          (json['sodium_mg'] as num?)?.toDouble() ??
          0,
      potassiumMg:
          (json['potassium'] as num?)?.toDouble() ??
          (json['potassium_mg'] as num?)?.toDouble() ??
          0,
      calciumMg:
          (json['calcium'] as num?)?.toDouble() ??
          (json['calcium_mg'] as num?)?.toDouble() ??
          0,
      ironMg:
          (json['iron'] as num?)?.toDouble() ??
          (json['iron_mg'] as num?)?.toDouble() ??
          0,
      magnesiumMg:
          (json['magnesium'] as num?)?.toDouble() ??
          (json['magnesium_mg'] as num?)?.toDouble() ??
          0,
      zincMg:
          (json['zinc'] as num?)?.toDouble() ??
          (json['zinc_mg'] as num?)?.toDouble() ??
          0,
      vitAMcgRae:
          (json['vitA'] as num?)?.toDouble() ??
          (json['vit_a_mcg_rae'] as num?)?.toDouble() ??
          0,
      vitCMg:
          (json['vitC'] as num?)?.toDouble() ??
          (json['vit_c_mg'] as num?)?.toDouble() ??
          0,
      vitDMcg:
          (json['vitD'] as num?)?.toDouble() ??
          (json['vit_d_mcg'] as num?)?.toDouble() ??
          0,
      vitB12Mcg:
          (json['vitB12'] as num?)?.toDouble() ??
          (json['vit_b12_mcg'] as num?)?.toDouble() ??
          0,
      folateMcgDfe:
          (json['folate'] as num?)?.toDouble() ??
          (json['folate_mcg_dfe'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories_kcal': caloriesKcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'saturated_fat_g': saturatedFatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'added_sugar_g': addedSugarG,
      'sodium_mg': sodiumMg,
      'potassium_mg': potassiumMg,
      'calcium_mg': calciumMg,
      'iron_mg': ironMg,
      'magnesium_mg': magnesiumMg,
      'zinc_mg': zincMg,
      'vit_a_mcg_rae': vitAMcgRae,
      'vit_c_mg': vitCMg,
      'vit_d_mcg': vitDMcg,
      'vit_b12_mcg': vitB12Mcg,
      'folate_mcg_dfe': folateMcgDfe,
    };
  }

  Map<String, double> toIntakeMap() {
    return {
      'calories_kcal': caloriesKcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'saturated_fat_g': saturatedFatG,
      'added_sugar_g': addedSugarG,
      'sodium_mg': sodiumMg,
      'potassium_mg': potassiumMg,
      'calcium_mg': calciumMg,
      'iron_mg': ironMg,
      'magnesium_mg': magnesiumMg,
      'zinc_mg': zincMg,
      'vit_a_mcg_rae': vitAMcgRae,
      'vit_c_mg': vitCMg,
      'vit_d_mcg': vitDMcg,
      'vit_b12_mcg': vitB12Mcg,
      'folate_mcg_dfe': folateMcgDfe,
    };
  }

  Nutrients plus(Nutrients other) {
    return Nutrients(
      caloriesKcal: caloriesKcal + other.caloriesKcal,
      proteinG: proteinG + other.proteinG,
      carbsG: carbsG + other.carbsG,
      fatG: fatG + other.fatG,
      saturatedFatG: saturatedFatG + other.saturatedFatG,
      fiberG: fiberG + other.fiberG,
      sugarG: sugarG + other.sugarG,
      addedSugarG: addedSugarG + other.addedSugarG,
      sodiumMg: sodiumMg + other.sodiumMg,
      potassiumMg: potassiumMg + other.potassiumMg,
      calciumMg: calciumMg + other.calciumMg,
      ironMg: ironMg + other.ironMg,
      magnesiumMg: magnesiumMg + other.magnesiumMg,
      zincMg: zincMg + other.zincMg,
      vitAMcgRae: vitAMcgRae + other.vitAMcgRae,
      vitCMg: vitCMg + other.vitCMg,
      vitDMcg: vitDMcg + other.vitDMcg,
      vitB12Mcg: vitB12Mcg + other.vitB12Mcg,
      folateMcgDfe: folateMcgDfe + other.folateMcgDfe,
    );
  }

  static const zero = Nutrients(
    caloriesKcal: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
    saturatedFatG: 0,
    fiberG: 0,
    sugarG: 0,
    addedSugarG: 0,
    sodiumMg: 0,
    potassiumMg: 0,
    calciumMg: 0,
    ironMg: 0,
    magnesiumMg: 0,
    zincMg: 0,
    vitAMcgRae: 0,
    vitCMg: 0,
    vitDMcg: 0,
    vitB12Mcg: 0,
    folateMcgDfe: 0,
  );
}
