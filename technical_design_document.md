# Technical Design Document
## Constraint-Aware Nutrition Decision Support App — Flutter/Dart Android Prototype

**Project:** NIH DEBUT Challenge 2026 — NIMHD Healthcare Technologies for Low-Resource Settings Prize  
**Document type:** Technical specification for Codex-assisted implementation  
**Primary platform:** Android mobile app built with Flutter and Dart  
**Secondary platform:** iOS-compatible architecture, but Android is the v1 delivery target  
**Status:** Rewritten technical design replacing the older fully-offline/web-app-leaning design

---

## 0. Codex Implementation Brief

This document is meant to be pasted into Codex or used as the source-of-truth implementation spec. The implementation should be a **Flutter/Dart Android app**, not a web app, PWA, React app, or server-first system.

### Build the prototype in this order

1. Create a Flutter app with the folder structure in Section 5.
2. Implement local SQLite storage for user profile, cached food items, cached restaurants, cached menu items, and cache metadata.
3. Implement mock API adapters first, using local JSON fixtures that behave like real network responses.
4. Implement the decision engine as pure Dart: filters, scoring, explanations, and ranked outputs.
5. Implement the core screens: onboarding, search, restaurant menu view, recommendation results, explanation detail, and settings/cache manager.
6. Add real API adapters only after the UI and mock data path work end-to-end.
7. Add tests around the decision engine and cache eviction rules.

### Codex rules

- Do **not** build a web app.
- Do **not** require a backend server for v1.
- Do **not** assume the entire food universe lives on-device.
- Do **not** put API or database logic directly in widgets.
- Do **not** run an LLM in the user-facing recommendation path.
- Do **not** overbuild authentication, accounts, cloud sync, clinician dashboards, or social features.
- Use simple, readable Dart classes and repository interfaces.
- Prefer deterministic code over clever code.
- Favor mockable interfaces over hard-coded vendor APIs.
- Keep Android permissions minimal: network only unless a later feature explicitly requires location or camera.

### Core architectural correction

The previous design treated the app as **fully offline** with a large bundled food database. That is not realistic for a mobile prototype because food, packaged-product, and restaurant-menu datasets are too large and too frequently updated to ship fully on-device.

The corrected design is:

> The app is **online-capable and cache-first**, not fully offline. It uses API calls when online, normalizes returned foods and restaurant menu items into a local SQLite cache, and keeps frequently accessed items available offline. Cached items that are not used again for 90 days are evicted to keep storage small.

This gives users the benefit of large external databases without forcing the phone to store an enormous database.

---

## 1. Product Thesis

Diet apps usually answer the wrong question. They ask users to log what they already ate. This app answers a forward-looking decision question:

> Given my restrictions, budget, available food source, cooking setup, and nutrition goals, what is the best food decision I can make right now?

That question is a **constraint-aware ranking problem**. The app should not act like a generic calorie tracker. It should act like a practical decision-support tool for users whose choices are constrained by cost, medical needs, religion, allergies, preparation access, restaurant availability, and limited time.

The app uses a deterministic recommendation engine:

1. Remove unsafe foods.
2. Remove infeasible foods.
3. Soft-rank by preferences.
4. Score nutrition quality and goal fit.
5. Explain the recommendation in plain language.

The intelligence is not in a black-box model. It is in the constraint model, scoring function, cache design, and explanation layer.

---

## 2. Revised Goals and Non-Goals

## 2.1 Goals

### G1. Android-first Flutter implementation

Build the v1 prototype as a Flutter/Dart Android app. The app should run smoothly on common low-end and mid-range Android phones. iOS compatibility is acceptable if it falls out naturally from Flutter, but Android is the delivery target.

### G2. Online API access with local cache

The app should call food/product/restaurant APIs when online. Returned items should be normalized into local app models and saved to SQLite. The cache is not a mirror of the entire upstream database; it is a practical working set of foods and menus the user has searched, selected, or repeatedly viewed.

### G3. 90-day unused cache eviction

Cached food and restaurant-menu entries have a `last_accessed_at` timestamp. If an item has not been accessed in 90 days, it is eligible for deletion. Frequently used restaurants, such as Taco Bell, remain cached because the user keeps accessing them. Rare one-off product searches naturally age out.

### G4. Restaurant menu prefetching

When a user searches/selects a restaurant, the app should fetch and cache the restaurant metadata and menu items together. The goal is to avoid making the user search item-by-item. If the user opens Taco Bell, the app should have the menu ready or be actively fetching it.

### G5. Offline degraded mode

The app should still be useful without internet, but only for cached data. Offline mode should support:

- Viewing profile/settings.
- Viewing previously cached restaurants and foods.
- Re-running recommendations over cached foods.
- Seeing a clear message that new searches require internet.

The app should **not** claim that all foods or all restaurant menus are available offline.

### G6. Safety-first recommendations

No recommended item should violate user-declared hard constraints: allergies, religious restrictions, major medical exclusions, or explicitly disliked ingredients marked as “never show.” Safety filters must run before scoring.

### G7. Explainable rankings

Each recommendation must explain why it ranked well and what tradeoffs exist. Example:

> “Recommended because it fits your $8 budget, is available at Taco Bell, has high protein for the calories, and avoids your dairy restriction. Tradeoff: sodium is high.”

### G8. LLM-readable implementation structure

The codebase should be easy for Codex or another coding model to extend. That means clear folder boundaries, descriptive class names, small files, explicit interfaces, and simple data-transfer objects.

---

## 2.2 Non-Goals

### NG1. Fully offline global database

The app will not ship the full USDA, Open Food Facts, branded-food, and restaurant-menu universe inside the APK. This would bloat the app and still become stale.

### NG2. Backend server

V1 does not require our own backend. API adapters call external services directly or use local mock fixtures during prototype development. A backend may be added later for API-key protection, aggregation, pricing, or analytics, but not for the first mockable prototype.

