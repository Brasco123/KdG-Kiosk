#!/bin/bash
set -euo pipefail

source /usr/share/kdg-kiosk/kiosk-config.sh

RESET_COMMAND="pkill -f $BROWSER"

log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

cleanup() {
    log "Starting cleanup..."
    
    # Remove temporary files
    rm -f "$PIDFILE" "/tmp/kiosk-exit.flag"
    
    # Stop xbindkeys
    pkill xbindkeys 2>/dev/null || true
    setxkbmap -layout $KEYMAP_LANG
    pkill -x "$(basename "$BROWSER")" 2>/dev/null || true
    sleep 0.5
    
    log "Cleanup completed successfully."
}
trap cleanup EXIT

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

# Convert CUSTOM_KEYBIND format (Alt+5) to xbindkeys format (Alt + 5)
XBINDKEYS_KEYBIND=$(echo "$CUSTOM_KEYBIND" | sed 's/+/ + /g')

cat > "$XBINDKEYS_CONFIG" << EOF
"$RESET_COMMAND"
    $XBINDKEYS_KEYBIND
EOF

# Kill any existing xbindkeys process
pkill xbindkeys 2>/dev/null || true
sleep 1

# Start xbindkeys with the new configuration
log "Starting xbindkeys with config: $XBINDKEYS_CONFIG"
xbindkeys -f "$XBINDKEYS_CONFIG"

# Verify xbindkeys is running
if pgrep xbindkeys > /dev/null; then
    log "xbindkeys started successfully"
else
    log "WARNING: xbindkeys failed to start"
fi

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