// Controlled vocabularies and small enum-like value objects.
// Mirrors §8.4 of the spec but in plain JS (frozen objects).

export const Allergen = Object.freeze({
  peanut:    'peanut',
  treeNut:   'tree_nut',
  dairy:     'dairy',
  egg:       'egg',
  soy:       'soy',
  wheat:     'wheat',
  gluten:    'gluten',
  fish:      'fish',
  shellfish: 'shellfish',
  sesame:    'sesame',
});

export const ALLERGEN_LABELS = {
  peanut: 'Peanut',
  tree_nut: 'Tree nut',
  dairy: 'Dairy / milk',
  egg: 'Egg',
  soy: 'Soy',
  wheat: 'Wheat',
  gluten: 'Gluten',
  fish: 'Fish',
  shellfish: 'Shellfish',
  sesame: 'Sesame',
};

export const Religion = Object.freeze({
  none: 'none',
  halal: 'halal',
  kosher: 'kosher',
  hinduVeg: 'hindu_veg',
  jain: 'jain',
});

export const RELIGION_LABELS = {
  none: 'No restriction',
  halal: 'Halal',
  kosher: 'Kosher',
  hindu_veg: 'Hindu vegetarian',
  jain: 'Jain',
};

export const MedicalRestriction = Object.freeze({
  diabetic: 'diabetic',
  lowSodium: 'low_sodium',
  lowPotassiumCkd: 'low_potassium_ckd',
  hypertension: 'hypertension',
});

export const MEDICAL_LABELS = {
  diabetic: 'Diabetes-aware',
  low_sodium: 'Low sodium',
  low_potassium_ckd: 'Low potassium (CKD)',
  hypertension: 'Hypertension',
};

export const PrepEnvironment = Object.freeze({
  none: 'none',
  microwave: 'microwave',
  stoveTop: 'stove',
  fullKitchen: 'full_kitchen',
});

export const PREP_LABELS = {
  none: 'No prep (ready-to-eat only)',
  microwave: 'Microwave only',
  stove: 'Stovetop + microwave',
  full_kitchen: 'Full kitchen',
};

export const AvailabilityContext = Object.freeze({
  grocery: 'grocery',
  convenience: 'convenience',
  fastFood: 'fast_food',
  foodPantry: 'food_pantry',
  dollarStore: 'dollar_store',
});

export const AVAILABILITY_LABELS = {
  grocery: 'Grocery store',
  convenience: 'Convenience store',
  fast_food: 'Fast food',
  food_pantry: 'Food pantry',
  dollar_store: 'Dollar store',
};

export const MealType = Object.freeze({
  breakfast: 'breakfast',
  lunch: 'lunch',
  dinner: 'dinner',
  snack: 'snack',
  any: 'any',
});

// Returns true if a food whose required prep is `required` is feasible
// in this environment. Environments are nested:
// fullKitchen ⊃ stoveTop ⊃ microwave ⊃ none.
export function envCanHandle(env, required) {
  switch (env) {
    case PrepEnvironment.none:        return required === 'none';
    case PrepEnvironment.microwave:   return required === 'none' || required === 'microwave';
    case PrepEnvironment.stoveTop:    return required !== 'oven';
    case PrepEnvironment.fullKitchen: return true;
    default: return false;
  }
}

export function allowedPrepMethods(env) {
  switch (env) {
    case PrepEnvironment.none:        return ['none'];
    case PrepEnvironment.microwave:   return ['none', 'microwave'];
    case PrepEnvironment.stoveTop:    return ['none', 'microwave', 'stove'];
    case PrepEnvironment.fullKitchen: return ['none', 'microwave', 'stove', 'oven'];
    default: return ['none'];
  }
}

export const RELATED_CUISINES = {
  mexican:       ['tex_mex', 'latin_american', 'central_american'],
  mediterranean: ['greek', 'italian', 'middle_eastern', 'levantine'],
  asian:         ['japanese', 'chinese', 'korean', 'thai', 'vietnamese'],
  indian:        ['south_asian', 'pakistani', 'sri_lankan'],
};
