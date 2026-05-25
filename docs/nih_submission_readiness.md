# NIH Submission Readiness

This file tracks what the repo now covers versus what still needs to be produced outside the app for a strong NIH NIBIB DEBUT 2026 / NIMHD low-resource submission.

## What the current prototype now supports

- deterministic, explainable recommendation engine
- local-first and offline-first behavior
- pantry-aware reasoning
- transportation-aware access burden modeling
- ZIP-based bundled local access snapshots
- source trip planning
- today-plan generation with buy-first / if-money-left / skip-first logic
- meal basket generation
- emergency mode
- SNAP/WIC-aware explanations
- English/Spanish and plain-language support across more decision-critical surfaces
- explicit bundled-vs-live data disclosure

## What still needs to be produced outside the app

### 1. Stakeholder validation

Needed:

- feedback from food pantry operators
- feedback from community health workers
- feedback from safety-net clinic staff
- feedback from SNAP/WIC-adjacent service providers

Suggested evidence package:

- 1-page summary per stakeholder group
- quotes with permission
- concrete product changes made from feedback

### 2. User interviews

Needed:

- interviews with low-income users in low-access neighborhoods
- testing with users who have limited transportation
- testing with users who rely on pantry or benefits-based shopping
- testing under time pressure and emergency-day scenarios

Suggested outputs:

- scenario scripts
- participant profiles
- task success notes
- confusion points
- plain-language failures and fixes

### 3. Support letters

Recommended sources:

- clinic partners
- community organizations
- pantry networks
- public health or nutrition faculty

### 4. Proof / metrics package

Needed:

- before/after recommendation examples
- time-to-decision comparisons
- access-burden reduction examples
- cost and feasibility comparisons against naive nutrition ranking
- scenario-based outputs showing pantry-first or benefits-aware improvement

### 5. Demo scenario package

Prepare a small set of reproducible demo cases:

- emergency day with no cooking equipment
- pantry stretch day with one staple running low
- SNAP-focused grocery run under tight budget
- food-desert ZIP with limited transportation
- bilingual / plain-language user flow

Each scenario should include:

- user profile
- source constraints
- pantry state
- expected first stop
- expected buy order
- backup plan

Starter scenario files now exist in `submission_assets/demo_scenarios/`, along with matching metrics starter cases in `submission_assets/metrics_package/`.

## Suggested repo-adjacent asset structure

These do not need to live in the shipping app, but they should be assembled before submission. A starter structure now exists in `submission_assets/`.

- `submission_assets/stakeholder_validation/`
- `submission_assets/user_interviews/`
- `submission_assets/support_letters/`
- `submission_assets/metrics_package/`
- `submission_assets/demo_scenarios/`

The repo now also includes:

- a live demo run sheet in `submission_assets/demo_scenarios/demo_run_of_show.md`
- a user test packet in `submission_assets/user_interviews/accessplate_user_test_packet.md`
- a stakeholder review packet in `submission_assets/stakeholder_validation/accessplate_partner_review_packet.md`
- an evidence summary sheet in `submission_assets/metrics_package/evidence_scorecard.md`
- a narrative starter in `submission_assets/submission_narrative_packet.md`
- a support-letter outreach draft in `submission_assets/support_letters/support_letter_request_template.md`
- a model-boundary summary in `submission_assets/model_boundary_summary.md`

## Highest remaining non-code risks

- limited real-world validation of bundled access assumptions
- limited state-specific WIC verification
- limited field evidence that users can act on the plans under real constraints
- limited outcome metrics unless scenario testing is documented
