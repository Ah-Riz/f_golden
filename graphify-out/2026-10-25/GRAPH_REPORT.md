# Graph Report - gold_rush_AI  (2026-10-23)

## Corpus Check
- 41 files · ~674,870 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 314 nodes · 399 edges · 26 communities (20 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- 04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting
- QA gate — Gold Rush AI v0.1
- Gold Rush AI v0.1 — Design (lean)
- Suggested implementation milestones
- run_bridge.sh
- ablation_report.py
- ASSUMPTIONS.md
- GLM_PROVIDER_VERIFY.md
- FAILURE_MATRIX.md
- README.md
- Gold Rush AI Strategy Tester sets
- deploy_mt5.sh
- Fixed_001 — v0.4 close port
- parse_set
- Analysis — `v0.4_armC_holdA_nodist` vs other v0.4 armC (research)
- hostile_trade_review_to_csv.py
- 1. Scoreboard
- SMC_Lana MT5 indicator
- Gold Rush AI v0.3 / v0.4 — Design (lean)
- trade_lifecycle_forensics.py
- v0.4 trade lifecycle
- Audit: v0.3 trade lifecycle (pre-v0.4)
- v0.4 validation plan and status
- V0.4_PARAMS.md
- v0.3.3 — SmcLana bias + MTF gates (no H4 overwrite)
- 1. OnTick, in execution order

## God Nodes (most connected - your core abstractions)
1. `call_provider()` - 11 edges
2. `export_deals_trades()` - 11 edges
3. `analyze_trade()` - 11 edges
4. `1. OnTick, in execution order` - 11 edges
5. `How Gold Rush AI v0.3 enters the market — full trace (`v0.3_armC_dynamic.set`)` - 10 edges
6. `SectionTableParser` - 9 edges
7. `Exit / Holding Audit (frozen)` - 9 edges
8. `Fixed_001 — v0.4 close port` - 9 edges
9. `Gold Rush AI set codes` - 9 edges
10. `Handler` - 8 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `call_provider()`  [EXTRACTED]
  python/bridge/verify_provider.py → python/bridge/server.py
- `call_provider()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/server.py → python/bridge/schema.py
- `serve()` --calls--> `_log()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py
- `serve()` --calls--> `_wait()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py
- `serve()` --calls--> `call_provider()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py

## Import Cycles
- None detected.

## Communities (26 total, 6 thin omitted)

### Community 0 - "04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting"
Cohesion: 0.13
Nodes (14): 1.1 Sample L13 — Dist-heavy book, 1.2 Sample DYNAMIC — primary experiment baseline, 1.3 Sample v0.3 (hostile reference), 1. Samples (kept separate), 2. Source paths — exit authority, 3.1 Actual (pre–Exp A), 3.2 Target after Experiment A, 3. Precedence (+6 more)

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.11
Nodes (22): BaseHTTPRequestHandler, main(), post(), load_dotenv(), Path, Minimal .env loader (no third-party deps). Does not override existing env., GRAI GLM advisory schema v0.3 — local validation only., validate_advice() (+14 more)

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.11
Nodes (27): HTMLParser, build_arg_parser(), classify_exit_reason(), DealsTableParser, dedupe_rows(), export_deals_trades(), main(), OrdersTableParser (+19 more)

### Community 3 - "Suggested implementation milestones"
Cohesion: 0.25
Nodes (7): 1. Monthly salary digests (research), 2. Report-level scoreboard, 3. Structural change vs v0.3 (deal-level), 4. Ablation verdicts, 5. Salary / promote, 6. Recommended next experiments (ranked), Detailed analysis — v0.4 armC batch (research)

### Community 9 - "README.md"
Cohesion: 0.06
Nodes (29): Ablation E vs D, Arm E preflight (required — avoids 0 trades), Backtest / walk-forward / ablation (v0.2), Matrix, MOM_D segregation, Walk-forward, Authority, Bias / trend (SMC gate) (+21 more)

### Community 10 - "Gold Rush AI Strategy Tester sets"
Cohesion: 0.13
Nodes (13): Gold Rush AI set codes, Screen S pin, v0.1 (frozen baseline), v0.2 (frozen), v0.3.1 (SMC_Lana_OB entry gate), v0.3.2 (MTF phrase stack), v0.3.3 (SmcLana bias + MTF gates), v0.3 (frozen baseline) (+5 more)

### Community 11 - "deploy_mt5.sh"
Cohesion: 0.36
Nodes (10): _add_family(), _add_related(), _add_ver(), _compile_indicator(), compile_one(), deploy_smc_indicator(), list_versions(), deploy_mt5.sh script (+2 more)

### Community 12 - "Fixed_001 — v0.4 close port"
Cohesion: 0.20
Nodes (9): Acceptance checklist, Deploy / compile, Fixed_001 — v0.4 close port, Mode C / D gap, Sets, Tester compare protocol (user), Verify after compile, What changed (+1 more)

### Community 13 - "parse_set"
Cohesion: 0.67
Nodes (3): main(), parse_set(), Path

### Community 14 - "Analysis — `v0.4_armC_holdA_nodist` vs other v0.4 armC (research)"
Cohesion: 0.29
Nodes (6): Analysis — `v0.4_armC_holdA_nodist` vs other v0.4 armC (research), Exp A verdict (H-DIST on primary pin), Gate: Exp A **VALID** on this report, Monthly digests (research 5k / 100%), Next (if continuing exit work), Report scoreboard + exit mix

### Community 15 - "hostile_trade_review_to_csv.py"
Cohesion: 0.18
Nodes (18): build_arg_parser(), build_improvement_rows(), build_metrics_rows(), fnum(), load_trades(), main(), median_or_blank(), normalize_entry_tag() (+10 more)

### Community 16 - "1. Scoreboard"
Cohesion: 0.11
Nodes (18): 1. Scoreboard, 2. Short findings, 3. Hostile issues, 4. Verdict + next experiments, Basket / episode level, By entry_tag (normalized), By exit_reason, By layer depth (+10 more)

### Community 17 - "SMC_Lana MT5 indicator"
Cohesion: 0.18
Nodes (10): Acceptance checklist, Alerts, Defaults (M5-friendly), Deploy, Deploy / compile, Known intentional diffs, Layout, SMC_Lana MT5 indicator (+2 more)

### Community 18 - "Gold Rush AI v0.3 / v0.4 — Design (lean)"
Cohesion: 0.33
Nodes (5): Hard gates (closed bar `shift=1`), Research sets, Split roles, Tester checklist, v0.3.2 — H4 → H1 → M15 → M5 phrase stack

### Community 19 - "trade_lifecycle_forensics.py"
Cohesion: 0.23
Nodes (13): TestForensicsDefs, analyze_trade(), bars_after(), bars_between(), classify_exit(), failure_label(), fnum(), load_bars() (+5 more)

### Community 20 - "v0.4 trade lifecycle"
Cohesion: 0.29
Nodes (6): Entry stages (logged `SKIP_STAGE`), Exit priority, Long rules (short = mirror), Manage modes, State machine, v0.4 trade lifecycle

### Community 21 - "Audit: v0.3 trade lifecycle (pre-v0.4)"
Cohesion: 0.33
Nodes (5): Audit: v0.3 trade lifecycle (pre-v0.4), Diagnosis (evidence-backed), Forensics (price-path proxy; no M5 bars supplied), Hypotheses → v0.4 tests, Mechanics summary

### Community 22 - "v0.4 validation plan and status"
Cohesion: 0.33
Nodes (5): Baseline forensics snapshot (geometry proxy), Operator run matrix, Predeclared success (evaluation-ready, not promote), Status, v0.4 validation plan and status

### Community 24 - "v0.3.3 — SmcLana bias + MTF gates (no H4 overwrite)"
Cohesion: 0.33
Nodes (5): Hard gates (closed bar `shift=1`), Research sets, Split roles, Tester checklist, v0.3.3 — SmcLana bias + MTF gates (no H4 overwrite)

### Community 43 - "1. OnTick, in execution order"
Cohesion: 0.07
Nodes (26): 1.10 Calendar gates — `:3148-3236`, 1.1 Spread filter — `:2648`, 1.2 Episode close + ladder sync — `:2655-2662`, 1.3 The per-tick kill switches — `:2663-2757`, 1.4 Pyramid attempt — `:2756`, 1.5 Base lot arithmetic — `:2773-2826`, 1.6 Housekeeping — `:2827-2891`, 1.7 The ratchet lines — `:2892-2940` (+18 more)

## Knowledge Gaps
- **135 isolated node(s):** `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Quick start (v0.3.1 OB ablation)`, `Bridge (Path B / Arm E)`, `Assumptions / unresolved` (+130 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Quick start (v0.3.1 OB ablation)` to the rest of the system?**
  _135 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `QA gate — Gold Rush AI v0.1` be split into smaller, more focused modules?**
  _Cohesion score 0.11363636363636363 - nodes in this community are weakly interconnected._
- **Should `Gold Rush AI v0.1 — Design (lean)` be split into smaller, more focused modules?**
  _Cohesion score 0.10873440285204991 - nodes in this community are weakly interconnected._
- **Should `README.md` be split into smaller, more focused modules?**
  _Cohesion score 0.058823529411764705 - nodes in this community are weakly interconnected._
- **Should `Gold Rush AI Strategy Tester sets` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `1. Scoreboard` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._