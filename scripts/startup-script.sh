#!/bin/bash

source scripts/kiosk-config.sh

# Functie gebruikt om logs te bewaren
log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

cleanup() {
    rm -f "$PIDFILE" "/tmp/kiosk-exit.flag"
    kill "$KEYLISTENER_PID" 2>/dev/null
    pkill -x "$(basename $BROWSER)" 2>/dev/null
    log "Cleanup done."
}
trap cleanup EXIT


# Zal nakijken of er al een process loopt
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Kiosk is already running." >&2
    exit 1
fi
echo $$ > "$PIDFILE"


# Starten Kiosk
log "Starting kiosk browser..."
$BROWSER --kiosk --new-window "$URL" 2>&1 &
BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"

# Starten keylistener
log "Starting keylistener..."
source venv/bin/activate
echo $KEYLISTENER_SCRIPT
nohup python3 "scripts/kiosk_keylistener.py" >/tmp/kiosk_keylistener.log 2>&1 &
KEYLISTENER_PID=$!
log "Keylistener started with PID $KEYLISTENER_PID" 

# Checken of exit-key gebruikt is
while pgrep -x "$(basename $BROWSER)" >/dev/null; do
    if [[ -f /tmp/kiosk-exit.flag ]]; then
        log "Exit key pressed, stopping kiosk..."
        pkill -x "$(basename $BROWSER)"
        break
    fi
    sleep 1
done

log "Browser closed, kiosk stopped"