### NG3. Full calorie tracker

The app may optionally let a user mark “I ate this,” but a full diary, barcode-history tracker, and weekly dashboard are not v1 priorities.

### NG4. Medical diagnosis or prescription

The app is decision support, not medical advice. It filters and ranks foods according to user-declared constraints. It does not diagnose disease or prescribe a diet.

### NG5. LLM-generated nutrition advice at runtime

Do not put a language model in the recommendation path. Runtime recommendations must be deterministic, testable, and explainable.

### NG6. Perfect restaurant coverage

Restaurant APIs and menu datasets are incomplete and inconsistent. V1 should handle partial data gracefully and support mock/curated restaurant fixtures for demo reliability.

---

## 3. System Overview

## 3.1 User flow

### First launch

1. User opens the Android app.
2. User completes onboarding:
    - allergies
    - religious restrictions
    - medical constraints
    - budget
    - cooking/prep environment
    - nutrition goals
    - preferred food contexts: grocery, packaged food, fast food, restaurant
3. App saves the profile locally.
4. User lands on the home screen.

### Normal online use

1. User searches for a food, product, or restaurant.
2. App checks local cache first.
3. If cached data is fresh enough, show it immediately.
4. If online, call the relevant API adapter in the background.
5. Normalize returned foods/menu items.
6. Save results to SQLite with `last_accessed_at` and `expires_at`.
7. Run the decision engine over the candidate set.
8. Show ranked recommendations with explanations.

### Offline use

1. App detects no usable internet.
2. Search screen clearly says new searches are unavailable offline.
3. Cached restaurants/foods remain searchable.
4. Decision engine can still rank cached candidates.
5. UI labels results as “from saved data.”

---

## 3.2 Data flow

```text
User input
  ↓
Flutter UI screens
  ↓
Riverpod providers / use cases
  ↓
Repository layer
  ├── Local SQLite cache lookup
  ├── Network API adapter call when online
  └── Normalization into domain models
  ↓
Decision engine
  ├── L1 safety filters
  ├── L2 feasibility filters
  ├── L3 preference matching
  └── L4 nutrition scoring
  ↓
Ranked Recommendation objects
  ↓
Explanation cards in UI
```

---

## 4. Technology Stack

## 4.1 Framework

Use **Flutter with Dart**.

Reasons:

- Single codebase for Android-first development with later iOS portability.
- Strong UI toolkit for fast mockup iteration.
- Dart type system is readable for Codex and human contributors.
- Flutter supports native Android release builds without needing a web runtime.

## 4.2 Android compatibility target

Recommended v1 settings:

```gradle
minSdk = 23
compileSdk = 35
targetSdk = 35
```

Rationale:

- `targetSdk` should satisfy current Google Play submission requirements.
- `minSdk 23` supports older Android devices while avoiding extremely old OS constraints.
- If a package requires a higher minimum SDK, raise `minSdk` only when necessary.

Do not request location permission in v1 unless “restaurants near me” is explicitly implemented. Restaurant search can start with text search.

Required Android permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Optional later permissions:

```xml
<!-- Only if barcode scanning is implemented -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Only if nearby restaurant search is implemented -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 4.3 State management

Use **Riverpod**.

Use Riverpod providers for:

- user profile state
- connectivity state
- search state
- selected restaurant state
- recommendation state
- cache maintenance state

Avoid placing business logic inside widgets.

## 4.4 Local storage

Use **SQLite through `sqflite`** for the prototype.

Reasons:

- SQLite is stable and familiar.
- `sqflite` keeps implementation simple.
- SQL tables map naturally to cached foods, restaurants, menu items, and metadata.
- It is easier for Codex to generate and debug than heavy codegen storage frameworks.

If the project later needs fully reactive SQL streams and stricter compile-time query safety, migrate to Drift. Do not start with Drift unless the team is comfortable with code generation.

## 4.5 HTTP client

Use **Dio**.

Reasons:

- Request cancellation.
- Timeouts.
- Interceptors.
- Cleaner API-client structure than raw `http` for a multi-adapter app.

## 4.6 Connectivity

Use **connectivity_plus** only as a first signal. Do not treat it as proof that the internet works. After connectivity says Wi-Fi/mobile is present, the API client should still handle failed requests, captive portals, DNS errors, and timeouts.

## 4.7 Serialization

Use manual `fromJson`/`toJson` methods at first, or `json_serializable` if the model count grows. For a vibe-coded prototype, avoid unnecessary codegen until the domain model stabilizes.

## 4.8 Suggested dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: any
  sqflite: any
  path: any
  path_provider: any
  dio: any
  connectivity_plus: any
  intl: any

  # optional if using codegen later
  json_annotation: any
  freezed_annotation: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: any
  mocktail: any

  # optional if using codegen later
  build_runner: any
  json_serializable: any
  freezed: any
```

Codex should not invent exact version numbers. Use `flutter pub add` or check current package compatibility before pinning.

---

## 5. Project Folder Structure

