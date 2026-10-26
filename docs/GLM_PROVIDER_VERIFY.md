# GLM provider verify (before Arm E)

```bash
# Fill repo-root .env (from .env.example), then:
cd python/bridge && python3 verify_provider.py
# Or export GRAI_BASE_URL / ZAI_API_KEY instead of .env
```

Pass = structured JSON validates `grai.glm.v0.1`. Fail → try `GRAI_RESPONSE_FORMAT=none` or different endpoint; do not assume OpenAI-compat parity.

Model/provider/prompt/schema change ⇒ new experiment version.
