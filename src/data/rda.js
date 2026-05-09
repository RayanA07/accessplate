// Reference daily intake values, indexed by demographic group.
// Values reflect NIH ODS / IOM DRI tables (illustrative subset).

export const DEMOGRAPHIC_KEYS = [
  'male_19_50', 'male_51_70',
  'female_19_50', 'female_51_70',
  'pregnant_19_50', 'lactating_19_50',
];

export const RDA = {
  male_19_50: {
    iron_mg: 8, calcium_mg: 1000, potassium_mg: 3400, magnesium_mg: 400,
    zinc_mg: 11, vit_a_mcg_rae: 900, vit_c_mg: 90, vit_d_mcg: 15,
    vit_b12_mcg: 2.4, folate_mcg_dfe: 400,
  },
  male_51_70: {
    iron_mg: 8, calcium_mg: 1000, potassium_mg: 3400, magnesium_mg: 420,
    zinc_mg: 11, vit_a_mcg_rae: 900, vit_c_mg: 90, vit_d_mcg: 15,
    vit_b12_mcg: 2.4, folate_mcg_dfe: 400,
  },
  female_19_50: {
    iron_mg: 18, calcium_mg: 1000, potassium_mg: 2600, magnesium_mg: 310,
    zinc_mg: 8, vit_a_mcg_rae: 700, vit_c_mg: 75, vit_d_mcg: 15,
    vit_b12_mcg: 2.4, folate_mcg_dfe: 400,
  },
  female_51_70: {
    iron_mg: 8, calcium_mg: 1200, potassium_mg: 2600, magnesium_mg: 320,
    zinc_mg: 8, vit_a_mcg_rae: 700, vit_c_mg: 75, vit_d_mcg: 15,
    vit_b12_mcg: 2.4, folate_mcg_dfe: 400,
  },
  pregnant_19_50: {
    iron_mg: 27, calcium_mg: 1000, potassium_mg: 2900, magnesium_mg: 350,
    zinc_mg: 11, vit_a_mcg_rae: 770, vit_c_mg: 85, vit_d_mcg: 15,
    vit_b12_mcg: 2.6, folate_mcg_dfe: 600,
  },
  lactating_19_50: {
    iron_mg: 9, calcium_mg: 1000, potassium_mg: 2800, magnesium_mg: 310,
    zinc_mg: 12, vit_a_mcg_rae: 1300, vit_c_mg: 120, vit_d_mcg: 15,
    vit_b12_mcg: 2.8, folate_mcg_dfe: 500,
  },
};

// Default per-meal macro target derivations.
// These match the spec's 30/35/30/5 split across breakfast/lunch/dinner/snack.
export function defaultMealTargets({ calories = 2000 } = {}) {
  return {
    breakfast: macroSplit(calories * 0.30),
    lunch:     macroSplit(calories * 0.35),
    dinner:    macroSplit(calories * 0.30),
    snack:     macroSplit(calories * 0.05),
  };
}

function macroSplit(kcal) {
  // Standard 50% carbs / 20% protein / 30% fat split, with fiber goal.
  return {
    calories: kcal,
    proteinG: (kcal * 0.20) / 4,   // 4 kcal/g
    carbsG:   (kcal * 0.50) / 4,
    fatG:     (kcal * 0.30) / 9,   // 9 kcal/g
    fiberG:   (kcal / 1000) * 14,  // 14 g per 1000 kcal
  };
}
