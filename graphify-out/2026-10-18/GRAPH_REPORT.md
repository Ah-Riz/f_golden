# Graph Report - gold_rush_AI  (2026-10-18)

## Corpus Check
- 39 files · ~408,107 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 318 nodes · 401 edges · 25 communities (19 shown, 6 thin omitted)
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
- 02 — SMC, Liquidity, Displacement & Zones
- parse_set
- 01 — OHLC, Candle Mathematics & Market Structure
- hostile_trade_review_to_csv.py
- 1. Scoreboard
- 03 — Fibonacci Retracements, Extensions & Harmonic Patterns
- OHLC, SMC, Fibonacci & Harmonic Trading — Knowledge Pack
- trade_lifecycle_forensics.py
- v0.4 trade lifecycle
- Audit: v0.3 trade lifecycle (pre-v0.4)
- v0.4 validation plan and status
- V0.4_PARAMS.md
- 1. OnTick, in execution order

## God Nodes (most connected - your core abstractions)
1. `04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting` - 13 edges
2. `call_provider()` - 11 edges
3. `export_deals_trades()` - 11 edges
4. `analyze_trade()` - 11 edges
5. `02 — SMC, Liquidity, Displacement & Zones` - 11 edges
6. `1. OnTick, in execution order` - 11 edges
7. `How Gold Rush AI v0.3 enters the market — full trace (`v0.3_armC_dynamic.set`)` - 10 edges
8. `SectionTableParser` - 9 edges
9. `Handler` - 8 edges
10. `main()` - 8 edges

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

## Communities (25 total, 6 thin omitted)

### Community 0 - "04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting"
Cohesion: 0.09
Nodes (21): 04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting, 10. Backtesting requirements, 11. Useful diagnostics, 12. Safety constraints for a research engine, 1. Strategy architecture, 2. Example long setup (hypothesis to test), 3. Example short setup, 4. Stop-loss models (+13 more)

### Community 1 - "QA gate — Gold Rush AI v0.1"
Cohesion: 0.11
Nodes (22): BaseHTTPRequestHandler, main(), post(), load_dotenv(), Path, Minimal .env loader (no third-party deps). Does not override existing env., GRAI GLM advisory schema v0.3 — local validation only., validate_advice() (+14 more)

### Community 2 - "Gold Rush AI v0.1 — Design (lean)"
Cohesion: 0.11
Nodes (27): HTMLParser, build_arg_parser(), classify_exit_reason(), DealsTableParser, dedupe_rows(), export_deals_trades(), main(), OrdersTableParser (+19 more)

### Community 3 - "Suggested implementation milestones"
Cohesion: 0.13
Nodes (14): AI Coding Agent Brief — OHLC / SMC / Fibonacci / Harmonic Research Engine, M0 — Data correctness, M1 — Causal pivots and structure, M2 — Zones, M3 — Fibonacci and harmonics, M4 — One simple strategy, M5 — Execution realism, M6 — Evaluation (+6 more)

### Community 9 - "README.md"
Cohesion: 0.07
Nodes (24): Ablation E vs D, Arm E preflight (required — avoids 0 trades), Backtest / walk-forward / ablation (v0.2), Matrix, MOM_D segregation, Walk-forward, Authority, Bias / trend (SMC gate) (+16 more)

### Community 10 - "Gold Rush AI Strategy Tester sets"
Cohesion: 0.17
Nodes (10): Gold Rush AI set codes, Screen S pin, v0.1 (frozen baseline), v0.2 (frozen), v0.3 (frozen baseline), v0.4 (lifecycle candidate), Arms (v0.3), Deploy (+2 more)

### Community 11 - "deploy_mt5.sh"
Cohesion: 0.44
Nodes (8): _add_family(), _add_related(), _add_ver(), compile_one(), list_versions(), deploy_mt5.sh script, usage(), version_exists()

### Community 12 - "02 — SMC, Liquidity, Displacement & Zones"
Cohesion: 0.15
Nodes (12): 02 — SMC, Liquidity, Displacement & Zones, 10. Common implementation failures, 1. Scope and epistemic caution, 2. Structure and breaks, 3. Displacement, 4. Order-block definitions, 5. Supply/demand zones, 6. Liquidity references and sweep definitions (+4 more)

### Community 13 - "parse_set"
Cohesion: 0.67
Nodes (3): main(), parse_set(), Path

### Community 14 - "01 — OHLC, Candle Mathematics & Market Structure"
Cohesion: 0.18
Nodes (10): 01 — OHLC, Candle Mathematics & Market Structure, 1. OHLC data model, 2. OHLC versus OLHC, 3. Confirmed swing highs/lows, 4. Market structure vocabulary, 5. BOS and CHoCH as explicit rules, 6. Equal highs/lows and tolerance, 7. No-lookahead contract (+2 more)

### Community 15 - "hostile_trade_review_to_csv.py"
Cohesion: 0.18
Nodes (18): build_arg_parser(), build_improvement_rows(), build_metrics_rows(), fnum(), load_trades(), main(), median_or_blank(), normalize_entry_tag() (+10 more)

### Community 16 - "1. Scoreboard"
Cohesion: 0.11
Nodes (18): 1. Scoreboard, 2. Short findings, 3. Hostile issues, 4. Verdict + next experiments, Basket / episode level, By entry_tag (normalized), By exit_reason, By layer depth (+10 more)

### Community 17 - "03 — Fibonacci Retracements, Extensions & Harmonic Patterns"
Cohesion: 0.18
Nodes (10): 03 — Fibonacci Retracements, Extensions & Harmonic Patterns, 1. Ratios, 2. Retracement formula, 3. Normalized location, 4. Harmonic pattern structure, 5. Ratio tolerance, 6. Potential Reversal Zone (PRZ), 7. Harmonic detection cautions (+2 more)

### Community 18 - "OHLC, SMC, Fibonacci & Harmonic Trading — Knowledge Pack"
Cohesion: 0.33
Nodes (5): Core principles, Files, Not financial advice, OHLC, SMC, Fibonacci & Harmonic Trading — Knowledge Pack, Suggested build order

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

### Community 43 - "1. OnTick, in execution order"
Cohesion: 0.07
Nodes (26): 1.10 Calendar gates — `:3148-3236`, 1.1 Spread filter — `:2648`, 1.2 Episode close + ladder sync — `:2655-2662`, 1.3 The per-tick kill switches — `:2663-2757`, 1.4 Pyramid attempt — `:2756`, 1.5 Base lot arithmetic — `:2773-2826`, 1.6 Housekeeping — `:2827-2891`, 1.7 The ratchet lines — `:2892-2940` (+18 more)

## Knowledge Gaps
- **142 isolated node(s):** `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Candle features`, `2. OHLC versus OLHC`, `Adaptive swing alternatives` (+137 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `run_bridge.sh script`, `GRAI_MT5_ROOT`, `Candle features` to the rest of the system?**
  _142 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `04 — Long/Short Entries, Exits, Parameters, Trading Style & Backtesting` be split into smaller, more focused modules?**
  _Cohesion score 0.09090909090909091 - nodes in this community are weakly interconnected._
- **Should `QA gate — Gold Rush AI v0.1` be split into smaller, more focused modules?**
  _Cohesion score 0.11363636363636363 - nodes in this community are weakly interconnected._
- **Should `Gold Rush AI v0.1 — Design (lean)` be split into smaller, more focused modules?**
  _Cohesion score 0.10873440285204991 - nodes in this community are weakly interconnected._
- **Should `Suggested implementation milestones` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `README.md` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._
- **Should `1. Scoreboard` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._