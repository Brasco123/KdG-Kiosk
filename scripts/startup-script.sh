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
    $BROWSER --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --no-first-run \
    --fast \
    --fast-start \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    --incognito \
    --disable-session-crashed-bubble \
    --disable-translate \
    --disable-restore-session-state \
    --no-default-browser-check \
    --disable-sync \
    --disable-print-preview \
    --disable-extensions \
    --disable-features=TranslateUI, TabHoverCards, TabGroups \
    "$URL"
    
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
    else
        setxkbmap -layout be
        log "No default keymap file found, keyboard reset to Belgian keyboard layout."
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
# Key combination to exit kiosk mode Pause/Break (Mod3) + VolumeUp
"$RESET_COMMAND"
    F11 + F12
EOF

xbindkeys -f ~/.xbindkeysrc_kiosk

# Clearing modifiers
log "Clearing modifiers..."
xmodmap -e "clear shift"
xmodmap -e "clear control"
xmodmap -e "clear mod1" # alt
xmodmap -e "clear mod4" # Super/Windows

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
for i in {67..76}; do # F1 (67) through F10 (78)
    xmodmap -e "keycode $i = NoSymbol"
done

# Start application
run_kiosk