# Where each `.env` variable comes from

Fill [`.env`](../.env) (gitignored). Template: [`.env.example`](../.env.example).  
The Python bridge loads `.env` automatically. **Never put the API key in the EA.**

| Variable | Where you get it | What to put |
|---|---|---|
| `ZAI_API_KEY` | **Z.AI console** → [z.ai](https://z.ai) login → **API Keys** page ([docs](https://docs.z.ai/guides/develop/http/introduction)) | The secret key string they give you |
| `GRAI_BASE_URL` | **Z.AI docs** (fixed URL, not a secret) | **Coding Plan** (subscription credits, $0; off-peak = 50% rate): `https://api.z.ai/api/coding/paas/v4` · **Pay-as-you-go**: `https://api.z.ai/api/paas/v4` (free models here: GLM-4.7-Flash, GLM-4.5-Flash; glm-5.3-flash ≈ $3–6 per 12k-bar backtest, needs credit) |
| `GRAI_MODEL` | **Z.AI model list** for your plan | `glm-5.3-flash` — works on **both** endpoints above (verified on Coding Plan). Coding endpoint also serves `glm-5.3`; GLM-4.7 requests there auto-map to GLM-5.3-Flash |
| `GRAI_PROVIDER` | You | Label for logs, usually `zai` |
| `GRAI_RESPONSE_FORMAT` | You + verify | `json_object` first; if `verify_provider.py` fails, try `none` |
| `GRAI_PROMPT_VERSION` | You | Bump when you change the prompt text |
| `GRAI_BRIDGE_TOKEN` | **You invent it** | Any random secret; paste the **same** into EA input `InpBridgeToken` |
| `GRAI_BRIDGE_PORT` | You | Default `8765` |
| `GRAI_JSONL` | You | Log filename, default `grai_bridge.jsonl` |
| `GRAI_MT5_ROOT` | You | MT5 install dir for the tester file watcher, default `/home/lana/.mt5/drive_c/Program Files/MetaTrader 5` |
| `GRAI_MIN_INTERVAL_MS` | You | Min spacing between provider calls (z.ai has no published RPM — limits are per-account/concurrency); default `1000`, `0` disables. 429/5xx retried ×3 (exp backoff); z.ai quota codes (1308/1310/1316–1321) pause the bridge until `next_flush_time`. Your live tier limits: z.ai/manage-apikey/rate-limits |

## Step-by-step (first time)

1. Open [https://z.ai](https://z.ai) → register / login.
2. Open **API Keys** → create a key → copy it into `ZAI_API_KEY=` in `.env`.
3. Set `GRAI_BASE_URL=https://api.z.ai/api/paas/v4` (already in `.env.example`).
4. Invent a bridge token, e.g. `openssl rand -hex 16` → put in `GRAI_BRIDGE_TOKEN=` **and** in MT5 EA `InpBridgeToken`.
5. In MT5: Tools → Options → Expert Advisors → allow WebRequest for `http://127.0.0.1:8765`.
6. Test provider (optional):  
   `cd python/bridge && python3 verify_provider.py`
7. Start bridge:  
   `python3 python/bridge/server.py`
8. EA: `InpLLMEnabled=true` only for Arm E / demo (keep `false` in Tester Path A).
9. **Arm E transport:** the Strategy Tester **bans `WebRequest()`** (`err=4014` regardless of allowlist) — in the tester the EA exchanges files with the watcher started by `scripts/run_bridge.sh` (see [BACKTEST_PROTOCOL](BACKTEST_PROTOCOL.md)). The WebRequest allowlist below is **live chart only**:  
   MT5 → Options → Expert Advisors → allow WebRequest URL `http://127.0.0.1:8765`  
   Without it (live) you get `LLM_FAIL layer=BOT code=WR_DENY err=4014` and **zero trades**.  
   Cheat: `FILE_TIMEOUT`=watcher down / `GRAI_MT5_ROOT` wrong (tester) · `WR_DENY`=allowlist (live) · `BRIDGE_401`=InpBridgeToken · `PROVIDER_*`=ZAI_API_KEY.

## EA inputs that are **not** in `.env`

| EA input | Meaning |
|---|---|
| `InpBridgeURL` | Default `http://127.0.0.1:8765/advise` — must match port |
| `InpBridgeToken` | Must equal `GRAI_BRIDGE_TOKEN` |
| `InpLLMEnabled` | `false` = Path A (no GLM); `true` = call bridge |
| `InpGlmTimeoutMs` | Sync transport timeout ms (WebRequest live / file poll tester; Arm E set uses 5000) |

If the key or URL is wrong, the bridge returns **WAIT** (safe). No profit guarantee.
