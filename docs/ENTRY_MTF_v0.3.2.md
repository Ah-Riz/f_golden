# v0.3.2 — H4 → H1 → M15 → M5 phrase stack

EA: `gold_rush_AI_v0.3.2.mq5` · schema `grai.glm.v0.3.2`  
Frozen: `gold_rush_AI_v0.3.mq5`, `gold_rush_AI_v0.3.1.mq5`.

## Split roles

| Role | Module |
|------|--------|
| MTF phrase gates | `Include/GRAI/MtfStack.mqh` |
| Chart trigger | Buy&Sell rotating (unchanged Arm C) |
| Control bias | SmcLana on `mtf0_ctrl` only |
| OB arm | OFF on all v0.3.2 MTF sets |

## Hard gates (closed bar `shift=1`)

| Layer | LONG | SHORT |
|-------|------|-------|
| H4 direction | close > EMA200 and EMA20 > EMA50 | inverse |
| H1 trend | EMA20 > EMA50 and close > EMA20; must agree H4 | inverse |
| M15 pullback | low within 0.5×ATR(14) of EMA20 or EMA50 | high in band |
| M5 entry | bullish bar, close ≥ mid-range, low in EMA band | mirror |

Invalid MA/ATR → WAIT. Disabled layers pass through. Experts: `SKIP mtf_h4|mtf_h1|mtf_m15|mtf_m5|mtf_data`.

When `InpUseMtfStack` + `InpMtfUseH4`: stack writes `g_grai_bias` from H4 (SmcLana OFF on MTF sets).

## Research sets

| Set | MTF | H4 | H1 | M15 | M5 | SmcLana |
|-----|-----|----|----|-----|-----|---------|
| `v0.3.2_armC_mtf0_ctrl` | OFF | — | — | — | — | ON |
| `v0.3.2_armC_mtf1_h4` | ON | ON | OFF | OFF | OFF | OFF |
| `v0.3.2_armC_mtf2_h4h1` | ON | ON | ON | OFF | OFF | OFF |
| `v0.3.2_armC_mtf3_pb` | ON | ON | ON | ON | OFF | OFF |
| `v0.3.2_armC_mtf4_full` | ON | ON | ON | ON | ON | OFF |

## Tester checklist

1. `bash scripts/deploy_mt5.sh --compile v0.3.2`
2. XAUUSD M5, deposit **5000**, range 2026.01.01–2026.03.01.
3. Run `mtf0_ctrl` then `mtf4_full`; if starved, step mtf1→mtf3.
4. INIT must show `mtf=` / `h4=` / `h1=` / `m15=` / `m5=`.
5. Slice `--deposit 5000 --threshold 5000`. Research only — not Mode S promote.
