# AccessPlate Demo Scenarios

These scenarios are meant to be easy to reproduce in the app and easy to explain to judges.

Use the linked files below as the live-demo version of each scenario:

- [01 Emergency no-cook day](./01_emergency_no_cook_45211.md)
- [02 Pantry-stretch restock day](./02_pantry_stretch_19133.md)
- [03 SNAP tight-budget run](./03_snap_tight_budget_77026.md)
- [04 WIC grocery vs convenience](./04_wic_grocery_vs_convenience_90011.md)
- [05 Spanish plain-language low-access case](./05_spanish_plain_language_60623.md)

## 1. Emergency day, no cooking setup

- User context:
  - transportation: `limited`
  - prep setup: `none`
  - benefits: none
  - emergency mode: on
- Pantry:
  - nothing ready
- Availability:
  - convenience store
  - dollar store
  - fast food
- Expected story:
  - the app should favor the fastest low-burden ready meal
  - the `today plan` should clearly show what to buy first and what to skip if money gets tight

## 2. Pantry stretch with one staple running low

- User context:
  - transportation: `walk`
  - prep setup: `microwave`
  - benefits: SNAP
- Pantry:
  - rice: `have enough`
  - beans: `running low`
  - oats: `restock`
- Availability:
  - food pantry
  - dollar store
  - grocery store
- Expected story:
  - the app should use pantry food first
  - the first stop should prefer pantry or low-cost staple restock
  - purchases should not include pantry/no-purchase-needed items

## 3. SNAP-focused trip under tight budget

- User context:
  - transportation: `transit`
  - prep setup: `stoveTop`
  - benefits: SNAP
- Pantry:
  - oil and seasoning available
- Availability:
  - dollar store
  - grocery store
  - convenience store
- Expected story:
  - the app should favor likely SNAP-compatible staples first
  - hot/prepared caution items should fall into `skip first` or later-priority positions
  - the source card should show why the chosen stop is better for a benefits-aware basics run

## 4. WIC-oriented grocery decision with easier convenience fallback

- User context:
  - transportation: `transit`
  - prep setup: `microwave`
  - benefits: WIC
- Pantry:
  - cereal: `running low`
- Availability:
  - convenience store
  - grocery store
- Expected story:
  - even if convenience is slightly easier, the app should explain when grocery is the stronger WIC stop
  - the explanation should distinguish `Likely WIC candidate` from `Likely not a WIC stop`

## 5. Food-desert ZIP with bilingual plain-language mode

- User context:
  - language: Spanish
  - plain language: on
  - transportation: `limited`
  - prep setup: `microwave`
  - benefits: SNAP
  - ZIP: use a bundled low-access profile
- Pantry:
  - two basics on hand, one restock needed
- Availability:
  - food pantry
  - convenience store
  - grocery store
- Expected story:
  - the app should explain the first stop, buy order, and backup in short Spanish/plain-language copy
  - the UI should clearly show what comes from home first versus what still needs to be purchased

## Presenter order

For a short DEBUT demo, use this order:

1. `01_emergency_no_cook_45211.md`
2. `03_snap_tight_budget_77026.md`
3. `05_spanish_plain_language_60623.md`

That sequence shows urgency, benefits realism, and bilingual low-resource usability in under three scenarios.
