# AccessPlate

Offline-first Flutter prototype for constraint-aware dietary decision support in low-resource settings.

## What is in this repo

- `lib/domain/`: pure decision logic, scoring, explainability, and immutable entities
- `lib/data/`: local SQLite initialization plus asset seeding
- `lib/presentation/`: Riverpod-driven onboarding, recommendations, explanations, and settings
- `assets/reference/`: bundled food catalog, micronutrient RDA table, and medical penalty modifiers
- `technical_design_document.md`: the implementation reference used for the app logic

## Product behavior

- Runs fully offline after install
- Uses a deterministic four-layer pipeline:
  1. Safety filters
  2. Feasibility filters
  3. Preference matching
  4. Nutrition scoring
- Persists the user profile locally with no account or server dependency

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
- Android and iOS project folders are included, but signing, store metadata, icons, and release certificates still need to be finalized before shipping to the App Store or Play Store.
