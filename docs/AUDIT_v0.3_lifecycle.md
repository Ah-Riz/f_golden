# Audit: v0.3 trade lifecycle (pre-v0.4)

**Baseline:** `sets/v0.3_armC_dynamic.set` · `gold_rush_AI_v0.3.mq5`  
**Artifacts:** `logs/hostile_review_trades_v0.3_armC_dynamic.md`, `logs/forensics_v0.3_armC_dynamic.csv`  
**Research only — not Mode S / promote.**

## Mechanics summary

| Concern | v0.3 behavior |
|---|---|
| Entry | Tick/forming-bar impulse + Dist ratchet; SMC bias gate; closed-bar bias only |
| Initial SL | `max(ATR×1.5, RiskPoints×_Point)` — not structure-based |
| SL+ | Activate at **1R**; BE+lock vs 1R trail; tighten-only |
| News widen | Can loosen SL |
| Exits | Broker SL/TP; Dist+MinProfit flats; 5% equity kill |
| Pyramid Step | Used `_Point` (asymmetric vs Dist pipfactor) |
| Episode budget | Pre-send passed `layer_risk_cash=0` |

**Digit note:** Sample trade SL distance ≈ $20 ⇒ 2-digit `_Point` reading of RiskPoints=2000 on that Tester book. Re-check Digits on every report.

## Forensics (price-path proxy; no M5 bars supplied)

Frozen defs: early = hold &lt; 15 min **or** MAE≥0.7R in first 3 M5 bars; favorable = post-exit ≥1R over 20 bars (needs `--bars`).

| Metric | Value |
|---|---|
| Trades | 214 |
| Early stop | 37 (17.3%) |
| Exit class | tp 40 · other 114 · sl_initial_loss 27 · sl_trail 33 |
| Top failure labels | **flat_near_sl_suspect 100** · trail_into_profit 33 · valid_tp 40 |

## Diagnosis (evidence-backed)

1. **Do not widen initial SL first** — flats dominate; 100/214 labeled flat-near-SL.
2. **SL+ at 1R** is plausible for cutting trends (33 trail wins); delay activation is justified for Mode B.
3. **Pyramid Step unit bug** and weak episode pre-send amplify basket risk — fixed in v0.4.
4. Post-exit continuation unavailable until M5 OHLC is passed to forensics — do not claim “missed trends” without it.

## Hypotheses → v0.4 tests

| ID | Test set / mode |
|---|---|
| H-FLAT | `v0.4_armC_flattight` |
| H-SLPLUS | `v0.4_armC_dynamic` (Mode B actR=1.5) vs v0.3 |
| H-STEP | Step pipfactor fix (all v0.4) |
| H-ENTRY | `InpEntryConfirmClose=true` |
| H-STRUCT | `v0.4_armC_modeA` |
| H-LAYER | `v0.4_armC_l1` / `_l3` |
| H-REGIME | `v0.4_armC_regime` |
