# How Gold Rush AI v0.3 enters the market — full trace (`v0.3_armC_dynamic.set`)

Analysis of `gold_rush_AI_v0.3.mq5` + `sets/export_v0.3/v0.3_armC_dynamic.set`.
Backtest context: XAUUSD M5, deposit 50,000, 2026.01–03, hedging account (3-digit RoboForex feed: point = $0.001, pip = $0.01 — corroborated by trade-log magnitudes).

The EA is two engines stacked: the original decompiled **GRP grid engine** (obfuscated names, generates the raw signals) and the **GRAI v0.3 overlay** (SMC bias, risk, episode accounting) wrapped around it. Every single order — parent entries and pyramid layers — funnels through one choke point, `GRP_OrderSend()` (`gold_rush_AI_v0.3.mq5:1886`). The legacy engine decides *when to attempt* an entry; the GRAI stack decides *whether it actually goes*, at what size, and with what SL/TP.

Config in force from the set: `sg_1` (Buy&Sell Rotating), `Dist=20`, `Step=20`, `HowBar=100`, `InpUseBiasGate=true`, `InpUseSmc=true`, `InpUseRegimeGate=false`, `InpLLMEnabled=false`, `InpUsePctRisk=true`, `InpAdverseAveraging=false`, `MaxTrades=5`, `InpMaxLayers=5`, risk ladder 1→2%, DD kill 5%, Mon–Thu, hours 01–22.

---

## 1. OnTick, in execution order

### 1.1 Spread filter — `:2648`
`MarketInfo(MODE_SPREAD) > MaxSpread (200 points)` → `Sleep(60s)` and **return**. Nothing runs — not even exit management — until spread normalizes.

### 1.2 Episode close + ladder sync — `:2655-2662`
If an episode is active but the basket is flat (everything closed since last tick):
- `realized = equity_now − equity_at_open`
- `GRAI_EpisodeClose("flat", realized)` (`Episode.mqh:75-87`)
- `GRAI_RiskLadderOnClose(direction, bias_at_start, realized)` (`RiskEngine.mqh:75-95`):
  - `realized > 0` **and** direction matched bias at entry → `risk_pct += 0.5`, capped at 2.0 (`RISK_UP`)
  - `realized < 0` **and** direction fought the bias → reset to 1.0% (`wrong_bias_loss`)
  - aligned loss or scratch → unchanged

This is the only place the ladder moves (besides equity-kill reset), and it only moves between baskets — i.e., **the size of your *next* episode is set by how the *last* one ended.**

### 1.3 The per-tick kill switches — `:2663-2757`
`g_grai_entries_allowed = true`, then forced **false** by, in order:

1. **SMC bias is FLAT** (`:2668-2677`, logged `SKIP bias_flat` 1×/60s). `GRAI_BiasUpdate()` runs first (`:2665`), see §3.
2. **±30min CSV news window** (`:2681-2690`, `NEWS parent30_block`) — `grai_high_impact_us.csv` events, padded ±30 min (`NewsGate.mqh:15,73-84`). This flag blocks *everything*, parents and pyramids.
3. **Regime gate** (`:2700-2709`) — **off** in this set (`InpUseRegimeGate=false`). Had it been on: `GRAI_DetectRegime` (`:2696-2698`, inputs = EMA(5) slope, ATR14 vs ATR50-median, news/spike flags) returning UNKNOWN/ABNORMAL would block.
4. **LLM wait-bar** (`:2711-2754`) — dead: `InpLLMEnabled=false`, no bridge request is ever built.

Note what is *not* here: spike-bar and session are **not** entries_allowed flags — they're enforced later, per-order.

### 1.4 Pyramid attempt — `:2756`
If entries allowed and a basket is open → `GRAI_TryFavorablePyramid()` runs **before** the legacy signal blocks (§7).

### 1.5 Base lot arithmetic — `:2773-2826`
Autolot: `Lots(0.01)/BalanceInit(1000) × balance(50,000) = 0.50` → clipped to `MaximumInitLot = 0.25` → `Id_04728 = 0.25`, snapped to broker min/step. This is only the *requested* volume — with `InpUsePctRisk=true`, `GRP_OrderSend` recomputes it (§5). So the autolot chain is effectively decorative in this set.

