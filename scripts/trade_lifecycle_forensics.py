#!/usr/bin/env python3
"""Per-trade lifecycle forensics for v0.3/v0.4 diagnosis.

Uses only data between entry and exit from the trade CSV (prices + SL/TP).
Without tick/M1 path: MFE/MAE are proxied from exit vs entry/SL/TP geometry
and labeled estimate_quality=price_path_missing when bars are unavailable.

Frozen definitions (do not retune after seeing results):
  early_stop: hold_seconds < 900 OR (mae_r >= 0.7 and hold_bars_m5 <= 3)
  subsequent_favorable: post_exit_continuation_r >= 1.0
    (requires --bars CSV with time,high,low,close; else left blank)

Example:
  python3 scripts/trade_lifecycle_forensics.py \\
    --trades logs/trades_v0.3_armC_dynamic.csv \\
    --out logs/forensics_v0.3_armC_dynamic.csv
"""

from __future__ import annotations

import argparse
import csv
import statistics
from datetime import datetime, timedelta
from pathlib import Path

EARLY_HOLD_SEC = 900.0
EARLY_MAE_R = 0.7
EARLY_BARS = 3.0
CONTINUATION_R = 1.0
CONTINUATION_BARS = 20  # M5 bars after exit


def fnum(x: str | None) -> float | None:
    if x is None or x == "":
        return None
    try:
        return float(x)
    except ValueError:
        return None


def parse_dt(s: str) -> datetime:
    return datetime.strptime(s, "%Y.%m.%d %H:%M:%S")


