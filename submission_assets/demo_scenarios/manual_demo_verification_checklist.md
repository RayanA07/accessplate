# AccessPlate Manual Demo Verification Checklist

Use this after `flutter analyze` and `flutter test` pass.

Goal: verify the live app still matches the judged story on the exact screens the demo will use.

## Preflight

- [ ] Launch the app from a clean state or reset to the scenario profile before each walkthrough.
- [ ] Confirm the app opens without a loading or persistence error.
- [ ] Confirm the selected language and plain-language settings match the chosen scenario.
- [ ] If showing live grocery data, confirm the chosen store is loaded before the demo.
- [ ] If not showing live grocery data, keep the demo in bundled/offline mode only.

## First-Screen Thesis Check

On the main recommendations screen, verify the user can understand these in under `10 seconds`:

- [ ] `Go first`
- [ ] `Use from home`
- [ ] `Buy first`
- [ ] `Skip first`
- [ ] `Why this route`
- [ ] `Backup`

Also verify:

- [ ] `Decision evidence` is visible or easy to reach.
- [ ] The screen clearly distinguishes bundled modeled ZIP access from live grocery data.
- [ ] The first action reads like food-access decision support, not generic wellness advice.

## Scenario 01: Emergency No-Cook Day

File: [01_emergency_no_cook_45211.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/01_emergency_no_cook_45211.md)

- [ ] Emergency mode is visibly on.
- [ ] First stop is convenience or dollar store, not a longer grocery trip.
- [ ] `Buy first` shows one fast, cheap, ready-to-eat option.
- [ ] `Skip first` pushes back a pricier or heavier option.
- [ ] `Backup` is operational, not generic.
- [ ] `Today plan` reads like a same-day action path.

## Scenario 02: Pantry-Stretch Restock Day

File: [02_pantry_stretch_19133.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/02_pantry_stretch_19133.md)

- [ ] First stop is pantry or dollar store before a harder grocery route.
- [ ] `Use from home` clearly mentions pantry items already on hand.
- [ ] `Buy first` is limited to a few add-ons or restock basics.
- [ ] Pantry or no-purchase-needed logic is clear in the explanation.
- [ ] Basket or today plan covers tonight plus the next meal in a believable way.

## Scenario 03: SNAP Tight-Budget Run

File: [03_snap_tight_budget_77026.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/03_snap_tight_budget_77026.md)

- [ ] Plan mode is clearly SNAP-aware, not generic restock.
- [ ] `Buy first` prefers likely SNAP-compatible staples.
- [ ] `Skip first` pushes back prepared or less certain items.
- [ ] Source-trip explanation makes it obvious why this stop wins for a benefits run.
- [ ] Benefits wording is specific enough to feel credible.

## Scenario 04: WIC Grocery vs Convenience

File: [04_wic_grocery_vs_convenience_90011.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/04_wic_grocery_vs_convenience_90011.md)

- [ ] First stop is grocery when WIC staple fit outweighs easier convenience.
- [ ] WIC wording distinguishes `Likely WIC candidate` from `Likely not a WIC stop` or `Likely not WIC-friendly`.
- [ ] California/state-specific wording is visible where relevant.
- [ ] Backup still shows the easier convenience fallback if the grocery path fails.

## Scenario 05: Spanish Plain-Language Low-Access Case

File: [05_spanish_plain_language_60623.md](/abs/path/C:/Users/fears/Downloads/accessplate-main/submission_assets/demo_scenarios/05_spanish_plain_language_60623.md)

- [ ] Recommendations screen is in Spanish.
- [ ] `Do this first today` is short and scannable.
- [ ] `Why this route` is understandable in Spanish/plain-language mode.
- [ ] `Quick read` in the explain screen is usable and brief.
- [ ] `Use from home` and `Buy first` stay clear in Spanish.

## Accessibility Spot Check

Use the main recommendation screen, source-trip card, today-plan card, and explain screen.

- [ ] Increase text size and verify no critical first-action text is clipped or unreadable.
- [ ] Verify tap targets on `Adjust`, `Why this`, and settings remain usable.
- [ ] Screen-reader basics: section headings and action summaries are announced in a sensible order.
- [ ] No important decision depends on color alone.

## Evidence Boundaries

- [ ] For bundled ZIP scenarios, verify the app shows exact ZIP vs ZIP-area vs fallback confidence honestly.
- [ ] If a live grocery store is selected, verify the app still says that pantry/convenience/dollar-store access is modeled, not live inventory.
- [ ] If no live grocery store is selected, verify the app does not imply live grocery inventory exists.

## Sign-Off

- [ ] All 5 hero scenarios walked end-to-end in the app UI.
- [ ] No blocking copy, layout, or stability issue found.
- [ ] Demo presenter can complete the 3-scenario run-of-show without ad-libbing around product ambiguity.
