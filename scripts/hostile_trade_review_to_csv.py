#!/usr/bin/env python3
"""Recompute hostile trade-log scoreboard + improvement backlog CSVs.

Research only — never invent Mode S / salary / promote pass.

Example:
  python3 scripts/hostile_trade_review_to_csv.py \\
    --trades logs/trades_v0.3_armC_smc_full_long.csv \\
    --out-metrics logs/hostile_metrics_v0.3_armC_smc_full_long.csv \\
    --out-improvements logs/hostile_improvements_v0.3_armC_smc_full_long.csv
"""

from __future__ import annotations

import argparse
import csv
import statistics
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


METRICS_FIELDS = [
    "set_name",
    "report_file",
    "slice_type",
    "slice_key",
    "n",
    "wins",
    "losses",
    "win_rate",
    "net",
    "avg_win",
    "avg_loss",
    "profit_factor",
    "expectancy",
    "max_consec_wins",
    "max_consec_losses",
    "worst_losing_streak_sum",
    "largest_win",
    "largest_loss",
    "planned_rr_median",
    "realized_r_median",
    "hold_seconds_median",
    "notes",
]

IMPROVEMENT_FIELDS = [
    "set_name",
    "rank",
    "issue_id",
    "problem",
    "why_it_matters",
    "evidence_from_csv",
    "correction",
    "test_required",
    "suggested_set_name",
    "param_changes",
    "baseline_set",
    "status",
    "promote_eligible",
]


def fnum(x: str | None) -> float | None:
    if x is None or x == "":
        return None
    try:
        return float(x)
    except ValueError:
        return None


def normalize_entry_tag(comment: str | None, tag: str | None = None) -> str:
    """Map deal comments to BUY&SEL / PYRAMID (handles BUY&SELL-1, trailing dashes)."""
    raw = (tag or "").strip().upper()
    cmt = (comment or "").strip().upper()
    blob = f"{cmt} {raw}"
    if "PYRAMID" in blob:
        return "PYRAMID"
    if "BUY&SELL" in blob or "BUY&SEL" in blob:
        return "BUY&SEL"
    if raw in ("BUY&SEL", "BUY&SELL", "PYRAMID"):
        return "BUY&SEL" if raw.startswith("BUY") else "PYRAMID"
    return (tag or "").strip()


def parse_dt(s: str) -> datetime:
    return datetime.strptime(s, "%Y.%m.%d %H:%M:%S")


def median_or_blank(vals: list[float]) -> str:
    if not vals:
        return ""
    return f"{statistics.median(vals):.6g}"


def fmt(x: float | None, digits: int = 4) -> str:
    if x is None:
        return ""
    if isinstance(x, float) and (x != x):  # NaN
        return ""
    return f"{x:.{digits}f}".rstrip("0").rstrip(".") if digits else str(x)


