# Trade-log hostile review: v0.3_armC_dynamic

**Research only** — never claim guaranteed profit or recommend live size.  
**Not a Mode S / salary / promote score.** Dual-gate (WF/holdout + Mode S slicer) not satisfied by this file alone. Existing `salary_digest_*.RESEARCH.txt` uses deposit=5000 — refuse promote.

| Field | Value |
|---|---|
| set_name | `v0.3_armC_dynamic.set` |
| report_file | `ReportTester-52016350_v0.3_armC_dynamic.html` |
| source CSV | `logs/trades_v0.3_armC_dynamic.csv` |
| symbol / side | XAUUSD / buy |
| closed round-trips | 214 |
| months | 2026-01, 2026-02 |

**Units:** `net` = Tester book units. CSV has no deposit/cent flag. If RoboForex cent book: ≈$ real = units÷100 (total net +5175.15 ≈ +$51.75).

**Cash-risk R proxy:** `cash_risk ≈ entry_volume × |entry−SL| × 100` (not broker-spec certified).

**Tags:** Raw `entry_tag` in CSV was broken (`1` / empty from `BUY&SELL-1` comments). Metrics use normalized tags from `entry_comment` (`BUY&SEL` / `PYRAMID`).

**Baskets:** Reconstructed from overlapping same-side opens; 42 baskets, avg size 5.10; 18 multi-layer net&lt;0.

**Set note:** EA `gold_rush_AI_v0.3.mq5` — no `InpLongPeakExit`; flat levers = `MinProfit` / `Dist`.

---

## 1. Scoreboard

### Overall (trade-level)

| Metric | Value |
|---|---|
| Trades | 214 |
| Win rate | 55.6% (119W / 95L) |
| Total net | +5175.15 |
| Avg win / avg loss | +89.86 / −58.09 |
| Profit factor | 1.938 |
| Expectancy | +24.18 / trade |
| Max consec W / L | 17 / 15 |
| Largest W / L | +300.00 / −280.70 |
| Worst losing-streak sum | −1263.54 |
| Planned R:R median | 2.47 |
| Realized R median (cash proxy) | +0.15 |
| Hold median | 3937s (~1.1h) |

### By month

| Month | n | WR | Net | PF | E | Max CL | Worst streak sum |
|---|---|---|---|---|---|---|---|
| 2026-01 | 123 | 65.9% | +5665.86 | 4.574 | +46.06 | 6 | −269.19 |
| 2026-02 | 91 | 41.8% | −490.71 | 0.875 | −5.39 | 15 | −1263.54 |

Jan carries the run; Feb is negative with a long losing streak.

### By exit_reason

| Exit | n | % | WR | Net | PF | E | Hold med (s) |
|---|---|---|---|---|---|---|---|
| tp | 40 | 18.7% | 100% | +6524.83 | ∞ | +163.12 | 6870 |
| sl | 60 | 28.0% | 55.0% | −1498.59 | 0.451 | −24.98 | 2702 |
| other | 114 | **53.3%** | 40.4% | +148.91 | 1.053 | +1.31 | 3872 |

- **other:** avg \|exit−TP\| = 56.73, avg \|exit−SL\| = 20.39; **100/114 (87.7%) closer to SL**.
- SL label: **33 trail wins** / **27 initial losses** (see `sl_trail` / `sl_initial_loss` in metrics CSV).

**Exit-quality:** Still flat-heavy (53% other); TP only ~19% but +6525 of P&L. Flats near SL, near-zero E.

### By entry_tag (normalized)

| Tag | n | WR | Net | PF | E | Worst streak sum |
|---|---|---|---|---|---|---|
| BUY&SEL (parent) | 40 | 35.0% | −983.40 | 0.535 | −24.59 | −630.99 |
| PYRAMID | 174 | 60.3% | +6158.55 | 2.809 | +35.39 | −737.96 |

Parents drag; pyramids make the book (~81% of trades, &gt;100% of net).

### By layer depth

| Depth | n | WR | Net | E |
|---|---|---|---|---|
| 0 (first) | 42 | 38.1% | −535.88 | −12.76 |
| 1 | 38 | 42.1% | +304.31 | +8.01 |
| 2+ | 134 | 64.9% | +5406.72 | +40.35 |

Exact depths 0–4 present; max open-at-entry = 4.

### Basket / episode level

| Metric | Value |
|---|---|
| Baskets | 42 |
| Basket WR | **40.5%** (vs 55.6% trade WR) |
| Basket E / PF | +123.22 / 2.268 |
| Avg size | 5.10 |
| Multi-layer net&lt;0 | 18 |
| Jan baskets | 19, WR 57.9%, net +5665.86 |
| Feb baskets | 23, WR **26.1%**, net −490.71 |

### Planned vs realized mix