Use this structure exactly unless there is a strong reason not to:

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── connectivity_service.dart
│   │   └── network_result.dart
│   ├── theme/
│   └── utils/
├── presentation/
│   ├── screens/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── search/
│   │   ├── restaurant/
│   │   ├── recommendations/
│   │   ├── explanation/
│   │   └── settings/
│   ├── widgets/
│   └── providers/
├── application/
│   ├── use_cases/
│   │   ├── search_foods_use_case.dart
│   │   ├── fetch_restaurant_menu_use_case.dart
│   │   ├── recommend_foods_use_case.dart
│   │   ├── update_profile_use_case.dart
│   │   └── evict_stale_cache_use_case.dart
│   └── dto/
├── domain/
│   ├── entities/
│   │   ├── food_item.dart
│   │   ├── restaurant.dart
│   │   ├── menu_item.dart
│   │   ├── nutrient_profile.dart
│   │   ├── user_profile.dart
│   │   ├── constraints.dart
│   │   ├── recommendation.dart
│   │   └── explanation.dart
│   ├── engine/
│   │   ├── decision_engine.dart
│   │   ├── filters/
│   │   │   ├── safety_filter.dart
│   │   │   ├── feasibility_filter.dart
│   │   │   └── preference_filter.dart
│   │   ├── scoring/
│   │   │   ├── macro_scorer.dart
│   │   │   ├── micro_scorer.dart
│   │   │   ├── penalty_scorer.dart
│   │   │   └── composite_scorer.dart
│   │   └── recommendation_explainer.dart
│   └── repositories/
│       ├── food_repository.dart
│       ├── restaurant_repository.dart
│       ├── profile_repository.dart
│       └── cache_repository.dart
├── data/
│   ├── local/
│   │   ├── app_database.dart
│   │   ├── schema.sql
│   │   ├── cache_dao.dart
│   │   ├── food_dao.dart
│   │   ├── restaurant_dao.dart
│   │   └── profile_dao.dart
│   ├── remote/
│   │   ├── food_api_adapter.dart
│   │   ├── restaurant_api_adapter.dart
│   │   ├── mock_food_api_adapter.dart
│   │   └── mock_restaurant_api_adapter.dart
│   ├── mappers/
│   │   ├── food_mapper.dart
│   │   ├── restaurant_mapper.dart
│   │   └── nutrient_mapper.dart
│   └── repositories/
│       ├── food_repository_impl.dart
│       ├── restaurant_repository_impl.dart
│       ├── profile_repository_impl.dart
│       └── cache_repository_impl.dart
└── fixtures/
    ├── mock_food_search.json
    ├── mock_restaurant_search.json
    └── mock_taco_bell_menu.json

test/
├── domain/
│   ├── filters/
│   ├── scoring/
│   └── decision_engine_test.dart
├── data/
│   ├── cache_repository_test.dart
│   └── mappers_test.dart
└── widget/
```

---

## 6. Local Cache Design

## 6.1 Cache principle

The app stores only what the user is likely to reuse:

- searched foods
- selected foods
- frequently used products
- searched restaurants
- selected restaurant menus
- recommendation results derived from cached items

The app does **not** store huge upstream datasets.

## 6.2 Cache lifecycle

Each cached item has:

- `created_at`
- `updated_at`
- `last_accessed_at`
- `expires_at`
- `access_count`
- `source`
- `source_id`
- `sync_status`

Cache rules:

1. Every time a food/menu/restaurant is shown or used in a recommendation, update `last_accessed_at` and increment `access_count`.
2. Items unused for 90 days are eligible for deletion.
3. Restaurant records and menu items should be evicted together only when the restaurant itself has not been accessed for 90 days.
4. Recently accessed items remain even if they are technically stale.
5. Stale data can be shown offline but should be labeled.
6. Online mode should refresh stale data in the background.

## 6.3 Fresh, stale, and expired definitions

```text
fresh:   current date <= expires_at
stale:   current date > expires_at but last_accessed_at < 90 days ago
expired: last_accessed_at >= 90 days ago
```

Use stale cached data when:

- device is offline
- API request fails
- API rate limit occurs
- user wants quick results while refresh runs in background

Do not use expired data unless the user explicitly opens an archive/debug view.

## 6.4 Cache eviction timing

Run eviction:

- on app launch, after first frame
- once per day at most
- after large menu/API imports
- manually from Settings → Storage → Clean cache

Do not run eviction on every query.

## 6.5 Cache size target

V1 target:

- Normal user cache: under 50 MB.
- Heavy user cache: under 150 MB.
- Warn user above 250 MB.

These are soft targets, not hard crashes.

---

## 7. SQLite Schema

Save this as `lib/data/local/schema.sql`.

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS user_profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  payload_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS cached_food_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  source_id TEXT NOT NULL,
  name TEXT NOT NULL,
  brand TEXT,
  restaurant_id INTEGER,
  category TEXT,
  serving_label TEXT,
  serving_size_g REAL,
  calories_kcal REAL,
  protein_g REAL,
  carbs_g REAL,
  fat_g REAL,
  saturated_fat_g REAL,
  fiber_g REAL,
  sugar_g REAL,
  added_sugar_g REAL,
  sodium_mg REAL,
  potassium_mg REAL,
  calcium_mg REAL,
  iron_mg REAL,
  magnesium_mg REAL,
  zinc_mg REAL,
  vitamin_a_mcg REAL,
  vitamin_c_mg REAL,
  vitamin_d_mcg REAL,
  vitamin_b12_mcg REAL,
  folate_mcg REAL,
  ingredients_text TEXT,
  allergens_json TEXT,
  diet_tags_json TEXT,
  medical_tags_json TEXT,
  prep_required TEXT NOT NULL DEFAULT 'none',
  estimated_cost_usd REAL,
  confidence TEXT NOT NULL DEFAULT 'medium',
  raw_payload_json TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_accessed_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  access_count INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'cached',
  UNIQUE(source, source_id)
);

CREATE INDEX IF NOT EXISTS idx_cached_food_name ON cached_food_items(name);
CREATE INDEX IF NOT EXISTS idx_cached_food_source ON cached_food_items(source, source_id);
CREATE INDEX IF NOT EXISTS idx_cached_food_restaurant ON cached_food_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_cached_food_last_accessed ON cached_food_items(last_accessed_at);
CREATE INDEX IF NOT EXISTS idx_cached_food_expires ON cached_food_items(expires_at);

CREATE TABLE IF NOT EXISTS cached_restaurants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  source_id TEXT NOT NULL,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  cuisine TEXT,
  website_url TEXT,
  raw_payload_json TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_accessed_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  access_count INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'cached',
  UNIQUE(source, source_id)
);

CREATE INDEX IF NOT EXISTS idx_restaurant_name ON cached_restaurants(normalized_name);
CREATE INDEX IF NOT EXISTS idx_restaurant_last_accessed ON cached_restaurants(last_accessed_at);

CREATE TABLE IF NOT EXISTS cached_menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  restaurant_id INTEGER NOT NULL REFERENCES cached_restaurants(id) ON DELETE CASCADE,
  food_item_id INTEGER NOT NULL REFERENCES cached_food_items(id) ON DELETE CASCADE,
  menu_section TEXT,
  is_available INTEGER NOT NULL DEFAULT 1,
  price_estimate_usd REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_accessed_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  UNIQUE(restaurant_id, food_item_id)
);

CREATE INDEX IF NOT EXISTS idx_menu_restaurant ON cached_menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_food ON cached_menu_items(food_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_last_accessed ON cached_menu_items(last_accessed_at);

CREATE TABLE IF NOT EXISTS search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  query TEXT NOT NULL,
  search_type TEXT NOT NULL,
  selected_result_source TEXT,
  selected_result_id TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS recommendation_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  context_json TEXT NOT NULL,
  recommendation_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS cache_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

## 8. Domain Entities

Keep domain entities pure Dart. They should not import Flutter, SQLite, or Dio.

## 8.1 FoodItem

```dart
class FoodItem {
  final int? localId;
  final String source;
  final String sourceId;
  final String name;
  final String? brand;
  final String? category;
  final String? servingLabel;
  final double? servingSizeG;
  final NutrientProfile nutrients;
  final String? ingredientsText;
  final Set<String> allergens;
  final Set<String> dietTags;
  final Set<String> medicalTags;
  final PrepRequired prepRequired;
  final double? estimatedCostUsd;
  final DataConfidence confidence;
  final DateTime lastAccessedAt;
  final DateTime expiresAt;

