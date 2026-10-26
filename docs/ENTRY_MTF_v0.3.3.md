# v0.3.3 — SmcLana bias + MTF gates (no H4 overwrite)

EA: `gold_rush_AI_v0.3.3.mq5` · schema `grai.glm.v0.3.3`  
Frozen: `gold_rush_AI_v0.3.mq5`, `gold_rush_AI_v0.3.1.mq5`, `gold_rush_AI_v0.3.2.mq5`.  
v0.4 remains the lifecycle fork (no MTF merge).

## Split roles

| Role | Module |
|------|--------|
| Directional bias | SmcLana via `GRAI_BiasUpdate()` → `g_grai_bias` |
| MTF phrase gates | `Include/GRAI/MtfStack.mqh` → `GRAI_MtfAllowsCmd` |
| H4 → bias overwrite | Opt-in only: `InpMtfH4WritesBias=true` (v0.3.2 restore) |
| Chart trigger | Buy&Sell rotating (unchanged Arm C) |
| OB arm | OFF on all v0.3.3 hybrid sets |

Default hybrid: **SmcLana owns bias**; MTF layers only WAIT-gate. Invalid MA/ATR → WAIT.

## Hard gates (closed bar `shift=1`)

Same phrase rules as v0.3.2 when a layer is ON:

| Layer | LONG | SHORT |
|-------|------|-------|
| H4 direction | close > EMA200 and EMA20 > EMA50 | inverse |
| H1 trend | EMA20 > EMA50 and close > EMA20; must agree H4 if both on | inverse |
| M15 pullback | low within 0.5×ATR(14) of EMA20 or EMA50 | high in band |
| M5 entry | bullish bar, close ≥ mid-range, low in EMA band | mirror |

INIT must show `mtf=` / `h4=` / `h1=` / `m15=` / `m5=` / `h4bias=`.  
Experts: `SKIP mtf_h4|mtf_h1|mtf_m15|mtf_m5|mtf_data`.

## Research sets

All arms: **SmcLana ON**, **`InpMtfH4WritesBias=false`**, OB OFF.

| Set | MTF | H4 | H1 | M15 | M5 | Purpose |
|-----|-----|----|----|-----|-----|---------|
| `v0.3.3_armC_hyb0_ctrl` | OFF | — | — | — | — | Re-baseline ≈ mtf0 |
| `v0.3.3_armC_hyb1_m5` | ON | OFF | OFF | OFF | ON | Soft M5 only |
| `v0.3.3_armC_hyb2_pb` | ON | OFF | OFF | ON | ON | Pullback + entry |
| `v0.3.3_armC_hyb3_h4and` | ON | ON | OFF | OFF | ON | SmcLana ∩ H4 veto + M5 |
| `v0.3.3_armC_hyb4_softfull` | ON | ON | ON | ON | ON | Full stack as gates only |

## Tester checklist

1. `bash scripts/deploy_mt5.sh --compile v0.3.3`
2. XAUUSD M5, deposit **5000**, range 2026.01.01–2026.03.01.
3. Run hyb0 → hyb1 → hyb2 → hyb3 → hyb4 (Load matching `.set`).
4. INIT must show `h4bias=OFF` on hybrid arms; `smc=ON`.
5. Slice `--deposit 5000 --threshold 5000`. Research only — not Mode S promote.

Success bar (research): keep ≥ ~70% of hyb0 Jan net **and** cut Feb hole vs hyb0 without starvation (n≪30 = WAIT metric, not a pass).
