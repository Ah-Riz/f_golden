# SMC_Lana MT5 indicator

Visual port of [`pine/SMC_Lana.pine`](../pine/SMC_Lana.pine) → chart overlay.

**Not** a dual-promote / Mode S / walk-forward gate. Chart tooling only — no profit claim.

## Layout

| Path | Role |
|---|---|
| `Indicators/SMC_Lana.mq5` | Overlay entry + Pine-mirrored inputs |
| `Include/SMC_Lana/SmcEngine.mqh` | Structure BOS/CHoCH/sweeps, volumetric OB, mapping, posLIQ, sweep area |
| `Include/SMC_Lana/SmcObjects.mqh` | Chart objects (`SMCLana_` prefix) |
| `Include/SMC_Lana/SmcFvg.mqh` | Fair value gaps + raid / mitigate |
| `Include/SMC_Lana/SmcSfp.mqh` | Swing failure pattern |
| `Include/SMC_Lana/SmcMtf.mqh` | Prior D/W/M/Q/Y highs-lows (completed HTF only) |
| `Include/SMC_Lana/SmcLiq.mqh` | Premium/discount + strong/weak HL |
| `Include/SMC_Lana/SmcAlert.mqh` | Alert matrix |

EA trading gate remains [`Include/GRAI/SmcLana.mqh`](../Include/GRAI/SmcLana.mqh) — unchanged.

## Deploy / compile

```bash
bash scripts/deploy_mt5.sh --compile --indicator
```

Copies:

- `MQL5/Indicators/SMC_Lana.mq5`
- `MQL5/Include/SMC_Lana/*.mqh`

In MT5: **Insert → Indicators → Custom → SMC_Lana**.

## Visual parity checklist (vs TradingView)

Same symbol/TF (e.g. XAUUSD M5), defaults where possible:

1. Swing BOS / CHoCH labels and line styles (solid after confirm, dotted sweep `x`)
2. Last N volumetric OBs + mid-line; breaker style when enabled
3. Mapping polyline-ish segments when Mapping ON
4. FVG boxes when FVG ON
5. SFP markers when SFP ON
6. MTF PDH/PDL etc. when each TF toggle ON
7. Premium/Discount + Strong/Weak HL when those toggles ON
8. Status label top-left (`SMC-Lana BULL|BEAR …`)

### Known intentional diffs

- Pine MTF uses `lookahead_on`; MT5 uses **completed** higher-TF bars only.
- Q/Y levels are synthetic from D1/MN1 calendar windows.
- MT5 object model ≠ Pine boxes/polylines — counts capped; not pixel-identical.
- Candle coloring buffer is `DRAW_NONE` (trend value only); MT5 cannot recolor chart candles like `barcolor()`.
- Internal structure toggle is reserved (swing path only in v1).

## Alerts

Enable flags under **ANY ALERT**. Direction: `0` Bullish, `1` Bearish, `2` Both. Uses MT5 `Alert()`.

---

## SMC_Lana_OB (SNR only)

Lean fork: **order blocks only** as support/resistance. No BOS/CHoCH labels, FVG, SFP, MTF, bubbles, or status clutter.

| Path | Role |
|---|---|
| `Indicators/SMC_Lana_OB.mq5` | Overlay + minimal inputs |
| `Include/SMC_Lana_OB/SmcObEngine.mqh` | Structure → OB birth; Touch mitigation; OB draw only |
| `Include/SMC_Lana_OB/SmcObObjects.mqh` | `SMCLanaOB_` rectangles |

### Defaults (M5-friendly)

- Mitigation **`0 = Touch`**: wick or body enters zone → **remove** (no leftover extending box)
- Show last **3** OBs per side; midline OFF; overlap hide ON

### Deploy

```bash
bash scripts/deploy_mt5.sh --compile --indicator
```

Also produces `MQL5/Indicators/SMC_Lana_OB.ex5`. Load **SMC_Lana_OB** (remove full `SMC_Lana` if both are attached).

### Acceptance checklist

- [ ] Chart shows only bull/bear OB rectangles (no BOS/CHoCH/SFP/FVG text)
- [ ] Touch into an OB removes it on the next closed bar
- [ ] Removed OB does not leave an extending rectangle
- [ ] At most 3 bull + 3 bear OBs with default `Show last N`
- [ ] Compile: `SMC_Lana_OB.ex5` with 0 errors; Experts shows `[SMC-Lana-OB] INIT …`
