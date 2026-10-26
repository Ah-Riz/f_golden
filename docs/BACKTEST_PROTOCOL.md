# Backtest / walk-forward / ablation (v0.2)

Same data, XAUUSD, M5, costs, slippage, risk budget, periods for comparable arms.

## Matrix

| Arm | Set | Config |
|---|---|---|
| A | `v0.2_armA_single.set` | First entry only; LLM OFF; AutoLot |
| B | `v0.2_armB_fixed_layers.set` | Adverse layers research |
| C | `v0.2_armC_dynamic.set` | pctRisk + favorable pyramid |
| D | `v0.2_armD_regime.set` | C + regime |
| E | `v0.2_armE_glm.set` | D + GLM AND-gate |

## Arm E preflight (required — avoids 0 trades)

**Tester (backtest):** `WebRequest()` is banned in the MT5 Strategy Tester (`err=4014` regardless of allowlist), so in the tester the EA uses a **file transport**: it writes `grai_bridge/req/<rid>-<nonce>.json` into the tester agent sandbox and polls for the matching `resp/` file. `scripts/run_bridge.sh` runs the HTTP server **and** the file watcher together.

1. `bash scripts/run_bridge.sh` — bridge + watcher up (`/health` ok, `key_configured=true`, `GRAI_MT5_ROOT` correct)
2. Fresh compile deployed (`bash scripts/deploy_mt5.sh --compile`) — file transport is tester-only
3. Load set → set `InpBridgeToken` = `.env` `GRAI_BRIDGE_TOKEN` (INIT shows `bridgeToken=ON`)
4. Experts must show `LLM_RESPONSE` per bar (not mass `LLM_FAIL`)
5. Layer codes: `FILE_TIMEOUT` → watcher down / wrong `GRAI_MT5_ROOT` · `BRIDGE_401` → EA token · `PROVIDER_*` → API key
6. If mass `FILE_TIMEOUT` / `WR_DENY` / `WR_FAIL` → stop; result invalid for ablation

**Live chart (demo):** WebRequest path — MT5 → Tools → Options → Expert Advisors → **Allow WebRequest** for `http://127.0.0.1:8765` (`WR_DENY`/`err=4014` = allowlist, live only). Optimization with LLM is opted out (`OPT_NO_LLM`).

## Ablation E vs D

1. Identical inputs/risk except LLM.
2. Both complete Screen S window (or same demo window).
3. `python3 python/research/ablation_report.py --d d.json --e e.json`
4. Promote LLM only if multi-metric improvement (DD, expectancy, stability, exposure). Explanations alone ≠ promote.

## MOM_D segregation

Report parent_entry (A/B/C) vs layer_continuation (D) vs episode separately.

## Walk-forward

Train → as-of stats → classify → caps → next window → roll. Holdout untouched.