  const FoodItem({
    required this.localId,
    required this.source,
    required this.sourceId,
    required this.name,
    required this.brand,
    required this.category,
    required this.servingLabel,
    required this.servingSizeG,
    required this.nutrients,
    required this.ingredientsText,
    required this.allergens,
    required this.dietTags,
    required this.medicalTags,
    required this.prepRequired,
    required this.estimatedCostUsd,
    required this.confidence,
    required this.lastAccessedAt,
    required this.expiresAt,
  });
}
```

## 8.2 NutrientProfile

```dart
class NutrientProfile {
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double saturatedFatG;
  final double fiberG;
  final double sugarG;
  final double? addedSugarG;
  final double sodiumMg;
  final double potassiumMg;
  final double calciumMg;
  final double ironMg;
  final double magnesiumMg;
  final double zincMg;
  final double vitaminAMcg;
  final double vitaminCMg;
  final double vitaminDMcg;
  final double vitaminB12Mcg;
  final double folateMcg;

  const NutrientProfile({
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
    required this.vitaminAMcg,
    required this.vitaminCMg,
    required this.vitaminDMcg,
    required this.vitaminB12Mcg,
    required this.folateMcg,
  });
}
```

## 8.3 Restaurant

```dart
class Restaurant {
  final int? localId;
  final String source;
  final String sourceId;
  final String name;
  final String normalizedName;
  final String? cuisine;
  final DateTime lastAccessedAt;
  final DateTime expiresAt;

  const Restaurant({
    required this.localId,
    required this.source,
    required this.sourceId,
    required this.name,
    required this.normalizedName,
    required this.cuisine,
    required this.lastAccessedAt,
    required this.expiresAt,
  });
}
```

## 8.4 UserProfile

```dart
class UserProfile {
  final Set<String> allergens;
  final Set<String> religiousRestrictions;
  final Set<String> medicalRestrictionsAvoid;
  final Set<String> medicalRestrictionsLimit;
  final double? maxMealBudgetUsd;
  final PrepEnvironment prepEnvironment;
  final NutritionTargets targets;
  final Set<String> dislikedIngredients;
  final Set<String> preferredCuisines;

  const UserProfile({
    required this.allergens,
    required this.religiousRestrictions,
    required this.medicalRestrictionsAvoid,
    required this.medicalRestrictionsLimit,
    required this.maxMealBudgetUsd,
    required this.prepEnvironment,
    required this.targets,
    required this.dislikedIngredients,
    required this.preferredCuisines,
  });
}
```

## 8.5 Recommendation

```dart
class Recommendation {
  final FoodItem food;
  final double score;
  final double displayScore0To100;
  final List<String> topReasons;
  final List<String> tradeoffs;
  final Explanation explanation;

