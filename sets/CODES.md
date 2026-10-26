# Gold Rush AI set codes

Experts: `[stem] INIT set=stem …` — filter by stem.

## v0.4 (lifecycle candidate)

| CODE | set file | Notes |
|---|---|---|
| v0.4_armC | `v0.4_armC_dynamic.set` | Mode B delayed SL+ (actR=1.5); ATR_FLOOR; entry close confirm |
| v0.4_armC_modeA | `v0.4_armC_modeA.set` | Mode A structural fixed stop |
| v0.4_armC_modeC | `v0.4_armC_modeC.set` | Mode C structure trail |
| v0.4_armC_l1 | `v0.4_armC_l1.set` | max layers 1 |
| v0.4_armC_l3 | `v0.4_armC_l3.set` | max layers 3 |
| v0.4_armC_flattight | `v0.4_armC_flattight.set` | MinProfit=0.01 |
| v0.4_armC_regime | `v0.4_armC_regime.set` | regime gate ON |
| v0.4_armC_l13 | `v0.4_armC_l13.set` | diagnostic MaxLayers/MaxTrades=13; episode risk 15% (research) |
| v0.4_armC_holdA | `v0.4_armC_holdA_nodist.set` | Exp A: Mode B + `InpAllowDistFlat=false` (vs dynamic) |

EA: `gold_rush_AI_v0.4` · schema `grai.glm.v0.4`  
Preserve v0.3 baseline; compare before promote. Dual-gate still required.  
Exit holding audit: `docs/EXIT_HOLDING_AUDIT.md`.

## v0.3.4 final (pre-AI SMC usage ablation)

| CODE | set file | Notes |
|---|---|---|
| v0.3.4_armC_final0_ctrl | `v0.3.4_armC_final0_ctrl.set` | = soft0; SmcLana ON; MTF OFF |
| v0.3.4_armC_final1_soft3 | `v0.3.4_armC_final1_soft3.set` | = soft3 pin; H4 + loose M5 |
| v0.3.4_armC_final2_sweep | `v0.3.4_armC_final2_sweep.set` | soft3 + `InpSmcRequireSweep` |
| v0.3.4_armC_final3_obarm | `v0.3.4_armC_final3_obarm.set` | soft3 + `InpSmcObEntryGate` |
| v0.3.4_armC_final4_ma | `v0.3.4_armC_final4_ma.set` | soft3 + `InpUseMaBias` |

EA: `gold_rush_AI_v0.3.4` · set-only · **SMC internals frozen**.  
Range **2025.07.01–2026.03.01** · deposit **5000** · `--threshold 5000`.  
Freeze doc: `docs/PRE_AI_CANDIDATE.md`.

## v0.3.4 (soft hyb3 ladder)

| CODE | set file | Notes |
|---|---|---|
| v0.3.4_armC_soft0_ctrl | `v0.3.4_armC_soft0_ctrl.set` | SmcLana ON; MTF OFF; re-baseline |
| v0.3.4_armC_soft1_h4 | `v0.3.4_armC_soft1_h4.set` | SmcLana + H4 veto only |
| v0.3.4_armC_soft2_h4m5 | `v0.3.4_armC_soft2_h4m5.set` | hyb3 clone; H4 + strict M5 |
| v0.3.4_armC_soft3_h4loose | `v0.3.4_armC_soft3_h4loose.set` | H4 + loose M5 (no EMA band) |
| v0.3.4_armC_soft4_h4reg | `v0.3.4_armC_soft4_h4reg.set` | H4 veto + regime gate |

EA: `gold_rush_AI_v0.3.4` · schema `grai.glm.v0.3.4`  
OB arm OFF; `h4bias=OFF`. Research deposit **5000** · `--threshold 5000`.  
Entry rule: `docs/ENTRY_MTF_v0.3.4.md`.

## v0.3.3 (SmcLana bias + MTF gates)

| CODE | set file | Notes |
|---|---|---|
| v0.3.3_armC_hyb0_ctrl | `v0.3.3_armC_hyb0_ctrl.set` | SmcLana ON; MTF OFF; h4bias=OFF |
| v0.3.3_armC_hyb1_m5 | `v0.3.3_armC_hyb1_m5.set` | SmcLana + M5 gate only |
| v0.3.3_armC_hyb2_pb | `v0.3.3_armC_hyb2_pb.set` | SmcLana + M15 + M5 |
| v0.3.3_armC_hyb3_h4and | `v0.3.3_armC_hyb3_h4and.set` | SmcLana ∩ H4 veto + M5; no H4 overwrite |
| v0.3.3_armC_hyb4_softfull | `v0.3.3_armC_hyb4_softfull.set` | Full MTF as gates only; h4bias=OFF |

