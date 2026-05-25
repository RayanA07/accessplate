# AccessPlate

Offline-first Flutter prototype for food-access decision support in low-resource U.S. settings.

AccessPlate is designed around one question:

> What is the safest, cheapest, actually obtainable meal or basket I can get today from places I can realistically reach with the benefits and equipment I actually have?

The app keeps a deterministic, explainable engine at the center. It does not rely on a chatbot, an account system, or always-on network access.

## What this repo includes

- `lib/domain/`: pure decision logic, scoring, explainability, and immutable entities
- `lib/data/`: local SQLite initialization plus asset seeding
- `lib/presentation/`: Riverpod-driven onboarding, recommendations, access planning, explanations, and settings
- `assets/reference/`: bundled food catalog, ZIP access profiles, micronutrient RDA table, and medical penalty modifiers
- `docs/food_access_model.md`: deterministic access modeling, pantry logic, benefits logic, and bundled-vs-live data boundaries
- `docs/nih_submission_readiness.md`: NIH DEBUT / NIMHD-oriented submission checklist and external validation gaps
- `submission_assets/`: starter structure for demo scenarios, validation notes, support letters, and metrics packaging
- `technical_design_document.md`: the implementation reference used for the app logic

## Product behavior

- Runs fully offline after install
- Uses a deterministic pipeline:
  1. Safety filters
  2. Feasibility filters
  3. Preference matching
  4. Access-aware source and travel realism
  5. Nutrition scoring
  6. Explainable recommendation, basket, source-trip, and today-plan output
- Persists the user profile locally with no account or server dependency
- Supports pantry-aware planning, transportation limits, emergency mode, SNAP/WIC-aware reasoning, and ZIP-based bundled access modeling

## Modeled vs live data

- Most food-access reasoning is bundled with the app and works offline.
- ZIP-based source access uses bundled modeled snapshots in `assets/reference/local_access_profiles.json`.
- Optional live grocery support adds Kroger-specific product names, aisle hints, and local prices for a selected grocery store.
- Live grocery lookup does **not** mean live pantry, dollar-store, convenience-store, or full neighborhood inventory coverage.

## Why this matters

AccessPlate is meant to be more than a nutrition-ranking demo. The current product direction is explicitly aimed at:

- low-income households in underserved U.S. communities
- people with limited transportation, limited cooking equipment, and time pressure
- users relying on SNAP, WIC, pantries, dollar stores, convenience stores, and mixed food sources
- practical decision support under uncertainty, not generic wellness tracking

## Run locally

```bash
flutter pub get
flutter run
```

## Validate

```bash
flutter analyze
flutter test
```

## Notes

- The bundled dataset is seeded into SQLite on first launch from local JSON assets.
- The bundled access model is intentionally transparent: some recommendations are based on modeled local access rather than live store inventory.
- Android and iOS project folders are included, but signing, store metadata, icons, and release certificates still need to be finalized before shipping to the App Store or Play Store.