  const Recommendation({
    required this.food,
    required this.score,
    required this.displayScore0To100,
    required this.topReasons,
    required this.tradeoffs,
    required this.explanation,
  });
}
```

---

## 9. Repository Interfaces

Interfaces live in `domain/repositories`. Implementations live in `data/repositories`.

## 9.1 FoodRepository

```dart
abstract class FoodRepository {
  Future<List<FoodItem>> searchFoods(String query);
  Future<List<FoodItem>> searchCachedFoods(String query);
  Future<List<FoodItem>> fetchFoodsFromApi(String query);
  Future<void> upsertFoodItems(List<FoodItem> items);
  Future<void> markFoodAccessed(int localFoodId);
  Future<List<FoodItem>> getCandidateFoodsFromCache(UserProfile profile);
}
```

Expected behavior:

- `searchFoods` checks local cache first.
- If online, it fetches API data, saves normalized results, and merges with cached results.
- If offline, it returns cached results only.
- It should never throw raw Dio/SQLite exceptions to the UI. Return typed failures or empty states.

## 9.2 RestaurantRepository

```dart
abstract class RestaurantRepository {
  Future<List<Restaurant>> searchRestaurants(String query);
  Future<Restaurant?> getCachedRestaurantByName(String normalizedName);
  Future<List<FoodItem>> getCachedMenuItems(int restaurantLocalId);
  Future<List<FoodItem>> fetchAndCacheRestaurantMenu(Restaurant restaurant);
  Future<void> markRestaurantAccessed(int restaurantLocalId);
}
```

Expected behavior:

- Searching “Taco Bell” should return cached restaurant data immediately if present.
- If online, refresh restaurant metadata in the background.
- Selecting a restaurant triggers menu prefetch.
- Menu items are stored as normal `FoodItem` records linked through `cached_menu_items`.

## 9.3 CacheRepository

```dart
abstract class CacheRepository {
  Future<void> evictExpiredItems({int unusedDays = 90});
  Future<int> estimateCacheSizeBytes();
  Future<CacheStats> getCacheStats();
  Future<void> clearAllCachedFoods();
  Future<void> clearRestaurantCache(int restaurantLocalId);
}
```

---

## 10. API Adapter Design

## 10.1 Adapter principle

External nutrition APIs differ in naming, nutrient units, serving sizes, restaurant coverage, allergen fields, and data quality. Do not let vendor-specific JSON leak into the domain layer.

Each adapter should return a neutral DTO, then the mapper converts DTOs into domain entities.

```text
Dio response JSON
  ↓
Remote DTO
  ↓
Mapper / Normalizer
  ↓
FoodItem / Restaurant / MenuItem
  ↓
SQLite cache
```

## 10.2 FoodApiAdapter

```dart
abstract class FoodApiAdapter {
  Future<List<RemoteFoodDto>> searchFoods(String query);
  Future<RemoteFoodDto?> getFoodById(String sourceId);
}
```

Implement first:

```dart
class MockFoodApiAdapter implements FoodApiAdapter {
  // Reads fixtures/mock_food_search.json and simulates network delay.
}
```

Later implementations may include:

- USDA FoodData Central adapter
- Open Food Facts adapter
- branded-food API adapter
- barcode adapter

## 10.3 RestaurantApiAdapter

```dart
abstract class RestaurantApiAdapter {
  Future<List<RemoteRestaurantDto>> searchRestaurants(String query);
  Future<List<RemoteMenuItemDto>> fetchMenu(String restaurantSourceId);
}
```

Implement first:

```dart
class MockRestaurantApiAdapter implements RestaurantApiAdapter {
  // Reads fixtures/mock_restaurant_search.json and fixtures/mock_taco_bell_menu.json.
}
```

## 10.4 Restaurant menu prefetch rule

When the user selects a restaurant:

```dart
Future<List<FoodItem>> openRestaurant(Restaurant restaurant) async {
  await restaurantRepository.markRestaurantAccessed(restaurant.localId!);

  final cachedMenu = await restaurantRepository.getCachedMenuItems(restaurant.localId!);
  if (cachedMenu.isNotEmpty) {
    // Return cached menu instantly.
    unawaited(_refreshMenuIfOnline(restaurant));
    return cachedMenu;
  }

  // No cached menu. Fetch if possible.
  return restaurantRepository.fetchAndCacheRestaurantMenu(restaurant);
}
```

This makes the app feel fast while still keeping data fresh.

---

## 11. Decision Engine

## 11.1 Engine input/output

```dart
class DecisionEngineInput {
  final UserProfile profile;
  final List<FoodItem> candidates;
  final RecommendationContext context;

  const DecisionEngineInput({
    required this.profile,
    required this.candidates,
    required this.context,
  });
}

class DecisionEngineOutput {
  final List<Recommendation> recommendations;
  final List<String> warnings;
  final bool usedCachedOnlyData;

  const DecisionEngineOutput({
    required this.recommendations,
    required this.warnings,
    required this.usedCachedOnlyData,
  });
}
```

## 11.2 Pipeline

```text
candidate foods
  ↓
L1 SafetyFilter
  ↓
L2 FeasibilityFilter
  ↓
L3 PreferenceFilter / PreferenceScorer
  ↓
L4 Nutrition scoring
  ↓
Composite score
  ↓
Sort descending
  ↓
Explain top N
```

## 11.3 L1 safety filters

Hard exclusions:

- allergens
- religious restrictions
- medical restrictions marked `avoid`
- disliked ingredients marked `never show`

A food failing L1 must never be displayed as a recommendation.

```dart
class SafetyFilter {
  bool isSafe(FoodItem food, UserProfile profile) {
    if (food.allergens.intersection(profile.allergens).isNotEmpty) return false;
    if (food.dietTags.intersection(profile.religiousRestrictions).isNotEmpty) return false;
    if (food.medicalTags.intersection(profile.medicalRestrictionsAvoid).isNotEmpty) return false;
    if (_containsNeverShowIngredient(food, profile)) return false;
    return true;
  }
}
```

## 11.4 L2 feasibility filters

Hard-but-adjustable exclusions:

- price exceeds meal budget
- prep required exceeds user environment
- restaurant/source context does not match current mode

```dart
class FeasibilityFilter {
  bool isFeasible(FoodItem food, UserProfile profile, RecommendationContext context) {
    final budget = profile.maxMealBudgetUsd;
    if (budget != null && food.estimatedCostUsd != null) {
      if (food.estimatedCostUsd! > budget) return false;
    }

    if (!profile.prepEnvironment.canHandle(food.prepRequired)) return false;

    if (context.restaurantOnly && food.restaurantId == null) return false;

    return true;
  }
}
```

## 11.5 L3 preference matching

Soft preference boosts:

- preferred cuisine
- preferred meal type
- repeated favorites
- high confidence data
- cached/frequent restaurant match

Soft penalties:

- disliked but not forbidden ingredient
- low data confidence
- stale data
- missing price
- missing micronutrients

## 11.6 L4 nutrition scoring

Use a deterministic weighted score:

```text
score =
  0.30 * macro_alignment
