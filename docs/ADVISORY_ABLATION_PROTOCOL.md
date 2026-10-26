# Pre-registered Advisory Ablation Protocol

**Status:** **APPROVED WITH AMENDMENT** (Manager GO). **P0 authorized**; stop at P0 review gate (`docs/P0_ADVISORY_EXIT.md`). P1 after P0 passes review. P2 conditional.  
**Track:** Pre-AI / advisory research (separate from Phase 1 historical-performance AS).  
**Frozen strategy baseline:** Candidate B per `docs/PRE_AI_CANDIDATE.md`  
**Educational only — no profit guarantee.**

| Field | Value |
|---|---|
| ea_version | `v0.3.4` |
| pack_id (baseline / B0) | `final1_soft3` |
| set_name (baseline) | `v0.3.4_armC_final1_soft3.set` |
| pack_id (B1 advisory ON) | `final1_soft3_adv` |
| EA | `gold_rush_AI_v0.3.4` |
| Schema / prompt (freeze at build) | `grai.glm.v0.3.4` · `grai.prompt.v0.3.4` (+ bridge validator id recorded) |
| Symbol / TF | XAUUSD · M5 |
| Research book | deposit **5000** · threshold **5000** (100%) |
| Mode S | Out of scope for this protocol’s pass/fail |

---

## 0. Scope and non-goals

**In scope:** Incremental effect of advisory on **identical** Candidate B (OFF vs ON).

**Forbidden:** Jan–Feb 2026 alone as robustness proof; Mode S/live claims from this ablation; editing SmcLana / SMC_Lana indicators; substituting B into Phase 1 AS without Spec amendment; using `soft0_ctrl` as matched control; advisory orders / SL removal / risk increase / Risk Engine bypass.

---

## 1. Matched experiment arms

| Arm | pack_id | Config | Difference |
|---|---|---|---|
| **B0 (OFF)** | `final1_soft3` | `v0.3.4_armC_final1_soft3.set` · `InpLLMEnabled=false` | Advisory OFF |
| **B1 (ON)** | `final1_soft3_adv` | Identical strategy params except `InpLLMEnabled=true` (+ bridge token / transport) | Advisory ON |

Hard match: same EA/include/`.ex5` hashes, costs, deposit, calendar, deterministic gates, risk pins. Advisory enablement is the **only** intended behavioral difference. Full config dump must prove no unrelated parameter drift.

`soft0_ctrl` = max-P&L reference only.

---

## 2. Evaluation calendars (regression vs confirmatory)

| Window | Dates (broker server time) | Role |
|---|---|---|
| **W-REG (regression)** | `[2026-01-01, 2026-03-01)` broker server | Historical reproduction, integration test, exploratory research. **Not** untouched holdout. Candidate B was selected using this period. |
| **W-CONF (confirmatory)** | **Candidate to verify/freeze:** `[2026-03-01, 2026-10-01)` (Mar–Sep 2026), **after** W-REG | Forward-time confirmatory window. Verify Tester coverage + not used for advisory tuning **without inspecting confirmatory P&L**. Freeze exact dates/data snapshot before B1 confirmatory scoring. If unsuitable, pick another contiguous **post–W-REG** window — never silently substitute an earlier window as “forward” confirmation. |

**Rules:**

- Exploratory findings on W-REG may inform a **new protocol version**; once they influence advisory design, W-REG must not be presented as independent confirmation.  
- Confirmatory pass/fail uses **frozen W-CONF** only (plus mandatory safety tests that may use synthetic invalid responses).  
- P0 may check data availability / prior-examination status only — **no** confirmatory P&L aggregation to select the window or tune advisory.

---

## 3. Shared opportunity clock and primary metric

### 3.1 Clock definition

One chronological stream of **candidate parent opportunities** from:

1. Frozen Candidate B **signal logic**, and  
2. Deterministic **market-eligibility** gates (SmcLana bias, H4 veto, loose M5, session, news, spread, DQ, etc.),

**before** advisory decisions and **before** arm-specific execution / basket constraints.

| Rule | Requirement |
|---|---|
| Same IDs/timestamps | Both arms share opportunity identity + time |
| Basket open | If EA suppresses candidates while a basket is open, use a **signal-only shadow** path to emit clock rows without placing orders |
| Per opportunity log | Deterministic eligibility · advisory response (B1) · final EA decision · rejection/execution reason |
| Membership | Advisory OFF/ON must not change clock population |

### 3.2 Episode contribution

