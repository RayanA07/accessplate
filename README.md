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
- Bundled ZIP-based access snapshots still exist for offline ranking and explainability.
- Live nearby-store discovery is a separate mechanism powered by device GPS or an entered address / ZIP through OpenStreetMap services.
- A 5-digit ZIP is treated as an approximate ZIP-area fallback and is labeled that way in the UI.
- Nearby-store distances are straight-line approximations unless a separate routing service is added later.
- Optional Kroger APIs add live product names, sizes, and prices when a nearby Kroger-family store can be matched.
- Live product coverage does **not** imply verified inventory at unsupported retailers.

## Live API setup

AccessPlate now has one required no-key live store layer and one optional retail layer:

- OpenStreetMap public services
  - Nominatim is used for address / ZIP lookup and reverse geocoding
  - Overpass is used for nearby-store discovery
  - no API key is required for the prototype path
- `KROGER_CLIENT_ID`
- `KROGER_CLIENT_SECRET`
- `KROGER_SCOPES`
  - enables live Kroger product / brand / price matching when a nearby store can be linked to Kroger APIs

Example:

```bash
flutter run \
  --dart-define=KROGER_CLIENT_ID=your_kroger_client_id \
  --dart-define=KROGER_CLIENT_SECRET=your_kroger_client_secret \
  --dart-define=KROGER_SCOPES=product.compact
```

Optional endpoint overrides for demos:

```bash
flutter run \
  --dart-define=OSM_NOMINATIM_BASE_URL=https://nominatim.openstreetmap.org \
  --dart-define=OSM_OVERPASS_BASE_URL=https://overpass-api.de/api/interpreter \
  --dart-define=OSM_HTTP_USER_AGENT="AccessPlate prototype demo"
```

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
- The bundled access model is intentionally transparent: recommendation ranking can still use modeled local access, but nearby stores should only come from the live OSM store-discovery layer or be marked approximate / unavailable.
- The current OSM prototype does not compute driving or walking time. Meal cards should show approximate distance, not travel minutes.
- Public OSM services are practical for a prototype, but they have rate limits and availability limits. A production deployment should use a managed proxy or hosted geospatial backend.
- Android and iOS project folders are included, but signing, store metadata, icons, and release certificates still need to be finalized before shipping to the App Store or Play Store.
