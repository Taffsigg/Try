#!/usr/bin/env python3
"""Analyze crash multipliers and optimize cash-out targets from historical data.

V2 features:
- Optional rolling window analysis (`--window-size`)
- Optional train/test split (`--test-ratio`)
- Wilson confidence intervals for target reach probability
- Optional export of target table to CSV (`--export-targets`)
- Optional bankroll Monte Carlo (`--simulate-rounds` + `--starting-bankroll`)
"""

from __future__ import annotations

import argparse
import csv
import math
import random
from dataclasses import dataclass
from pathlib import Path
from statistics import mean, median


@dataclass
class TargetRow:
    target: float
    p_reach: float
    p_low: float
    p_high: float
    ev_per_unit: float


@dataclass
class SimResult:
    target: float
    ruin_rate: float
    median_ending_bankroll: float


def load_multipliers(path: Path) -> list[float]:
    rows: list[float] = []
    with path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if "crash_multiplier" not in (reader.fieldnames or []):
            raise ValueError("CSV must include a 'crash_multiplier' column")

        for line in reader:
            raw = (line.get("crash_multiplier") or "").strip()
            if not raw:
                continue
            val = float(raw)
            if val <= 1.0:
                continue
            rows.append(val)

    if not rows:
        raise ValueError("No valid crash_multiplier values > 1.0 found")
    return rows


def percentile(sorted_vals: list[float], p: float) -> float:
    if not sorted_vals:
        raise ValueError("Cannot compute percentile on empty list")
    idx = max(0, min(len(sorted_vals) - 1, math.ceil((p / 100.0) * len(sorted_vals)) - 1))
    return sorted_vals[idx]


def probability_reach(vals: list[float], target: float) -> tuple[float, int, int]:
    n = len(vals)
    hits = sum(1 for v in vals if v >= target)
    return hits / n, hits, n


def wilson_interval(hits: int, n: int, z: float = 1.96) -> tuple[float, float]:
    if n == 0:
        return 0.0, 0.0
    phat = hits / n
    denom = 1 + (z * z / n)
    center = (phat + (z * z) / (2 * n)) / denom
    margin = (z / denom) * math.sqrt((phat * (1 - phat) / n) + ((z * z) / (4 * n * n)))
    return max(0.0, center - margin), min(1.0, center + margin)


def ev_for_target(p_reach: float, target: float, house_edge: float) -> float:
    return p_reach * (target - 1.0) - (1.0 - p_reach) - house_edge


def analyze_targets(vals: list[float], min_target: float, max_target: float, step: float, house_edge: float) -> list[TargetRow]:
    rows: list[TargetRow] = []
    t = min_target
    while t <= max_target + 1e-9:
        p, hits, n = probability_reach(vals, t)
        p_low, p_high = wilson_interval(hits, n)
        ev = ev_for_target(p, t, house_edge)
        rows.append(TargetRow(target=round(t, 4), p_reach=p, p_low=p_low, p_high=p_high, ev_per_unit=ev))
        t += step
    return rows


def split_train_test(vals: list[float], test_ratio: float) -> tuple[list[float], list[float]]:
    split_idx = int(len(vals) * (1 - test_ratio))
    split_idx = max(1, min(len(vals) - 1, split_idx))
    return vals[:split_idx], vals[split_idx:]


def simulate_bankroll(
    targets: list[float],
    p_map: dict[float, float],
    bankroll_start: float,
    bet_size: float,
    rounds: int,
    trials: int,
) -> list[SimResult]:
    out: list[SimResult] = []
    for target in targets:
        p = p_map[target]
        ruins = 0
        endings: list[float] = []
        for _ in range(trials):
            bank = bankroll_start
            for _ in range(rounds):
                if bank < bet_size:
                    ruins += 1
                    break
                if random.random() < p:
                    bank += bet_size * (target - 1)
                else:
                    bank -= bet_size
            endings.append(bank)
        endings_sorted = sorted(endings)
        out.append(
            SimResult(
                target=target,
                ruin_rate=ruins / trials,
                median_ending_bankroll=endings_sorted[len(endings_sorted) // 2],
            )
        )
    return out


def maybe_export(rows: list[TargetRow], export_path: Path | None) -> None:
    if not export_path:
        return
    export_path.parent.mkdir(parents=True, exist_ok=True)
    with export_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["target", "p_reach", "p_reach_low95", "p_reach_high95", "ev_per_unit"])
        for r in rows:
            writer.writerow([f"{r.target:.4f}", f"{r.p_reach:.6f}", f"{r.p_low:.6f}", f"{r.p_high:.6f}", f"{r.ev_per_unit:.6f}"])


