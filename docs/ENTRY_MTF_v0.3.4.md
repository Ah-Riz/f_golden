# v0.3.4 — Soft hyb3 ladder (SmcLana + H4 veto + optional loose M5)

EA: `gold_rush_AI_v0.3.4.mq5` · schema `grai.glm.v0.3.4`  
Frozen: `gold_rush_AI_v0.3.mq5` … `v0.3.3.mq5`. v0.4 remains lifecycle (no MTF merge).

## Split roles

| Role | Module |
|------|--------|
| Directional bias | SmcLana → `g_grai_bias` |
| H4 / M5 gates | `Include/GRAI/MtfStack.mqh` → `GRAI_MtfAllowsCmd` |
| H4 → bias overwrite | Opt-in `InpMtfH4WritesBias` (OFF on soft sets) |
| M5 loose | `InpMtfM5Loose`: candle + mid only; drop EMA near-band |
| Chart trigger | Buy&Sell rotating (Arm C) |
| OB arm | OFF on all soft sets |

Invalid MA/ATR (strict path) → WAIT. INIT must show `mtf=` / `h4=` / `m5=` / `h4bias=` / `m5loose=` / `regime=`.

## Hard gates (closed bar `shift=1`)

| Layer | LONG | SHORT |
|-------|------|-------|
| H4 direction | close > EMA200 and EMA20 > EMA50 | inverse |
| M5 strict | bullish, close ≥ mid, low in EMA20/50 band | mirror |
| M5 loose | bullish, close ≥ mid (no EMA band) | mirror |

H1 / M15 OFF on soft ladder.

## Research sets

All: **SmcLana ON**, **`InpMtfH4WritesBias=false`**, OB OFF.

| Set | MTF | H4 | M5 | M5Loose | Regime | Role |
|-----|-----|----|----|---------|--------|------|
| `v0.3.4_armC_soft0_ctrl` | OFF | — | — | — | OFF | Re-baseline ≈ hyb0 |
| `v0.3.4_armC_soft1_h4` | ON | ON | OFF | — | OFF | H4 veto only |
| `v0.3.4_armC_soft2_h4m5` | ON | ON | ON | OFF | OFF | hyb3 clone |
| `v0.3.4_armC_soft3_h4loose` | ON | ON | ON | ON | OFF | H4 + loose M5 |
| `v0.3.4_armC_soft4_h4reg` | ON | ON | OFF | — | ON | H4 + regime gate |

## Tester checklist

1. `bash scripts/deploy_mt5.sh --compile v0.3.4`
2. XAUUSD M5, deposit **5000**, range 2026.01.01–2026.03.01.
3. Run soft0 → soft4 (Load matching `.set`).
4. Slice `--deposit 5000 --threshold 5000`. Research only — not Mode S promote.

**Success bar:** Jan ≥ ~70% of soft0 Jan **and** Feb net > soft0 Feb **and** Feb n ≳ 40. Else fail — no promote.

## Final pre-AI pack (`sets/export_v0.3.4_final/`)

Last entry/filter research before AI chat. **Do not edit SmcLana / SMC_Lana indicator sources** — set-only usage ablation on EA `gold_rush_AI_v0.3.4`.

| Set | Base | Usage delta |
|-----|------|-------------|
| `v0.3.4_armC_final0_ctrl` | soft0 | control |
| `v0.3.4_armC_final1_soft3` | soft3 | dual-goal pin |
| `v0.3.4_armC_final2_sweep` | soft3 | `InpSmcRequireSweep=true` |
| `v0.3.4_armC_final3_obarm` | soft3 | `InpSmcObEntryGate=true` |
| `v0.3.4_armC_final4_ma` | soft3 | `InpUseMaBias=true` |

Tester: XAUUSD M5 · deposit **5000** · **2025.07.01–2026.03.01** · final0→final4.  
Slice `--deposit 5000 --threshold 5000`. Freeze winner in `docs/PRE_AI_CANDIDATE.md`. LLM OFF — not Mode S promote.
