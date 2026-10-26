#!/usr/bin/env bash
# Start GRAI localhost bridge (Arm E / Path B). Foreground — Ctrl+C to stop.
# Usage: bash scripts/run_bridge.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${GRAI_BRIDGE_PORT:-8765}"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "WARN: $ROOT/.env missing — copy from .env.example and fill keys (see docs/ENV.md)"
else
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/.env"
  set +a
fi

if [[ -n "${GRAI_BRIDGE_PORT:-}" ]]; then
  PORT="$GRAI_BRIDGE_PORT"
fi

export GRAI_MT5_ROOT="${GRAI_MT5_ROOT:-/home/lana/.mt5/drive_c/Program Files/MetaTrader 5}"

echo "GRAI bridge → http://127.0.0.1:${PORT}"
echo "  health:    http://127.0.0.1:${PORT}/health"
echo "  advise:    POST http://127.0.0.1:${PORT}/advise  (browser GET → 404 is OK)"
echo "  MT5 live:  allow WebRequest http://127.0.0.1:${PORT} (charts only — tester bans WebRequest)"
echo "  MT5 test:  watcher serves \${GRAI_MT5_ROOT}/Tester/Agent-*/MQL5/Files/grai_bridge"
echo "  EA token:  InpBridgeToken must match GRAI_BRIDGE_TOKEN (never logged)"
echo "Ctrl+C to stop."
echo

cd "$ROOT/python/bridge"
python3 watcher.py &
WATCHER_PID=$!
python3 server.py &
SERVER_PID=$!
trap 'kill $SERVER_PID $WATCHER_PID 2>/dev/null' INT TERM EXIT
wait -n
STATUS=$?
kill $SERVER_PID $WATCHER_PID 2>/dev/null
exit $STATUS
