# GLM provider verify + prompt (Arm E / P0)

Schema: `grai.glm.v0.3.4`. Prompt text lives in `python/bridge/server.py` (`call_provider`). Tag: `GRAI_PROMPT_VERSION` (bump when you edit the system string).

## Test ladder

```bash
# 0) secrets — copy .env.example → .env (see docs/ENV.md); never commit .env

# 1) offline schema / fault matrix (bridge optional)
python3 python/bridge/schema.py
python3 python/bridge/hostile_smoke.py

# 2) provider (needs ZAI_API_KEY + GRAI_BASE_URL)
cd python/bridge && python3 verify_provider.py

# 3) bridge + live smoke
bash scripts/run_bridge.sh   # other terminal:
python3 python/bridge/hostile_smoke.py
# health: http://127.0.0.1:8765/health
```

Pass verify = reply validates schema. Fail → try `GRAI_RESPONSE_FORMAT=none` or other endpoint; do not assume OpenAI-compat parity.

Model / provider / prompt text / schema change ⇒ new experiment identity.

## Prompt shape

| Role | Content |
|---|---|
| system | Flat JSON-only: echo `request_id`; `decision` / `direction` / `selected_momentum_id` / `regime_assessment` / `recommended_max_layers` (0..det_max) / `confidence` / `data_quality_status`. No markdown. Advisory only. |
| user | Full EA feature payload JSON (`GRAI_BuildFeatureJson`) |
| API | `temperature=0.1`, `max_tokens=400`, `thinking.disabled`, optional `response_format=json_object` |

Allowed enums: `python/bridge/schema.py`.

## Broken pipe

`BrokenPipeError` while writing `/advise` = client hung up (often `InpGlmTimeoutMs=1000` vs slow GLM). Bridge process usually stays up; EA gets WAIT / timeout. Not a crash. Raise timeout only as a logged experiment change.

## Tester vs live

- **Tester:** WebRequest banned — `scripts/run_bridge.sh` watcher + `GRAI_MT5_ROOT` file exchange.
- **Live chart:** allow WebRequest `http://127.0.0.1:8765`; token must match.

Handoff / next steps: [`DEVICE_HANDOFF.md`](DEVICE_HANDOFF.md).
