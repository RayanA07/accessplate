# AccessPlate Submission Narrative Packet

Use this file as the starting point for the written NIH NIBIB DEBUT 2026 / NIMHD submission narrative, pitch deck text, and presenter talking points.

## One-sentence thesis

AccessPlate is a deterministic, explainable, local-first food-access decision-support tool that helps low-income users find the safest, cheapest, actually obtainable meal or basket they can reach today with the benefits, pantry food, transportation, and cooking setup they really have.

## Problem framing paragraph

In many underserved U.S. communities, food decisions are constrained less by abstract nutrition knowledge than by transportation burden, unstable pantry supply, benefit-program rules, low-bandwidth conditions, limited cooking equipment, and the limited source types people can realistically reach on a given day. A user may be choosing between a pantry stop, a dollar store, a convenience store, a grocery trip, or a fast-food fallback while trying to protect a few dollars, avoid unsafe foods, and cover more than one meal. Most food apps are not built for that decision. They rank foods as if access were stable, inventory were obvious, and the user had equal ability to reach any source. AccessPlate is built around the opposite assumption: for low-resource households, the key question is not simply what is healthiest, but what is safest, cheapest, and realistically obtainable today.

## Significance framing

AccessPlate addresses a real and common low-resource health problem: the gap between ideal nutrition advice and real food access. That gap is especially severe in low-access neighborhoods and food deserts, where transportation limits, source scarcity, time pressure, and benefit-program dependence shape what a household can actually obtain. By focusing on the decision conditions that drive same-day food choice, the prototype targets a problem with direct relevance to nutrition-related chronic disease risk, food insecurity, and practical care guidance in underserved communities.

## Impact framing

The prototype is designed to improve action, not just ranking quality. It gives users a concrete next step: where to go first, what to use from home first, what to buy first, what to skip if money is tight, and what the backup is if the first plan fails. That matters because low-resource households often need fast, feasible decisions rather than broad wellness guidance. The expected impact is a more realistic and usable decision path under constrained travel, budget pressure, pantry instability, limited cooking setup, and benefit-program use.

## Innovation framing

AccessPlate's innovation is not a chatbot or opaque personalization layer. Its novelty is a deterministic, explainable planning engine that combines food safety constraints, pantry state, transportation burden, ZIP-based local access modeling, source-type realism, benefit-program logic, and plain-language presentation into one decision flow. The system stays transparent about why a pantry-first meal, a dollar-store staple run, a grocery trip, or an emergency convenience fallback is being recommended, and it makes its modeled-versus-live data boundaries explicit. That combination is more relevant to low-resource food access than a standard nutrition recommender.

## Prototype strength framing

The prototype is not just a concept mockup. It already implements local-first onboarding, offline persistence, pantry tracking, ZIP-based bundled access snapshots, transportation-aware source-trip planning, benefits-aware explanation, emergency mode, buy-order logic, meal baskets, and English/Spanish plain-language output across key decision surfaces. The repo also includes reproducible demo scenarios, metric-case scaffolding, stakeholder-review packets, user-test packets, and submission-tracking materials, which strengthens the prototype story beyond the app UI alone.

## NIMHD low-resource fit paragraph

AccessPlate is especially aligned with low-resource and underserved settings because it treats food access as a constrained systems problem rather than an individual motivation problem. It explicitly models pantry use, limited transportation, mixed retail ecosystems, uncertain grocery access, SNAP/WIC dependence, low-literacy needs, and bilingual decision support. Its design goal is not to optimize lifestyle tracking, but to support safer and more realistic same-day food decisions in communities where health behavior is tightly bounded by access conditions.

## What to say about explainability

AccessPlate preserves deterministic, explainable logic as a core strength. Users and reviewers can inspect why a recommendation was favored, which source is the best first stop, which foods are meant to be used from home, how benefit-program fit affected the plan, and why a backup exists. That transparency is important for trust, for iteration with community stakeholders, and for use in care-adjacent or public-health settings where opaque recommendations are harder to validate.

## What to say about privacy and local-first design

The prototype is designed so that core user context stays local on-device and the app remains useful offline after install. Bundled data supports the core food-access reasoning without requiring an account system or always-on connectivity. Optional live grocery matching can enrich store-specific grocery information, but the app remains transparent that most neighborhood access logic is bundled modeled data rather than universal live inventory.

## Model-boundary paragraph

AccessPlate does not claim live neighborhood inventory coverage across all source types, perfect state-by-state WIC verification for every item, or proven clinical outcomes at this stage. Instead, it provides a defensible, transparent prototype that already models the major practical constraints shaping low-resource food decisions and is structured for stakeholder validation, usability testing, and scenario-based evidence collection.

## Short versions

### 30-second version

AccessPlate is a deterministic, local-first food-access decision-support app for low-resource U.S. settings. Instead of only ranking foods by health, it helps a user decide what to use from home, where to go first, what to buy first, and what to skip when money, transportation, benefits, and cooking setup are tight.

### 90-second version

Most food apps assume the user can reach any store and just needs better nutrition advice. AccessPlate starts from the opposite assumption. In low-resource communities, the real problem is figuring out what meal or basket is actually safe, affordable, and reachable today with the pantry food, transportation, benefits, and cooking setup a household really has. The app uses a deterministic and explainable engine to combine safety rules, pantry state, ZIP-based access modeling, source-trip planning, SNAP/WIC-aware logic, emergency mode, and plain-language output. The result is not just a ranked food list, but a real action path: where to go first, what to use from home, what to buy first, what to skip, and what the backup is.

## Suggested evidence pairing

Pair these narrative sections with:

- `demo_scenarios/demo_run_of_show.md`
- `metrics_package/judging_matrix.md`
- `metrics_package/evidence_scorecard.md`
- `stakeholder_validation/accessplate_partner_review_packet.md`
- `user_interviews/accessplate_user_test_packet.md`
