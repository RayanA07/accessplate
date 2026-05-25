# AccessPlate Model Boundary Summary

Use this as the short reference for judges, faculty, partners, or interviewers when they ask what AccessPlate does and does not claim at this stage.

## What AccessPlate does now

- ranks food options with deterministic, explainable logic
- uses safety, budget, cooking setup, pantry state, transportation, and source-type constraints
- models bundled ZIP-based food-access conditions offline
- generates a first stop, buy order, backup, and short-run meal plan
- supports English, Spanish, and plain-language decision text across key flows
- keeps the core user profile local on-device

## What the bundled model means

- ZIP access data is bundled modeled data, not universal live inventory
- exact ZIP matches are treated as stronger than prefix or fallback estimates
- pantry, dollar-store, convenience-store, grocery, and fast-food access are modeled as source types with different burden and coverage

## What optional live data means

- optional live grocery matching can add store-specific grocery names and prices
- live grocery support does not mean live pantry inventory
- live grocery support does not mean live convenience-store or dollar-store inventory
- live grocery support does not mean complete neighborhood food inventory coverage

## What AccessPlate does not claim

- perfect live inventory across all local food sources
- perfect item-level SNAP eligibility in all cases
- perfect item-level WIC eligibility across every state, brand, and package size
- clinical outcome proof
- broad real-world generalizability without more field validation

## Why this still matters

Even with those boundaries, the prototype already handles major decision constraints that many nutrition apps ignore:

- limited travel
- pantry instability
- low-cost source tradeoffs
- benefit-program context
- emergency-day food decisions
- low-literacy and bilingual decision support

## Suggested one-slide version

### Title

AccessPlate: What is modeled now vs what still needs validation

### Left column: already implemented

- deterministic food-access engine
- pantry-aware planning
- ZIP-based bundled access realism
- benefits-aware explanation
- emergency mode and buy order
- bilingual plain-language output

### Right column: still being validated

- broader field validation of local-access assumptions
- stronger item-level WIC verification
- more stakeholder and user evidence
- larger proof and metrics package

## Best spoken version

This prototype is intentionally transparent. It already gives a realistic, explainable food-access plan using bundled local models, pantry state, travel burden, and benefit context, but it does not claim live inventory everywhere or final clinical proof. That honesty is part of the design and part of the validation plan.
