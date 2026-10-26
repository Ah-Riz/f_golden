# Graph Report - gold_rush_AI  (2026-10-08)

## Corpus Check
- 19 files · ~100,948 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 76 nodes · 85 edges · 13 communities (8 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- server.py
- QA gate — Gold Rush AI v0.1
- Gold Rush AI v0.1 — Design (lean)
- Backtest / walk-forward / ablation
- validate_advice
- ablation_report.py
- ASSUMPTIONS.md
- GLM_PROVIDER_VERIFY.md
- FAILURE_MATRIX.md
- README.md
- Gold Rush AI Strategy Tester sets
- deploy_mt5.sh
- QA gate — Gold Rush AI v0.2

## God Nodes (most connected - your core abstractions)
1. `Gold Rush AI v0.2 — Design (lean)` - 9 edges
2. `Handler` - 7 edges
3. `call_provider()` - 6 edges
4. `Backtest / walk-forward / ablation (v0.2)` - 6 edges
5. `load_dotenv()` - 5 edges
6. `validate_advice()` - 5 edges
7. `QA gate — Gold Rush AI v0.2` - 4 edges
8. `Gold Rush AI set codes` - 4 edges
9. `Gold Rush AI Strategy Tester sets` - 4 edges
10. `Gold Rush AI` - 3 edges

## Surprising Connections (you probably didn't know these)
- `call_provider()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/server.py → python/bridge/schema.py
- `main()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/verify_provider.py → python/bridge/schema.py

## Import Cycles
- None detected.

## Communities (13 total, 5 thin omitted)

### Community 0 - "server.py"
Cohesion: 0.23
Nodes (8): BaseHTTPRequestHandler, call_provider(), Handler, _hash(), _log(), main(), Returns (advice_dict, meta). Never raises secrets into meta., _wait()

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.38
Nodes (5): Path, main(), post(), load_dotenv(), Minimal .env loader (no third-party deps). Does not override existing env.

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.22
Nodes (9): Arms, Authority, Gold Rush AI v0.2 — Design (lean), Layer allow, Mode S, Modules, Momentum, Paths (+1 more)

### Community 3 - "Backtest / walk-forward / ablation"
Cohesion: 0.33
Nodes (6): Ablation E vs D, Arm E preflight (required — avoids err=4014 / 0 trades), Backtest / walk-forward / ablation (v0.2), Matrix, MOM_D segregation, Walk-forward

### Community 4 - "validate_advice"
Cohesion: 0.60
Nodes (3): GRAI GLM advisory schema v0.2 — local validation only., validate_advice(), main()

### Community 9 - "README.md"
Cohesion: 0.20
Nodes (6): EA inputs that are **not** in `.env`, Step-by-step (first time), Where each `.env` variable comes from, Bridge (Path B / Arm E), Gold Rush AI, Quick start (Path A — v0.2)

### Community 10 - "Gold Rush AI Strategy Tester sets"
Cohesion: 0.20
Nodes (8): Gold Rush AI set codes, Screen S pin, v0.1 (frozen baseline), v0.2 (current), Arms (v0.2), Deploy, Gold Rush AI Strategy Tester sets, Screen S pin

### Community 12 - "QA gate — Gold Rush AI v0.2"
Cohesion: 0.40
Nodes (4): Design / impl, Hostile checklist, Ponytail notes, QA gate — Gold Rush AI v0.2

## Knowledge Gaps
- **30 isolated node(s):** `deploy_mt5.sh script`, `Quick start (Path A — v0.2)`, `Bridge (Path B / Arm E)`, `Assumptions / unresolved`, `Matrix` (+25 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Gold Rush AI v0.2 — Design (lean)` connect `Gold Rush AI v0.1 — Design (lean)` to `README.md`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Why does `Backtest / walk-forward / ablation (v0.2)` connect `Backtest / walk-forward / ablation` to `README.md`?**
  _High betweenness centrality (0.065) - this node is a cross-community bridge._
- **What connects `deploy_mt5.sh script`, `Quick start (Path A — v0.2)`, `Bridge (Path B / Arm E)` to the rest of the system?**
  _30 weakly-connected nodes found - possible documentation gaps or missing edges._