Let \(r_{a,j}\) = realized episode contribution in **parent-risk units** (\(R_{\text{parent}}\)) for arm \(a\) at opportunity \(j\); \(r_{a,j}=0\) if no episode opens (WAIT, block, position-state, fail-safe, etc.).

\[
R_{\text{parent}}
=
\frac{\text{net episode P\&L after costs}}
{\text{initial parent planned cash risk}}
\]

(with broker tick_size / tick_value reconstruction as in Phase 1 AS economics; no counterfactual P&L for skips).

### 3.3 Primary lift

\[
\Delta_{\mathrm{adv}}
=
\frac{1}{N}
\sum_{j=1}^{N}
(r_{\mathrm{ON},j}-r_{\mathrm{OFF},j})
\]

**Uncertainty (freeze before W-CONF examination):** 95% paired chronological block-bootstrap on \(d_j=r_{\mathrm{ON},j}-r_{\mathrm{OFF},j}\) (shared block indices). Block length chosen on W-REG integration data only from `{3,5,7}` (default 5 if tied); **not** chosen on W-CONF.

### 3.4 Overlap, closure, terminal liquidation, invalid advisory

| Topic | Rule (same for OFF and ON) |
|---|---|
| Overlapping / open basket | Opportunity stays on clock; if arm cannot open → \(r=0\); log `BLOCKED_POSITION_STATE` |
| Episode assignment | One outcome per parent opportunity that opened; layers are not new clock rows |
| Entry window vs terminal | Stop admitting new opportunities at window end \(T_{\text{entry end}}\); continue to \(T_{\text{terminal}}\); **liquidate** remaining positions at \(T_{\text{terminal}}\) under the cost model; include all opportunities in \(N\) (no outcome-dependent exclusion) |
| Invalid / missing / late advisory (ON) | Final action **WAIT** for that opportunity → \(r_{\mathrm{ON},j}=0\) unless a position was already open under prior valid confirm (manage under normal EA exits only) |
| Counterfactuals | Never assign profits for trades the arm did not take |

### 3.5 Report alongside \(\Delta_{\mathrm{adv}}\)

Portfolio net P&L, ROE, max equity DD, expectancy among **executed** episodes (diagnostic), trade/episode coverage, WAIT rate, skipped opportunities, by month and regime, advisory health (valid vs fail-safe WAIT separated).

---

## 4. Advisory action contract (tightened)

### 4.1 Role

AND-gate / veto / layer-cap advice only. Never invent entries, reverse direction, place orders, remove stops, increase risk, or bypass Risk Engine.

### 4.2 Preferred action values (`decision`)

| Value | Meaning |
|---|---|
| `CONFIRM` | Confirm deterministic candidate’s **existing** direction and permitted action |
| `WAIT` | Reject proposed entry or layer |
| `REDUCE_FUTURE_LAYERS` | Lower future layer cap; do **not** close existing positions |
| `HALT_NEW_ENTRIES` | Block new parents and layer adds; do **not** independently liquidate existing positions |

`recommended_max_layers` (int) must satisfy \(0 \le \texttt{recommended\_max\_layers} \le \texttt{deterministic\_max\_layers}\). For `REDUCE_FUTURE_LAYERS`, effective cap = `min(det, recommended)`. Confidence \(\in[0,1]\) is audit-only — **never** authorizes extra risk or gate bypass.

### 4.3 Legacy BUY/SELL compatibility

If transport still emits `BUY`/`SELL`:

- Direction must match the deterministic candidate direction → treat as `CONFIRM`  
- Direction mismatch → **WAIT** (never flip direction)  
- Bridge validator / EA mapper must implement this mapping before scored B1  

### 4.4 Other response fields (freeze)

| Field | Rule |
|---|---|
| `request_id` | Echo required |
| `direction` | Must align with deterministic candidate when confirming; else WAIT |
| `selected_momentum_id` | MOM_* / NONE — must not invent a different parent family than deterministic |
| `regime_assessment` | Allowed regime enums |
| `data_quality_status` | VALID / INCOMPLETE / CONFLICTING / INVALID; INVALID → WAIT |
| `reason_codes[]` | Optional but logged when present |
| `confidence` | `[0,1]`; no risk authority |

Freeze JSON schema, allowed values, prompt version, model/config identity, and mapper version in experiment identity.

### 4.5 Timeout / health / fail-safe

