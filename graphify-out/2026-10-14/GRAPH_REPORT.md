# Graph Report - gold_rush_AI  (2026-10-14)

## Corpus Check
- 21 files · ~402,335 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 87 nodes · 109 edges · 14 communities (7 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- server.py
- QA gate — Gold Rush AI v0.1
- Gold Rush AI v0.1 — Design (lean)
- Backtest / walk-forward / ablation
- run_bridge.sh
- ablation_report.py
- ASSUMPTIONS.md
- GLM_PROVIDER_VERIFY.md
- FAILURE_MATRIX.md
- README.md
- Gold Rush AI Strategy Tester sets
- deploy_mt5.sh
- QA gate — Gold Rush AI v0.2
- hostile_smoke.py

## God Nodes (most connected - your core abstractions)
1. `call_provider()` - 11 edges
2. `Handler` - 8 edges
3. `Gold Rush AI v0.3 — Design (lean)` - 8 edges
4. `serve()` - 6 edges
5. `Backtest / walk-forward / ablation (v0.2)` - 6 edges
6. `load_dotenv()` - 5 edges
7. `_wait()` - 5 edges
8. `Gold Rush AI set codes` - 5 edges
9. `_log()` - 4 edges
10. `QA gate — Gold Rush AI v0.3 (+ SMC-Lana)` - 4 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `call_provider()`  [EXTRACTED]
  python/bridge/verify_provider.py → python/bridge/server.py
- `serve()` --calls--> `call_provider()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py
- `call_provider()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/server.py → python/bridge/schema.py
- `serve()` --calls--> `_log()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py
- `serve()` --calls--> `_wait()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py

## Import Cycles
- None detected.

## Communities (14 total, 7 thin omitted)

### Community 0 - "server.py"
Cohesion: 0.40
Nodes (4): Design / impl, Hostile checklist, Notes, QA gate — Gold Rush AI v0.3 (+ SMC-Lana)

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.23
Nodes (11): Path, load_dotenv(), Minimal .env loader (no third-party deps). Does not override existing env., GRAI GLM advisory schema v0.3 — local validation only., validate_advice(), call_provider(), _hash(), Returns (advice_dict, meta). Never raises secrets into meta. (+3 more)

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.25
Nodes (8): Authority, Bias / trend (v0.3 SMC), Equity DD, Gold Rush AI v0.3 — Design (lean), Modules, Momentum / Arms / Mode S, Paths, Risk ladder

### Community 3 - "Backtest / walk-forward / ablation"
Cohesion: 0.32
Nodes (3): BaseHTTPRequestHandler, Handler, main()

### Community 9 - "README.md"
Cohesion: 0.13
Nodes (12): Ablation E vs D, Arm E preflight (required — avoids 0 trades), Backtest / walk-forward / ablation (v0.2), Matrix, MOM_D segregation, Walk-forward, EA inputs that are **not** in `.env`, Step-by-step (first time) (+4 more)

### Community 10 - "Gold Rush AI Strategy Tester sets"
Cohesion: 0.18
Nodes (9): Gold Rush AI set codes, Screen S pin, v0.1 (frozen baseline), v0.2 (frozen), v0.3 (current), Arms (v0.3), Deploy, Gold Rush AI Strategy Tester sets (+1 more)

### Community 12 - "QA gate — Gold Rush AI v0.2"
Cohesion: 0.52
Nodes (6): _log(), _wait(), _agent(), main(), purge_old(), serve()

## Knowledge Gaps
- **32 isolated node(s):** `deploy_mt5.sh script`, `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Quick start (Path A — v0.3)`, `Bridge (Path B / Arm E)` (+27 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Gold Rush AI v0.3 — Design (lean)` connect `Gold Rush AI v0.1 — Design (lean)` to `README.md`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **What connects `deploy_mt5.sh script`, `run_bridge.sh script`, `GRAI_MT5_ROOT` to the rest of the system?**
  _32 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `README.md` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._