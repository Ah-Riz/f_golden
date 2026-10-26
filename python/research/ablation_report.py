#!/usr/bin/env python3
"""Arm E vs Arm D ablation helper — compare two digest JSON/CSV rows.

Usage:
  python3 ablation_report.py --d arm_d.json --e arm_e.json

Expect keys: max_dd, expectancy, episode_expectancy, pf, worst_episode_loss,
avg_layers, glm_wait_rate (E only). Does not promote; prints deltas only.
"""
from __future__ import annotations

import argparse
import json
import sys


KEYS = (
    "max_dd",
    "expectancy",
    "episode_expectancy",
    "pf",
    "worst_episode_loss",
    "avg_layers",
)


def load(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--d", required=True)
    ap.add_argument("--e", required=True)
    args = ap.parse_args()
    d, e = load(args.d), load(args.e)
    print("Arm E vs Arm D (negative max_dd / worst_episode_loss = better if more negative? No)")
    print("Convention: max_dd and worst_episode_loss are loss magnitudes (lower better).")
    improve = 0
    for k in KEYS:
        if k not in d or k not in e:
            print(f"  {k}: MISSING")
            continue
        dv, ev = float(d[k]), float(e[k])
        delta = ev - dv
        better = False
        if k in ("max_dd", "worst_episode_loss", "avg_layers"):
            better = ev < dv  # lower better
        else:
            better = ev > dv
        if better:
            improve += 1
        print(f"  {k}: D={dv} E={ev} delta={delta:+.4f} better={better}")
    print(f"metrics_improved={improve}/{len(KEYS)}")
    print("PROMOTION: require multi-metric improvement; explanations alone do not promote.")
    if "glm_wait_rate" in e:
        print(f"  glm_wait_rate={e['glm_wait_rate']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