| Item | Pin |
|---|---|
| Timeout | `InpGlmTimeoutMs=1000` |
| Tester transport | File req/resp; enforce and **measure** latency under real Strategy Tester file transport before confirmatory scoring |
| Fail-safe → WAIT | Missing, malformed, stale, mismatched `request_id`, duplicate, late (> timeout), schema-invalid, provider error, auth fail, bridge down |
| Service-health floor (confirmatory) | ≥ **95%** valid **on-time** responses among advisory calls on eligible opportunities; failures reported **separately** from legitimate `WAIT` recommendations |
| Preflight | `docs/BACKTEST_PROTOCOL.md` Arm E; mass timeout/deny ⇒ run invalid |

**Required tests (before confirmatory claim):** inject missing, malformed, stale, mismatched-request, duplicate, and late responses; confirm WAIT and audit codes.

---

## 5. Costs, risk pins, identity

Inherit Candidate B: risk 1%, ladder to 2%, episode risk 3%, max layers 5, adverse OFF, DD kill 5%, spread in prices, Tester commission/swap, no double-count.

Every scored run records: EA/include/set/ex5 hashes, broker specs, data snapshot, `InpLLMEnabled`, schema/prompt/model, transport, timeout, policy `B0`/`B1`, full inputs. Scoreboards: `ea_version` + `pack_id` + `set_name`.

---

## 6. Acceptance criteria (freeze before W-CONF examination)

**Passing ≠ Mode S ≠ live.** Research digests remain Mode-S-ineligible.

### 6.1 Minimum evidence (confirmatory)

≥ **50 completed independent parent episodes per arm** on W-CONF (terminal liquidations count as completed). If either arm &lt; 50 → **inconclusive ≠ pass**.

### 6.2 Primary pass/fail (all required)

| # | Criterion |
|---|---|
| 1 | Point estimate \(\Delta_{\mathrm{adv}} \ge +0.05\) \(R_{\text{parent}}\) per eligible opportunity |
| 2 | 95% paired block-bootstrap CI lower bound for \(\Delta_{\mathrm{adv}}\) **> 0** |
| 3 | B1 max equity DD ≤ B0 DD + **1.0** percentage point |
| 4 | Service health ≥ **95%** valid on-time responses; timeout/invalid rates reported separately |
| 5 | Fail-safe WAIT verified on injected fault cases |
| 6 | No risk-pin increase; adverse still false; no SL removal / safety bypass |
| 7 | Soft0 not used as control |

**Safety/risk failure overrides any metric pass.**

### 6.3 Coverage / skips

Report coverage and skip rates; primary metric already zeros blocked opportunities. No separate “success only on executed B1 trades” primary.

### 6.4 Regression window

W-REG may be used for integration and exploratory \(\Delta_{\mathrm{adv}}\) diagnostics; **must not** alone establish confirmatory pass.

---

## 7. Auditability

Join on `request_id` / opportunity_id: feature snapshot → advisory response (+ latency, failure_code) → final EA decision + reason → episode/deal outcome. Archive reports, Experts, digests under `logs/` with research labels.

---

## 8. Relationship to other contracts

| Contract | Relationship |
|---|---|
| `docs/PRE_AI_CANDIDATE.md` | Frozen B |
| Phase 1 AS | Separate; no silent parent substitution |
| Mode S / dual promote | Not granted here |

---

## 9. Build / implementation gating (authorized)

| Phase | Status | What |
|---|---|---|
| **P0** | **Authorized now** (Manager GO) | Schema/mapper; side-effect-free shadow clock; audit + latency; fault injection; B1 set; W-CONF coverage check (no P&L); exit report |
| **P1** | After P0 passes review | Scored B0/B1 on **W-REG** only (not confirmatory claim) |
| **P2** | Conditional | Frozen W-CONF + frozen advisory design; §6 pass/fail |

### P0 safeguards (mandatory)

1. `InpLLMEnabled=false` trading path unchanged; shadow logs only; no SmcLana edits.  
2. Stable `opportunity_id` ≠ unique `request_id`; late/duplicate must not apply to a later request.  
3. W-CONF coverage check without examining confirmatory performance.  
4. Action contract: CONFIRM / WAIT / REDUCE_FUTURE_LAYERS / HALT_NEW_ENTRIES (+ legacy BUY/SELL→CONFIRM or WAIT).

**P0 is not green until** [`docs/P0_ADVISORY_EXIT.md`](P0_ADVISORY_EXIT.md) is submitted and reviewed.

— Gold Rush AI engineering
