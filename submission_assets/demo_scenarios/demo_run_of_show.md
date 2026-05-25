# AccessPlate Demo Run of Show

Use this as the live-demo script for a DEBUT or NIMHD-focused presentation.

## Target length

- `6 to 8 minutes` for the main demo
- `2 minutes` for follow-up questions

## Main message

AccessPlate is not trying to answer, "What food is healthiest in theory?"

It is trying to answer, "What is the safest, cheapest, actually obtainable meal or basket I can get today from places I can realistically reach with the benefits and equipment I actually have?"

## Before the demo

- Reset the profile to the chosen scenario before each run.
- Confirm the app is in offline-ready mode.
- If showing live grocery data, verify the selected store is loaded ahead of time.
- Run [manual_demo_verification_checklist.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/manual_demo_verification_checklist.md) once after the final build.
- Keep the three core scenarios open in this order:
  1. `01_emergency_no_cook_45211.md`
  2. `03_snap_tight_budget_77026.md`
  3. `05_spanish_plain_language_60623.md`

## Minute-by-minute script

### 0:00 to 0:45

- State the problem:
  - low-income users often face food decisions shaped by transportation, pantry state, benefits, cooking limits, and time pressure
  - most food apps optimize wellness, not real access
- State AccessPlate's thesis:
  - deterministic, explainable, local-first food-access decision support

### 0:45 to 2:15

- Open `01_emergency_no_cook_45211.md`
- Show:
  - emergency mode
  - `Do this first today`
  - `Best first stop`
  - buy-order sections in `Today plan`
- Say:
  - "This user cannot cook, cannot travel far, and needs food now."
  - "The app is not sending them on an ideal grocery trip. It is routing them to the lowest-burden practical choice."
- What judges should notice:
  - immediate first action
  - realistic source choice
  - skip-first logic under a tight budget

### 2:15 to 4:00

- Open `03_snap_tight_budget_77026.md`
- Show:
  - benefits-related tags and explanation
  - `Buy first`, `If money is left`, `Skip first`
  - source comparison or backup
- Say:
  - "Benefits are not cosmetic tags here. They change the trip plan and purchase order."
  - "Hot or uncertain items are pushed back when the app is trying to protect a SNAP-oriented basics run."
- What judges should notice:
  - benefits-aware routing
  - one-stop realism
  - deterministic tradeoff explanation

### 4:00 to 5:30

- Open `05_spanish_plain_language_60623.md`
- Show:
  - Spanish mode
  - plain-language mode
  - `Do this first today`
  - `Quick read` in explain view
- Say:
  - "The same deterministic logic stays visible in Spanish and simpler language."
  - "This matters because low-resource decision tools fail if users cannot act on them under stress."
- What judges should notice:
  - bilingual practical guidance
  - use-from-home logic
  - low-literacy friendliness

### 5:30 to 6:30

- Briefly show `metrics_package/judging_matrix.md`
- Say:
  - "We also structured the repo around validation and proof, not just app screens."
  - "These scenario and metric files map directly to significance, impact, innovation, and prototype strength."

### 6:30 to 7:00

- Close with model boundaries:
  - "The app is transparent about what is bundled modeled access data versus live grocery data."
  - "That honesty is part of the design."

## Backup paths

- If live grocery data fails:
  - skip store-specific product matching
  - stay in bundled offline scenarios
- If time is cut short:
  - show scenario 1 and scenario 3 only
- If asked about accessibility:
  - jump to Spanish/plain-language scenario and explain `Quick read`, decision summary, and localized setup flow

## Demo success criteria

- Judges can clearly tell:
  - where the user should go first
  - what the user should use from home first
  - what the user should buy first
  - why the output is realistic for a low-resource setting
