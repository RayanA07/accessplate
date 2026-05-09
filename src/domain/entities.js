// Domain entities — immutable factories for the engine's working data.
// These mirror the freezed Dart classes in §B.1 of the spec.

import {
  Allergen, Religion, MedicalRestriction, PrepEnvironment,
  AvailabilityContext, MealType,
} from './value-objects.js';

export function createSafetyConstraints({
  allergens = [], religion = Religion.none,
  medicalAvoid = [], medicalLimit = [],
} = {}) {
  return Object.freeze({
    allergens: new Set(allergens),
    religion,
    medicalAvoid: new Set(medicalAvoid),
    medicalLimit: new Set(medicalLimit),
  });
}

export function createFeasibilityConstraints({
  maxCostPerMeal = 8,
  environment = PrepEnvironment.microwave,
  availability = [
    AvailabilityContext.grocery,
    AvailabilityContext.convenience,
  ],
} = {}) {
  return Object.freeze({
    maxCostPerMeal,
    environment,
    availability: new Set(availability),
  });
}

export function createPreferenceConstraints({
  cuisinePreference = null,
  dislikedIngredients = [],
  mealType = MealType.lunch,
  applyVariety = true,
} = {}) {
  return Object.freeze({
    cuisinePreference,
    dislikedIngredients: new Set(dislikedIngredients),
    mealType,
    applyVariety,
  });
}

export function createNutritionalTargets({
  calories = 700, proteinG = 35, carbsG = 88, fatG = 23, fiberG = 10,
  demographic = 'female_19_50',
  declaredConcerns = [], // 'anemia', 'pregnancy', 'vegetarian', etc.
} = {}) {
  return Object.freeze({
    calories, proteinG, carbsG, fatG, fiberG,
    demographic,
    declaredConcerns: new Set(declaredConcerns),
  });
}

export function createUserConstraints({
  safety = createSafetyConstraints(),
  feasibility = createFeasibilityConstraints(),
  preference = createPreferenceConstraints(),
  targets = createNutritionalTargets(),
  todayIntake = {},      // { iron_mg: 4.0, ... } — empty if no tracking
  recentlyActed = new Map(), // foodId -> Date
} = {}) {
  return Object.freeze({
    safety, feasibility, preference, targets,
    todayIntake, recentlyActed,
    fingerprint: hashConstraints({ safety, feasibility, preference, targets }),
  });
}

// Stable string fingerprint for caching.
function hashConstraints(u) {
  const parts = [
    [...u.safety.allergens].sort().join(','),
    u.safety.religion,
    [...u.safety.medicalAvoid].sort().join(','),
    [...u.safety.medicalLimit].sort().join(','),
    u.feasibility.maxCostPerMeal.toFixed(2),
    u.feasibility.environment,
    [...u.feasibility.availability].sort().join(','),
    u.preference.cuisinePreference || '',
    [...u.preference.dislikedIngredients].sort().join(','),
    u.preference.mealType,
    u.targets.calories,
    u.targets.demographic,
    [...u.targets.declaredConcerns].sort().join(','),
  ];
  return parts.join('|');
}

// A scored food carries the food, its score breakdown, and the composite.
export function createScoredFood({ food, breakdown, composite }) {
  return Object.freeze({
    food, breakdown, composite,
    displayScore: 0, // populated post-rank
  });
}
