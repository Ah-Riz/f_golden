#!/usr/bin/env python3
"""Stream MT5 Tester UTF-16 journals → Experts / entry CSVs (reusable).

Pass a comment/InpLogTag key and one or more log filenames. The script only
reads those logs (basename resolved under --root, or absolute paths).

Example:
  python3 scripts/extract_tester_experts_csv.py \\
    --comment v0.3_armC_smc_full_long \\
    --log 20261016.log \\
    --log 20261015.log \\
    --root /run/media/lana/Game/mt5-testdata/Tester \\
    --out-dir logs \\
    --report logs/ReportTester-52016350_v0.3_armC_smc_full_long.html
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from html.parser import HTMLParser
from pathlib import Path

DEFAULT_ROOT = Path("/run/media/lana/Game/mt5-testdata/Tester")

DEFAULT_EVENTS = frozenset(
    {
        "INIT",
        "OPEN",
        "SKIP",
        "CLOSE",
        "SL+",
        "ERROR",
        "ERR",
        "LAYER_REJECT",
        "LAYER_ALLOW",
        "RISK_FAIL",
        "RISK_PASS",
        "RISK_RESET",
        "RISK_UP",
        "NEWS",
        "KILL",
        "SMC",
        "BIAS",
    }
)

EVENT_FIELDS = [
    "source_file",
    "wall_time",
    "sim_time",
    "comment",
    "event",
    "message",
    "side",
    "lots",
    "price",
    "sl",
    "tp",
    "ticket",
    "role",
    "episode",
    "mom",
    "regime",
    "bias",
    "risk",
    "riskPct",
    "cmd",
    "reason",
]

DEAL_FIELDS = [
    "time",
    "deal",
    "symbol",
    "type",
    "direction",
    "volume",
    "price",
    "order",
    "commission",
    "swap",
    "profit",
    "balance",
    "comment",
    "month",
    "net",
    "set_name",
    "report_file",
]

TRADE_FIELDS = [
    "trade_id",
    "set_name",
    "report_file",
    "symbol",
    "side",
    "entry_time",
    "entry_deal",
    "entry_order",
    "entry_volume",
    "entry_price",
    "entry_sl",
    "entry_tp",
    "entry_comment",
    "entry_tag",
    "exit_time",
    "exit_deal",
    "exit_order",
    "exit_price",
    "exit_comment",
    "exit_reason",
    "exit_reason_source",
    "commission",
    "swap",
    "profit",
    "net",
    "hold_seconds",
    "hold_bars_m5",
    "month",
    "same_basket_entries_open",
]

# Gold / XAUUSD: allow half-dollar slip vs printed SL/TP when deal comment is empty.
PRICE_TOL = 0.50

KV_RE = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)=([^\s]+)")
SIM_TAG_RE = re.compile(
    r"(?P<sim>\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2}:\d{2})\s+"
    r"\[(?P<tag>[^\]]+)\]\s+"
    r"(?P<event>\S+)\s*(?P<msg>.*)$"
)


def safe_stem(comment: str) -> str:
    return re.sub(r"[^\w.\-]+", "_", comment.strip())


def parse_num(s: str) -> float:
    s = s.replace("\xa0", " ").strip()
    if not s or s == "-":
        return 0.0
    cleaned = s.replace(" ", "").replace(",", "")
    try:
        return float(cleaned)
    except ValueError:
        return 0.0


def probe_contains_tag(path: Path, comment: str, probe_bytes: int = 32 * 1024 * 1024) -> bool:
    pat = comment.encode("utf-16-le")
    try:
        with path.open("rb") as f:
            data = f.read(probe_bytes)
    except OSError:
        return False
    return pat in data


def resolve_logs(
    log_args: list[str],
    root: Path,
    comment: str,
    one_file: bool,
) -> list[Path]:
    """Resolve each --log to concrete Path(s). Basename → search root/**/logs/<name>."""
    resolved: list[Path] = []
    seen: set[Path] = set()

    for raw in log_args:
        p = Path(raw)
        if p.is_file():
            rp = p.resolve()
            if rp not in seen:
                resolved.append(rp)
                seen.add(rp)
            continue

        name = p.name
        hits = sorted(
            (h.resolve() for h in root.glob(f"**/logs/{name}") if h.is_file()),
            key=lambda x: (-x.stat().st_size, str(x)),
        )
        if not hits:
            raise FileNotFoundError(
                f"log not found as path or under {root}/**/logs/{name}: {raw}"
            )

        tagged = [h for h in hits if probe_contains_tag(h, comment)]
        chosen = tagged if tagged else hits
        if one_file:
            chosen = chosen[:1]
            if len(hits) > 1 and not tagged:
                print(
                    f"warn: multiple {name}; no early tag hit — using largest {chosen[0]}",
                    file=sys.stderr,
                )
            elif len(hits) > 1 and tagged:
                print(
                    f"info: multiple {name}; using tag-matching {chosen[0]}",
                    file=sys.stderr,
                )
        else:
            if len(chosen) > 1:
                print(
                    f"info: {name} resolved to {len(chosen)} file(s)",
                    file=sys.stderr,
                )

        for h in chosen:
            if h not in seen:
                resolved.append(h)
                seen.add(h)

    return resolved


def parse_journal_line(line: str, comment: str) -> dict[str, str] | None:
    """Parse one MT5 journal line containing [comment]."""
    bracket = f"[{comment}]"
    if bracket not in line:
        return None

    parts = line.split("\t")
    wall_time = parts[2] if len(parts) >= 3 else ""
    payload = parts[-1] if parts else line

    m = SIM_TAG_RE.search(payload)
    if not m or m.group("tag") != comment:
        # fallback: split on bracket
        left, right = payload.split(bracket, 1)
        sim = left.strip()
        rest = right.strip()
        if not rest:
            return None
        bits = rest.split(None, 1)
        event = bits[0]
        msg = bits[1] if len(bits) > 1 else ""
    else:
        sim = m.group("sim")
        event = m.group("event")
        msg = m.group("msg").strip()

    row: dict[str, str] = {
        "wall_time": wall_time.strip(),
        "sim_time": sim.strip(),
        "comment": comment,
        "event": event,
        "message": msg,
        "side": "",
        "lots": "",
        "price": "",
        "sl": "",
        "tp": "",
        "ticket": "",
        "role": "",
        "episode": "",
        "mom": "",
        "regime": "",
        "bias": "",
        "risk": "",
        "riskPct": "",
        "cmd": "",
        "reason": "",
    }

    kvs = dict(KV_RE.findall(msg))
    for key in (
        "lots",
        "price",
        "sl",
        "tp",
        "ticket",
        "role",
        "episode",
        "mom",
        "regime",
        "bias",
        "risk",
        "riskPct",
        "cmd",
    ):
        if key in kvs:
            row[key] = kvs[key]
    if "dir" in kvs and not row["side"]:
        # dir=0 buy / 1 sell in some OPEN lines
        d = kvs["dir"]
        row["side"] = "buy" if d == "0" else ("sell" if d == "1" else d)
    if "bias" in kvs:
        row["bias"] = kvs["bias"]
    # side from BUY/SELL tokens
    up = msg.upper()
    if " BUY" in f" {up}" or up.startswith("BUY"):
        row["side"] = row["side"] or "buy"
    elif " SELL" in f" {up}" or up.startswith("SELL"):
        row["side"] = row["side"] or "sell"
    # reason: leftover words without '=' for SKIP/RISK
    if event in ("SKIP", "RISK_FAIL", "LAYER_REJECT", "NEWS", "KILL", "ERROR", "ERR"):
        # first token without = often reason code
        tokens = msg.split()
        if tokens and "=" not in tokens[0]:
            row["reason"] = tokens[0]
        elif "reason" in kvs:
            row["reason"] = kvs["reason"]

    return row


def stream_extract(
    path: Path,
    comment: str,
    keep_events: frozenset[str] | None,
    keep_regime: bool,
    progress_every_gb: float = 1.0,
) -> list[dict[str, str]]:
    """Stream UTF-16-LE journal; return kept event rows."""
    tag_bytes = comment.encode("utf-16-le")
    crlf = "\r\n".encode("utf-16-le")
    rows: list[dict[str, str]] = []
    source = str(path)

    with path.open("rb") as f:
        bom = f.read(2)
        if bom not in (b"\xff\xfe", b"\xfe\xff"):
            # still try utf-16-le; may be missing BOM
            f.seek(0)
        carry = b""
        pos = f.tell()
        next_prog = progress_every_gb * 1024**3

        while True:
            data = f.read(16 * 1024 * 1024)
            if not data:
                break
            buf = carry + data
            parts = buf.split(crlf)
            carry = parts[-1]
            for part in parts[:-1]:
                if tag_bytes not in part:
                    continue
                try:
                    line = part.decode("utf-16-le")
                except UnicodeDecodeError:
                    continue
                parsed = parse_journal_line(line, comment)
                if not parsed:
                    continue
                ev = parsed["event"]
                if ev == "REGIME":
                    if not keep_regime:
                        continue
                elif keep_events is not None and ev not in keep_events:
                    continue
                parsed["source_file"] = source
                rows.append(parsed)
            pos += len(data)
            if pos >= next_prog:
                print(
                    f"  … {path.name}: {pos / 1e9:.2f} GB, kept={len(rows)}",
                    file=sys.stderr,
                    flush=True,
                )
                next_prog += progress_every_gb * 1024**3

        if carry and tag_bytes in carry:
            try:
                line = carry.decode("utf-16-le")
                parsed = parse_journal_line(line.rstrip("\r\n"), comment)
                if parsed:
                    ev = parsed["event"]
                    keep_line = True
                    if ev == "REGIME":
                        keep_line = keep_regime
                    elif keep_events is not None and ev not in keep_events:
                        keep_line = False
                    if keep_line:
                        parsed["source_file"] = source
                        rows.append(parsed)
            except UnicodeDecodeError:
                pass

    return rows


def dedupe_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    seen: set[tuple[str, str, str]] = set()
    out: list[dict[str, str]] = []
    for r in rows:
        key = (r.get("sim_time", ""), r.get("event", ""), r.get("message", ""))
        if key in seen:
            continue
        seen.add(key)
        out.append(r)
    return out


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


# --- ReportTester deals / trades -------------------------------------------------


class SectionTableParser(HTMLParser):
    """Extract data rows from a named MT5 ReportTester section (Orders / Deals)."""

    def __init__(self, section_title: str, min_cells: int) -> None:
        super().__init__()
        self.section_title = section_title
        self.min_cells = min_cells
        self.in_section = False
        self.in_tr = False
        self.in_cell = False
        self.cur_cells: list[str] = []
        self.cur_text: list[str] = []
        self.rows: list[list[str]] = []
        self._header_done = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "tr":
            self.in_tr = True
            self.cur_cells = []
        elif tag in ("td", "th") and self.in_tr:
            self.in_cell = True
            self.cur_text = []

    def handle_endtag(self, tag: str) -> None:
        if tag in ("td", "th") and self.in_cell:
            self.in_cell = False
            self.cur_cells.append("".join(self.cur_text).strip())
        elif tag == "tr" and self.in_tr:
            self.in_tr = False
            cells = self.cur_cells
            if not cells:
                return
            joined = " ".join(cells)
            if self.section_title in joined and len(cells) <= 2:
                self.in_section = True
                self._header_done = False
                return
            # Leaving current section when another section title appears
            if (
                self.in_section
                and len(cells) <= 2
                and any(
                    t in joined
                    for t in ("Orders", "Deals", "Positions", "Results")
                    if t != self.section_title
                )
            ):
                self.in_section = False
                return
            if not self.in_section:
                return
            # Skip column header row (Open Time / Time)
            if cells and cells[0] in ("Open Time", "Time"):
                self._header_done = True
                return
            if len(cells) >= self.min_cells and any(c for c in cells):
                self.rows.append(cells)

    def handle_data(self, data: str) -> None:
        if self.in_cell:
            self.cur_text.append(data)


class DealsTableParser(SectionTableParser):
    def __init__(self) -> None:
        super().__init__("Deals", min_cells=11)


class OrdersTableParser(SectionTableParser):
    def __init__(self) -> None:
        super().__init__("Orders", min_cells=8)


def read_html(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig")
    if len(raw) > 4 and raw[1] == 0 and raw[3] == 0:
        return raw.decode("utf-16-le")
    return raw.decode("utf-8", errors="replace")


def parse_dt(s: str):
    from datetime import datetime

    return datetime.strptime(s.strip(), "%Y.%m.%d %H:%M:%S")


def parse_orders_sl_tp(html: str) -> dict[str, tuple[str, str]]:
    """Map order id → (sl, tp) from Orders table.

    Filled market rows look like:
      Open Time | Order | Symbol | Type | Volume | Price | S/L | T/P | Time | State | Comment
    """
    parser = OrdersTableParser()
    parser.feed(html)
    by_order: dict[str, tuple[str, str]] = {}
    for cells in parser.rows:
        # Skip blank / pending-only junk
        if len(cells) < 8:
            continue
        # Heuristic: order id is numeric in col 1; SL/TP near end before state
        order_id = cells[1].strip() if len(cells) > 1 else ""
        if not order_id.isdigit():
            continue
        # Prefer 11-col filled layout: [0]=open,1=order,2=sym,3=type,4=vol,5=price,6=sl,7=tp,8=time,9=state,10=cmt
        if len(cells) >= 11 and cells[9].lower() in ("filled", "started", "canceled", "cancelled"):
            sl, tp = cells[6], cells[7]
        elif len(cells) >= 8:
            # Fallback: last numeric-looking pair before state-ish token
            sl, tp = cells[6], cells[7]
        else:
            continue
        by_order[order_id] = (sl.strip(), tp.strip())
    return by_order


def classify_exit_reason(
    exit_comment: str,
    exit_price: float,
    entry_sl: float | None,
    entry_tp: float | None,
    tol: float = PRICE_TOL,
) -> tuple[str, str]:
    """Return (exit_reason, exit_reason_source)."""
    cmt = (exit_comment or "").strip().lower()
    if cmt.startswith("tp"):
        return "tp", "comment"
    if cmt.startswith("sl"):
        return "sl", "comment"
    if cmt:
        return "other", "comment"

    if entry_tp is not None and entry_tp > 0 and abs(exit_price - entry_tp) <= tol:
        return "tp", "price"
    if entry_sl is not None and entry_sl > 0 and abs(exit_price - entry_sl) <= tol:
        return "sl", "price"

    if entry_sl is None and entry_tp is None:
        return "unknown", "unknown"
    # SL/TP known but price not near either → EA/manual/flat close
    return "other", "inferred"


def export_deals_trades(report: Path, comment: str, out_dir: Path) -> tuple[Path, Path]:
    html = read_html(report)
    parser = DealsTableParser()
    parser.feed(html)
    if not parser.rows:
        raise ValueError(f"No Deals rows in {report}")

    orders_sl_tp = parse_orders_sl_tp(html)

    stem = safe_stem(comment)
    set_name = f"{comment}.set"
    deal_rows: list[dict[str, object]] = []
    for cells in parser.rows:
        # pad to 13
        while len(cells) < 13:
            cells.append("")
        t, deal, sym, typ, direc, vol, price, order, comm, swap, profit, bal, cmt = cells[:13]
        month = t[:7].replace(".", "-") if len(t) >= 7 else ""
        net = parse_num(comm) + parse_num(swap) + parse_num(profit)
        deal_rows.append(
            {
                "time": t,
                "deal": deal,
                "symbol": sym,
                "type": typ,
                "direction": direc,
                "volume": vol,
                "price": price,
                "order": order,
                "commission": comm,
                "swap": swap,
                "profit": profit,
                "balance": bal,
                "comment": cmt,
                "month": month,
                "net": round(net, 2),
                "set_name": set_name,
                "report_file": report.name,
            }
        )

    deals_path = out_dir / f"deals_{stem}.csv"
    write_csv(deals_path, DEAL_FIELDS, [{k: str(v) for k, v in r.items()} for r in deal_rows])

    # FIFO pair in → out by symbol
    open_q: dict[str, list[dict[str, object]]] = defaultdict(list)
    trades: list[dict[str, object]] = []
    tid = 0
    for r in deal_rows:
        typ = str(r["type"]).lower()
        direc = str(r["direction"]).lower()
        sym = str(r["symbol"])
        if typ == "balance" or not sym:
            continue
        if direc == "in":
            basket = sum(
                1
                for x in open_q.get(sym, [])
                if str(x["type"]).lower() == typ
            )
            r = dict(r)
            r["_basket"] = basket
            open_q[sym].append(r)
            continue
        if direc in ("out", "out by") and open_q.get(sym):
            want = "buy" if typ == "sell" else "sell"
            idx = next(
                (i for i, x in enumerate(open_q[sym]) if str(x["type"]).lower() == want),
                None,
            )
            if idx is None:
                continue
            entry = open_q[sym].pop(idx)
            tid += 1
            try:
                t0 = parse_dt(str(entry["time"]))
                t1 = parse_dt(str(r["time"]))
                hold = (t1 - t0).total_seconds()
            except ValueError:
                hold = 0.0
            entry_cmt = str(entry["comment"])
            # Prefer token match: comments like stem-BUY&SELL-1 or stem-PYRAMID-
            # must not use rsplit("-")[-1] (that yields "1" / "").
            cu = entry_cmt.upper()
            if "PYRAMID" in cu:
                entry_tag = "PYRAMID"
            elif "BUY&SELL" in cu or "BUY&SEL" in cu:
                entry_tag = "BUY&SEL"
            elif "-" in entry_cmt:
                entry_tag = entry_cmt.rsplit("-", 1)[-1]
            else:
                entry_tag = ""


            entry_order = str(entry["order"]).strip()
            sl_s, tp_s = orders_sl_tp.get(entry_order, ("", ""))
            entry_sl_f = parse_num(sl_s) if sl_s else None
            entry_tp_f = parse_num(tp_s) if tp_s else None
            if entry_sl_f == 0.0:
                entry_sl_f = None
            if entry_tp_f == 0.0:
                entry_tp_f = None

            exit_price_f = parse_num(str(r["price"]))
            exit_reason, exit_src = classify_exit_reason(
                str(r["comment"]),
                exit_price_f,
                entry_sl_f,
                entry_tp_f,
            )
            net = parse_num(str(r["commission"])) + parse_num(str(r["swap"])) + parse_num(
                str(r["profit"])
            )
            trades.append(
                {
                    "trade_id": tid,
                    "set_name": set_name,
                    "report_file": report.name,
                    "symbol": sym,
                    "side": str(entry["type"]).lower(),
                    "entry_time": entry["time"],
                    "entry_deal": entry["deal"],
                    "entry_order": entry["order"],
                    "entry_volume": entry["volume"],
                    "entry_price": entry["price"],
                    "entry_sl": sl_s,
                    "entry_tp": tp_s,
                    "entry_comment": entry_cmt,
                    "entry_tag": entry_tag,
                    "exit_time": r["time"],
                    "exit_deal": r["deal"],
                    "exit_order": r["order"],
                    "exit_price": r["price"],
                    "exit_comment": r["comment"],
                    "exit_reason": exit_reason,
                    "exit_reason_source": exit_src,
                    "commission": r["commission"],
                    "swap": r["swap"],
                    "profit": r["profit"],
                    "net": round(net, 2),
                    "hold_seconds": int(hold),
                    "hold_bars_m5": round(hold / 300.0, 2) if hold else 0,
                    "month": str(r["time"])[:7].replace(".", "-") if r["time"] else "",
                    "same_basket_entries_open": entry.get("_basket", 0),
                }
            )

    trades_path = out_dir / f"trades_{stem}.csv"
    write_csv(
        trades_path,
        TRADE_FIELDS,
        [{k: str(v) for k, v in t.items()} for t in trades],
    )
    return deals_path, trades_path


def build_arg_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(
        description="Extract MT5 Tester Experts lines by comment/InpLogTag into CSV"
    )
    ap.add_argument(
        "--comment",
        "--tag",
        dest="comment",
        required=True,
        help="InpLogTag / comment key, e.g. v0.3_armC_smc_full_long",
    )
    ap.add_argument(
        "--log",
        action="append",
        dest="logs",
        default=None,
        help="Log basename or path (repeat for 2+ logs), e.g. --log 20261016.log",
    )
    ap.add_argument(
        "--root",
        type=Path,
        default=DEFAULT_ROOT,
        help=f"Tester tree root (default {DEFAULT_ROOT})",
    )
    ap.add_argument("--out-dir", type=Path, default=Path("logs"), help="Output directory")
    ap.add_argument(
        "--events",
        default=None,
        help="Comma-separated events to keep (default: analysis set, no REGIME)",
    )
    ap.add_argument(
        "--keep-regime",
        action="store_true",
        help="Include REGIME lines (huge)",
    )
    ap.add_argument("--no-dedupe", action="store_true", help="Keep duplicate rows")
    ap.add_argument(
        "--one-file",
        action="store_true",
        help="When basename matches multiple Agents, use only the best hit",
    )
    ap.add_argument("--raw", action="store_true", help="Also write filtered .txt")
    ap.add_argument(
        "--report",
        type=Path,
        default=None,
        help="ReportTester HTML → deals_*.csv + trades_*.csv",
    )
    ap.add_argument(
        "--report-only",
        action="store_true",
        help="Only export deals/trades from --report (skip Experts log scan)",
    )
    ap.add_argument(
        "--all-events",
        action="store_true",
        help="Keep every non-REGIME event (ignore default allow-list)",
    )
    return ap


def main() -> int:
    ap = build_arg_parser()
    args = ap.parse_args()
    comment = args.comment.strip()
    if not comment:
        print("error: --comment is empty", file=sys.stderr)
        return 2

    out_dir = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.report_only:
        if not args.report:
            print("error: --report-only requires --report", file=sys.stderr)
            return 2
        if not args.report.is_file():
            print(f"error: --report not found: {args.report}", file=sys.stderr)
            return 2
        print(f"comment=[{comment}] report-only", file=sys.stderr)
        deals_p, trades_p = export_deals_trades(args.report, comment, out_dir)
        print(f"wrote {deals_p}", file=sys.stderr)
        print(f"wrote {trades_p}", file=sys.stderr)
        return 0

    if not args.logs:
        print("error: --log is required unless --report-only", file=sys.stderr)
        return 2

    try:
        paths = resolve_logs(args.logs, args.root, comment, one_file=args.one_file)
    except FileNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    if args.events:
        keep: frozenset[str] | None = frozenset(
            x.strip() for x in args.events.split(",") if x.strip()
        )
    elif args.all_events:
        keep = None  # all except REGIME unless --keep-regime
    else:
        keep = DEFAULT_EVENTS

    print(f"comment=[{comment}]", file=sys.stderr)
    for p in paths:
        print(f"log={p} ({p.stat().st_size / 1e9:.2f} GB)", file=sys.stderr)

    all_rows: list[dict[str, str]] = []
    for p in paths:
        print(f"scanning {p.name} …", file=sys.stderr, flush=True)
        all_rows.extend(
            stream_extract(
                p,
                comment,
                keep_events=keep,
                keep_regime=args.keep_regime,
            )
        )
        print(f"  kept so far: {len(all_rows)}", file=sys.stderr, flush=True)

    before = len(all_rows)
    if not args.no_dedupe:
        all_rows = dedupe_rows(all_rows)
        print(f"dedupe {before} → {len(all_rows)}", file=sys.stderr)

    # stable sort by sim_time then wall_time
    all_rows.sort(key=lambda r: (r.get("sim_time", ""), r.get("wall_time", ""), r.get("event", "")))

    stem = safe_stem(comment)
    experts_path = out_dir / f"experts_{stem}.csv"
    write_csv(experts_path, EVENT_FIELDS, all_rows)

    entries = [r for r in all_rows if r.get("event") == "OPEN"]
    entries_path = out_dir / f"experts_entries_{stem}.csv"
    write_csv(entries_path, EVENT_FIELDS, entries)

    print(f"wrote {experts_path} ({len(all_rows)} rows)", file=sys.stderr)
    print(f"wrote {entries_path} ({len(entries)} OPEN rows)", file=sys.stderr)

    if args.raw:
        raw_path = out_dir / f"experts_{stem}.txt"
        with raw_path.open("w", encoding="utf-8") as f:
            for r in all_rows:
                f.write(
                    f"{r.get('sim_time', '')} [{comment}] {r.get('event', '')} {r.get('message', '')}\n"
                )
        print(f"wrote {raw_path}", file=sys.stderr)

    # event summary
    counts: dict[str, int] = defaultdict(int)
    for r in all_rows:
        counts[r["event"]] += 1
    print("event counts:", dict(sorted(counts.items(), key=lambda x: -x[1])), file=sys.stderr)

    if args.report:
        if not args.report.is_file():
            print(f"error: --report not found: {args.report}", file=sys.stderr)
            return 2
        deals_p, trades_p = export_deals_trades(args.report, comment, out_dir)
        print(f"wrote {deals_p}", file=sys.stderr)
        print(f"wrote {trades_p}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