### 1.6 Housekeeping — `:2827-2891`
Daily equity-loss accounting (`Id_04770`), open-order count, info panel (`func_1033`), then the two exit-side managers: `GRP_ManageRiskAndExits()` (`:2890` — the 5% equity-DD kill, §6.3) and `GRP_UpdateDynamicSL()` (`:2891` — news-widen / SL+ trailing, §6.2).

### 1.7 The ratchet lines — `:2892-2940`
Two horizontal chart objects, re-read into `Id_04798` (LineBuy) / `Id_04790` (LineSell) every tick (`:2882-2889`):

- **LineBuy** is re-anchored to `Ask + Dist×pipfactor` **only downward** (`Ask+20pips < LineBuy` → move down).
- **LineSell** is re-anchored to `Bid − Dist×pipfactor` **only upward**.

`pipfactor` = 10×point on 3/5-digit symbols (`:2318-2330`). On the 3-digit gold feed: **Dist=20 → the lines sit $0.20 away** from price and ratchet toward it. The band never widens — in a trend it degenerates into a tight trailing trigger on the pullback side, and on a reversal the far line is wherever price last left it.

### 1.8 Legacy news flag `Ib_046F0` — `:3043-3105`
Live-only: scans the downloaded calendar's chart objects for the next USD event (`SetSymbol=3` = symbol currencies + `"USD,"`, `SetPowerNews=2` = 2+ stars), sets `Ib_046F0=false` within ±`BeforeNewsTime`(2h) of it. **In the Strategy Tester the download block is skipped** (`func_1016` returns early, `:5592-5616`), the next-news timestamps stay 0, and the fallback branch at `:3100-3105` evaluates to `Ib_046F0 = true` always. News duty in the tester falls entirely to the CSV gate (§1.3) and spike bar (§4.4).

### 1.9 Momentum-candle flags — `:3106-3147`
With `SetAverageBar=true, HowBar=100, ExpBar=1`:
- `avgRange` = mean of (high−low) of bars 1..100, in points, ×1.0
- `Lb_FFFAE` (bearish momentum) = **forming bar's body** `Open(0)−Close(0)` **> avgRange**
- `Lb_FFFAF` (bullish momentum) = `Close(0)−Open(0)` > avgRange

So the current, still-forming M5 bar must already have a body bigger than the *average full range* of the last 100 bars. On 3-digit gold that's roughly a bar whose body exceeds ~$1.5–2 — a genuine impulse candle, evaluated tick-by-tick intrabar.

### 1.10 Calendar gates — `:3148-3236`
- **Days**: Mon–Thu allowed, Fri/Sat/Sun blocked (set values).
- **Strategy dispatch** (`:3183-3199`): `SetStrategies=1` → `Ib_047C1=true`; the sg_2 (candlestick) and sg_3 (balance-hedging) blocks later in OnTick are compiled but never reachable.
- **EMA stack** (`:3200-3235`): `SetEMA=false` → all four filter flags `Ib_047C4..C7 = true` (pass-through).
- **Hours** (`:3236`): server hour `>= 01 && <= 22`.
- MM+/MM− daily targets (`:3238` guard): both false → guard passes unconditionally.

---

## 2. The signal itself — sg_1 "Buy & Sell Rotating" (`:3238-3485`)

Both branches require **flat**: the loop at `:3256-3268` / `:3378-3390` counts open orders with this symbol+magic; `Gi_00035` stays −1 so it counts *all* of them — zero open positions required. (The historical flip-flop — "last closed order type must differ" — is disabled with `if(true)` at `:3255` and `:3377`, so same-side re-entry immediately after a close is allowed.)