def load_bars(path: Path | None) -> list[dict]:
    if path is None or not path.exists():
        return []
    rows = []
    with path.open(newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            t = r.get("time") or r.get("datetime") or r.get("Time")
            if not t:
                continue
            try:
                if "." in t and ":" in t:
                    dt = parse_dt(t.replace("-", "."))
                else:
                    dt = datetime.fromisoformat(t)
            except ValueError:
                continue
            hi = fnum(r.get("high") or r.get("High"))
            lo = fnum(r.get("low") or r.get("Low"))
            cl = fnum(r.get("close") or r.get("Close"))
            if hi is None or lo is None or cl is None:
                continue
            rows.append({"dt": dt, "high": hi, "low": lo, "close": cl})
    rows.sort(key=lambda x: x["dt"])
    return rows


def bars_between(bars: list[dict], t0: datetime, t1: datetime) -> list[dict]:
    return [b for b in bars if t0 <= b["dt"] <= t1]


def bars_after(bars: list[dict], t1: datetime, n: int) -> list[dict]:
    after = [b for b in bars if b["dt"] > t1]
    return after[:n]


def classify_exit(reason: str, net: float) -> str:
    r = (reason or "").lower()
    if r == "tp":
        return "tp"
    if r == "sl":
        return "sl_trail" if net > 0 else "sl_initial_loss"
    if r == "other":
        return "other"
    return r or "unknown"


def failure_label(
    exit_class: str,
    early: bool,
    cont_r: float | None,
    closer_to_sl: bool | None,
) -> str:
    if exit_class == "tp":
        return "valid_tp"
    if exit_class == "sl_initial_loss":
        if cont_r is not None and cont_r >= CONTINUATION_R:
            return "initial_sl_too_tight_possible"
        if early:
            return "poor_entry_timing_or_tight_sl"
        return "valid_stop_or_insufficient_evidence"
    if exit_class == "sl_trail":
        if cont_r is not None and cont_r >= CONTINUATION_R:
            return "sl_plus_or_trail_too_early"
        return "trail_into_profit"
    if exit_class == "other":
        if closer_to_sl:
            return "flat_near_sl_suspect"
        return "flat_other"
    return "insufficient_evidence"


def analyze_trade(r: dict, bars: list[dict]) -> dict:
    entry = fnum(r.get("entry_price"))
    exit_p = fnum(r.get("exit_price"))
    sl = fnum(r.get("entry_sl"))
    tp = fnum(r.get("entry_tp"))
    net = fnum(r.get("net")) or 0.0
    hold = fnum(r.get("hold_seconds")) or 0.0
    hold_bars = fnum(r.get("hold_bars_m5")) or 0.0
    side = (r.get("side") or "buy").lower()
    reason = r.get("exit_reason") or ""

    risk = None
    if entry is not None and sl is not None:
        risk = abs(entry - sl)
    if risk is None or risk <= 0:
        risk = None

    mfe = mae = None
    mfe_r = mae_r = None
    cont_r = None
    estimate = "price_path_missing"
    time_to_mfe = ""

    t0 = t1 = None
    try:
        t0 = parse_dt(r["entry_time"])
        t1 = parse_dt(r["exit_time"])
    except (KeyError, ValueError):
        pass

    if bars and t0 and t1 and entry is not None and risk:
        path = bars_between(bars, t0, t1)
        if path:
            estimate = "m5_ohlc"
            if side == "buy":
                mfe = max(b["high"] for b in path) - entry
                mae = entry - min(b["low"] for b in path)
            else:
                mfe = entry - min(b["low"] for b in path)
                mae = max(b["high"] for b in path) - entry
            mfe_r = mfe / risk if risk else None
            mae_r = mae / risk if risk else None
            # rough time-to-MFE: first bar that tags MFE high/low
            for b in path:
                if side == "buy" and abs(b["high"] - entry - (mfe or 0)) < 1e-9:
                    time_to_mfe = str(int((b["dt"] - t0).total_seconds()))
                    break
                if side == "sell" and abs(entry - b["low"] - (mfe or 0)) < 1e-9:
                    time_to_mfe = str(int((b["dt"] - t0).total_seconds()))
                    break
            after = bars_after(bars, t1, CONTINUATION_BARS)
            if after and exit_p is not None:
                if side == "buy":
                    cont = max(b["high"] for b in after) - exit_p
                else:
                    cont = exit_p - min(b["low"] for b in after)
                cont_r = cont / risk
        else:
            # fallback geometry
            if exit_p is not None and entry is not None:
                fav = (exit_p - entry) if side == "buy" else (entry - exit_p)
                mfe = max(fav, 0.0)
                mae = max(-fav, 0.0)
                mfe_r = mfe / risk
                mae_r = mae / risk
    elif entry is not None and exit_p is not None and risk:
        fav = (exit_p - entry) if side == "buy" else (entry - exit_p)
        mfe = max(fav, 0.0)
        mae = max(-fav, 0.0)
        mfe_r = mfe / risk
        mae_r = mae / risk

    closer_to_sl = None
    if entry is not None and exit_p is not None and sl is not None and tp is not None:
        d_sl = abs(exit_p - sl)
        d_tp = abs(exit_p - tp)
        closer_to_sl = d_sl <= d_tp

    exit_class = classify_exit(reason, net)
    early = False
    if hold < EARLY_HOLD_SEC:
        early = True
    if mae_r is not None and mae_r >= EARLY_MAE_R and hold_bars <= EARLY_BARS:
        early = True

    label = failure_label(exit_class, early, cont_r, closer_to_sl)

    return {
        "trade_id": r.get("trade_id", ""),
        "set_name": r.get("set_name", ""),
        "side": side,
        "entry_time": r.get("entry_time", ""),
        "exit_time": r.get("exit_time", ""),
        "entry_price": r.get("entry_price", ""),
        "exit_price": r.get("exit_price", ""),
        "entry_sl": r.get("entry_sl", ""),
        "entry_tp": r.get("entry_tp", ""),
        "exit_reason": reason,
        "exit_class": exit_class,
        "net": f"{net:.4f}",
        "hold_seconds": f"{hold:.0f}",
        "risk_price": f"{risk:.5f}" if risk else "",
        "mfe": f"{mfe:.5f}" if mfe is not None else "",
        "mae": f"{mae:.5f}" if mae is not None else "",
        "mfe_r": f"{mfe_r:.4f}" if mfe_r is not None else "",
        "mae_r": f"{mae_r:.4f}" if mae_r is not None else "",
        "time_to_mfe_sec": time_to_mfe,
        "post_exit_continuation_r": f"{cont_r:.4f}" if cont_r is not None else "",
        "early_stop": "1" if early else "0",
        "subsequent_favorable": (
            "1" if cont_r is not None and cont_r >= CONTINUATION_R else
            ("0" if cont_r is not None else "")
        ),
        "closer_to_sl": "" if closer_to_sl is None else ("1" if closer_to_sl else "0"),
        "failure_label": label,
        "estimate_quality": estimate,
    }


def summarize(rows: list[dict]) -> str:
    n = len(rows)
    if n == 0:
        return "no trades"
    early = sum(1 for r in rows if r["early_stop"] == "1")
    by_label: dict[str, int] = {}
    by_class: dict[str, int] = {}
    for r in rows:
        by_label[r["failure_label"]] = by_label.get(r["failure_label"], 0) + 1
        by_class[r["exit_class"]] = by_class.get(r["exit_class"], 0) + 1
    cont = [float(r["post_exit_continuation_r"]) for r in rows if r["post_exit_continuation_r"]]
    lines = [
        f"trades={n}",
        f"early_stop={early} ({100*early/n:.1f}%)",
        f"exit_class={by_class}",
        f"failure_label={by_label}",
    ]
    if cont:
        lines.append(
            f"continuation_r median={statistics.median(cont):.3f} "
            f"pct_ge_1R={100*sum(1 for x in cont if x >= 1)/len(cont):.1f}%"
        )
    else:
        lines.append("continuation_r=unavailable (pass --bars for M5 OHLC)")
    lines.append(
        f"defs: early_hold<{EARLY_HOLD_SEC}s OR mae_r>={EARLY_MAE_R} in first {EARLY_BARS} M5; "
        f"favorable=post_exit>={CONTINUATION_R}R over {CONTINUATION_BARS} bars"
    )
    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--trades", type=Path, required=True)
    ap.add_argument("--bars", type=Path, default=None, help="Optional M5 OHLC CSV")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--summary", type=Path, default=None)
    args = ap.parse_args()

    with args.trades.open(newline="", encoding="utf-8") as f:
        trades = list(csv.DictReader(f))
    bars = load_bars(args.bars)
    out_rows = [analyze_trade(t, bars) for t in trades if fnum(t.get("net")) is not None]

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fields = list(out_rows[0].keys()) if out_rows else [
        "trade_id", "failure_label", "early_stop", "estimate_quality"
    ]
    with args.out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(out_rows)

    text = summarize(out_rows)
    print(text)
    if args.summary:
        args.summary.write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
