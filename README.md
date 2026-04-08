# Crash Cash Data Tracker + Excel Model (V2)

This toolkit helps you track crash-game outcomes, analyze distribution changes, and choose data-driven cash-out targets.

## Important risk note
Crash games are usually negative-EV after edge/fees and have severe variance. This toolkit improves discipline and measurement, but it **cannot remove risk**.

## What's included
- `data/crash_rounds.csv` — tracker template for each round.
- `scripts/analyze_crash.py` — V2 analysis script (rolling window, confidence intervals, train/test, simulation).
- `excel/Excel_Model_Guide.md` — step-by-step Excel formulas for a no-code model.

## Quick start
1. Track rounds in `data/crash_rounds.csv`.
2. Run analysis with a rolling window:
   ```bash
   python3 scripts/analyze_crash.py \
     --input data/crash_rounds.csv \
     --min-target 1.10 --max-target 5.00 --step 0.05 \
     --house-edge 0.01 --window-size 500 --test-ratio 0.20 \
     --export-targets output/targets_ev.csv
   ```
3. Optionally run Monte Carlo risk checks:
   ```bash
   python3 scripts/analyze_crash.py \
     --input data/crash_rounds.csv \
     --simulate-rounds 300 --sim-trials 2000 \
     --starting-bankroll 100 --bet-size 1
   ```

## What V2 adds
- **Rolling window** (`--window-size`): focuses on latest regime instead of all-time blended behavior.
- **Out-of-sample test** (`--test-ratio`): picks a target on train data, then validates on holdout rounds.
- **95% confidence intervals**: Wilson interval for each target's reach probability.
- **CSV export** (`--export-targets`): one file you can import directly into Excel.
- **Monte Carlo bankroll check** (`--simulate-rounds`): estimates ruin rate and ending bankroll spread for top targets.

## Recommended operating routine
- Recompute weekly or every N=200 rounds.
- If optimized target shifts materially, update in small increments.
- If test EV is negative, reduce risk or pause.
- Keep strict stop-loss and max bet rules.

## Suggested safety rules
- Hard session stop-loss (e.g., 20 units)
- Max bet size cap (e.g., <= 1% bankroll per round)
- No progression/martingale after losses
- Stop if emotional tilt appears