**SELL** (`:3240`, sends at `:3347`):
```
Open(0) > Close(0)          // forming bar currently bearish
&& Ask <= Id_04790          // price broke DOWN through LineSell (Bid−$0.20 ratchet)
&& Gi_00036 == 0            // flat
&& Ib_047C4 && Ib_047C5     // EMA filters: pass (SetEMA=false)
&& Ib_046F0                 // legacy news clear: always true in Tester
&& Lb_FFFAE                 // bearish body > 100-bar avg range
```
→ `GRP_OrderSend(OP_SELL, Id_04728, Bid, sl=0, tp=0, comment+"-BUY&SELL-N")`, then LineBuy is re-anchored fresh at `Ask+$0.20`.

**BUY** (`:3363`, sends at `:3469`): exact mirror — bullish forming bar, `Bid >= LineBuy`, flat, `Lb_FFFAF` → market buy at Ask, comment `-BUY&SELL-N`, LineSell re-anchored at `Bid−$0.20`.

The STOPS_LEVEL sanity check in between (`:3269-3347`) uses dummy distances of 50000 pips (`:2230-2231, :2331-2332`) so it always passes — vestigial. The margin check (`AccountFreeMarginCheck`) is real.

In plain terms: **a fat impulse candle in the direction of the break, crossing a $0.20 trailing band** — a momentum-breakout trigger, not a mean-reversion one. Because it requires flat, this block fires at most one order per basket: the *parent*.

---

## 3. The directional brain — SMC-Lana bias (`Include/GRAI/SmcLana.mqh`, `Bias.mqh`)

`GRAI_BiasUpdate()` (`Bias.mqh:40-78`) is called at init (`:2104`) and every tick, but the underlying structure only advances **once per closed M5 bar** (`SmcLana.mqh:955-996`; at init a warmup replays up to `InpSmcLookback=500` closed bars, minimum `pivot_len*2+10 = 20` bars).

Mechanics (1:1 port of the SMC-Lana Pine script):

1. **Swings**: pivot highs/lows with `left = right = InpSmcPivotLen = 5` — a swing confirms 5 bars after the extreme (`:197-226`).
2. **Structure state machine** (`GRAI_SmcStructureStep`, `:566-876`): tracks running up/down extremes. A *close* beyond the pending CHoCH/BOS level = **CHoCH/BOS** (flips or continues `trend` ±1); a *wick* through with close back inside = **sweep** (`CHoCH_SWEEP_*` / `BOS_SWEEP_*` — flag only, no trend change).
3. **Order blocks**: every BOS/CHoCH spawns an OB from the prior extreme bar (`:322-348`); only the newest 5 kept; an OB is *mitigated* when a candle body trades through it (close-mode; `:370-440`).
4. **Ready** = `start>=2 && trend != 0` (`:880`) — i.e., after the first confirmed CHoCH.

Mapping to bias: `trend +1 → LONG`, `−1 → SHORT`, `0/not-ready → FLAT` (`Bias.mqh:48-58`). Optional D1-SMA200 + H4-EMA200 AND-confirm (`InpUseMaBias`) is **off**.

`GRAI_BiasAllowsCmd(cmd)` (`Bias.mqh:80-92`) = `GRAI_SmcAllowsCmd(cmd)` **then** bias/cmd match:
- `GRAI_SmcAllowsCmd` (`SmcLana.mqh:1027-1058`) fails if: not ready; trend ≠ direction; swing-mapping (HH/HL vs LL/LH, `:487-515`) disagrees with structure trend; (soft sweep requirement — off; liq-print filter — off).
- Then: LONG → BUY only, SHORT → SELL only, FLAT → nothing.

Two consequences worth internalizing:
- **The first CHoCH after a trend flip gates everything**: until structure confirms, bias = FLAT, entries_allowed = false — the bot stands aside, both directions.
- **The OB filter (`InpSmcObFilter=true`) is dead code as wired**: `GRAI_SmcObBlocksCmd` (`:1009-1025`) blocks BUY only if `unmitigated bear OB && trend != 1` — but it's only reached after a check that already required `trend == 1`. The condition can never be true. Despite the set having it ON, no order is ever blocked by an order block in this build.

---

## 4. The choke point — `GRP_OrderSend()` (`:1886-2064`), gate by gate

Every order arrives here with `sl=0, tp=0` — stops are computed inside.

