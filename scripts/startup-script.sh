#!/bin/bash
set -euo pipefail

source ~/Documenten/Scripts/kiosk-config.sh

log() {
  local ts
  ts="$(date '+%F %T')"
  echo "[$ts] $*" | tee -a "$LOGFILE"
}

cleanup() {
  rm -f "$PIDFILE" "/tmp/kiosk-exit.flag"
  [[ -n "${KEYLISTENER_PID:-}" ]] && kill "$KEYLISTENER_PID" 2>/dev/null || true
  pkill -x "$(basename "$BROWSER")" 2>/dev/null || true
  log "Cleanup done."
}
trap cleanup EXIT

# Al draaiende?
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Kiosk is already running." >&2
  exit 1
fi
echo $$ > "$PIDFILE"


# Genereer actuele Squid-config uit template
if [[ -f "$SQUID_TEMPLATE" ]]; then
  log "Generating Squid configuration from template..."
  envsubst < "$SQUID_TEMPLATE" | sudo tee "$SQUID_CONFIG" > /dev/null
  sudo systemctl restart squid
  log "Squid configuration applied and service restarted."
else
  log "Warning: Squid template not found at $SQUID_TEMPLATE"
fi



# Start Chromium in kiosk via proxy
log "Starting kiosk browser via proxy $PROXY_URL ..."
"$BROWSER" \
  --kiosk \
  --incognito \
  --proxy-server="$PROXY_URL" \
  --new-window "$URL" 2>&1 &
BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"

# Start keylistener
log "Starting keylistener..."
nohup python3 "$KEYLISTENER_SCRIPT" >/tmp/kiosk_keylistener.log 2>&1 &
KEYLISTENER_PID=$!
log "Keylistener started with PID $KEYLISTENER_PID"

# Wacht tot browser stopt of exit-flag gezet is
while pgrep -x "$(basename "$BROWSER")" >/dev/null; do
  if [[ -f /tmp/kiosk-exit.flag ]]; then
    log "Exit key pressed, stopping kiosk..."
    pkill -x "$(basename "$BROWSER")"
    break
  fi
  sleep 1
done

log "Browser closed, kiosk stopped"
