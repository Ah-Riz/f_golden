#!/usr/bin/env python3
"""Pre-code / pre-Arm-E provider structured-output check.

Runs the REAL bridge path (server.call_provider): thinking-disabled,
fence-strip, reasoning_content fallback, enum uppercase, retries, quota
pause — whatever production does. Does not print secrets.
Exit 0 = pass, 1 = fail/skip.
"""
from __future__ import annotations

import json
import os
import sys

from load_dotenv import load_dotenv
from schema import SCHEMA_VERSION

load_dotenv()

# imported after load_dotenv so server picks up .env
from server import call_provider  # noqa: E402


def main() -> int:
    base = os.environ.get("GRAI_BASE_URL", "").rstrip("/")
    key = os.environ.get("ZAI_API_KEY") or os.environ.get("OPENAI_API_KEY") or ""
    if not base or not key:
        print("SKIP: set GRAI_BASE_URL and ZAI_API_KEY to verify")
        return 1

    payload = {
        "request_id": "verify-1",
        "symbol": "XAUUSD",
        "deterministic_max_layers": 3,
        "schema_version": SCHEMA_VERSION,
    }
    advice, meta = call_provider(payload)
    failure = advice.get("failure_code")
    reason = advice.get("uncertainty_flags", [""])[0] if failure else "ok"
    print(
        json.dumps(
            {
                "ok": failure is None,
                "reason": reason,
                "failure_code": failure,
                "model_requested": meta.get("model_requested"),
                "model_returned": meta.get("model_returned"),
                "latency_ms": meta.get("latency_ms"),
                "retries": meta.get("retries"),
                "provider_code": meta.get("provider_code"),
                "prompt_version": meta.get("prompt_version"),
                "schema_version": SCHEMA_VERSION,
            }
        )
    )
    return 0 if failure is None else 1


if __name__ == "__main__":
    sys.exit(main())