def print_summary(vals: list[float], target_rows: list[TargetRow], label: str) -> None:
    svals = sorted(vals)
    print(f"=== {label}: Crash Distribution Summary ===")
    print(f"Rounds analyzed: {len(vals)}")
    print(f"Mean multiplier: {mean(vals):.4f}")
    print(f"Median multiplier: {median(vals):.4f}")
    print(f"P10: {percentile(svals, 10):.4f}")
    print(f"P25: {percentile(svals, 25):.4f}")
    print(f"P75: {percentile(svals, 75):.4f}")
    print(f"P90: {percentile(svals, 90):.4f}")
    print(f"P95: {percentile(svals, 95):.4f}")
    print()

    best = max(target_rows, key=lambda r: r.ev_per_unit)
    print(f"=== {label}: Target Optimization (Empirical) ===")
    print(f"Best target in tested range: {best.target:.2f}x")
    print(f"Estimated reach probability: {best.p_reach:.4%} (95% CI {best.p_low:.4%} to {best.p_high:.4%})")
    print(f"Estimated EV per 1-unit bet: {best.ev_per_unit:.6f}")
    print()

    print("Top 10 targets by EV:")
    top = sorted(target_rows, key=lambda r: r.ev_per_unit, reverse=True)[:10]
    print("target\tp_reach\tp_low95\tp_high95\tev_per_unit")
    for r in top:
        print(f"{r.target:.2f}\t{r.p_reach:.4%}\t{r.p_low:.4%}\t{r.p_high:.4%}\t{r.ev_per_unit:.6f}")
    print()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Analyze crash-game distributions and optimize cash-out targets")
    parser.add_argument("--input", required=True, type=Path, help="CSV input file containing crash_multiplier column")
    parser.add_argument("--min-target", type=float, default=1.10, help="Minimum cash-out target to test")
    parser.add_argument("--max-target", type=float, default=5.00, help="Maximum cash-out target to test")
    parser.add_argument("--step", type=float, default=0.05, help="Step size for target grid")
    parser.add_argument("--house-edge", type=float, default=0.01, help="Per-bet edge/cost in units")
    parser.add_argument("--window-size", type=int, default=0, help="Use only the latest N rounds (0 = all rounds)")
    parser.add_argument("--test-ratio", type=float, default=0.0, help="Hold out final ratio of rounds for out-of-sample check")
    parser.add_argument("--export-targets", type=Path, default=None, help="Optional CSV export path for target table")
    parser.add_argument("--simulate-rounds", type=int, default=0, help="Optional Monte Carlo rounds per trial")
    parser.add_argument("--starting-bankroll", type=float, default=100.0, help="Starting bankroll for simulation")
    parser.add_argument("--bet-size", type=float, default=1.0, help="Fixed bet size for simulation")
    parser.add_argument("--sim-trials", type=int, default=1000, help="Number of Monte Carlo trials")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.min_target <= 1.0:
        raise ValueError("--min-target must be > 1.0")
    if args.max_target < args.min_target:
        raise ValueError("--max-target must be >= --min-target")
    if args.step <= 0:
        raise ValueError("--step must be > 0")
    if not (0 <= args.house_edge < 1):
        raise ValueError("--house-edge must be in [0,1)")
    if not (0 <= args.test_ratio < 0.9):
        raise ValueError("--test-ratio must be in [0, 0.9)")
    if args.window_size < 0:
        raise ValueError("--window-size must be >= 0")

    vals = load_multipliers(args.input)
    if args.window_size > 0:
        vals = vals[-args.window_size :]

    if len(vals) < 30:
        print("Warning: fewer than 30 rounds. Estimates are noisy.")

    train_vals = vals
    test_vals: list[float] = []
    if args.test_ratio > 0 and len(vals) >= 20:
        train_vals, test_vals = split_train_test(vals, args.test_ratio)

    train_targets = analyze_targets(train_vals, args.min_target, args.max_target, args.step, args.house_edge)
    print_summary(train_vals, train_targets, label="Train")

    maybe_export(train_targets, args.export_targets)
    if args.export_targets:
        print(f"Exported target table: {args.export_targets}")

    best_train = max(train_targets, key=lambda r: r.ev_per_unit)

    if test_vals:
        p_test, hits_test, n_test = probability_reach(test_vals, best_train.target)
        low_test, high_test = wilson_interval(hits_test, n_test)
        ev_test = ev_for_target(p_test, best_train.target, args.house_edge)
        print("=== Out-of-sample check ===")
        print(f"Train-chosen target: {best_train.target:.2f}x")
        print(f"Test reach probability: {p_test:.4%} (95% CI {low_test:.4%} to {high_test:.4%})")
        print(f"Test EV per 1-unit bet: {ev_test:.6f}")
        print()

    if args.simulate_rounds > 0:
        top_targets = [r.target for r in sorted(train_targets, key=lambda r: r.ev_per_unit, reverse=True)[:3]]
        p_map = {r.target: r.p_reach for r in train_targets}
        sim = simulate_bankroll(
            targets=top_targets,
            p_map=p_map,
            bankroll_start=args.starting_bankroll,
            bet_size=args.bet_size,
            rounds=args.simulate_rounds,
            trials=args.sim_trials,
        )
        print("=== Monte Carlo (based on empirical p_reach) ===")
        print("target\truin_rate\tmedian_ending_bankroll")
        for s in sim:
            print(f"{s.target:.2f}\t{s.ruin_rate:.2%}\t{s.median_ending_bankroll:.2f}")


if __name__ == "__main__":
    main()
