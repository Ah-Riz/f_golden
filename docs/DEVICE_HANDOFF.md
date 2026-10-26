# Device handoff — P0 advisory (continue here)

**Date:** 2026-10-26 · **Stop gate:** human review — no P1/P2/Mode S.

## Bring to the other machine

| Item | Notes |
|---|---|
| This git tree | `gold_rush_AI` (code + docs below) |
| Repo-root `.env` | **Copy yourself** — gitignored. Never commit. Template: `.env.example` |
| MT5 | Recompile `gold_rush_AI_v0.3.4.ex5` on that box if `.mq5` newer than `.ex5` |

## Pins

| Role | Value |
|---|---|
| EA | `gold_rush_AI_v0.3.4` |
| Schema | `grai.glm.v0.3.4` |
| B0 (OFF) | `sets/v0.3.4_armC_final1_soft3.set` |
| B1 (ON) | `sets/v0.3.4_armC_final1_soft3_adv.set` · `InpLLMEnabled=true` only intentional delta |
| Provider (example) | `zai` · model from `.env` (often `glm-5.3-flash`) · code default `glm-4.7-flash` |
| Prompt tag | `GRAI_PROMPT_VERSION` (e.g. `grai.prompt.v0.2`) — **text is inline** in `python/bridge/server.py` |
| W-CONF | `[2026-03-01, 2026-10-01)` — coverage only, no P&L |
| Timeout pin | `InpGlmTimeoutMs=1000` in adv set — GLM often slower → WAIT / broken pipe (see below) |

## Already green (do not re-claim as Mode S)

```bash
python3 python/bridge/schema.py            # OK grai.glm.v0.3.4
bash scripts/run_bridge.sh                 # keep running
python3 python/bridge/hostile_smoke.py     # OK fails=0 (with bridge up)
```

Exit report: [`P0_ADVISORY_EXIT.md`](P0_ADVISORY_EXIT.md). Protocol: [`ADVISORY_ABLATION_PROTOCOL.md`](ADVISORY_ABLATION_PROTOCOL.md).

## Next on new device

1. Restore `.env` → `bash scripts/run_bridge.sh`
2. Optional: `cd python/bridge && python3 verify_provider.py`
3. Recompile `.ex5` · Load B1 set · `InpBridgeToken` = `GRAI_BRIDGE_TOKEN`
4. Tester: Experts `OPP` / `LLM_BIND` / `LLM_LATENCY` (file transport — WebRequest banned in Tester)
5. Operator: confirm W-CONF M5 history exists (no P&L)
6. Human sign-off on exit doc → only then discuss P1

## Prompt sent to GLM (summary)

**System:** return ONLY flat JSON — `request_id`, `decision`, `direction`, `selected_momentum_id`, `regime_assessment`, `recommended_max_layers` (0..det_max), `confidence`, `data_quality_status`. No markdown. Advisory only.

**User:** EA feature JSON (`Include/GRAI/Features.mqh` → `GRAI_BuildFeatureJson`) — opp/request ids, symbol, bar time, bid/ask/spread, regime, session/news/spike flags, momentum, basket, episode risk, det max layers, DQ, schema.

Full verify + ladder: [`GLM_PROVIDER_VERIFY.md`](GLM_PROVIDER_VERIFY.md) · env map: [`ENV.md`](ENV.md).

## Ops cheats

| Symptom | Likely cause |
|---|---|
| `BrokenPipeError` on bridge | Client closed early — usually EA `InpGlmTimeoutMs=1000` &lt; GLM latency. Bridge still up; EA fail-safe WAIT |
| `AUTH_FAIL path=/advise` | Missing/wrong `X-GRAI-Token` (smoke bad_token or EA token mismatch) |
| `FILE_TIMEOUT` | Watcher down or `GRAI_MT5_ROOT` wrong |
| `WR_DENY` / `4014` | Live chart WebRequest allowlist — not Tester |
| `BRIDGE_401` | `InpBridgeToken` ≠ `GRAI_BRIDGE_TOKEN` |

No profit guarantee. Dual promote still Mode S + WF/holdout — neither started for advisory promote.
