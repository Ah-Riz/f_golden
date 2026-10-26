# Graph Report - gold_rush_AI  (2026-10-26)

## Corpus Check
- 47 files · ~902,332 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 411 nodes · 503 edges · 31 communities (26 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `56905617`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- v0.3.4 — Soft hyb3 ladder (SmcLana + H4 veto + optional loose M5)
- §7.3 Downside / tail-risk evaluation
- Pre-AI candidate (awaiting final digests)
- Gold Rush AI v0.3 / v0.4 — Design (lean)
- Device handoff — P0 advisory (continue here)
- 1. OnTick, in execution order

## God Nodes (most connected - your core abstractions)
1. `call_provider()` - 11 edges
2. `export_deals_trades()` - 11 edges
3. `analyze_trade()` - 11 edges
4. `Pre-registered Advisory Ablation Protocol` - 11 edges
5. `1. OnTick, in execution order` - 11 edges
6. `Gold Rush AI set codes` - 11 edges
7. `How Gold Rush AI v0.3 enters the market — full trace (`v0.3_armC_dynamic.set`)` - 10 edges
8. `SectionTableParser` - 9 edges
9. `Exit / Holding Audit (frozen)` - 9 edges
10. `Fixed_001 — v0.4 close port` - 9 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `call_provider()`  [EXTRACTED]
  python/bridge/verify_provider.py → python/bridge/server.py
- `fault_matrix_offline()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/hostile_smoke.py → python/bridge/schema.py
- `call_provider()` --calls--> `validate_advice()`  [EXTRACTED]
  python/bridge/server.py → python/bridge/schema.py
- `serve()` --calls--> `_log()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py
- `serve()` --calls--> `_wait()`  [EXTRACTED]
  python/bridge/watcher.py → python/bridge/server.py

## Import Cycles
- None detected.

## Communities (31 total, 5 thin omitted)

### Community 0 - "04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting"
Cohesion: 0.13
Nodes (14): 1.1 Sample L13 — Dist-heavy book, 1.2 Sample DYNAMIC — primary experiment baseline, 1.3 Sample v0.3 (hostile reference), 1. Samples (kept separate), 2. Source paths — exit authority, 3.1 Actual (pre–Exp A), 3.2 Target after Experiment A, 3. Precedence (+6 more)

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.11
Nodes (25): BaseHTTPRequestHandler, fault_matrix_offline(), main(), post(), Schema-level faults that must not authorize risk (no bridge required)., load_dotenv(), Path, Minimal .env loader (no third-party deps). Does not override existing env. (+17 more)

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.11
Nodes (27): HTMLParser, build_arg_parser(), classify_exit_reason(), DealsTableParser, dedupe_rows(), export_deals_trades(), main(), OrdersTableParser (+19 more)

### Community 3 - "Suggested implementation milestones"
Cohesion: 0.25
Nodes (7): 1. Monthly salary digests (research), 2. Report-level scoreboard, 3. Structural change vs v0.3 (deal-level), 4. Ablation verdicts, 5. Salary / promote, 6. Recommended next experiments (ranked), Detailed analysis — v0.4 armC batch (research)

### Community 7 - "GLM_PROVIDER_VERIFY.md"
Cohesion: 0.08
Nodes (26): 0. Scope and non-goals, 1. Matched experiment arms, 2. Evaluation calendars (regression vs confirmatory), 3.1 Clock definition, 3.2 Episode contribution, 3.3 Primary lift, 3.4 Overlap, closure, terminal liquidation, invalid advisory, 3.5 Report alongside \(\Delta_{\mathrm{adv}}\) (+18 more)

### Community 9 - "README.md"
Cohesion: 0.05
Nodes (33): Ablation E vs D, Arm E preflight (required — avoids 0 trades), Backtest / walk-forward / ablation (v0.2), Matrix, MOM_D segregation, Walk-forward, Bias, OB entry gate (`InpSmcObEntryGate`) — arm window (+25 more)

### Community 10 - "Gold Rush AI Strategy Tester sets"
Cohesion: 0.12
Nodes (15): Gold Rush AI set codes, Screen S pin, v0.1 (frozen baseline), v0.2 (frozen), v0.3.1 (SMC_Lana_OB entry gate), v0.3.2 (MTF phrase stack), v0.3.3 (SmcLana bias + MTF gates), v0.3.4 final (pre-AI SMC usage ablation) (+7 more)

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

### Community 25 - "v0.3.4 — Soft hyb3 ladder (SmcLana + H4 veto + optional loose M5)"
Cohesion: 0.29
Nodes (6): Final pre-AI pack (`sets/export_v0.3.4_final/`), Hard gates (closed bar `shift=1`), Research sets, Split roles, Tester checklist, v0.3.4 — Soft hyb3 ladder (SmcLana + H4 veto + optional loose M5)

### Community 26 - "§7.3 Downside / tail-risk evaluation"
Cohesion: 0.07
Nodes (27): 1. LPM, 2. UNCONFIRMED, 3. MPM / HPM, 7.3.1 Purpose, 7.3.2 Absolute hard limits (never loosened), 7.3.3 Definitions, 7.3.4 Training-derived reference thresholds (B0 train only), 7.3.5 Bucket tail statistics — single deterministic procedure (+19 more)

### Community 27 - "Pre-AI candidate (awaiting final digests)"
Cohesion: 0.20
Nodes (9): Freeze rule result, Locked candidate identity, Mandatory constraints for subsequent AI advisory research, Next milestone, Optional follow-up (not required for AI start), Pre-AI candidate (frozen), Run caveats (this freeze), Scope boundary (Phase 1 AS) (+1 more)

### Community 28 - "Gold Rush AI v0.3 / v0.4 — Design (lean)"
Cohesion: 0.22
Nodes (8): Authority, Bias / trend (SMC gate), Equity DD, Gold Rush AI v0.3 / v0.4 — Design (lean), Modules, Momentum / Arms / Mode S, Paths, Risk ladder

### Community 29 - "Device handoff — P0 advisory (continue here)"
Cohesion: 0.29
Nodes (7): Already green (do not re-claim as Mode S), Bring to the other machine, Device handoff — P0 advisory (continue here), Next on new device, Ops cheats, Pins, Prompt sent to GLM (summary)

### Community 43 - "1. OnTick, in execution order"
Cohesion: 0.07
Nodes (26): 1.10 Calendar gates — `:3148-3236`, 1.1 Spread filter — `:2648`, 1.2 Episode close + ladder sync — `:2655-2662`, 1.3 The per-tick kill switches — `:2663-2757`, 1.4 Pyramid attempt — `:2756`, 1.5 Base lot arithmetic — `:2773-2826`, 1.6 Housekeeping — `:2827-2891`, 1.7 The ratchet lines — `:2892-2940` (+18 more)

## Knowledge Gaps
- **208 isolated node(s):** `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Quick start (v0.3.1 OB ablation)`, `Bridge (Path B / Arm E)`, `0. Scope and non-goals` (+203 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Pre-registered Advisory Ablation Protocol` connect `GLM_PROVIDER_VERIFY.md` to `README.md`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **What connects `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Quick start (v0.3.1 OB ablation)` to the rest of the system?**
  _208 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `QA gate — Gold Rush AI v0.1` be split into smaller, more focused modules?**
  _Cohesion score 0.10634920634920635 - nodes in this community are weakly interconnected._
- **Should `Gold Rush AI v0.1 — Design (lean)` be split into smaller, more focused modules?**
  _Cohesion score 0.10873440285204991 - nodes in this community are weakly interconnected._
- **Should `GLM_PROVIDER_VERIFY.md` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `README.md` be split into smaller, more focused modules?**
  _Cohesion score 0.0545876887340302 - nodes in this community are weakly interconnected._