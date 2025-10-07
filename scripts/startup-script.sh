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
cat > "$XBINDKEYS_CONFIG" << EOF
# Key combination to exit kiosk mode (F11 + F12)
"$RESET_COMMAND"
    F11 + F12
EOF

xbindkeys -f "$XBINDKEYS_CONFIG"

# Clearing modifiers
log "Clearing modifiers..."
xmodmap -e "clear shift"
xmodmap -e "clear control"
xmodmap -e "clear mod1"  # Alt
xmodmap -e "clear mod4"  # Super/Windows

# Unbinding keys
log "Unbinding keys..."
xmodmap -e "keycode 50 = NoSymbol"    # Shift_L
xmodmap -e "keycode 62 = NoSymbol"    # Shift_R
xmodmap -e "keycode 37 = NoSymbol"    # Control_L
xmodmap -e "keycode 105 = NoSymbol"   # Control_R
xmodmap -e "keycode 64 = NoSymbol"    # Alt_L
xmodmap -e "keycode 108 = NoSymbol"   # Alt_R
xmodmap -e "keycode 133 = NoSymbol"   # Super_L
xmodmap -e "keycode 134 = NoSymbol"   # Super_R
xmodmap -e "keycode 9 = NoSymbol"     # Escape

# Disabling F-keys
log "Disabling F-keys..."
for i in {67..76}; do
    xmodmap -e "keycode $i = NoSymbol"
done

# ========================
# BROWSER STARTEN
# ========================
log "Starting Kiosk Browser via proxy $PROXY_URL ..."
"$BROWSER" \
  --kiosk \
  --incognito \
  --proxy-server="$PROXY_URL" \
  --new-window "$URL" 2>&1 &

BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"
wait $BROWSER_PID

# Restore keys na afsluiten
log "Restoring keys..."
pkill xbindkeys 2>/dev/null
setxkbmap -layout be
log "Keyboard layout restored."

log "Browser closed, kiosk stopped."


