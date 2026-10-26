# Gold Rush AI v0.3 / v0.4 — Design (lean)

No profit guarantee. Frozen: `gold_rush_pro_Fixed.mq5`, `gold_rush_AI_v0.1.mq5`, `gold_rush_AI_v0.2.mq5`, `gold_rush_AI_v0.3.mq5`, `gold_rush_AI_v0.3_short.mq5`.

**v0.4 candidate:** `gold_rush_AI_v0.4.mq5` · `Include/GRAI/Lifecycle.mqh` · Mode B delayed SL+ · schema `grai.glm.v0.4`. See `docs/V0.4_LIFECYCLE.md`, `docs/VALIDATION_v0.4.md`. Preserve v0.3 baseline sets.

**Active SMC gate fork:** `gold_rush_AI_v0.3_smc.mq5` (+ `v0.3_smc_short`) · `Include/GRAI/SmcLanaGate.mqh`.

v0.3_smc: **SMC trading-signal 1:1** (structure/OB/mapping/liq vs `pine/SMC_Lana.pine`) · lookback **5000** · 5% equity-peak DD · risk ladder 1%→1.5%→2%. Not a full Pine visual/FVG/SFP port.

## Authority

MQL5 RiskEngine final. Python/GLM advisory only. LLM cannot raise risk ladder, DD, or SMC caps.

## Paths

| Path | Use |
|---|---|
| A | LLM OFF, Fixed entry + GRAI wrappers (Tester, Arms A–D) |
| B | Localhost bridge + GLM; live `InpDeterministicFallback=false` |

## Bias / trend (SMC gate)

Primary: [`pine/SMC_Lana.pine`](../pine/SMC_Lana.pine) logic in `Include/GRAI/SmcLanaGate.mqh` (fork). Frozen v0.3 still uses `SmcLana.mqh`.

| Signal | Role |
|---|---|
| BOS / CHoCH / sweeps | `ms.trend` ±1 — BUY only if bull, SELL only if bear |
| Volumetric OB + mitigation | Block fighting unmitigated opposite OB |
| Mapping structure | Must agree with `ms.trend` when set |
| Liquidity prints | Optional soft filter |
| D1 SMA200 + H4 EMA200 | Optional AND (`InpUseMaBias`, default **OFF**) |

FLAT / not ready → **WAIT**. Chart objects optional (`InpSmcDraw`).

## Risk ladder

- Floor 1% → step +0.5% on bias-aligned win → cap 2%
- Reset to 1% on equity DD ≥5% or wrong-bias loss

## Equity DD

`MaxEquityDDPercent=5` → flatten, block until next D1 day, `RISK_RESET dd`.

## Momentum / Arms / Mode S

Unchanged matrix (A–E). Arm C + SMC-full sets: `v0.3_armC_smc_full*.set`. Screen S: 50k cent, M5, 2026-01→03, ≥+5k/mo.

## Modules

`Include/GRAI/{Types,AuditLog,Episode,RiskEngine,SmcLana,SmcLanaGate,SmcDraw,Bias,Classify,Regime,LlmBridge}.mqh`  
`pine/SMC_Lana.pine` · `gold_rush_AI_v0.3_smc.mq5` · `scripts/smc_parity_dump.py`
