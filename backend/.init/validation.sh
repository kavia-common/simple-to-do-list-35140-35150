#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/simple-to-do-list-35140-35150/backend"
cd "$WS"
# Source local env if present (non-login scripts)
set +u; [ -f "$WS/.env" ] && source "$WS/.env" || true; set -u
# Activate venv (assumes prior env step created .venv)
. "$WS"/.venv/bin/activate
# Ensure Django settings env
export DJANGO_SETTINGS_MODULE=project.settings
export DJANGO_DEBUG="${DJANGO_DEBUG:-True}"
export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-dev-secret-key-please-change}"
# Run migrations
python manage.py migrate --noinput
LOG="$WS/server.log"
: >"$LOG"
# start server without autoreload in background
setsid python manage.py runserver 0.0.0.0:8000 --noreload >"$LOG" 2>&1 &
PID=$!
if ! printf '%s' "$PID" | grep -qE '^[0-9]+$'; then echo "Invalid PID" >&2; exit 3; fi
# wait for server to respond
MAX_WAIT=20
SLEEP=1
UP=0
for i in $(seq 1 $MAX_WAIT); do
  sleep $SLEEP
  if curl -sS --max-time 2 --fail http://127.0.0.1:8000/ >/dev/null 2>&1; then UP=1; break; fi
done
if [ $UP -ne 1 ]; then
  echo "server failed to respond; tail of log:" >&2
  tail -n 200 "$LOG" >&2 || true
  kill -TERM -$PID >/dev/null 2>&1 || true; sleep 1; kill -KILL -$PID >/dev/null 2>&1 || true
  exit 2
fi
# evidence: print first lines of response and tail log
curl -sS --max-time 5 --fail http://127.0.0.1:8000/ | head -n 10
tail -n 50 "$LOG" | sed -n '1,50p'
# graceful shutdown
kill -TERM -$PID >/dev/null 2>&1 || true
for i in $(seq 1 10); do
  if ! kill -0 $PID 2>/dev/null; then break; fi
  sleep 1
done
if kill -0 $PID 2>/dev/null; then kill -KILL -$PID >/dev/null 2>&1 || true; fi
wait $PID 2>/dev/null || true
echo "validation completed"