+ 0.25 * micronutrient_value
+ 0.15 * preference_match
- 0.20 * penalty_score
- 0.10 * cost_pressure
```

Clamp component scores to `0.0–1.0`. The raw composite can be any real number. Convert to 0–100 for display after ranking.

## 11.7 Macro alignment

```dart
double agreement(double target, double actual) {
  if (target <= 0) return actual <= 0 ? 1.0 : 0.0;
  final score = 1.0 - ((target - actual).abs() / target);
  return score.clamp(0.0, 1.0);
}
```

Macro score:

```text
macro_alignment =
  0.30 * protein_agreement
+ 0.20 * calorie_agreement
+ 0.20 * carb_agreement
+ 0.20 * fat_agreement
+ 0.10 * fiber_agreement
```

## 11.8 Penalty score

Penalty components:

- sodium above per-meal threshold
- added sugar above per-meal threshold
- saturated fat above per-meal threshold
- medical-condition-specific penalties
- missing critical data

Example:

```dart
double excessPenalty(double value, double threshold) {
  if (threshold <= 0) return 0.0;
  final excess = value - threshold;
  if (excess <= 0) return 0.0;
  return (excess / threshold).clamp(0.0, 1.0);
}
```

Medical multiplier example:

```text
if low_sodium is in profile.medicalRestrictionsLimit:
  sodium penalty weight *= 2.0

if diabetic is in profile.medicalRestrictionsLimit:
  added sugar penalty weight *= 2.0
  fiber gets a positive weight bump
```

## 11.9 Explanation layer

The explanation layer must be generated from structured scoring traces, not free-written guesses.

```dart
class ScoreTrace {
  final double macroScore;
  final double microScore;
  final double preferenceScore;
  final double penaltyScore;
  final double costPressure;
  final List<String> satisfiedConstraints;
  final List<String> tradeoffs;
  final List<String> missingDataWarnings;
}
```

Example explanation output:

```text
Why this ranked well:
- Fits your current budget.
- Does not violate your allergen or religious restrictions.
- Strong protein-to-calorie ratio.
- Available from a restaurant you recently searched.

Tradeoffs:
- Sodium is high, so this may not be ideal if you are strictly limiting sodium.
- Fiber data is missing from the source database.
```

---

## 12. Use Cases

## 12.1 Search foods

```dart
class SearchFoodsUseCase {
  final FoodRepository repository;

  Future<List<FoodItem>> call(String query) async {
    final cached = await repository.searchCachedFoods(query);
    final remote = await repository.fetchFoodsFromApi(query);
    await repository.upsertFoodItems(remote);
    return _mergeAndDedupe(cached, remote);
  }
}
```

Implementation detail:

- If remote fails, return cached plus warning.
- If cached is empty and remote fails, return an error state.
- Dedupe by `(source, sourceId)` first, then normalized name/brand/serving if needed.

## 12.2 Fetch restaurant menu

```dart
class FetchRestaurantMenuUseCase {
  final RestaurantRepository repository;

  Future<List<FoodItem>> call(Restaurant restaurant) async {
    final cached = await repository.getCachedMenuItems(restaurant.localId!);
    if (cached.isNotEmpty) {
      // Return fast path first; refresh can happen outside this use case.
      return cached;
    }
    return repository.fetchAndCacheRestaurantMenu(restaurant);
  }
}
```

## 12.3 Recommend foods

```dart
class RecommendFoodsUseCase {
  final FoodRepository foodRepository;
  final DecisionEngine decisionEngine;

  Future<DecisionEngineOutput> call(UserProfile profile, RecommendationContext context) async {
    final candidates = await foodRepository.getCandidateFoodsFromCache(profile);
    return decisionEngine.recommend(
      DecisionEngineInput(
        profile: profile,
        candidates: candidates,
        context: context,
      ),
    );
  }
}
```

## 12.4 Evict stale cache

```dart
class EvictStaleCacheUseCase {
  final CacheRepository cacheRepository;

  Future<void> call() async {
    await cacheRepository.evictExpiredItems(unusedDays: 90);
  }
}
```

---

## 13. UI/UX Architecture

## 13.1 Screen list

### OnboardingScreen

Collects:

- allergies
- religion/diet restrictions
- medical restrictions
- budget
- prep environment
- nutrition targets

### HomeScreen

Shows:

- search bar
- quick action buttons: “Restaurant,” “Packaged food,” “Grocery/basic food”
- recently used restaurants
- cached favorites
- offline/online status banner

### SearchScreen

Supports:

- text search
- cached results first
- online refresh indicator
- error states

### RestaurantSearchScreen

Supports:

- search restaurant by name
- show cached restaurants
- selecting a restaurant triggers menu prefetch

### RestaurantMenuScreen

Shows:

- menu sections
- item nutrition summary
- “rank best options for me” button
- cache freshness label

### RecommendationResultsScreen

Shows:

- ranked cards
- display score
- top 3 reasons
- tradeoff chips
- sort/filter controls

### ExplanationScreen

Shows:

- full score breakdown
- constraints satisfied
- penalties
- missing-data warnings
- “why not higher?” explanation

### SettingsScreen

Shows:

- profile editing
- cache stats
- clear cache
- last cache cleanup date
- app version/debug info

---

## 13.2 Recommendation card UI

Each card should include:

```text
Food name
Brand / restaurant
Calories | Protein | Carbs | Fat
Score: 87/100
Reasons:
  ✓ Fits budget
  ✓ Safe for your restrictions
  ✓ High protein for calories
Tradeoff:
  ⚠ High sodium
