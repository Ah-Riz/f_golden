# Gold Rush AI

Research-grade XAUUSD EA fork + optional GLM advisory (default model in code `glm-4.7-flash`; `.env` often `glm-5.3-flash`).

- **Frozen:** `gold_rush_pro_Fixed.mq5`, `gold_rush_AI_v0.1.mq5`, `gold_rush_AI_v0.2.mq5`, `gold_rush_AI_v0.3.mq5` — do not edit
- **Active:** `gold_rush_AI_v0.3.1.mq5` (SMC_Lana_OB gate) · `gold_rush_AI_v0.4.mq5` — see [`currently best/`](currently%20best/) for prior best
- **SMC (TradingView):** [`pine/SMC_Lana.pine`](pine/SMC_Lana.pine)
- **SMC (MT5 indicator):** [`Indicators/SMC_Lana.mq5`](Indicators/SMC_Lana.mq5) · OB-only SNR: [`Indicators/SMC_Lana_OB.mq5`](Indicators/SMC_Lana_OB.mq5) — [docs/SMC_LANA_INDICATOR.md](docs/SMC_LANA_INDICATOR.md)
- **v0.3.1 OB entry:** [docs/ENTRY_SMC_OB_v0.3.1.md](docs/ENTRY_SMC_OB_v0.3.1.md)
- **Design:** [docs/DESIGN.md](docs/DESIGN.md)
- **QA:** [docs/QA_GATE.md](docs/QA_GATE.md)

No profit guarantee. Strategy Tester ≠ live.

## Quick start (v0.3.1 OB ablation)

```bash
bash scripts/deploy_mt5.sh --compile v0.3.1
# SMC_Lana_OB chart overlay (optional visual):
bash scripts/deploy_mt5.sh --compile --indicator
```

1. Tester Expert = `gold_rush_AI\gold_rush_AI_v0.3.1`
2. Load `v0.3.1_armC_ob_free.set` (SMC-Lana bias) then `v0.3.1_armC_ob_touch.set` (bias + bull-OB BUY arm 2h) — [docs/ENTRY_SMC_OB_v0.3.1.md](docs/ENTRY_SMC_OB_v0.3.1.md)
3. Research deposit **5000** · slicer `--threshold 5000` (100%). Not Mode S promote.
4. Frozen v0.3 armC: `gold_rush_AI_v0.3` + `v0.3_armC_dynamic.set` — [sets/README.md](sets/README.md) · [docs/BACKTEST_PROTOCOL.md](docs/BACKTEST_PROTOCOL.md)
5. Arm E: allow WebRequest `http://127.0.0.1:8765` or you get `err=4014` and **0 trades**

## Bridge (Path B / Arm E)

**Where each variable comes from:** [docs/ENV.md](docs/ENV.md)

Short version:

| Variable | Get it from |
|---|---|
| `ZAI_API_KEY` | [z.ai](https://z.ai) → API Keys ([howto](https://docs.z.ai/guides/develop/http/introduction)) |
| `GRAI_BASE_URL` | Usually `https://api.z.ai/api/paas/v4` ([OpenAI SDK guide](https://docs.z.ai/guides/develop/openai/python)) |
| `GRAI_MODEL` | Your Z.AI plan model id (code default `glm-4.7-flash`) |
| `GRAI_BRIDGE_TOKEN` | You invent it; paste same into EA `InpBridgeToken` |

```bash
# edit .env  →  then:
bash scripts/run_bridge.sh
```

Allow WebRequest URL `http://127.0.0.1:8765` in MT5. Never put the API key in MQL5.

**P0 continue / new device:** [docs/DEVICE_HANDOFF.md](docs/DEVICE_HANDOFF.md) · prompt + verify: [docs/GLM_PROVIDER_VERIFY.md](docs/GLM_PROVIDER_VERIFY.md) · exit: [docs/P0_ADVISORY_EXIT.md](docs/P0_ADVISORY_EXIT.md)
