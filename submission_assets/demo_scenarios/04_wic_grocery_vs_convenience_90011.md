# Demo Scenario 04: WIC Grocery vs Convenience

- Bundled ZIP snapshot: `90011` South Los Angeles, California
- Main judging theme: more precise benefits credibility

## User snapshot

- Transportation: `transit`
- Travel limit: `20 min`
- Prep setup: `microwave`
- Benefits: WIC
- Emergency mode: off
- Language: English
- Plain-language mode: on

## Pantry on hand

- Have enough: none
- Running low: `cereal`
- Need restock: `milk`

## Real-world pressure today

- Budget: tightly constrained
- Situation: convenience is easier, but a true grocery stop may fit WIC better
- Sources available: convenience store, grocery store

## Expected app behavior

- Best first stop: grocery when WIC staple fit outweighs convenience
- Buy first: likely WIC candidate basics
- Skip first: foods that look easy but are poor WIC fits
- Backup: convenience fallback if the grocery trip is not possible

## What the presenter should show

1. WIC-specific explanation text
2. State-aware note that California can change benefits wording
3. Top pick versus backup comparison
4. Evidence card showing bundled ZIP confidence and benefit fit

## Why this helps the submission

- `Significance`: models a real tradeoff between easier access and better benefit fit.
- `Impact`: may help users avoid wasting a trip on the wrong source type.
- `Innovation`: deterministic WIC-aware routing with explicit caution language.
- `Prototype strength`: the app shows nuanced benefit tradeoffs without becoming opaque.
