# QA gate — Gold Rush AI v0.3_smc (+ SMC trading-signal gate)

## Design / impl

- [x] v0.3 / v0.3_short frozen; v0.3_smc fork
- [x] Equity-peak DD 5% + risk ladder 1→1.5→2
- [x] `pine/SMC_Lana.pine` cleaned from `SMC-lana.txt` (primary script only)
- [x] `SmcLanaGate.mqh` — trading-signal 1:1 (structure BOS/CHoCH/sweeps, OB mitigate, mapping, liquidity); lookback default 5000
- [x] Frozen `SmcLana.mqh` untouched
- [x] `SmcDraw.mqh` — optional chart objects
- [x] Bias gate: SMC primary; MA optional AND
- [x] Sets: `v0.3_armC_smc_full` / `_long` / `_short`
- [x] Compile `gold_rush_AI_v0.3_smc.mq5` (+ short sibling) — 0 errors
- [x] Pine adj modulo fix (`bar_index % mslen`) in `SmcLanaGate.mqh`
- [x] Algorithm twin: `scripts/smc_structure_twin.py` → `logs/smc_parity_report.txt` PASS (≥95% pine↔gate_fixed)
- [x] Experts CSV dump path: `InpSmcParityDump` → `grai_smc_parity.csv` (+ `v0.3_armC_smc_parity.set`)
- [x] Live Experts CSV vs twin (`logs/grai_smc_parity.csv`) — ≥95% with ±1 bar / bar_agree (see `logs/smc_parity_report.txt`)
- [ ] Path A: fighting trend → 0 opens; aligned → opens with risk/news
- [ ] Arm E bridge / WebRequest checks (unchanged)

## Hostile checklist

- [ ] Bridge down → WAIT
- [ ] LLM cannot raise SMC / ladder / DD
- [ ] Unknown SMC / FLAT → WAIT

## Notes

No profit guarantee. Dual promote: Mode S digest (deposit **50000** / threshold **5000**) + WF/holdout.

**Mode S digest discipline:** refuse promote / salary pass if slicer `--deposit` ≠ Tester deposit, or if digest rows show `5000/500` (research-scale). Legacy `logs/salary_digest_v0.3_*.csv` at deposit 5000 are **not** Mode S. Score only digests with deposit **50000** and threshold **5000**.

Claim language: **trading-signal 1:1** (gate), not full indicator. Twin report: `logs/smc_parity_report.txt`.
