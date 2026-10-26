# Pre-AI candidate (frozen)

**Status:** **MANAGER APPROVED** as frozen baseline for AI advisory research (research only — **not** Mode S / dual-promote / live).  
**Sign-off:** Formal Sign-off — Gold Rush AI Pre-AI Research Freeze (Manager, Gold Rush AI).  
**EA:** `gold_rush_AI_v0.3.4` · schema `grai.glm.v0.3.4`  
**SMC:** internals **frozen** (`Include/GRAI/SmcLana.mqh`, `Indicators/SMC_Lana*`). AI must not rewrite them.

## Locked candidate identity

| Field | Value |
|-------|--------|
| ea_version | **v0.3.4** |
| pack_id | **final1_soft3** |
| set_name | **`v0.3.4_armC_final1_soft3.set`** |
| EA family | `gold_rush_AI_v0.3.4` |
| Research book | XAUUSD M5 · deposit **5000** · threshold **5000** (100%) |
| Months scored | **2026-01 / 2026-02** |
| report_file | `logs/ReportTester-52016350_v0.3.4_armC_final1_soft3.html` |
| digest | `logs/salary_digest_v0.3.4_armC_final1_soft3.csv` (+ `.RESEARCH.txt`) |
| stack | SmcLana bias · H4 veto · loose M5 · `h4bias=OFF` · LLM OFF · adverse OFF |

**Max-P&L reference (not AI matched baseline):** `soft0_ctrl` / `v0.3.4_armC_soft0_ctrl.set` — entry filters differ from B; do **not** use A as the advisory ablation control.

## Run caveats (this freeze)

| Issue | Detail |
|-------|--------|
| Range | Reports are **2026.01.01–2026.03.01** (Jan–Feb score), **not** the planned 2025.07–2026.03 widen |
| final0 | **Missing** — control proxy = prior `v0.3.4_armC_soft0_ctrl` on same Jan–Feb book |
| final2 / final4 | Same monthly nets as final1 on this window (RequireSweep / MaBias **inert** here) |
| Sample | Feb on B: **n=39** (thin); not statistically established robustness |
| Promote | All arms `range_verdict=fail` vs monthly +5000 — **refuse Mode S / dual promote / live** on these digests |

## Scoreboard (research 5k / 100% · units)

| pack_id | set_name | Jan (n) | Feb (n) | sum | worst |
|---------|----------|--------:|--------:|----:|------:|
| soft0_ctrl (proxy) | `v0.3.4_armC_soft0_ctrl` | +5665.86 (123) | −490.71 (91) | **5175.15** | −490.71 |
| final1_soft3 | `v0.3.4_armC_final1_soft3` | +4825.73 (90) | +253.50 (39) | 5079.23 | **+253.50** |
| final2_sweep | `v0.3.4_armC_final2_sweep` | +4825.73 (90) | +253.50 (39) | 5079.23 | +253.50 |
| final3_obarm | `v0.3.4_armC_final3_obarm` | +513.08 (23) | −7.21 (20) | 505.87 | −7.21 |
| final4_ma | `v0.3.4_armC_final4_ma` | +4825.73 (90) | +253.50 (39) | 5079.23 | +253.50 |

All range_verdict=**fail** vs monthly +5000 bar. No starvation reject (all n≥20).

## Freeze rule result

No usage arm beats control on **sum-net AND worst-month** (sums all &lt; soft0). Per plan fallback → **final1_soft3**. Manager approved B as research starting point (~98.15% of A’s 2m total; worst month +253.50 vs A’s −490.71) — **research choice only**, not a salary or live pass.

## Mandatory constraints for subsequent AI advisory research

1. Keep Candidate B’s strategy configuration frozen. Do **not** modify `Include/GRAI/SmcLana.mqh` or `Indicators/SMC_Lana*`.
2. Advisory may recommend or explain an action; must **not** send orders, remove stops, increase risk, or bypass deterministic controls.
3. Invalid / malformed / late advisory → fail-safe **WAIT**. Risk Engine remains final authority.
4. To measure advisory lift: compare **B + advisory OFF** vs **same B + advisory ON** — matched data, costs, execution, risk pins, and other strategy behavior. Do **not** use soft0 as the advisory control.
5. Preserve source / include-tree / `.set` / compiled-build / data / full-config identities. Every scoreboard: `ea_version` + `pack_id` + `set_name`.
6. Research digests at deposit **5000** remain **ineligible** as Mode S promotion evidence.

## Scope boundary (Phase 1 AS)

This freeze is for the **pre-AI / advisory research track** only. It does **not** silently replace the parent strategy in the Phase 1 Acceptance Specification (historical-performance engine; Arm C pin `v0.3_armC_dynamic` unless separately amended). Any proposal to substitute `final1_soft3` into that contract requires an **explicit Spec amendment**.

## Next milestone

**Pre-registered Advisory Ablation Protocol:** `docs/ADVISORY_ABLATION_PROTOCOL.md` — revised after manager review (regression W-REG vs confirmatory W-CONF, \(\Delta_{\mathrm{adv}}\), tightened actions). Pending written sign-off + explicit **when to build** authorization before scored B1 claims.

## Optional follow-up (not required for AI start)

Re-run final0–final4 on **2025.07.01–2026.03.01** if you want true widen OOS; current freeze is Jan–Feb research only.

Educational only — no profit guarantee.
