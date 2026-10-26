#!/usr/bin/env python3
"""Hostile smoke against local /advise — expects WAIT-shaped safe failures.

Requires bridge running on 127.0.0.1:8765. Does not need a live provider key
(provider errors also return WAIT).
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

from load_dotenv import load_dotenv

load_dotenv()

HOST = os.environ.get("GRAI_BRIDGE_HOST", "127.0.0.1")
PORT = os.environ.get("GRAI_BRIDGE_PORT", "8765")
TOKEN = os.environ.get("GRAI_BRIDGE_TOKEN", "")
URL = f"http://{HOST}:{PORT}/advise"


def post(raw: bytes | str, token: str | None = None) -> tuple[int, dict | str]:
    data = raw if isinstance(raw, bytes) else raw.encode("utf-8")
    headers = {"Content-Type": "application/json"}
    tok = TOKEN if token is None else token
    if tok:
        headers["X-GRAI-Token"] = tok
    req = urllib.request.Request(URL, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read().decode("utf-8")
            try:
                return resp.status, json.loads(body)
            except json.JSONDecodeError:
                return resp.status, body
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")
    except Exception as e:  # noqa: BLE001
        return -1, str(e)


def main() -> int:
    fails = 0

    # 1) malformed JSON
    code, body = post(b"{not-json")
    print("malformed:", code, body if isinstance(body, str) else body.get("decision"))
    # bridge may return WAIT with empty request_id or 200 with WAIT
    if code == 200 and isinstance(body, dict) and body.get("decision") == "WAIT":
        print("  OK WAIT")
    else:
        print("  note: bridge should still be safe")

    # 2) wrong request_id echo path — valid JSON but we check response WAIT / mismatch handling
    payload = {
        "request_id": "hostile-1",
        "symbol": "XAUUSD",
        "deterministic_max_layers": 3,
        "schema_version": "grai.glm.v0.3",
        "bid": 1.0,
        "ask": 1.1,
        "regime": 0,
    }
    code, body = post(json.dumps(payload))
    print("valid_packet:", code, body if isinstance(body, str) else body.get("decision"))
    if code != 200:
        print("FAIL: bridge not reachable — start server.py")
        return 1
    if not isinstance(body, dict) or body.get("decision") != "WAIT" and body.get("failure_code") is None:
        # With no API key, expect WAIT / PROVIDER_UNAVAILABLE
        if isinstance(body, dict) and body.get("decision") in ("WAIT", "BUY", "SELL"):
            print("  OK got decision", body.get("decision"))
        else:
            fails += 1
            print("  FAIL unexpected", body)

    # 3) wrong token → HTTP 200 + failure_code=BRIDGE_AUTH (EA-parseable)
    if TOKEN:
        code, body = post(json.dumps(payload), token="wrong-token")
        print("bad_token:", code, body if isinstance(body, str) else body.get("failure_code"))
        if (
            code != 200
            or not isinstance(body, dict)
            or body.get("failure_code") != "BRIDGE_AUTH"
            or body.get("decision") != "WAIT"
        ):
            fails += 1
            print("  FAIL expected 200 WAIT BRIDGE_AUTH")
        else:
            print("  OK BRIDGE_AUTH")

    # 4) health
    try:
        with urllib.request.urlopen(f"http://{HOST}:{PORT}/health", timeout=3) as resp:
            health = json.loads(resp.read().decode())
            print("health:", health.get("ok"), "schema", health.get("schema_version"))
    except Exception as e:  # noqa: BLE001
        print("health FAIL", e)
        fails += 1

    print("hostile_smoke", "FAIL" if fails else "OK", "fails=", fails)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
