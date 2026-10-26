# v0.4 validation plan and status

## Status

| Item | Status |
|---|---|
| v0.3 baseline preserved | Yes — EA + `v0.3_armC_dynamic.set` untouched |
| Forensics on baseline | Done — `logs/forensics_v0.3_armC_dynamic.csv` |
| v0.4 EA + sets | Done — compile `.ex5` required before Tester |
| Strategy Tester comparison | **Pending operator** — MT5 Tester not run in this agent session |
| Mode S / promote | **Refuse** until slicer digest + WF/holdout both pass |

## Operator run matrix

Same symbol, M5, costs, window. Research book: deposit **5000**, then:

```bash
python3 logs/auto_slice_on_done.py
# or per report:
python3 logs/salary_month_slice.py <report.html> --deposit 5000 --threshold 5000 \
  --set <stem>.set --csv logs/salary_digest_<stem>.csv
```

| Run | EA | Set |
|---|---|---|
| B0 | v0.3 | `v0.3_armC_dynamic` |
| C0 | v0.4 | `v0.4_armC_dynamic` |
| C-A / C-C | v0.4 | `_modeA` / `_modeC` |
| C-L1 / C-L3 | v0.4 | `_l1` / `_l3` |
| C-FLAT | v0.4 | `_flattight` |
| C-REG | v0.4 | `_regime` |

After each v0.4 run, re-run forensics on the new trades CSV and compare early_stop %, exit mix, basket WR, Jan vs Feb, DD.

## Predeclared success (evaluation-ready, not promote)

- INIT `set=` matches loaded stem; schema `grai.glm.v0.4`
- Experts show `SL+` / `SL_MOD` / `FLAT` / `SKIP_STAGE` as applicable
- Lower early-stop alone ≠ pass if DD / expectancy / tails worsen
- Cite `ea_version` + `pack_id` + `set_name` on every scoreboard

## Baseline forensics snapshot (geometry proxy)

- early_stop 17.3%
- flat_near_sl_suspect 100/214
- sl_trail 33 · sl_initial_loss 27 · tp 40

Continuation after exit requires M5 bars:  
`python3 scripts/trade_lifecycle_forensics.py --trades … --bars … --out …`
