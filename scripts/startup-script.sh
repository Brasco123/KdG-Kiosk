#!/bin/bash

source scripts/kiosk-config.sh
DEFAULT_KEYMAP_FILE="$HOME/.xmodmap-default"
XBINDKEYS_CONFIG="~/.xbindkeysrc_kiosk"

RESET_COMMAND="pkill -f $BROWSER; restore_keys"

# Functie gebruikt om logs te bewaren
log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

run_kiosk(){
    log "Starting Kiosk Application"
    $BROWSER --kiosk --private-window "$URL" --new-instance --no-remote
    
    KIOSK_PID=$!
    wait $KIOSK_PID
    pkill xbindkeys 2>/dev/null
    restore_keys
}

restore_keys(){
    log "Restoring keys..."
    pkill xbindkeys 2>/dev/null
    if [ -f $DEFAULT_KEYMAP_FILE ]; then
        setxkbmap -layout be
        log "Keymap restored."
    fi
    exit 0
}

touch $LOGFILE

# Default keymap opslaan
if [ ! -f "$DEFAULT_KEYMAP_FILE" ]; then
    log "Saving default keymap to $DEFAULT_KEYMAP_FILE..."
    xmodmap -pke > $DEFAULT_KEYMAP_FILE
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
xmodmap -e "keycode 106 = NoSymbol"   # Alt_L
xmodmap -e "keycode 108 = NoSymbol"   # Alt_R
xmodmap -e "keycode 133 = NoSymbol"   # Super_L
xmodmap -e "keycode 134 = NoSymbol"   # Super_R
xmodmap -e "keycode 9 = NoSymbol"     # Escape
xmodmap -e "keycode 23 = NoSymbol"    # Tab
# Disabling F-keys
log "Disabling F-keys..."
# Disable all F-keys *except F8* for your admin combo
for i in {67..79}; do  # F1..F12
    if [ $i -ne 74 ]; then  # Skip F8 (keycode 74)
        xmodmap -e "keycode $i = NoSymbol"
    fi
done

# Start application
run_kiosk