1. **`g_grai_entries_allowed`** (`:1890`) — false (bias FLAT / ±30min news / regime / LLM) → `RISK_FAIL regime_or_policy`, dead.
2. **Equity-kill day-block** (`:1895`) — after a 5% DD kill, all entries blocked until the next daily bar opens (`GRP_EquityKillDay` check at `:1636-1637`).
3. **Session gate** (`:1905`, `GRP_IsMarketTradeAllowed :1548-1602`) — terminal trade-allowed, EA trade-allowed, symbol not DISABLED/CLOSEONLY, and current time inside an actual symbol trade session (handles overnight-wrap sessions; no sessions defined = pass).
4. **News union** (`:1916-1930`) — evaluated **only when flat** (parent entries): union of {spike bar, parent30 blackout}. Spike bar = current bar range > 2.0× the mean range of the last 20 bars (`GRP_IsSpikeBar :1662-1675`, `NewsSL_Mult=2.0`). Blocks: `NEWS parent30_block` / `NEWS spike_block`. Since the ±30min CSV window already killed `entries_allowed` in step 1, the *net new* effect here is: **spike bars block parent entries, but not pyramids** (basket > 0 skips this whole check).
5. **GLM** (`:1932`, `LlmBridge.mqh:69-98`) — `InpLLMEnabled=false` → returns true unconditionally, no request. (`InpDeterministicFallback=true` only matters if LLM were on: bad/missing advice would pass instead of blocking.)
6. **Bias gate** (`:1935`) — §3. Wrong direction or FLAT → `SKIP bias_block`.
7. **Side filter** (`:1940-1949`) — `GRAI_SIDE_BOTH`, inert.
8. **Layer rules** (`:1951-1977`) — only when a basket is already open:
   - `basket >= 5` (`InpMaxLayers` or `MaxTrades`, both 5) → `LAYER_REJECT max_layers`
   - `InpAdverseAveraging=false`: any order **without** `-PYRAMID-` in its comment → `LAYER_REJECT adverse_blocked use_pyramid` — this is where the legacy grid's step-add/martingale requests go to die; and a `-PYRAMID-` order must additionally pass `GRAI_IsFavorableAdd` → `not_favorable` otherwise.
   - `GRAI_RiskPassNewLayer(basket, 0.0, equity, remaining)` (`RiskEngine.mqh:138-164`) — called with `layer_risk_cash = 0.0`, so of its four checks only `max_layers`/`max_trades` can ever fire. **The 3% episode budget is NOT enforced pre-send.**
9. **Sizing** (`:1980-1988`) — §5.
10. **Basket volume cap** (`:1990`) — `MaxBasketVolume=0` = off.
11. **SL/TP attach** (`:1996-2034`) — §6.1.
12. **`OrderSend` market order** (`:2036`, slippage 10). On success, if basket ≤ 1 → `GRAI_EpisodeOpenEx(mom=A, cmd, UNKNOWN, bias, equity, equity×3%)` + `OPEN ... role=PARENT_ENTRY` (`:2040-2052`); else → `GRAI_EpisodeAddLayer(equity × risk_pct)` + `OPEN ... role=LAYER_CONTINUATION` (`:2053-2059`). **Note the order: `EpisodeAddLayer` runs after the fill** — see §5.3.

---

## 5. Sizing, worked through

### 5.1 The formula
`GRAI_LotsFromRisk` (`RiskEngine.mqh:119-136`):
```
cash          = equity × risk_pct / 100        // 1.0–2.0% via ladder
loss_per_lot  = (sl_distance / tick_size) × tick_value
lots          = floor(cash / loss_per_lot, vol_step)   // 0 if < vol_min
```
then capped at `MaximumInitLot = 0.25` (`:1840-1841`).

`sl_distance = GRP_RiskDistance()` (`:1503-1516`) = **max( ATR-proxy × 1.5, 2000 points )**, where the "ATR" is the simple mean of high−low over bars 1..14 on M5 (`GRP_AvgBarRange :1492`), not Wilder's ATR.