- TP reached: **18.7%**
- SL-labeled: **28.0%**
- Flat: **53.3%**
- Realized R medians: tp ~+2.47, other ~−0.12

---

## 2. Short findings

- Headline PF ~1.94 / E +24 is **Jan-dominated**; Feb PF &lt; 1, worst streak −1264.
- **Flat-heavy exits** (53% other, E ~+1); TP rare but accounts for **+6525** while SL label is −1499.
- Flats cluster **near SL** (88% closer to SL than TP).
- **Parents lose**; pyramids carry — trade WR overstates episode skill (basket WR 40.5%).
- Planned R:R ~2.47; realized median R ~0.15 — plan rarely completes.
- Research digest deposit ≠ Mode S pin — **cannot** promote from this CSV.

---

## 3. Hostile issues

### H1 — Flat-dominated exits vs planned TP/SL

1. **Problem:** 53% outcomes are EA `other` flats; TP only 19%.
2. **Why it matters:** Edge is basket MinProfit/Dist flat logic (no peak knobs on this EA), not stated R:R.
3. **Detect:** exit mix; other closer-to-SL 88%; other PF ≈ 1.05.
4. **Correction:** Raise `MinProfit` / widen `Dist`; log flat reason codes.
5. **Test:** EXP-FLATTIGHT / EXP-DIST vs baseline (other %, TP-hit %, episode E).

### H2 — Month instability (Jan vs Feb)

1. **Problem:** Jan +5666 / PF 4.57 vs Feb −491 / PF 0.88 / max CL 15.
2. **Why it matters:** Pooled PF hides regime break.
3. **Detect:** Monthly and basket-monthly splits.
4. **Correction:** `InpUseRegimeGate=true`; WF + holdout; do not retune on Feb.
5. **Test:** Freeze params; score Feb OOS.

### H3 — Win-rate illusion from correlated layers

1. **Problem:** Trade WR 55.6% vs basket WR 40.5%; depth 2+ strong while parents lose.
2. **Why it matters:** Inflates sample confidence; invalid HPM-style trade WR.
3. **Detect:** entry_tag + layer + basket tables.
4. **Correction:** Episode-level metrics; cap layers; require parent E ≥ 0 before adds.
5. **Test:** EXP-L1 vs EXP-L3 vs baseline.

### H4 — Over-layering / adverse basket closes

1. **Problem:** Avg ~5.1 legs; 18 multi-layer baskets net&lt;0.
2. **Why it matters:** Episode risk stacks; Feb streak −1264.
3. **Detect:** basket size / multi-layer net-neg count.
4. **Correction:** Hard episode risk + max layers 1–3.
5. **Test:** max_layers ∈ {1,3,5} under fixed episode cash-risk.

### H5 — SL label ≠ clean stop (trail winners)

1. **Problem:** 33/60 “sl” exits are winners (trail into profit).
2. **Why it matters:** Contaminates SL stats; true SL losses avg −101.
3. **Detect:** sl ∩ net&gt;0.
4. **Correction:** Use `sl_trail` / `sl_initial_loss` slices in metrics CSV.
5. **Test:** EXP-SLTAX (analysis only).

### H6 — Reliance on TP tails for net

1. **Problem:** +6525 from 40 TPs vs +149 from 114 flats.
2. **Why it matters:** Fragile to missed TP / spread stress.
3. **Detect:** P&L by exit_reason.
4. **Correction:** Raise TP-hit rate or shrink size until flats have standalone +E.
5. **Test:** Spread/TP-distance stress after flat-policy A/B.

---

## 4. Verdict + next experiments

**Verdict (research only):** Encouraging enough to **continue research** (pooled PF ~1.9, planned R:R intact) but **structurally fragile** — flats near SL, parents negative, Feb collapse, basket WR well below trade WR. Candidate for experiment matrix, **not** a promote.

**Dual-gate reminder:** Need approved walk-forward + untouched holdout **and** Mode S salary slicer at the cent pin (`ea_version` + `pack_id` + `set_name`). Neither is present here.

**Top 3 next experiments (ranked):**

1. **EXP-L1 / EXP-L3** — max layers 1 vs 3 under episode risk cap (H3–H4).
2. **EXP-FLATTIGHT / EXP-DIST** — `MinProfit=0.01` and/or `Dist=40` (H1/H6; peak knobs N/A).
3. **EXP-REGIME** — `InpUseRegimeGate=true`; freeze and score Feb OOS (H2).

Machine-readable twins: `logs/hostile_metrics_v0.3_armC_dynamic.csv`, `logs/hostile_improvements_v0.3_armC_dynamic.csv`.

---

*Numbers from `logs/trades_v0.3_armC_dynamic.csv` via `scripts/hostile_trade_review_to_csv.py`. Research artifact; not a salary pass.*
