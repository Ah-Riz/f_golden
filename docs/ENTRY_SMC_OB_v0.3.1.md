# v0.3.1 — SMC-Lana bias + SMC_Lana_OB BUY arm window

EA: `gold_rush_AI_v0.3.1.mq5` · schema `grai.glm.v0.3.1`  
Frozen v0.3 (`gold_rush_AI_v0.3.mq5`) is untouched.

## Split roles

| Role | Module |
|------|--------|
| Directional bias | `Include/GRAI/SmcLana.mqh` + `Bias.mqh` (same as frozen v0.3) |
| BUY arm window | `Include/SMC_Lana_OB/SmcObEngine.mqh` via `Include/GRAI/SmcObArm.mqh` |
| Chart trigger | Buy&Sell rotating (unchanged from v0.3) |

## Bias

- `InpUseSmc=true` → SMC-Lana structure trend → LONG / SHORT / FLAT.
- `GRAI_BiasAllowsCmd` in `GRP_OrderSend` (same choke as v0.3).
- Optional `InpUseMaBias` AND with D1 SMA200 + H4 EMA200.
- `InpSmcDraw` → SmcLana chart objects only (OB rectangles stay off).

## OB entry gate (`InpSmcObEntryGate`) — arm window

Uses **SMC_Lana_OB** zones (independent engine from bias). Mitigation default **Touch** (`InpObMiti=0`); keep last **N** (`InpObKeep=3`).

OB birth TF: `InpObTimeframe` (default `PERIOD_CURRENT` = chart / M5). HTF test uses **H1** zones while the EA chart, bias, and Buy&Sell stay on **M5**.

When gate **ON**:

1. Each tick: `SmcObUpdate` on `InpObTimeframe` + if live **Ask** or **M5 bar 0** high/low overlaps any kept unmitigated **bull** OB band, set / **refresh** `arm_until = now + InpObArmHours` (default **2.0**).
2. **BUY** (parent + pyramid): allowed only while armed. Location free inside the window.
3. **SELL**: OB gate always passes.
4. Never armed / expired → `SKIP ob_entry` on BUY only.
5. Experts: `OB_ARM until=… tf=H1|Current` (rate-limited). INIT includes `obTf=…`.

| Set | Gate | `InpObTimeframe` | `InpObArmHours` | Meaning |
|-----|------|------------------|-----------------|---------|
| `v0.3.1_armC_ob_free` | OFF | Current (inert) | 2 | SMC-Lana bias only — ≈ v0.3 control |
| `v0.3.1_armC_ob_touch` | ON | Current | 2 | M5 OB history; touch arms BUY 2h |
| `v0.3.1_armC_ob_arm8` | ON | Current | **8** | Same as touch; longer arm |
| `v0.3.1_armC_ob_h1` | ON | **H1** | 2 | H1 bull zones; M5 price touch arms BUY 2h |

## Research Tester checklist

1. Compile: `bash scripts/deploy_mt5.sh --compile v0.3.1` (and `--indicator` if OB indicator changed).
2. Tester: XAUUSD **M5**, hedging, deposit **5000**.
3. H1 arm test: Load `v0.3.1_armC_ob_h1.set`; confirm INIT `obGate=ON obTf=H1 armH=2.00`.
4. Compare to `ob_free` (control) and M5 `ob_touch`; archive under `logs/`.
5. Slice with `--deposit 5000 --threshold 5000` (100% rule). Research only — not Mode S promote.