### 5.2 Concrete numbers (3-digit gold feed)
- Floor: 2000 × $0.001 = **$2.00** — on typical M5 gold (avg bar $0.8–1.5 → ATR×1.5 ≈ $1.2–2.2) the floor usually wins, so SL ≈ $2, TP = 2.5R ≈ $5.
- 1% of 50,000 = $500 cash risk; loss/lot at $2 SL ≈ $200 → raw lots ≈ 2.5 → **clipped to 0.25**.
- **The 0.25 lot cap binds almost always in this backtest.** Effective per-layer planned risk ≈ 0.25 lots × $2 × 100 oz = **$50 ≈ 0.1% of equity**, and the ladder (1→2%) never manifests in size — it's clipped by the same 0.25 cap. (Cross-check: the hostile review's avg TP-exit +163 units and avg SL-exit −25 units fit $5/$2 targets at 0.25 lots, not the $50/$20 you'd get on a 2-digit feed — confirming the 3-digit reading.)

### 5.3 Episode budget — accounting, not enforcement
Budget = equity × 3% = $1,500 at open (`:2040`). Each *fill* consumes `equity × risk_pct` = $500 in `GRAI_EpisodeAddLayer` (`Episode.mqh:56-73`). Parent + 2 pyramids exhaust it; pyramids 3 and 4 log `LAYER_REJECT episode=…` — **after their `OrderSend` already succeeded** (`AddLayer` is called post-fill at `:2055`, and the pre-send `RiskPassNewLayer` got `0.0`). So in this build the true hard caps are `InpMaxLayers`/`MaxTrades = 5`; the 3% "ceiling" is bookkeeping plus log noise. This is exactly why the backtest shows 42 baskets averaging **5.10 layers** — every basket runs to the count cap, budget notwithstanding.

---

## 6. What's attached at send, and what happens right after

### 6.1 SL/TP (`:1996-2034`)
`risk = GRP_RiskDistance()` (≈$2): SL = entry ∓ risk, TP = entry ± `TP_RR(2.5)` × risk, both clamped to `SYMBOL_TRADE_STOPS_LEVEL`. (Planned R:R median 2.47 in the backtest — matches.)

### 6.2 `GRP_UpdateDynamicSL` (`:1677-1787`), every tick, per order
- **News/spike widen**: if legacy-news window or spike bar → SL pushed *away* to `open ± risk × NewsSL_Mult(2.0)` (widen-only). Note this uses the *current* risk distance, so a widened SL is ~$4.
- **Else SL+ trail** (`UseSLPlus=true`): once profit ≥ 1R (≈$2), SL jumps to `max(entry + 10pts, Bid − 1R)` for buys — breakeven-lock vs 1R-trail, whichever is higher; only tightens. This is why most "sl"-tagged exits in the log are small: they're trailed stops near BE, not the initial $2 stop.

### 6.3 The kill switch — `GRP_ManageRiskAndExits` (`:1633-1660`)
Equity peak tracked continuously; drawdown from peak ≥ 5% → close the whole basket (losers first pass, winners second, `GRP_CloseAllBasket :1604`), `GRP_EntriesBlocked = true` for the rest of the day, peak reset, ladder reset to 1% (`GRAI_RiskOnEquityKill`). Legacy `MinProfit (0.2% of balance) / Dist` remain the flat-basket levers on the legacy side.

---

## 7. The add-on path — `GRAI_TryFavorablePyramid` (`:1845-1884`)

Runs every allowed tick when a basket exists, before the legacy blocks:

- Guards: `InpAdverseAveraging=false` ✓, entries_allowed (so bias flip to FLAT or a ±30min news window **does** stop pyramids), 1 ≤ basket < 5.
- Direction = the side of the open basket.
- **Trigger** (`GRAI_IsFavorableAdd :1814-1825`): last open price = fill with the highest ticket on that side; BUY adds when `Bid ≥ last + Step×_Point`, SELL when `Ask ≤ last − Step×_Point`.
  - ⚠️ **Asymmetry**: this uses raw `_Point` ($0.001), not the pip factor the legacy engine uses everywhere else. `Step=20` → **$0.02** per layer, vs the $0.20 the ratchet lines use. On this feed pyramids qualify every 2 cents of favorable movement — which is why every basket saturates at 5 layers within minutes.
