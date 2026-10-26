# Detailed analysis — v0.4 armC batch (research)

**Not Mode S / not promote.** Dual-gate (WF/holdout + Mode S cent pin) not satisfied.  
Research pin: deposit **5000** / threshold **5000** (100% rule). Digests stamped `ea_version=v0.4`.

Reports: `ReportTester-52016350_v0.4_armC_{dynamic,flattight,l1,l3}.html`  
Baseline: `v0.3_armC_dynamic` · EA `gold_rush_AI_v0.3`  
Candidate EA: `gold_rush_AI_v0.4` · schema inputs Mode B / actR=1.5 / entryClose=ON

Gate: every v0.4 report `InpSetName` matches set stem; MaxLayers / MinProfit / ManageMode match `.set`.

---

## 1. Monthly salary digests (research)

| Run | Jan net | Jan n | Feb net | Feb n | Range |
|---|---|---|---|---|---|
| v0.3_armC_dynamic | **+5665.86 pass** | 123 | **−490.71 fail** | 91 | **fail** |
| v0.4_armC_dynamic | +1544.15 fail | 20 | +658.32 fail | 15 | **fail** |
| v0.4_armC_flattight | +1544.15 fail | 20 | +658.32 fail | 15 | **fail** (identical to dynamic) |
| v0.4_armC_l3 | +1544.15 fail | 20 | +658.32 fail | 15 | **fail** (identical) |
| v0.4_armC_l1 | +1469.83 fail | 18 | +487.55 fail | 12 | **fail** |

≈ $ real = units ÷ 100 on cent framing.

---

## 2. Report-level scoreboard

| Run | Net | PF | Trades | WR | Bal DD max | Eq DD max |
|---|---|---|---|---|---|---|
| v0.3 dynamic | +5175.15 | 1.94 | 214 | 55.6% | 21.06% | 24.11% |
| v0.4 dynamic | +2202.47 | **3.63** | **35** | **71.4%** | **6.77%** | **9.40%** |
| v0.4 flattight | +2202.47 | 3.63 | 35 | 71.4% | 6.77% | 9.40% |
| v0.4 l3 | +2202.47 | 3.63 | 35 | 71.4% | 6.77% | 9.40% |
| v0.4 l1 | +1957.38 | 3.53 | 30 | 70.0% | 6.53% | 8.71% |

---

## 3. Structural change vs v0.3 (deal-level)

| Metric | v0.3 | v0.4 dynamic |
|---|---|---|
| Exit mix | other **53%**, tp 19%, sl 28% | other **6%**, tp 14%, sl **80%** |
| Net by exit | TP +6525 drives book; other ~flat | TP +1341; **SL +975** (trail wins) |
| Tags | parents −983 / pyramids +6159 | parents **+2145** / pyramids +57 |
| Pyramid share | 174/214 (81%) | **4/35 (11%)** |
| Basket size avg / max | ~5.4 / high | **1.13 / 2** |
| Basket WR | ~40% | **71%** |
| Hold median | ~1.1 h | **~2.4 h** |
| Early stop (&lt;15m) | 17.3% | 20.0% |
| SL trail wins / initial losses | 33 / 26 | **20 / 8** |

Interpretation:

1. **Flat-dominated exits are largely gone** — not because MinProfit was raised (flattight = identical), but because v0.4 takes far fewer entries and exits mainly via trailed SL / TP.
2. **Pyramid Step pipfactor fix worked** — adds rare; max basket size 2 ⇒ `l3` cannot differ from dynamic.
3. **Parents flipped from drag to main P&amp;L** — entry-close + Mode B delayed SL+ changed the book’s engine.
4. **Risk profile improved** — DD roughly ⅓ of v0.3; PF up; absolute net and Jan salary bar down.
5. **Early-stop rate did not improve** — still ~20%; delayed SL+ did not fix “stopped shortly after entry” by that definition.
6. **l1** drops the 4 pyramid legs → ~−245 net vs dynamic; confirms pyramids add a little but are no longer the strategy.

---

## 4. Ablation verdicts

| Experiment | Result |
|---|---|
| EXP-FLATTIGHT (`MinProfit=0.01`) | **No effect** on this sample — Dist/MinProfit path almost unused (2 `other` exits). |
| EXP-L3 | **No effect** — never ≥3 layers after Step fix. |
| EXP-L1 | Slightly worse net; cleaner single-leg book; still range-fail. |

---

## 5. Salary / promote

- Research 100% bar: **all v0.4 months fail** (need ≥ +5000/mo at deposit 5000).
- Mode S (50k / +5k): **not run / not claimed**.
- Walk-forward + holdout: **not present**.
- **Refuse promote / Reset-default / live size.**

---

## 6. Recommended next experiments (ranked)

1. **Entry frequency** — measure SKIP_STAGE rates; consider `InpEntryConfirmClose=false` ablation (or softer impulse) to recover Jan mass without restoring v0.3 flat spam.
2. **Mode A / Mode C sets** — still unscored; isolate stop model vs delayed SL+.
3. **Step sensitivity** — Step between pipfactor×20 and old `_Point` behavior (e.g. Step=5–10 pipfactor) if controlled pyramids are desired.
4. **EXP-REGIME** — Feb was positive in v0.4 but small; regime gate for stability before size-up.
5. Only after a research range-pass candidate: Mode S at cent pin + WF/holdout.

---

*Generated from Tester HTML Deals + salary_month_slice digests. Research artifact.*
