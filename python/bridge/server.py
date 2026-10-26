#!/usr/bin/env python3
"""GRAI localhost bridge — no broker orders. API key from env only.

  GRAI_BRIDGE_TOKEN   shared secret for EA header X-GRAI-Token
  ZAI_API_KEY         provider key (optional; without it returns WAIT)
  GRAI_PROVIDER       provider_profile (default zai)
  GRAI_MODEL          model_name (default glm-4.7-flash)
  GRAI_BASE_URL       OpenAI-compatible base URL
  GRAI_RESPONSE_FORMAT  json_object | none  (verify per provider)

Bind: 127.0.0.1:8765
"""
from __future__ import annotations

import hashlib
import json
import os
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from load_dotenv import load_dotenv
from schema import (
    ALLOWED_DQ,
    ALLOWED_DECISIONS,
    ALLOWED_DIRECTIONS,
    ALLOWED_MOMENTUM,
    ALLOWED_REGIME,
    SCHEMA_VERSION,
    validate_advice,
)

load_dotenv()

HOST = "127.0.0.1"
PORT = int(os.environ.get("GRAI_BRIDGE_PORT", "8765"))
TOKEN = os.environ.get("GRAI_BRIDGE_TOKEN", "")
PROVIDER = os.environ.get("GRAI_PROVIDER", "zai")
MODEL = os.environ.get("GRAI_MODEL", "glm-4.7-flash")
BASE_URL = os.environ.get("GRAI_BASE_URL", "").rstrip("/")
RESPONSE_FORMAT = os.environ.get("GRAI_RESPONSE_FORMAT", "json_object")
PROMPT_VERSION = os.environ.get("GRAI_PROMPT_VERSION", "grai.prompt.v0.1")
API_KEY = os.environ.get("ZAI_API_KEY") or os.environ.get("OPENAI_API_KEY") or ""
LOG_PATH = os.environ.get("GRAI_JSONL", "grai_bridge.jsonl")

# z.ai publishes no fixed RPM — limits are per-account/concurrency-based.
# Space provider calls and absorb transient 429s (1302 rate / 1305 overload).
MIN_INTERVAL_MS = int(os.environ.get("GRAI_MIN_INTERVAL_MS", "1000"))
RATE_RETRIES = 3
RATE_BACKOFF_MAX_S = 2.4   # exponential: 0.6, 1.2, 2.4 — worst case inside EA's 9s budget
_provider_lock = threading.Lock()
_last_call_ts = 0.0
_provider_paused_until = 0.0

# z.ai error-code classes (docs.z.ai/api-reference/api-code.md)
RETRY_CODES = {1302, 1305, 1200, 1230, 1234}                       # transient: backoff+retry
FLUSH_CODES = {1308, 1310, 1316, 1317, 1318, 1319, 1320, 1321}    # quota: wait for next_flush_time
FATAL_CODES = {1113, 1309, 1311, 1314, 1315}                      # billing/plan: no retry


def _zai_code(e) -> tuple:
    """(z.ai error code or 0, next_flush_time epoch or 0.0) from an HTTPError body."""
    try:
        d = json.loads(e.read().decode("utf-8", "replace")).get("error", {})
        code = int(d.get("code") or 0)
        flush = d.get("next_flush_time")
        try:
            flush_at = float(flush)
        except (TypeError, ValueError):
            try:
                flush_at = datetime.fromisoformat(str(flush).replace("Z", "+00:00")).timestamp()
            except Exception:
                flush_at = 0.0
        return code, flush_at
    except Exception:
        return 0, 0.0


