#!/usr/bin/env python3
"""Build a headless MT5 Strategy Tester .ini from a Gold Rush .set file."""
from __future__ import annotations

import argparse
from pathlib import Path


def parse_set(path: Path) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith(";") or "=" not in line:
            continue
        key, val = line.split("=", 1)
        rows.append((key.strip(), val.strip()))
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--set", required=True, type=Path, help="path to .set")
    ap.add_argument("--out", required=True, type=Path, help="output .ini path")
    ap.add_argument("--expert", default=r"gold_rush_AI\gold_rush_AI_v0.3_smc_a.ex5")
    ap.add_argument("--symbol", default="XAUUSD")
    ap.add_argument("--period", default="M5")
    ap.add_argument("--deposit", type=int, default=5000)
    ap.add_argument("--model", type=int, default=0, help="0=every tick, 1=1min OHLC")
    ap.add_argument("--execution-mode", type=int, default=1000,
                    help="Delays ms (GUI Delays); 0=no delay, 1000=emulate slippage")
    ap.add_argument("--from-date", default="2026.01.01")
    ap.add_argument("--to-date", default="2026.03.01")
    ap.add_argument("--report-name", required=True, help="Report= basename (no extension)")
    ap.add_argument("--leverage", type=int, default=200)
    args = ap.parse_args()

    if not args.set.is_file():
        raise SystemExit(f"missing set: {args.set}")

    inputs = parse_set(args.set)
    # Avoid MT5 sticky Expert inputs when older .set files omit InpTradeSide
    # (0=Both, 1=LongOnly, 2=ShortOnly). Missing → EA default Both.
    if not any(k == "InpTradeSide" for k, _ in inputs):
        inputs.append(("InpTradeSide", "0||0||1||2||N"))
    stem_comment = next((v.split("||")[0] for k, v in inputs if k == "comment"), args.set.stem)

    lines = [
        f"; headless tester for {stem_comment}",
        "[Tester]",
        f"Expert={args.expert}",
        f"Symbol={args.symbol}",
        f"Period={args.period}",
        "Optimization=0",
        f"Model={args.model}",
        f"FromDate={args.from_date}",
        f"ToDate={args.to_date}",
        "ForwardMode=0",
        f"Deposit={args.deposit}",
        "Currency=USD",
        "ProfitInPips=0",
        f"Leverage={args.leverage}",
        f"ExecutionMode={args.execution_mode}",
        "OptimizationCriterion=0",
        "Visual=0",
        f"Report={args.report_name}",
        "ReplaceReport=1",
        "ShutdownTerminal=1",
        "[TesterInputs]",
    ]
    for key, val in inputs:
        lines.append(f"{key}={val}")
    lines.append("")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {args.out} inputs={len(inputs)} report={args.report_name}")


if __name__ == "__main__":
    main()
