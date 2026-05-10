CREATE TABLE foods (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  cuisine TEXT,
  serving_g REAL NOT NULL,
  serving_label TEXT NOT NULL,
  cost_estimate REAL NOT NULL,
  cost_confidence TEXT NOT NULL,
  prep_method TEXT NOT NULL,
  prep_time_min INTEGER NOT NULL,
  meal_types_json TEXT NOT NULL,
  availability_json TEXT NOT NULL,
  allergens_json TEXT NOT NULL,
  religion_json TEXT NOT NULL,
  medical_json TEXT NOT NULL,
  ingredients_json TEXT NOT NULL,
  source TEXT NOT NULL
);

CREATE TABLE nutrients (
  food_id INTEGER PRIMARY KEY,
  calories_kcal REAL NOT NULL,
  protein_g REAL NOT NULL,
  carbs_g REAL NOT NULL,
  fat_g REAL NOT NULL,
  saturated_fat_g REAL NOT NULL,
  fiber_g REAL NOT NULL,
  sugar_g REAL NOT NULL,
  added_sugar_g REAL NOT NULL,
  sodium_mg REAL NOT NULL,
  potassium_mg REAL NOT NULL,
  calcium_mg REAL NOT NULL,
  iron_mg REAL NOT NULL,
  magnesium_mg REAL NOT NULL,
  zinc_mg REAL NOT NULL,
  vit_a_mcg_rae REAL NOT NULL,
  vit_c_mg REAL NOT NULL,
  vit_d_mcg REAL NOT NULL,
  vit_b12_mcg REAL NOT NULL,
  folate_mcg_dfe REAL NOT NULL
);

CREATE TABLE cache_entries (
  entity_type TEXT NOT NULL,
  entity_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_accessed_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  access_count INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL,
  PRIMARY KEY(entity_type, entity_id)
);

CREATE TABLE cache_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
