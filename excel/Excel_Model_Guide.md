# Excel Model Guide (Crash Cash V2)

This model tracks rounds, computes EV by target, and now supports importing exported target tables from the Python analyzer.

## Sheet 1: `Rounds`
Create an Excel table named `RoundsTbl` with columns:
1. `RoundID`
2. `Timestamp`
3. `CrashMultiplier`
4. `BetSize`
5. `CashoutTarget`
6. `CashedOut` (1/0)
7. `ProfitUnits`
8. `CumProfit`

### Profit formula
```excel
=IF([@CashedOut]=1, [@BetSize]*([@CashoutTarget]-1), -[@BetSize])
```

### Cumulative profit
```excel
=SUM(INDEX(RoundsTbl[ProfitUnits],1):[@ProfitUnits])
```

## Sheet 2: `TargetsManual`
Use this if you are not importing from Python.

- `A2:A` target grid (1.10, 1.15, ..., 5.00)
- `B1` house edge (e.g., 0.01)

### Reach probability
```excel
=COUNTIFS(RoundsTbl[CrashMultiplier],">="&A2)/COUNT(RoundsTbl[CrashMultiplier])
```

### EV per 1-unit bet
```excel
=B2*(A2-1)-(1-B2)-$B$1
```

### Best target / EV
```excel
=INDEX(A2:A200, MATCH(MAX(C2:C200), C2:C200, 0))
```
```excel
=MAX(C2:C200)
```

## Sheet 3: `TargetsImported` (recommended)
1. Run Python with:
   - `--export-targets output/targets_ev.csv`
2. In Excel: **Data > From Text/CSV** and import `targets_ev.csv`.
3. Use imported columns:
   - `target`
   - `p_reach`
   - `p_reach_low95`
   - `p_reach_high95`
   - `ev_per_unit`

This gives you confidence bounds directly in Excel.

## Sheet 4: `Dashboard`
Suggested widgets:
- Total rounds: `=COUNT(RoundsTbl[CrashMultiplier])`
- Mean crash: `=AVERAGE(RoundsTbl[CrashMultiplier])`
- Median crash: `=MEDIAN(RoundsTbl[CrashMultiplier])`
- P10/P50/P90 using `PERCENTILE.INC`
- Line chart of `CumProfit`
- Bar chart of EV by target
- Optional CI band chart from imported low/high probability columns

## Interpretation tips
- If EV is near zero and CI is wide, you likely need more samples.
- If train result and out-of-sample result disagree, trust out-of-sample.
- If all targets are negative EV, focus on loss containment.
