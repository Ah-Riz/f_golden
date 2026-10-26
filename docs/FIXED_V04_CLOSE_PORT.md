# Fixed_001 — v0.4 close port

Educational risk framing only. No live deploy. No profit claims. Dual promote (Mode S + WF/holdout) is out of scope for this port.

## What changed

New EA: [`gold_rush_pro_Fixed_001.mq5`](../gold_rush_pro_Fixed_001.mq5) — copy of frozen [`gold_rush_pro_Fixed.mq5`](../gold_rush_pro_Fixed.mq5) with v0.4 Mode B protective-stop / Dist-gate close style only.

Slim helper: [`Include/GRAI/ManageClose.mqh`](../Include/GRAI/ManageClose.mqh) — manage-mode enum + `Fixed_TightenOnlyOk`. Does **not** pull full `Lifecycle.mqh` / SMC.

| Piece | Frozen Fixed | Fixed_001 (default) |
|---|---|---|
| SL+ activate | profit ≥ 1.0 × R | `InpSLPlusActivateR` = **1.5** |
| Trail distance | 1.0 × R | `InpTrailR` = **1.0** |
| BE lock | `SLPlus_LockPoints` | same |
| Tighten-only | informal curSL compare | `Fixed_TightenOnlyOk` |
| News widen | news/spike ungated | `InpAllowNewsWiden` = **false** |
| Manage mode | n/a | `InpManageMode` = **B** (A = no trail) |
| Dist basket flat | always if line+MinProfit | gated by `InpAllowDistFlat` (default **true**) |
| Equity DD kill | unchanged | unchanged (+ `FLAT reason=equity_kill` log) |
| Broker SL/TP | unchanged | unchanged |

Exit precedence (INIT + header comments):

1. Broker hard SL/TP  
2. Equity DD kill  
3. Protective SL modify (Mode B delayed SL+)  
4. Dist/MinProfit flat only if `InpAllowDistFlat` allows  

## What did not change

- Frozen `gold_rush_pro_Fixed.mq5` (do not edit in place)
- Entry / grid / Step / Layer_Multiplier / Dist HLine placement
- News filter entry block, session gates, MM± day closes
- Hard SL/TP at send, equity kill math
- No GRAI SMC bias, LLM, episode risk, thesis close, partials, Chandelier

## Mode C / D gap

Fixed has no confirmed pivot / SMC stacks. Enum values C and D are reserved for set parity; both use the same Mode B price trail. Real structure trail is **not** implemented here — see v0.4 + `Lifecycle.mqh` if needed later.

## Sets

| Set | Dist flat | Notes |
|---|---|---|
| `sets/Fixed_001_modeB_default.set` | ON | Fixed legacy parity + delayed activate |
| `sets/Fixed_001_modeB_nodist.set` | OFF | Dist-off A/B compare; expect `dist_tp_skipped` |

Load the `.set` — do not hand-edit knobs for scored runs. `InpLogTag` / `comment` = set stem.

## Deploy / compile

```bash
bash scripts/deploy_mt5.sh --compile --ea gold_rush_pro_Fixed_001.mq5
```

Copies EA + `sets/Fixed_001_*.set` into Wine MT5 Presets. User must recompile after any further `.mq5` edit before Tester.

## Verify after compile

1. Strategy Tester → Inputs must list:
   - `InpManageMode`
   - `InpSLPlusActivateR`
   - `InpTrailR`
   - `InpAllowDistFlat`
   - `InpAllowNewsWiden`
2. Experts INIT line: `manage=… actR=… trailR=… distFlat=… newsWiden=…`
3. Refuse to treat a run as valid if report Inputs omit `InpAllowDistFlat` / `InpSLPlusActivateR`.

## Tester compare protocol (user)

1. **BASE:** frozen Fixed, same symbol / TF / range / deposit.  
2. **NEW:** Fixed_001 + `Fixed_001_modeB_default.set`.  
3. Optional: Fixed_001 + `Fixed_001_modeB_nodist.set`.  

Report: net, profit factor, max DD, exit mix (tp / sl / other), hold time. MFE/MAE only with bar data — never fabricate. Success ≠ longer holds alone.

If using salary/research slicer: identical `--deposit` / `--threshold` (100% rule). Research digests ≠ Mode S promote.

## Acceptance checklist

- [ ] Frozen Fixed untouched  
- [ ] Inputs show new params after compile  
- [ ] Mode B: SL+ idle until profit ≥ actR × R  
- [ ] After activate: trail `InpTrailR` × R; BE lock; no loosen without news-widen ON  
- [ ] Equity kill still closes basket when enabled and breached  
- [ ] Dist OFF + Mode B: skip + `dist_tp_skipped` log  
- [ ] No entry rewrite; no live / promote claims  
