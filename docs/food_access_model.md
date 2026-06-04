# Food Access Model

This repo now treats AccessPlate as a deterministic food-access decision-support tool, not just a dietary ranking app.

## Core decision question

AccessPlate tries to answer:

> What is the safest, cheapest, actually obtainable meal or basket I can get today from places I can realistically reach with the benefits and equipment I actually have?

## Deterministic engine structure

The recommendation engine stays local-first and explainable:

1. Safety filtering
   - allergies
   - religion
   - medical restrictions
2. Feasibility filtering
   - budget
   - preparation environment
   - food-source availability
3. Preference matching
   - meal timing
   - dietary style
4. Access realism
   - ZIP-based bundled source snapshots for offline ranking
   - transportation mode
   - travel-time tolerance
   - emergency mode
   - pantry inventory state
   - source-type coverage
   - SNAP/WIC-aware logic
5. Nutrition scoring
   - macro fit
   - micronutrient priorities
   - penalty thresholds
6. Planning output
   - ranked recommendations
   - source trip plan
   - today plan
   - meal baskets
   - backup and restock logic

## Bundled access data vs live store data

AccessPlate now makes the distinction explicit in code and UI.

- Bundled modeled data:
  - ZIP snapshots and ZIP-prefix fallbacks in `assets/reference/local_access_profiles.json`
  - source burden for pantry, dollar store, convenience store, grocery, and fast food
  - offline access weighting used by the deterministic ranking engine
- Live store-specific data:
  - Google Maps APIs for address / ZIP geocoding, reverse geocoding, nearby-store discovery, and route distance / travel metrics
  - optional Kroger APIs for store-linked product names, package sizes, and prices

Important boundary:

- The bundled model is not live neighborhood inventory and must not be presented as nearby-store proof.
- A ZIP-only search origin is an approximate centroid fallback and must be labeled approximate.
- The live grocery layer does not provide live pantry, convenience-store, dollar-store, or unsupported-retailer inventory.
- A nearby store result does not guarantee item-level inventory unless a live product API confirms the item.

## Benefits-aware logic

Benefits reasoning is meant to be visible and precise, not hand-wavy.

- `No purchase needed`
  - used when pantry access is the realistic source
- `Likely SNAP-compatible`
  - staple-like grocery items that usually fit SNAP-style purchasing
- `Possible SNAP restaurant meal`
  - used only when the app knows a state that operates a SNAP Restaurant Meals Program, and still treated cautiously because eligibility and participating restaurants matter
- `SNAP check at checkout`
  - cold prepared grocery items that can vary by store coding
- `Likely WIC candidate`
  - items that still depend on state list, brand, and package-size rules
- `Likely not a WIC stop`
  - staple-like items that are more credible at a true grocery/WIC source than at convenience or discount stops
- `Likely not SNAP-friendly` / `Likely not WIC-friendly`
  - hot prepared food, many snack-like items, and cases that need caution

These labels are used in explanations, access tags, and decision snapshots.

When the app knows a store state or bundled ZIP-model state, benefits notes can become more specific:

- SNAP restaurant cautions can distinguish between:
  - states with a Restaurant Meals Program
  - states without one
  - limited-scope state implementations
- WIC notes can reference the relevant state-approved food list instead of only generic national wording

## Pantry-aware logic

Pantry state is not binary anymore.

- `Have enough`
- `Running low`
- `Restock soon`

The engine uses this to:

- favor pantry-first meals
- plan minimal add-on baskets
- create staple-restock today plans
- explain what to use from home first

## Source realism

The app reasons across source types that matter in low-resource settings:

- food pantry
- dollar store
- convenience store
- grocery store
- fast food

The planning layer can decide:

- which source is the best first stop
- which basket is most realistic for that source
- which backups are still reachable if the first option fails

## Current limits

The app is stronger than a pure ranking prototype, but some credibility gaps still depend on external work:

- broader empirical validation of ZIP access assumptions
- stronger item-level SNAP/WIC verification across states
- stakeholder feedback from pantry, clinic, and community partners
- user testing under real low-bandwidth and low-literacy conditions
