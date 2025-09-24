#!/bin/bash

source scripts/kiosk-config.sh
./scripts/keys/disbale_keys.sh
./scripts/keys/keybind.sh

EXT_PATH="./scripts/chrome-extensions/"

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
    ./scripts/keys/enable_keys.sh
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
EXT_PATH="/home/tibo/Documents/IP/KdG-Kiosk/scripts/chrome-extension"
$BROWSER  \
  --app="$URL" \
  --load-extension="$EXT_PATH" \
  --kiosk \
  --incognito \
  --noerrdialogs \
  --disable-translate \
  --overscroll-history-navigation=0 \
  --disable-pinch \
  --disable-features=TranslateUI,AutofillServerCommunication,BookmarkSuggestions \
  --disable-background-mode \
  --disable-breakpad \
  --disable-session-crashed-bubble \
  --disable-sync \
  --disable-print-preview \
  --no-first-run \
  --no-default-browser-check 2>&1 &

BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"

for i in {1..10}; do
    if kill -0 "$BROWSER_PID" 2>/dev/null; then
        break
    fi
    sleep 1
done

# Checken of exit-key gebruikt is
while kill -0 "$BROWSER_PID" 2>/dev/null; do
    if [[ -f /tmp/kiosk-exit.flag ]]; then
        log "Exit key pressed, stopping kiosk..."
        kill "$BROWSER_PID"
        break
    fi
    sleep 1
done

log "Browser closed, kiosk stopped"