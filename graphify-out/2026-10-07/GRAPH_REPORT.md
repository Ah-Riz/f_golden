# Graph Report - gold_rush_AI  (2026-10-07)

## Corpus Check
- 14 files · ~2,571 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 60 nodes · 67 edges · 9 communities (5 shown, 4 thin omitted)
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

## God Nodes (most connected - your core abstractions)
1. `Gold Rush AI v0.1 — Design (lean)` - 9 edges
2. `Handler` - 7 edges
3. `QA gate — Gold Rush AI v0.1` - 7 edges
4. `call_provider()` - 6 edges
5. `Backtest / walk-forward / ablation` - 6 edges
6. `validate_advice()` - 5 edges
7. `load_dotenv()` - 4 edges
8. `Gold Rush AI` - 3 edges
9. `_hash()` - 2 edges
10. `_log()` - 2 edges

## Surprising Connections (you probably didn't know these)
- `call_provider()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/server.py → python/bridge/schema.py
- `main()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/verify_provider.py → python/bridge/schema.py

## Import Cycles
- None detected.

## Communities (9 total, 4 thin omitted)

### Community 0 - "server.py"
Cohesion: 0.23
Nodes (8): BaseHTTPRequestHandler, call_provider(), Handler, _hash(), _log(), main(), Returns (advice_dict, meta). Never raises secrets into meta., _wait()

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.15
Nodes (10): Design exit, Hostile (Stage 7 checklist), Human gates remaining, Implementation checks, Ponytail-review (shipped tree), QA gate — Gold Rush AI v0.1, Traceability, Bridge (Path B / Arm E) (+2 more)

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.22
Nodes (9): Arms, Authority, Gold Rush AI v0.1 — Design (lean), Layer allow, Mode S, Modules, Momentum, Paths (+1 more)

### Community 3 - "Backtest / walk-forward / ablation"
Cohesion: 0.29
Nodes (6): Ablation E vs D, Backtest / walk-forward / ablation, Matrix, MOM_D segregation, Screen S / Mode S, Walk-forward

### Community 4 - "validate_advice"
Cohesion: 0.31
Nodes (6): Path, load_dotenv(), Minimal .env loader (no third-party deps). Does not override existing env., GRAI GLM advisory schema v0.1 — local validation only., validate_advice(), main()

## Knowledge Gaps
- **24 isolated node(s):** `Quick start (Path A)`, `Bridge (Path B / Arm E)`, `Assumptions / unresolved`, `Matrix`, `MOM_D segregation` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Gold Rush AI v0.1 — Design (lean)` connect `Gold Rush AI v0.1 — Design (lean)` to `QA gate — Gold Rush AI v0.1`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **What connects `Quick start (Path A)`, `Bridge (Path B / Arm E)`, `Assumptions / unresolved` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._