```

Use plain language. Avoid medical overclaiming.

---

## 14. Riverpod Provider Design

Suggested providers:

```dart
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(databaseProvider));
});

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl(
    db: ref.watch(databaseProvider),
    api: ref.watch(foodApiAdapterProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final recommendationProvider = FutureProvider.family<DecisionEngineOutput, RecommendationContext>((ref, context) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) throw StateError('Profile not completed');
  final useCase = ref.watch(recommendFoodsUseCaseProvider);
  return useCase(profile, context);
});
```

Provider rules:

- UI reads providers.
- Providers call use cases.
- Use cases call repositories and domain engine.
- Repositories call SQLite/API adapters.
- Widgets do not call Dio or SQLite directly.

---

## 15. Data Normalization Rules

## 15.1 Units

Normalize all nutrition data to:

- kcal
- grams for macros
- milligrams or micrograms for micronutrients
- serving size in grams when available

If a source returns nutrients per 100 g and serving size is known, convert to per serving.

If serving size is missing, keep the item but mark `confidence = low` and add a missing-data warning.

## 15.2 Names

Store both raw name and normalized name.

Normalization:

- lowercase
- trim whitespace
- remove repeated spaces
- remove trademark symbols
- preserve brand/restaurant separately

## 15.3 Allergens

Allergen tags should come from source fields when available. Also scan `ingredients_text` for conservative keyword matches.

Example:

```text
contains "peanut", "groundnut" → peanut
contains "whey", "milk", "casein" → dairy
contains "soy lecithin", "soy protein" → soy
contains "wheat", "semolina" → wheat/gluten
```

If allergen data is missing, do **not** mark as safe with high confidence. Use `confidence = low` and show a warning.

## 15.4 Diet/religion tags

Store diet exclusion tags rather than compatibility claims.

Examples:

- `contains_pork`
- `contains_beef`
- `contains_meat_unknown_source`
- `contains_alcohol`
- `contains_gelatin_unknown_source`

A halal user excludes `contains_pork`, `contains_alcohol`, and `contains_meat_unknown_source` unless source certifies otherwise.

## 15.5 Medical tags

Medical tags should be conservative and explainable.

Examples:

- `high_sodium`
- `very_high_added_sugar`
- `low_fiber_refined_carb`
- `high_potassium`

Do not encode complex clinical rules as if they are absolute truth. Use `avoid` only for user-declared strict restrictions. Use penalties for softer concerns.

---

## 16. Offline and Error Behavior

## 16.1 No internet

UI message:

```text
You're offline. Showing saved foods and restaurants only. New searches need internet.
```

Allowed:

- cached search
- cached restaurant menu view
- recommendations over cached items
- profile edits

Blocked:

- new API search
- menu refresh
- barcode lookup unless barcode result is cached

## 16.2 API timeout

Behavior:

- show cached results if available
- show warning chip: “Couldn’t refresh; using saved data”
- log debug error only in development

## 16.3 Empty restaurant menu

Message:

```text
We found this restaurant, but menu nutrition data is unavailable right now. Try another search or use cached/basic foods.
```

## 16.4 Missing nutrition values

Do not crash. Missing values should:

- reduce confidence
- add explanation warning
- avoid falsely high score

## 16.5 Cache corruption

If SQLite fails to open:

1. Try backup/recovery if implemented.
2. If not, show clear error.
3. Offer reset local cache.
4. Preserve profile if possible.

---

## 17. Privacy and Security

## 17.1 Local user data

Store profile locally. Do not require login. Do not upload user restrictions or health-related preferences in v1.

## 17.2 API requests

API requests may contain search terms like “Taco Bell” or “protein bar.” They should not include the full user profile. Filtering and scoring happen locally after results return.

## 17.3 No analytics by default

Do not add ad SDKs, analytics SDKs, or tracking SDKs to the prototype. If analytics are added later, they must be opt-in and privacy-preserving.

## 17.4 API keys

For local prototype:

- Use mock adapters by default.
- Use `.env` or build-time config for API keys if needed.
- Never hard-code secrets into the repository.

For production:

- Add backend proxy or secure key handling.
- Rate-limit requests.
- Cache aggressively.

---

## 18. Testing Strategy

## 18.1 Unit tests

Required unit tests:

- Safety filter excludes allergens.
- Safety filter excludes religious conflicts.
- Medical `avoid` excludes item.
- Medical `limit` penalizes item but does not exclude.
- Feasibility filter respects budget.
- Feasibility filter respects prep environment.
- Macro scorer handles zero targets.
- Penalty scorer handles high sodium/high sugar.
- Recommendation engine returns deterministic ranking.
- Explanation strings match score trace.

## 18.2 Cache tests

Required cache tests:

- Insert food item.
- Upsert same `(source, source_id)` updates existing row.
- Accessing item updates `last_accessed_at` and increments `access_count`.
- Eviction deletes items unused for 90+ days.
- Eviction keeps recently accessed items.
- Deleting restaurant cascades menu items.

## 18.3 Repository tests

Use mock API adapters.

Required tests:

- Cache hit returns immediately.
- Online search merges cached and remote results.
- Offline search returns cached only.
- API failure returns cached with warning.
- Restaurant selection prefetches menu.

## 18.4 Widget tests

Required widget tests:

- Onboarding saves profile.
- Offline banner appears when offline.
- Search results show cached data.
- Recommendation cards render score/reasons/tradeoffs.
- Explanation screen renders score breakdown.

---

## 19. Performance Targets

## 19.1 Latency

Targets on a low-end Android device:

| Operation | Target |
|---|---:|
| App cold start to first screen | < 2.0 sec |
| Cached search | < 150 ms |
| Recommendation over 500 cached items | < 250 ms |
| Restaurant cached menu open | < 250 ms |
| API search visible loading state | < 100 ms |
| Cache eviction after launch | background only |

## 19.2 Memory

- Avoid loading thousands of full raw payloads into memory.
- Query only columns needed for recommendation cards.
- Load raw payload only for debug/detail if needed.
- Limit recommendation candidate set to 500–1000 items per run.

## 19.3 Battery/network

- Debounce search input by 300–500 ms.
- Cancel in-flight search request when query changes.
- Cache API results.
- Do not refresh menus repeatedly in the same session unless user pulls to refresh.

---

## 20. Implementation Milestones

## Milestone 1 — App skeleton

Deliverables:

- Flutter project boots on Android emulator.
- Folder structure created.
- Theme and routing set up.
- Empty screens wired.

Acceptance:

- `flutter analyze` passes.
- App builds debug APK.

## Milestone 2 — Local database

Deliverables:

- SQLite database opens.
- Schema creates.
- DAOs insert/query/update cached foods/restaurants/profile.

Acceptance:

- Local DB tests pass.
- Can save and reload user profile.

## Milestone 3 — Mock API adapters

Deliverables:

- Mock food search from JSON.
- Mock restaurant search from JSON.
- Mock Taco Bell menu from JSON.
- Remote DTOs mapped to domain entities.

Acceptance:

- Search screen can show fixture results.
- Selecting Taco Bell caches menu items.

## Milestone 4 — Recommendation engine

Deliverables:

- Safety filter.
- Feasibility filter.
- Preference scoring.
- Nutrition scoring.
- Explanation generation.

Acceptance:

- Engine tests pass.
- Given a known fixture set, output ranking is deterministic.

## Milestone 5 — Core UI

Deliverables:

- Onboarding.
- Home.
- Search.
- Restaurant menu.
- Recommendations.
- Explanation detail.
- Settings/cache view.

Acceptance:

- User can complete profile, search Taco Bell, cache menu, rank best options, and view explanations.

## Milestone 6 — Offline mode

Deliverables:

- Connectivity service.
- Offline banner.
- Cached-only search path.
- Cached recommendation path.

Acceptance:

- With network disabled, cached Taco Bell menu still opens and ranks.
- New uncached search gives clear offline message.

## Milestone 7 — Real API adapter spike

Deliverables:

- One real food/product API adapter.
- One restaurant/menu API adapter if available and reliable.
- Feature flag to switch mock vs real adapter.

Acceptance:

- Mock mode remains demo-safe.
- Real mode can be tested without changing UI/domain code.

---

## 21. Recommended Mock Data

For demo reliability, include curated mock fixtures.

## 21.1 `mock_restaurant_search.json`

```json
[
  {
    "source": "mock",
    "source_id": "restaurant_taco_bell",
    "name": "Taco Bell",
    "cuisine": "fast_food_mexican",
    "website_url": "https://www.tacobell.com/"
  }
]
```

## 21.2 `mock_taco_bell_menu.json`

Include 15–30 representative items across categories:

- burritos
- tacos
- bowls
- sides
- drinks
- vegetarian items
- high-sodium items
- high-protein items
- low-calorie items

Each item should include:

```json
{
  "source": "mock",
  "source_id": "tb_chicken_power_bowl",
  "restaurant_source_id": "restaurant_taco_bell",
  "name": "Chicken Power Bowl",
  "category": "bowl",
  "serving_label": "1 bowl",
  "calories_kcal": 460,
  "protein_g": 26,
  "carbs_g": 50,
  "fat_g": 18,
  "saturated_fat_g": 6,
  "fiber_g": 8,
  "sugar_g": 3,
  "sodium_mg": 1200,
  "allergens": ["dairy"],
  "diet_tags": ["contains_meat_unknown_source"],
  "medical_tags": ["high_sodium"],
  "prep_required": "none",
  "estimated_cost_usd": 7.49
}
```

Mock data does not need to be perfect, but it must be internally consistent and good enough to test ranking behavior.

---

## 22. Acceptance Criteria for Codex-Generated Prototype

The prototype is acceptable when:

1. It runs as a Flutter Android app.
2. It does not require a backend server.
3. It has onboarding and persists a user profile locally.
4. It can search mock food data.
5. It can search mock restaurant data.
6. Selecting a restaurant fetches/caches its full mock menu.
7. Cached foods/menu items are stored in SQLite.
8. Items unused for 90 days are evicted by a tested use case.
9. The recommendation engine filters unsafe foods before scoring.
10. The recommendation engine ranks feasible foods by deterministic nutrition/preference score.
11. Recommendation cards show reasons and tradeoffs.
12. Offline mode shows cached data and blocks new searches clearly.
13. Unit tests cover filters, scoring, cache eviction, and repository behavior.
14. No widget calls Dio or SQLite directly.
15. `flutter analyze` passes.

---

## 23. Future Extensions

These are designed-around but not v1 requirements.

### 23.1 Barcode scanning

Add camera permission and barcode lookup adapter. Cache scanned products like normal foods.

### 23.2 Location-based restaurant search

Add optional location permission. Search restaurants near the user. Keep text search as fallback.

### 23.3 Backend proxy

Add backend only if needed for API-key protection, rate limiting, or aggregation.

### 23.4 Account sync

Optional account system for users who want profile/cache sync across devices. Not needed for v1.

### 23.5 Clinician mode

A clinician-configured profile QR code could load restrictions onto the app after discharge. This is promising but out of scope for the prototype.

### 23.6 SNAP/WIC filters

Add eligibility tags and filters for food assistance programs.

### 23.7 Daily intake tracking

Let users mark foods as eaten and update remaining daily macro/micronutrient targets.

---

## 24. Final Engineering Position

This app should be framed as a **mobile decision-support prototype**, not a giant offline nutrition database and not a generic tracker.

The best v1 is:

- Flutter/Dart Android app.
- API-backed search.
- Local SQLite cache.
- 90-day unused cache eviction.
- Restaurant menu prefetching.
- Deterministic constraint filtering and nutrition scoring.
- Clear explanations.
- Offline support for previously cached data only.
- Mock-first implementation so the prototype is demo-stable even before real API coverage is solved.

This scope is realistic, buildable, judge-friendly, and Codex-friendly.
