# Assumptions / unresolved

- ATR AI path may use Fixed H-L mean proxy; true ATR(14) = labeled variant.
- ±30 CPI/NFP/FOMC calendar: Tester may lack feed → GRP hours + spike until Stage 4+.
- Z.AI structured JSON: run `python/bridge/verify_provider.py` before Arm E.
- sg_3 hedging: out of scope v0.1.
- FOREX multi-symbol: deferred.
- Ablation numeric thresholds: set before promotion; default = no promote without multi-metric E>D.
- Bridge token: `InpBridgeToken` + `GRAI_BRIDGE_TOKEN`; never log value.
- `InpUsePctRisk` / `GRAI_LotsFromRisk` shipped but not wired into Fixed AutoLot path yet — enable when Arm C sizing replaces AutoLot.
- True pyramiding adds (favorable step) not in Fixed fork yet; v0.1 blocks Fixed adverse adds when `InpAdverseAveraging=false` (Arm A–D default).
