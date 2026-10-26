# Analysis — `v0.4_armC_holdA_nodist` vs other v0.4 armC (research)

**Not Mode S / not promote.** Research pin: deposit **5000** / threshold **5000** (100%).  
Sliced: `logs/salary_digest_v0.4_armC_holdA_nodist.csv` (+ `.RESEARCH.txt`).  
Cite: `ea_version=v0.4` · `pack_id=armC_holdA_nodist` · `set_name=v0.4_armC_holdA_nodist.set`  
Report: `ReportTester-52016350_v0.4_armC_holdA_nodist.html` (mtime **2026-10-19 11:06**)

---

## Gate: Exp A **VALID** on this report

| Check | Result |
|---|---|
| `InpSetName` / comment / log tag | `v0.4_armC_holdA_nodist` |
| `InpManageMode=1` (B) | OK |
| Report Inputs `InpAllowDistFlat` | **`false`** |
| Same ACT/R, Dist, MinProfit as dynamic | OK |

Prior runs (missing `InpAllowDistFlat` in Inputs) are superseded.

---

## Monthly digests (research 5k / 100%)

| pack_id | Jan net (n) | Feb net (n) | Range |
|---|---|---|---|
| armC_dynamic (BASE) | +1544.15 (20) fail | +658.32 (15) fail | **fail** |
| armC_flattight | +1544.15 (20) fail | +658.32 (15) fail | **fail** (≡ BASE) |
| armC_l3 | +1544.15 (20) fail | +658.32 (15) fail | **fail** (≡ BASE) |
| **armC_holdA_nodist (A)** | **+1544.15 (20) fail** | **+658.32 (15) fail** | **fail** (≡ BASE) |
| armC_l1 | +1469.83 (18) fail | +487.55 (12) fail | **fail** |
| armC_l13 | +1481.87 (122) fail | −162.37 (61) fail | **fail** |

≈ $ real = units ÷ 100.

---

## Report scoreboard + exit mix

| pack_id | Net | PF | n | WR | Bal DD | Exit mix |
|---|---|---|---|---|---|---|
| dynamic | +2202.47 | 3.63 | 35 | 71.4% | 6.77% | sl 28 / tp 5 / other 2 |
| flattight / l3 | +2202.47 | 3.63 | 35 | 71.4% | 6.77% | same |
| **holdA_nodist** | **+2202.47** | **3.63** | **35** | **71.4%** | **6.77%** | **same** |
| l1 | +1957.38 | 3.53 | 30 | 70.0% | 6.53% | sl 23 / tp 5 / other 2 |
| l13 | +1319.50 | 1.66 | 183 | 57.9% | 12.63% | other 175 / sl 8 |

Deal P/L series **holdA ≡ dynamic** (70 deal profits identical).

The 2 `other` closes remain: empty comment, **losses** (−101.22, −12.28) — not Dist+MinProfit winners. Path MFE/MAE/giveback: not computed (no bars).

---

## Exp A verdict (H-DIST on primary pin)

**Dist-off changes nothing on `v0.4_armC_dynamic` sample.**  
Aligned with audit: Dist was already almost unused here (unlike **l13**, kept as a separate Dist-heavy book).

Do **not** claim a holding fix. Longer holds / fewer early flats were not observed vs BASE.

**Refuse promote** (research months fail 100% bar; no Mode S; no WF/holdout).

---

## Next (if continuing exit work)

- Exp B (thesis close) only after rule sign-off — SMC gap still documented in `docs/EXIT_HOLDING_AUDIT.md`
- Or sensitivity: re-run Dist-off on **l13** pins (different book) if you want Dist-frequency confirmation — label as l13-A, not primary
- C1 = Mode C vs A = **mode comparison**, not pure trail
