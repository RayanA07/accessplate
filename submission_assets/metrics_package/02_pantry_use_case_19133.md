# Metric Case 02: Pantry Use and Restock Efficiency

- Scenario link: `../demo_scenarios/02_pantry_stretch_19133.md`
- Main question: does AccessPlate reduce unnecessary purchases by using food already at home?

## Baseline assumption

- A basic recommender often ignores pantry state and starts from zero.

## AccessPlate evidence to capture

- Whether pantry items were moved out of the buy list
- Whether the first buy improves meal coverage instead of duplicating food already at home
- Number of meals covered per dollar
- Whether the restock signal changed the today plan

## Strong result looks like

- `Use from home first` is clear
- Buy list is shorter than the baseline
- Basket coverage is better for the same or lower cost
