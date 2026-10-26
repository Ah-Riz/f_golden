#!/usr/bin/env python3
"""GRAI file-watcher — Strategy Tester transport.

WebRequest() is banned in the MT5 Strategy Tester (err=4014), so the EA's
tester build exchanges JSON files inside each tester agent sandbox:

  <MT5_ROOT>/Tester/Agent-*/MQL5/Files/grai_bridge/req/<rid>-<nonce>.json
     envelope: {"token": "<InpBridgeToken>", "payload": <advise body>}
  <MT5_ROOT>/Tester/Agent-*/MQL5/Files/grai_bridge/resp/<rid>-<nonce>.json
     the exact dict POST /advise would return (atomic write)

This watcher reuses server.py (token check, call_provider, JSONL audit log).
The EA deletes req on timeout; we delete req after serving; the EA deletes
resp after reading. Nonce in the filename makes stale resp harmless.

Run standalone:  python3 watcher.py [--once]
Or via scripts/run_bridge.sh (HTTP server + watcher together).
"""
from __future__ import annotations

import glob
import json
import os
import sys
import time

from server import API_KEY, TOKEN, _log, _wait, call_provider

MT5_ROOT = os.environ.get(
    "GRAI_MT5_ROOT", "/home/lana/.mt5/drive_c/Program Files/MetaTrader 5"
)
REQ_GLOB = os.path.join(
    MT5_ROOT, "Tester", "Agent-*", "MQL5", "Files", "grai_bridge", "req", "*.json"
)
RESP_GLOB = REQ_GLOB.replace(os.sep + "req" + os.sep, os.sep + "resp" + os.sep, 1)
PURGE_AFTER_S = 600
POLL_S = 0.075


def _agent(req_path: str) -> str:
    try:
        return req_path.split(os.sep + "Tester" + os.sep, 1)[1].split(os.sep, 1)[0]
    except IndexError:
        return "unknown"


def serve(req_path: str) -> None:
    resp_path = req_path.replace(os.sep + "req" + os.sep, os.sep + "resp" + os.sep, 1)
    try:
        with open(req_path, "r", encoding="utf-8") as f:
            envelope = json.load(f)
        if not isinstance(envelope, dict):
            envelope = {}
    except Exception:
        envelope = {}

    payload = envelope.get("payload", {})
    request_id = str(payload.get("request_id", "")) if isinstance(payload, dict) else ""

    if TOKEN and str(envelope.get("token", "")) != TOKEN:
        advice = _wait(request_id, "BRIDGE_AUTH")
        meta = {"failure_code": "BRIDGE_AUTH", "key_configured": bool(API_KEY)}
    else:
        advice, meta = call_provider(payload)
    meta["transport"] = "file"
    meta["agent"] = _agent(req_path)

    os.makedirs(os.path.dirname(resp_path), exist_ok=True)
    tmp = resp_path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(advice, f, ensure_ascii=True)
    os.replace(tmp, resp_path)
    _log({"event": "advise", "request_id": request_id, "meta": meta, "advice": advice})
    os.remove(req_path)


def purge_old() -> None:
    cutoff = time.time() - PURGE_AFTER_S
    for path in glob.glob(REQ_GLOB) + glob.glob(RESP_GLOB):
        try:
            if os.path.getmtime(path) < cutoff:
                os.remove(path)
        except OSError:
            pass


def main() -> None:
    once = "--once" in sys.argv
    print(f"GRAI watcher root={MT5_ROOT}", flush=True)
    purge_old()
    while True:
        try:
            for req in sorted(glob.glob(REQ_GLOB), key=os.path.getmtime):
                try:
                    serve(req)
                except Exception as e:  # noqa: BLE001 — one bad file must not kill the loop
                    print(f"WATCHER_FAIL file={req} err={type(e).__name__}", flush=True)
        except Exception as e:  # noqa: BLE001
            print(f"WATCHER_FAIL loop err={type(e).__name__}", flush=True)
        if once:
            break
        time.sleep(POLL_S)


if __name__ == "__main__":
    main()
