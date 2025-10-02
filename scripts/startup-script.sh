#!/bin/bash

source scripts/kiosk-config.sh
DEFAULT_KEYMAP_FILE="$HOME/.xmodmap-default"
XBINDKEYS_CONFIG="$HOME/.xbindkeysrc_kiosk"

PAUSE_KEYCODE=127 # Keycode for the pause knop
VOLUME_UP_KEYCODE=123
RESET_KEY_NAME="XF86AudioRaiseVolume"

RESET_COMMAND="pkill -f $BROWSER; restore_keys"

# Functie gebruikt om logs te bewaren
log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

run_kiosk(){
    xbindkeys -f "XBINDKEYS_CONFIG" &
    log "Starting Kiosk Application"
    $BROWSER --kiosk --incognito $URL
    KIOSK_PID=$!
    wait $KIOSK_PID
    pkill xbindkeys 2>/dev/null
    restore_keys
}

restore_keys(){
    log "Restoring keys..."
    pkill xbindkeys 2>/dev/null
    if [ -f $DEFAULT_KEYMAP_FILE ]; then
        xmodmap 
        log "Keymap restored."
    else
        setxkbmap -layout be
        log "No default keymap file found, keyboard reset to Belgian keyboard layout."
    fi
    exit 0
}

# Default keymap opslaan
if [ ! -f "$DEFAULT_KEYMAP_FILE" ]; then
    log "Saving default keymap to $DEFAULT_KEYMAP_FILE..."
    xmodmap -pke > $DEFAULT_KEYMAP_FILE
fi

# Configure xbindkeys
log "Configuring xbindkeys..."
cat > "$XBINDKEYS_CONFIG" << EOF
# Key combination to exit kiosk mode Pause/Break (Mod3) + VolumeUp
"$RESET_COMMAND"
    k
EOF

# Clearing modifiers
log "Clearing modifiers..."
xmodmap -e "clear shift"
xmodmap -e "clear control"
xmodmap -e "clear mod1" # alt
xmodmap -e "clear mod4" # Super/Windows

# Enabling Mod3 - Scroll lock
log "Binding Pause/Break (Keycode $PAUSE_KEYCODE) to Mod3."
xmodmap -e "clear mod3"
xmodmap -e "keycode $PAUSE_KEYCODE = Pause"
xmodmap -e "add mod3 = Pause"

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
for i in {67..78}; do # F1 (67) through F12 (78)
    xmodmap -e "keycode $i = NoSymbol"
done

# Start application
run_kiosk