#!/bin/bash
set -euo pipefail



source /etc/kdg-kiosk/kiosk-config.sh
# source scripts/kiosk-config.sh

RESET_COMMAND="pkill -f $BROWSER; restore_keys"

log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

cleanup() {
    rm -f "$PIDFILE" "/tmp/kiosk-exit.flag"
    pkill -x "$(basename "$BROWSER")" 2>/dev/null || true
    pkill xbindkeys 2>/dev/null || true
    log "Cleanup done."
}
trap cleanup EXIT

# ========================
# SQUID CONFIG GENEREREN
# ========================
if [[ -f "$SQUID_TEMPLATE" ]]; then
  log "Generating Squid configuration from template..."
  envsubst < "$SQUID_TEMPLATE" | sudo tee "$SQUID_CONFIG" > /dev/null
  sudo systemctl restart squid
  log "Squid configuration applied and service restarted."
else
  log "Warning: Squid template not found at $SQUID_TEMPLATE"
fi

# ========================
# KEYBOARD LOCKDOWN
# ========================
touch "$LOGFILE"

# Default keymap opslaan
if [ ! -f "$DEFAULT_KEYMAP_FILE" ]; then
    log "Saving default keymap to $DEFAULT_KEYMAP_FILE..."
    xmodmap -pke > "$DEFAULT_KEYMAP_FILE"
fi

# Configure xbindkeys
log "Configuring xbindkeys..."
cat > ~/.xbindkeysrc_kiosk << EOF
"$RESET_COMMAND"
    Alt + 5
EOF

xbindkeys -f ~/.xbindkeysrc_kiosk

# Clearing modifiers
log "Clearing modifiers..."
xmodmap -e "clear control"
xmodmap -e "clear mod1" # alt
xmodmap -e "clear mod4" # Super/Windows

# Unbinding keys
log "Unbinding keys..."
xmodmap -e "keycode 37 = NoSymbol"    # Control_L
xmodmap -e "keycode 105 = NoSymbol"   # Control_R
# xmodmap -e "keycode 64 = NoSymbol"   # Alt_L
xmodmap -e "keycode 108 = NoSymbol"   # Alt_R
xmodmap -e "keycode 133 = NoSymbol"   # Super_L
xmodmap -e "keycode 134 = NoSymbol"   # Super_R
xmodmap -e "keycode 9 = NoSymbol"     # Escape
xmodmap -e "keycode 23 = NoSymbol"    # Tab

# Disabling F-keys
log "Disabling F-keys..."
for i in {67..79}; do  # F1..F12
    if [ $i -ne 74 ]; then  # Skip F8 (keycode 74)
        xmodmap -e "keycode $i = NoSymbol"
    fi
done

# ========================
# BROWSER STARTEN
# ========================
log "Starting Kiosk Browser via proxy ${PROXY_URL} ..."
"$BROWSER" \
  --kiosk \
  --incognito \
  --no-first-run \
  --noerrdialogs \
  --disable-infobars \
  --proxy-server="${PROXY_URL}" \
  --new-window "$URL" 2>&1 & 


BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"
wait $BROWSER_PID

# Restore keys na afsluitenlog "Restoring keys..."
pkill xbindkeys 2>/dev/null
setxkbmap -layout be
log "Keyboard layout restored."

log "Browser closed, kiosk stopped."