def load_trades(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    out: list[dict] = []
    for r in rows:
        net = fnum(r.get("net"))
        if net is None:
            continue
        entry = fnum(r.get("entry_price"))
        exit_p = fnum(r.get("exit_price"))
        sl = fnum(r.get("entry_sl"))
        tp = fnum(r.get("entry_tp"))
        vol = fnum(r.get("entry_volume"))
        hold = fnum(r.get("hold_seconds"))
        layer = fnum(r.get("same_basket_entries_open"))
        risk_dist = abs(entry - sl) if entry is not None and sl is not None else None
        planned_rr = (
            abs(tp - entry) / risk_dist
            if entry is not None and tp is not None and risk_dist and risk_dist > 0
            else None
        )
        cash_risk = (
            vol * risk_dist * 100.0
            if vol is not None and risk_dist is not None
            else None
        )
        realized_r = net / cash_risk if cash_risk and cash_risk > 0 else None
        out.append(
            {
                **r,
                "net": net,
                "entry_price": entry,
                "exit_price": exit_p,
                "entry_sl": sl,
                "entry_tp": tp,
                "entry_volume": vol,
                "hold_seconds": hold,
                "layer": int(layer) if layer is not None else None,
                "entry_tag": normalize_entry_tag(
                    r.get("entry_comment"), r.get("entry_tag")
                ),
                "exit_reason": (r.get("exit_reason") or "").strip().lower(),

                "month": (r.get("month") or "").strip(),
                "et": parse_dt(r["entry_time"]),
                "xt": parse_dt(r["exit_time"]),
                "planned_rr": planned_rr,
                "realized_r": realized_r,
            }
        )
    return out


def streak_stats(nets: list[float]) -> tuple[int, int, float]:
    max_cw = max_cl = cw = cl = 0
    for n in nets:
        if n > 0:
            cw += 1
            cl = 0
            max_cw = max(max_cw, cw)
        elif n < 0:
            cl += 1
            cw = 0
            max_cl = max(max_cl, cl)
        else:
            cw = cl = 0
    streak_sums: list[float] = []
    cur = 0.0
    for n in nets:
        if n < 0:
            cur += n
        else:
            if cur < 0:
                streak_sums.append(cur)
            cur = 0.0
    if cur < 0:
        streak_sums.append(cur)
    worst = min(streak_sums) if streak_sums else 0.0
    return max_cw, max_cl, worst


def slice_metrics(
    trades: list[dict],
    set_name: str,
    report_file: str,
    slice_type: str,
    slice_key: str,
    notes: str = "",
) -> dict[str, str]:
    nets = [t["net"] for t in trades]
    wins = [n for n in nets if n > 0]
    losses = [n for n in nets if n < 0]
    n = len(nets)
    gw = sum(wins)
    gl = abs(sum(losses))
    pf = (gw / gl) if gl > 0 else (float("inf") if gw > 0 else 0.0)
    max_cw, max_cl, worst = streak_stats(nets)
    planned = [t["planned_rr"] for t in trades if t["planned_rr"] is not None]
    realized = [t["realized_r"] for t in trades if t["realized_r"] is not None]
    holds = [t["hold_seconds"] for t in trades if t["hold_seconds"] is not None]
    return {
        "set_name": set_name,
        "report_file": report_file,
        "slice_type": slice_type,
        "slice_key": slice_key,
        "n": str(n),
        "wins": str(len(wins)),
        "losses": str(len(losses)),
        "win_rate": f"{(100.0 * len(wins) / n):.4f}" if n else "",
        "net": f"{sum(nets):.4f}" if n else "",
        "avg_win": f"{(gw / len(wins)):.4f}" if wins else "",
        "avg_loss": f"{(sum(losses) / len(losses)):.4f}" if losses else "",
        "profit_factor": ("inf" if pf == float("inf") else f"{pf:.4f}") if n else "",
        "expectancy": f"{(sum(nets) / n):.4f}" if n else "",
        "max_consec_wins": str(max_cw),
        "max_consec_losses": str(max_cl),
        "worst_losing_streak_sum": f"{worst:.4f}",
        "largest_win": f"{max(nets):.4f}" if nets else "",
        "largest_loss": f"{min(nets):.4f}" if nets else "",
        "planned_rr_median": median_or_blank(planned),
        "realized_r_median": median_or_blank(realized),
        "hold_seconds_median": median_or_blank(holds),
        "notes": notes,
    }


def reconstruct_baskets(trades: list[dict]) -> dict[int, list[dict]]:
    """Assign basket ids from overlapping same-side opens (layer field)."""
    ordered = sorted(trades, key=lambda t: (t["et"], int(t.get("trade_id") or 0)))
    events: list[tuple] = []
    for t in ordered:
        events.append((t["et"], 0, "entry", t))
        events.append((t["xt"], 1, "exit", t))
    events.sort(key=lambda x: (x[0], x[1], int(x[3].get("trade_id") or 0)))

    open_trades: list[dict] = []
    basket_of: dict[int, int] = {}
    basket_trades: dict[int, list[dict]] = defaultdict(list)
    next_basket = 0

    for _t, _prio, kind, r in events:
        if kind == "entry":
            if (r["layer"] == 0) or (not open_trades):
                next_basket += 1
                active = next_basket
            else:
                bids = Counter(basket_of[id(x)] for x in open_trades)
                active = bids.most_common(1)[0][0]
            basket_of[id(r)] = active
            open_trades.append(r)
            basket_trades[active].append(r)
        else:
            if r in open_trades:
                open_trades.remove(r)
    return dict(basket_trades)


def build_metrics_rows(trades: list[dict]) -> list[dict[str, str]]:
    set_name = trades[0].get("set_name", "") if trades else ""
    report_file = trades[0].get("report_file", "") if trades else ""
    rows: list[dict[str, str]] = []

    rows.append(
        slice_metrics(
            trades,
            set_name,
            report_file,
            "overall",
            "all",
            notes="research units; not Mode S",
        )
    )

    months = sorted({t["month"] for t in trades if t["month"]})
    for m in months:
        rows.append(
            slice_metrics(
                [t for t in trades if t["month"] == m],
                set_name,
                report_file,
                "month",
                m,
            )
        )

    for er in sorted({t["exit_reason"] for t in trades}):
        sub = [t for t in trades if t["exit_reason"] == er]
        note = ""
        if er == "other":
            d_tp = [
                abs(t["exit_price"] - t["entry_tp"])
                for t in sub
                if t["exit_price"] is not None and t["entry_tp"] is not None
            ]
            d_sl = [
                abs(t["exit_price"] - t["entry_sl"])
                for t in sub
                if t["exit_price"] is not None and t["entry_sl"] is not None
            ]
            closer_sl = 0
            for t in sub:
                if (
                    t["exit_price"] is None
                    or t["entry_tp"] is None
                    or t["entry_sl"] is None
                ):
                    continue
                if abs(t["exit_price"] - t["entry_sl"]) < abs(
                    t["exit_price"] - t["entry_tp"]
                ):
                    closer_sl += 1
            note = (
                f"pct_of_all={100*len(sub)/len(trades):.1f};"
                f"avg_abs_exit_tp={sum(d_tp)/len(d_tp):.4f};"
                f"avg_abs_exit_sl={sum(d_sl)/len(d_sl):.4f};"
                f"closer_to_sl={closer_sl}/{len(sub)}"
                if d_tp and d_sl
                else f"pct_of_all={100*len(sub)/len(trades):.1f}"
            )
        elif er == "sl":
            trail_wins = sum(1 for t in sub if t["net"] > 0)
            note = f"trail_or_moved_sl_wins={trail_wins};pure_sl_losses={sum(1 for t in sub if t['net']<0)}"
        rows.append(
            slice_metrics(sub, set_name, report_file, "exit_reason", er, notes=note)
        )

    for tag in sorted({t["entry_tag"] for t in trades}):
        rows.append(
            slice_metrics(
                [t for t in trades if t["entry_tag"] == tag],
                set_name,
                report_file,
                "entry_tag",
                tag,
            )
        )

    # layer depth: 0, 1, 2+
    buckets = {"0": [], "1": [], "2+": []}
    for t in trades:
        L = t["layer"]
        if L is None:
            continue
        if L == 0:
            buckets["0"].append(t)
        elif L == 1:
            buckets["1"].append(t)
        else:
            buckets["2+"].append(t)
    for key in ("0", "1", "2+"):
        if buckets[key]:
            rows.append(
                slice_metrics(
                    buckets[key],
                    set_name,
                    report_file,
                    "layer_depth",
                    key,
                )
            )

    # also per exact depth
    by_l: dict[int, list[dict]] = defaultdict(list)
    for t in trades:
        if t["layer"] is not None:
            by_l[t["layer"]].append(t)
    for L in sorted(by_l):
        rows.append(
            slice_metrics(
                by_l[L],
                set_name,
                report_file,
                "layer_depth",
                str(L),
                notes="exact_depth",
            )
        )

    baskets = reconstruct_baskets(trades)
    basket_nets_ordered: list[float] = []
    basket_trades_as_rows: list[dict] = []
    for bid in sorted(
        baskets.keys(), key=lambda b: min(t["et"] for t in baskets[b])
    ):
        ts = baskets[bid]
        nnet = sum(t["net"] for t in ts)
        basket_nets_ordered.append(nnet)
        last = max(ts, key=lambda t: t["xt"])
        # synthetic one-row trade for slice_metrics on basket P&L list
        basket_trades_as_rows.append(
            {
                "net": nnet,
                "planned_rr": None,
                "realized_r": None,
                "hold_seconds": None,
                "month": last["month"],
            }
        )

    # basket overall via manual metrics on basket nets
    rows.append(
        slice_metrics(
            basket_trades_as_rows,
            set_name,
            report_file,
            "basket_overall",
            "all",
            notes=f"n_baskets={len(baskets)};avg_size={len(trades)/len(baskets):.2f};"
            f"multi_layer_net_neg={sum(1 for b,ts in baskets.items() if len(ts)>1 and sum(t['net'] for t in ts)<0)}",
        )
    )
    for m in months:
        sub = [b for b in basket_trades_as_rows if b["month"] == m]
        if sub:
            rows.append(
                slice_metrics(
                    sub,
                    set_name,
                    report_file,
                    "basket_month",
                    m,
                )
            )

    # H5 taxonomy split for SL
    sl_rows = [t for t in trades if t["exit_reason"] == "sl"]
    sl_trail = [t for t in sl_rows if t["net"] > 0]
    sl_init = [t for t in sl_rows if t["net"] < 0]
    if sl_trail:
        rows.append(
            slice_metrics(
                sl_trail,
                set_name,
                report_file,
                "exit_reason",
                "sl_trail",
                notes="analysis_split: sl label + net>0",
            )
        )
    if sl_init:
        rows.append(
            slice_metrics(
                sl_init,
                set_name,
                report_file,
                "exit_reason",
                "sl_initial_loss",
                notes="analysis_split: sl label + net<0",
            )
        )

    return rows


def build_improvement_rows(set_name: str, trades: list[dict]) -> list[dict[str, str]]:
    baseline = set_name if set_name.endswith(".set") else f"{set_name}.set"
    stem = baseline.replace(".set", "")
    n = len(trades)
    other_n = sum(1 for t in trades if t["exit_reason"] == "other")
    tp_n = sum(1 for t in trades if t["exit_reason"] == "tp")
    parent = [t for t in trades if t["entry_tag"] == "BUY&SEL"]
    parent_net = sum(t["net"] for t in parent) if parent else 0.0
    pyramid_n = sum(1 for t in trades if t["entry_tag"] == "PYRAMID")
    layers = [t["layer"] for t in trades if t["layer"] is not None]
    max_layer = max(layers) if layers else 0
    jan = [t for t in trades if t["month"] == "2026-01"]
    feb = [t for t in trades if t["month"] == "2026-02"]
    jan_net = sum(t["net"] for t in jan) if jan else 0.0
    feb_net = sum(t["net"] for t in feb) if feb else 0.0
    sl_trail = sum(1 for t in trades if t["exit_reason"] == "sl" and t["net"] > 0)
    # Peak-exit knobs exist on smc_full_* sets; armC_dynamic uses MinProfit/Dist flats.
    use_peak_exps = "smc_full" in stem or "peak" in stem

    flat_seeds = (
        [
            {
                "rank": "3",
                "issue_id": "H1/H6",
                "exp": "EXP-FLATTIGHT",
                "problem": "High share of inferred flats; TP rare relative to flats but drives net",
                "why": "Edge attribution is basket MinProfit/Dist flat logic not planned R:R (no InpLongPeakExit on this EA)",
                "evidence": f"other_n={other_n}/{n};tp_n={tp_n};peak_knobs=N/A",
                "correction": "Raise MinProfit basket flat barrier so fewer early flats",
                "test": "Same period: other%%, TP-hit%%, episode E vs baseline",
                "params": "MinProfit=0.01",
            },
            {
                "rank": "4",
                "issue_id": "H1/H6",
                "exp": "EXP-DIST",
                "problem": "Dist/MinProfit path may flat near SL before structure TP",
                "why": "Widen Dist to reduce premature basket-style flats",
                "evidence": f"other_n={other_n}/{n};baseline_Dist=20",
                "correction": "Widen Dist from 20 to 40",
                "test": "other%% and TP-hit%% vs FLATTIGHT and baseline",
                "params": "Dist=40",
            },
        ]
        if not use_peak_exps
        else [
            {
                "rank": "3",
                "issue_id": "H1/H6",
                "exp": "EXP-PEAKOFF",
                "problem": "High share of inferred flats; TP rare but drives almost all net",
                "why": "Edge attribution is flat/peak logic not planned R:R structure",
                "evidence": f"other_n={other_n}/{n};tp_n={tp_n};other_closer_to_sl_dominant",
                "correction": "Disable long peak giveback exit so more paths reach SL/TP",
                "test": "Same period: other%%, TP-hit%%, episode E vs baseline",
                "params": "InpLongPeakExit=false",
            },
            {
                "rank": "4",
                "issue_id": "H1/H6",
                "exp": "EXP-PEAKATR",
                "problem": "Peak giveback 0.5 ATR may cut winners/near-SL flats early",
                "why": "Widen giveback before abandoning peak-exit path entirely",
                "evidence": "baseline_InpPeakGivebackATR=0.5;other_avg_near_sl",
                "correction": "Keep peak exit but raise giveback ATR to 1.0",
                "test": "other%% and TP-hit%% vs PEAKOFF and baseline",
                "params": "InpLongPeakExit=true;InpPeakGivebackATR=1.0",
            },
        ]
    )

    seeds = [
        {
            "rank": "1",
            "issue_id": "H3/H4",
            "exp": "EXP-L1",
            "problem": "Over-layering and correlated layer win-rate illusion; parents often drag",
            "why": "Trade WR overstates episode skill; episode risk stacks on losers",
            "evidence": f"parent_net={parent_net:.2f};pyramid_share={100*pyramid_n/n:.1f}%;max_layer_open={max_layer}",
            "correction": "Model A single-leg: InpMaxLayers=1 MaxTrades=1; keep InpMaxEpisodeRiskPct=3",
            "test": "Compare basket WR/PF/worst streak vs baseline on same range",
            "params": "InpMaxLayers=1;MaxTrades=1",
        },
        {
            "rank": "2",
            "issue_id": "H3/H4",
            "exp": "EXP-L3",
            "problem": "Deep baskets; multi-layer books can close net-negative",
            "why": "Need middle pin between single-leg and full 5-layer book",
            "evidence": f"max_layer_open={max_layer};baseline_InpMaxLayers=5",
            "correction": "Cap layers at 3 with matching MaxTrades",
            "test": "max_layers matrix {1,3,5} under fixed episode cash-risk budget",
            "params": "InpMaxLayers=3;MaxTrades=3",
        },
        *flat_seeds,
        {
            "rank": "5",
            "issue_id": "H2",
            "exp": "EXP-REGIME",
            "problem": "Month instability; pooled PF can hide a weak month",
            "why": "Promote on pooled net would be misleading",
            "evidence": f"jan_net={jan_net:.2f};feb_net={feb_net:.2f}",
            "correction": "Enable regime gate FAIL→WAIT on UNKNOWN/HIGH_VOL; freeze params for Feb OOS",
            "test": "Walk-forward: freeze on Jan-style window, score Feb without retune",
            "params": "InpUseRegimeGate=true",
        },
        {
            "rank": "6",
            "issue_id": "H5",
            "exp": "EXP-SLTAX",
            "problem": "SL label mixes trail-into-profit wins with true stop losses",
            "why": "Contaminates SL quality; understates stop-loss damage",
            "evidence": f"sl_trail_wins={sl_trail}",
            "correction": "Analysis-only taxonomy: sl_trail vs sl_initial_loss (no Tester re-run)",
            "test": "Use metrics CSV exit_reason=sl_trail / sl_initial_loss before risk conclusions",
            "params": "analysis_only=true",
        },
    ]

    rows: list[dict[str, str]] = []
    for s in seeds:
        rows.append(
            {
                "set_name": baseline,
                "rank": s["rank"],
                "issue_id": s["issue_id"],
                "problem": s["problem"],
                "why_it_matters": s["why"],
                "evidence_from_csv": s["evidence"],
                "correction": s["correction"],
                "test_required": s["test"],
                "suggested_set_name": f"{stem}_{s['exp'].lower().replace('exp-','')}.set"
                if s["exp"] != "EXP-SLTAX"
                else "",
                "param_changes": s["params"],
                "baseline_set": baseline,
                "status": "proposed",
                "promote_eligible": "false",
            }
        )
    return rows


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow(r)


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Hostile trade-log review → metrics + improvements CSVs (research only)."
    )
    p.add_argument("--trades", type=Path, required=True, help="trades_*.csv path")
    p.add_argument(
        "--out-metrics",
        type=Path,
        default=None,
        help="Output metrics CSV (default: logs/hostile_metrics_<stem>.csv)",
    )
    p.add_argument(
        "--out-improvements",
        type=Path,
        default=None,
        help="Output improvements CSV (default: logs/hostile_improvements_<stem>.csv)",
    )
    return p


def main() -> int:
    args = build_arg_parser().parse_args()
    trades_path = args.trades
    if not trades_path.is_file():
        print(f"ERR missing trades CSV: {trades_path}", file=__import__("sys").stderr)
        return 1

    trades = load_trades(trades_path)
    if not trades:
        print("ERR no trades loaded", file=__import__("sys").stderr)
        return 1

    stem = trades_path.stem
    if stem.startswith("trades_"):
        stem = stem[len("trades_") :]

    out_metrics = args.out_metrics or Path(f"logs/hostile_metrics_{stem}.csv")
    out_improvements = args.out_improvements or Path(
        f"logs/hostile_improvements_{stem}.csv"
    )

    metrics_rows = build_metrics_rows(trades)
    set_name = trades[0].get("set_name", stem)
    improvement_rows = build_improvement_rows(set_name, trades)

    write_csv(out_metrics, METRICS_FIELDS, metrics_rows)
    write_csv(out_improvements, IMPROVEMENT_FIELDS, improvement_rows)

    print(f"OK metrics={out_metrics} rows={len(metrics_rows)}")
    print(f"OK improvements={out_improvements} rows={len(improvement_rows)}")
    print("NOTE research only; promote_eligible=false; not Mode S")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
