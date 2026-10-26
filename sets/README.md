# Gold Rush AI Strategy Tester sets

**Rule:** Load matching `.set` before every run. Arm E: set `InpBridgeToken` after Load.

**Codes:** [CODES.md](CODES.md) · export: `export_v0.3/` · MT5: `Presets/gold_rush_AI/`

## Deploy

```bash
bash scripts/deploy_mt5.sh --list
bash scripts/deploy_mt5.sh --compile v0.3
bash scripts/deploy_mt5.sh --compile --family v0.3
```

Copies EA(s), GRAI includes, news CSV → `MQL5/Files/`, matching `sets/<VER>_*.set` → Presets.

## Screen S pin

| Item | Value |
|---|---|
| Deposit | **50000** cent |
| Chart | **M5** |
| Range | **2026.01.01 – 2026.03.01** |
| Pass | ≥ **+5000**/mo both months |
| EA | `gold_rush_AI_v0.3` |

## Arms (v0.3)

| Set | Use |
|---|---|
| `v0.3_armA_single.set` | Control / Path A + bias + DD5 + ladder |
| `v0.3_armB_fixed_layers.set` | Adverse research — not salary |
| `v0.3_armC_dynamic.set` | pctRisk + pyramid (**primary**) |
| `v0.3_armD_regime.set` | Ablation baseline |
| `v0.3_armE_glm.set` | GLM — needs bridge + WebRequest allowlist |
| `v0.3_test_smc.set` | SMC ON smoke |
| `v0.3_test_smc_off.set` | SMC OFF + MA control |
| `v0.3_test_smc_long.set` | Arm C + SMC · LongOnly |
| `v0.3_test_smc_short.set` | Arm C + SMC · ShortOnly |

v0.3 pins: SMC-Lana 1:1 (`pine/SMC_Lana.pine` → `SmcLana.mqh`) · 5% equity-peak DD · risk ladder 1%→1.5%→2% · flip-flop OFF (same-side re-entry).
