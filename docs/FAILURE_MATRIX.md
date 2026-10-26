# Failure matrix

| Failure | EA | Log |
|---|---|---|
| WebRequest allowlist deny (live chart only) | WAIT bar | `LLM_FAIL layer=BOT code=WR_DENY err=4014` |
| Watcher down / no resp file (Tester) | WAIT bar | `LLM_FAIL layer=BOT code=FILE_TIMEOUT` (then `circuit_open`, re-probe every 60s) |
| Req file write fail (Tester) | WAIT bar | `LLM_FAIL layer=BOT code=FILE_WRITE_FAIL` |
| Optimization with LLM on | fast-fail | `LLM_FAIL layer=BOT code=OPT_NO_LLM` |
| Bridge down / other WebRequest err | WAIT bar | `LLM_FAIL layer=BOT code=WR_FAIL err=N` |
| Wrong `InpBridgeToken` | WAIT bar | `LLM_FAIL layer=AUTH code=BRIDGE_401` |
| Missing/empty `ZAI_API_KEY` or base URL | WAIT bar | `LLM_FAIL layer=API code=PROVIDER_UNAVAILABLE` |
| Provider HTTP 401/403/5xx | WAIT bar | `LLM_FAIL layer=API code=PROVIDER_HTTP` |
| Provider 429 rate/overload (z.ai 1302/1305) | retry ×3 exp backoff then WAIT bar | `LLM_FAIL layer=API code=PROVIDER_HTTP` (jsonl `meta.retries>0`) |
| Provider quota flush (z.ai 1308/1310/1316–1321) | bridge pauses until `next_flush_time`, instant WAIT bars | `LLM_FAIL layer=API code=PROVIDER_PAUSED` (jsonl `meta.paused_until`) |
| Provider billing/plan (z.ai 1113/1309/1311) | no retry, WAIT bar | `LLM_FAIL layer=API code=PROVIDER_HTTP` (jsonl `meta.provider_code`) |
| Provider network/other | WAIT bar | `LLM_FAIL layer=API code=PROVIDER_ERROR` |
| request_id mismatch | WAIT bar | `LLM_FAIL layer=BOT code=LLM_STALE` |
| Bad JSON / schema | WAIT bar | `LLM_FAIL layer=BOT code=LLM_SCHEMA_FAIL` (or API) |
| recommended_max_layers≤0 (no failure_code) | WAIT / SKIP | `LLM_RESPONSE` then AND-gate SKIP |
| HALT decision | WAIT + KILL log | KILL |
| Regime UNKNOWN/ABNORMAL | no new orders | SKIP regime_block |
| Adverse off + Fixed step-add | reject (use pyramid) | LAYER_REJECT adverse_blocked |
| Favorable pyramid not ready | skip add | (silent / not_favorable) |
| GLM WAIT/HALT/mismatch (AND gate) | no new risk | SKIP glm_wait / glm_mismatch |
| Parent ±30 CSV blackout | no new risk | NEWS parent30_block |
| Equity kill | block entries | RISK_FAIL |
| DeterministicFallback=true (research) | Path A continues on GLM fail | INIT |

**Cheat sheet:** `FILE_TIMEOUT` → watcher down / `GRAI_MT5_ROOT` (tester) · `WR_DENY` → MT5 allowlist (live) · `BRIDGE_401` → `InpBridgeToken` · `PROVIDER_*` → `.env` `ZAI_API_KEY` / provider.

Live: `InpDeterministicFallback=false`. No stale last-success reuse. Never log tokens or API keys.