EA: `gold_rush_AI_v0.3.3` · schema `grai.glm.v0.3.3`  
OB arm OFF. Research deposit **5000** · `--threshold 5000`.  
Entry rule: `docs/ENTRY_MTF_v0.3.3.md`.

## v0.3.2 (MTF phrase stack)

| CODE | set file | Notes |
|---|---|---|
| v0.3.2_armC_mtf0_ctrl | `v0.3.2_armC_mtf0_ctrl.set` | Arm C control ≈ ob_free; SmcLana ON; MTF OFF |
| v0.3.2_armC_mtf1_h4 | `v0.3.2_armC_mtf1_h4.set` | H4 direction only |
| v0.3.2_armC_mtf2_h4h1 | `v0.3.2_armC_mtf2_h4h1.set` | H4 + H1 trend |
| v0.3.2_armC_mtf3_pb | `v0.3.2_armC_mtf3_pb.set` | + M15 pullback |
| v0.3.2_armC_mtf4_full | `v0.3.2_armC_mtf4_full.set` | Full H4→H1→M15→M5 |

EA: `gold_rush_AI_v0.3.2` · schema `grai.glm.v0.3.2`  
OB arm OFF. Research deposit **5000** · `--threshold 5000`.  
Entry rule: `docs/ENTRY_MTF_v0.3.2.md`.

## v0.3.1 (SMC_Lana_OB entry gate)

| CODE | set file | Notes |
|---|---|---|
| v0.3.1_armC_ob_free | `v0.3.1_armC_ob_free.set` | Arm C; **SMC-Lana bias**; OB arm gate **OFF** (≈ v0.3 control) |
| v0.3.1_armC_ob_touch | `v0.3.1_armC_ob_touch.set` | Arm C; SMC-Lana bias + bull-OB **touch arms BUY 2h** (chart TF OB) |
| v0.3.1_armC_ob_arm8 | `v0.3.1_armC_ob_arm8.set` | Same as touch; **`InpObArmHours=8`** only |
| v0.3.1_armC_ob_h1 | `v0.3.1_armC_ob_h1.set` | Gate ON; **`InpObTimeframe=H1`**; M5 Ask/bar vs H1 bull zones; arm 2h |

EA: `gold_rush_AI_v0.3.1` · schema `grai.glm.v0.3.1`  
Bias = SMC-Lana (v0.3); arm = SMC_Lana_OB. Research deposit **5000** · `--threshold 5000`.  
Entry rule: `docs/ENTRY_SMC_OB_v0.3.1.md`.

## v0.3 (frozen baseline)

| CODE | set file | Arm | Notes |
|---|---|---|---|
| v0.3_armA | `v0.3_armA_single.set` | A | Single; bias + DD5% + ladder; pctRisk |
| v0.3_armB | `v0.3_armB_fixed_layers.set` | B | Adverse ON (research) |
| v0.3_armC | `v0.3_armC_dynamic.set` | C | pctRisk + favorable pyramid |
| v0.3_armD | `v0.3_armD_regime.set` | D | C + regime; ablation baseline |
| v0.3_armE | `v0.3_armE_glm.set` | E | D + GLM AND-gate |
| v0.3_test_smc | `v0.3_test_smc.set` | test | SMC ON · MA OFF — primary smoke |
| v0.3_test_smc_off | `v0.3_test_smc_off.set` | test | SMC OFF · MA ON — control |
| v0.3_test_smc_long | `v0.3_test_smc_long.set` | test | Arm C + SMC ON · **LongOnly** |
| v0.3_test_smc_short | `v0.3_test_smc_short.set` | test | Arm C + SMC ON · ShortOnly |

EA: `gold_rush_AI_v0.3` · schema `grai.glm.v0.3`  
Pins: SMC-Lana gate (frozen) · equity DD **5%** · risk ladder **1 → 1.5 → 2%** · optional MA AND · flip-flop OFF

## v0.2 (frozen)

| CODE | set file | Arm | Notes |
|---|---|---|---|
| v0.2_armA | `v0.2_armA_single.set` | A | Single; LLM OFF; AutoLot |
| v0.2_armB | `v0.2_armB_fixed_layers.set` | B | Adverse ON (research) |
| v0.2_armC | `v0.2_armC_dynamic.set` | C | pctRisk + favorable pyramid |
| v0.2_armD | `v0.2_armD_regime.set` | D | C + regime; ablation baseline |
| v0.2_armE | `v0.2_armE_glm.set` | E | D + GLM AND-gate |

EA: `gold_rush_AI_v0.2` · schema `grai.glm.v0.2`

## v0.1 (frozen baseline)

| CODE | set file | Arm |
|---|---|---|
| v0.1_armA … E | `v0.1_arm*.set` | A–E |

## Screen S pin

Deposit **50000** cent · M5 · `2026.01.01–2026.03.01` · ≥+5000/mo both months.
