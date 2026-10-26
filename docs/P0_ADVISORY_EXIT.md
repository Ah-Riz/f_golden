# P0 Advisory Ablation — Exit Report

**Status:** SUBMITTED FOR REVIEW (not green until reviewer sign-off).  
**Baseline:** `v0.3.4` · `final1_soft3` · `v0.3.4_armC_final1_soft3.set`  
**B1:** `final1_soft3_adv` · `sets/v0.3.4_armC_final1_soft3_adv.set`  
**P1/P2/Mode S:** unauthorized.  
**Continue on new device:** [`DEVICE_HANDOFF.md`](DEVICE_HANDOFF.md).

## QA — evidence

```
python3 python/bridge/schema.py          → schema self-check OK grai.glm.v0.3.4
python3 python/bridge/hostile_smoke.py   → hostile_smoke OK fails=0  (bridge up)
# earlier offline: OK_OFFLINE fails=0 when bridge down
```

Operator session (2026-10-26): bridge `provider=zai model=glm-5.3-flash`; smoke `BRIDGE_AUTH` / WAIT / reject paths OK. `BrokenPipeError` on slow replies = client timeout (`InpGlmTimeoutMs=1000`), not bridge death.

## Requirement audit

| Requirement | Evidence | Status |
|---|---|---|
| Protocol W-CONF `[2026-03-01, 2026-10-01)` | `docs/ADVISORY_ABLATION_PROTOCOL.md` | DONE |
| Schema + legacy map | `python/bridge/schema.py` | DONE |
| LlmBridge mapper / gate | `Include/GRAI/LlmBridge.mqh`, `Types.mqh` | DONE |
| OPP log · opp_id ≠ request_id | `gold_rush_AI_v0.3.4.mq5` OPP + `req-…-tick` | DONE |
| File `latency_ms` log | `LLM_LATENCY` in `GRAI_AdviceViaFile` | DONE (code) |
| Fault → reject/WAIT | hostile_smoke live + offline | DONE |
| B1 set (LLM ON only) | `sets/v0.3.4_armC_final1_soft3_adv.set` | DONE |
| OFF-path unchanged | `if(!llm_enabled) return true`; LLM block gated; OPP = log only; no SmcLana | DONE |
| Prompt documented | `docs/GLM_PROVIDER_VERIFY.md` + `server.py` | DONE |
| W-CONF coverage (no P&L) | Operator must confirm MT5 M5 bars for window; **no P&L inspected** | OPERATOR |
| Tester p50/p95 latency | Not run | OPEN — do not claim latency gate green |

## Ponytail-review (applied)

- `LlmBridge.mqh`: shrink GlmAllowsCmd legacy BUY/SELL branch; drop dead fall-through.
- `v0.3.4.mq5`: delete redundant post-request rid check (already in `GRAI_AdviceFromJson`).
- `hostile_smoke.py`: drop unused `normalize_advice` import.
- delete: staged `docs/P0_APPLY_*.md` / blueprint duplicates.

`net: ~-25 lines possible applied.`

## OFF regression

LLM OFF → `GRAI_GlmAllowsCmd` immediate true; no advise call; OPP Experts only; soft3 set untouched.

## Reviewer checklist

- [ ] Accept offline + live smoke QA + static OFF regression  
- [ ] Optional: Tester `LLM_LATENCY` sample (expect many timeouts at 1000 ms vs GLM)  
- [ ] W-CONF coverage freeze before P2  
- [ ] Recompile `gold_rush_AI_v0.3.4.ex5` before Tester  
- [ ] Authorize P1 only after sign-off  

**Stop at review gate.**