- Then straight into `GRP_OrderSend` with comment `-PYRAMID-` — passing gates 1–3, 5–8 (bias must *still* match at each add), pct sizing again, fresh SL/TP. **Not applied to pyramids**: hour window, day-of-week, momentum candle, legacy news flag, spike bar (union check requires basket==0). Only bias, session, kill-switches, caps.

---

## 8. One entry, end to end (worked example)

Tuesday 07:14, no positions, spread 90. Last 100 M5 bars averaged $1.60 range. SMC structure flipped bullish two bars ago (CHoCH up confirmed) → bias LONG, entries allowed, no CSV event within ±30min. A strong buy program pushes a forming candle to +$1.80 body and Bid crosses the LineBuy ratchet (Ask_last + $0.20):

1. sg_1 BUY branch fires: bullish bar ✓, `Bid ≥ LineBuy` ✓, flat ✓, momentum ✓, hour 7 ✓, Tuesday ✓, `Ib_046F0` ✓ (tester).
2. `GRP_OrderSend`: entries_allowed ✓, no kill-day ✓, session ✓, no spike/no news (flat basket → union checked) ✓, GLM no-op ✓, bias LONG vs BUY ✓, side BOTH ✓ (basket 0 → layer rules skipped), sizing: $500 target → 0.25 lots (cap), SL $2 below, TP $5 above.
3. Fill → episode #N opens: mom A, dir BUY, bias LONG, budget $1,500, layer 1.
4. Price grinds +$0.02 within seconds-to-minutes → pyramid 1 (bias re-checked) → 0.25 lots, own SL/TP; `AddLayer` consumes $500 → $1,000 left. Repeat at +$0.04, +$0.06 (budget hits $0; the 4th and 5th adds log `LAYER_REJECT` *post-fill* but the positions are live) → 5 × 0.25 lots long.
5. Basket rides: SL+ trails each order after +$2; TP $5 or trailed stop takes layers out one by one; flat → `EpisodeClose`, realized PnL → ladder +0.5% if positive (irrelevant to size while the 0.25 cap binds) or reset if a wrong-bias loss; equity peak guards the 5% kill; next parent can only fire when flat again.

---

## 9. Inert / dead in this exact build (worth knowing)

| Thing | Status |
|---|---|
| `InpSmcObFilter` (unmitigated OB block) | **Dead code** — gated behind a trend check that already passed (`SmcLana.mqh:1031` vs `:1009-1025`) |
| 3% episode ceiling | Post-fill accounting only; real cap = 5 layers (`:1975` passes `0.0`) |
| Risk ladder 1→2% | Computes, logs, but size pinned by 0.25-lot cap at this equity/SL |
| Regime gate, LLM/bridge, deterministic fallback | Off in set (`false`) |
| EMA stack, MA-bias AND, sg_2, sg_3, flip-flop, STOPS dummy check, autolot figure | Off/disabled/vestigial for this set |
| Legacy news calendar (`Ib_046F0`) | Live-only; always "clear" in Tester |

**Net characterization**: a *with-trend momentum-breakout* system — SMC structure on M5 picks the side and vetoes everything until a CHoCH confirms; a >100-bar-average impulse candle through a $0.20 ratchet line pulls the trigger at market; 1%-risk-nominal (0.25-lot-real) sizing with a ~$2 ATR/floor SL and 2.5R TP; layers pile on every $0.02 favorable (cap 5); exits via trailed stops, TP, or the 5% equity-DD kill; the ladder and episode budget exist in the plumbing but are the parts that don't actually bind in this configuration.

---
*Sources: `gold_rush_AI_v0.3.mq5` (line refs), `Include/GRAI/{SmcLana,Bias,RiskEngine,Episode,NewsGate,LlmBridge}.mqh`, `sets/export_v0.3/v0.3_armC_dynamic.set`, cross-checked against `logs/hostile_review_trades_v0.3_armC_dynamic.md`. Research only — no profit guarantee.*