def _hash(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()[:16]


def _log(row: dict) -> None:
    row["ts"] = time.time()
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def _wait(request_id: str, code: str) -> dict:
    return {
        "request_id": request_id,
        "decision": "WAIT",
        "direction": "NONE",
        "selected_momentum_id": "NONE",
        "regime_assessment": "UNKNOWN",
        "recommended_max_layers": 0,
        "confidence": 0.0,
        "reason_codes": [code],
        "invalidation_conditions": [],
        "data_quality_status": "VALID",
        "uncertainty_flags": [code],
        "model_requested": MODEL,
        "model_returned": "none",
        "provider": PROVIDER,
        "prompt_version": PROMPT_VERSION,
        "schema_version": SCHEMA_VERSION,
        "failure_code": code,
    }


def call_provider(payload: dict) -> tuple[dict, dict]:
    """Returns (advice_dict, meta). Never raises secrets into meta."""
    request_id = str(payload.get("request_id", ""))
    det_max = int(payload.get("deterministic_max_layers", 0))
    meta = {
        "provider": PROVIDER,
        "model_requested": MODEL,
        "base_url_set": bool(BASE_URL),
        "response_format": RESPONSE_FORMAT,
        "prompt_version": PROMPT_VERSION,
        "schema_version": SCHEMA_VERSION,
        "input_hash": _hash(json.dumps(payload, sort_keys=True)),
    }
    meta["key_configured"] = bool(API_KEY)
    if not API_KEY or not BASE_URL:
        advice = _wait(request_id, "PROVIDER_UNAVAILABLE")
        meta["latency_ms"] = 0
        meta["model_returned"] = "none"
        meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
        return advice, meta

    # OpenAI-compatible chat.completions — structured output is provider-specific.
    body = {
        "model": MODEL,
        "temperature": 0.1,
        "max_tokens": 400,
        # GLM 4.5+ default to thinking mode: reasoning eats the token budget
        # and content comes back empty/unparseable. Advisory JSON needs none.
        "thinking": {"type": "disabled"},
        "messages": [
            {
                "role": "system",
                "content": (
                    "Return ONLY a flat JSON object with exactly these fields: "
                    "request_id (echo as-is), "
                    f"decision (one of {sorted(ALLOWED_DECISIONS)}), "
                    f"direction (one of {sorted(ALLOWED_DIRECTIONS)}), "
                    f"selected_momentum_id (one of {sorted(ALLOWED_MOMENTUM)}), "
                    f"regime_assessment (one of {sorted(ALLOWED_REGIME)}), "
                    f"recommended_max_layers (integer 0..{det_max}), "
                    "confidence (number 0..1), "
                    f"data_quality_status (one of {sorted(ALLOWED_DQ)}). "
                    "No extra fields, no markdown. "
                    "Advisory only. Never invent credentials."
                ),
            },
            {"role": "user", "content": json.dumps(payload)},
        ],
    }
    if RESPONSE_FORMAT == "json_object":
        body["response_format"] = {"type": "json_object"}

    url = BASE_URL + "/chat/completions"

    # Quota pause (z.ai flush codes): instant WAIT, no API hit, no 9s per bar
    global _last_call_ts, _provider_paused_until
    if time.time() < _provider_paused_until:
        meta["paused_until"] = _provider_paused_until
        meta["model_returned"] = "none"
        advice = _wait(request_id, "PROVIDER_PAUSED")
        meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
        return advice, meta

    # Serialize + space provider calls (fast errors keep retry path inside the
    # EA's timeout budget; slow timeouts don't retry)
    throttle_ms = 0
    with _provider_lock:
        now = time.time()
        wait_s = _last_call_ts + MIN_INTERVAL_MS / 1000.0 - now
        if wait_s > 0:
            time.sleep(wait_s)
            throttle_ms = int((time.time() - now) * 1000)
        _last_call_ts = time.time()
    meta["throttle_ms"] = throttle_ms

    t0 = time.time()
    retries = 0
    while True:
        req = urllib.request.Request(
            url,
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {API_KEY}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=8) as resp:
                raw = resp.read().decode("utf-8")
            break
        except urllib.error.HTTPError as e:
            code, flush_at = _zai_code(e)
            if code:
                meta["provider_code"] = code
            if code in FLUSH_CODES:
                # Quota exhausted until next_flush_time — stop calling the API
                _provider_paused_until = flush_at if flush_at > time.time() else time.time() + 300
                meta["paused_until"] = _provider_paused_until
                advice = _wait(request_id, "PROVIDER_PAUSED")
                meta["latency_ms"] = int((time.time() - t0) * 1000)
                meta["http_status"] = int(e.code)
                meta["retries"] = retries
                meta["model_returned"] = "none"
                meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
                return advice, meta
            if (e.code == 429 or e.code >= 500 or code in RETRY_CODES) and retries < RATE_RETRIES:
                retries += 1
                time.sleep(min(0.6 * (2 ** (retries - 1)), RATE_BACKOFF_MAX_S))
                continue
            # Provider HTTP (401/403 = API key, FATAL_CODES = billing/plan), never confuse with BRIDGE_AUTH
            advice = _wait(request_id, "PROVIDER_HTTP")
            meta["latency_ms"] = int((time.time() - t0) * 1000)
            meta["http_status"] = int(e.code)
            meta["error"] = "HTTPError"
            meta["retries"] = retries
            meta["model_returned"] = "none"
            meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
            return advice, meta
        except Exception as e:  # noqa: BLE001 — bridge must never crash EA path
            advice = _wait(request_id, "PROVIDER_ERROR")
            meta["latency_ms"] = int((time.time() - t0) * 1000)
            meta["error"] = type(e).__name__
            meta["retries"] = retries
            meta["model_returned"] = "none"
            meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
            return advice, meta

    latency = int((time.time() - t0) * 1000)
    meta["latency_ms"] = latency
    meta["retries"] = retries
    try:
        envelope = json.loads(raw)
        model_returned = envelope.get("model") or "unknown"
        msg = envelope["choices"][0]["message"]
        content = msg.get("content") or msg.get("reasoning_content") or ""
        # Models often wrap JSON in ```json fences despite instructions
        if content.lstrip().startswith("```"):
            parts = content.lstrip().split("\n", 1)
            content = parts[1] if len(parts) > 1 else parts[0]
            content = content.rsplit("```", 1)[0]
        advice = json.loads(content)
    except Exception:
        advice = _wait(request_id, "LLM_SCHEMA_FAIL")
        meta["model_returned"] = "unknown"
        meta["output_hash"] = _hash(raw)
        return advice, meta

    ok, reason = validate_advice(advice, request_id, det_max)
    if not ok:
        advice = _wait(request_id, "LLM_SCHEMA_FAIL")
        advice["uncertainty_flags"] = [reason]
    advice["model_requested"] = MODEL
    advice["model_returned"] = model_returned
    advice["provider"] = PROVIDER
    advice["prompt_version"] = PROMPT_VERSION
    advice["schema_version"] = SCHEMA_VERSION
    meta["model_returned"] = model_returned
    meta["output_hash"] = _hash(json.dumps(advice, sort_keys=True))
    return advice, meta


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter
        return

    def _auth_ok(self) -> bool:
        if not TOKEN:
            return True
        return self.headers.get("X-GRAI-Token") == TOKEN

    def do_GET(self):  # noqa: N802
        if self.path.startswith("/health"):
            body = json.dumps(
                {
                    "ok": True,
                    "provider": PROVIDER,
                    "model": MODEL,
                    "schema_version": SCHEMA_VERSION,
                    "key_configured": bool(API_KEY),
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_error(404)

    def _send_json(self, status: int, obj: dict) -> None:
        out = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

    def do_POST(self):  # noqa: N802
        if self.path != "/advise":
            self.send_error(404)
            return
        n = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(n).decode("utf-8")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {}
        request_id = str(payload.get("request_id", ""))
        if not self._auth_ok():
            print("AUTH_FAIL path=/advise", flush=True)
            advice = _wait(request_id, "BRIDGE_AUTH")
            _log(
                {
                    "event": "advise",
                    "request_id": request_id,
                    "meta": {
                        "failure_code": "BRIDGE_AUTH",
                        "key_configured": bool(API_KEY),
                    },
                    "advice": advice,
                }
            )
            # HTTP 200 + failure_code so EA WebRequest always gets parseable JSON
            self._send_json(200, advice)
            return
        advice, meta = call_provider(payload)
        _log({"event": "advise", "request_id": request_id, "meta": meta, "advice": advice})
        self._send_json(200, advice)


def main() -> None:
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"GRAI bridge http://{HOST}:{PORT} provider={PROVIDER} model={MODEL}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
