#!/bin/bash
set -euo pipefail

source /usr/share/kdg-kiosk/kiosk-config.sh

RESET_COMMAND="pkill -f $BROWSER"

log() {
    local ts
    ts="$(date '+%F %T')"
    echo "[$ts] $*" | tee -a "$LOGFILE"
}

# Early logging - ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE" 2>/dev/null || {
    LOGFILE="/tmp/kiosk-fallback.log"
    touch "$LOGFILE"
}

log "=== KdG Kiosk Starting ==="
log "DISPLAY=$DISPLAY"
log "BROWSER=$BROWSER"
log "URL=$URL"

RESET_COMMAND="pkill -f $BROWSER"

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

readonly VERSION="1.0"
readonly SCRIPT_NAME="kdg-kiosk"

usage() {
    cat <<EOF
Gebruik: $SCRIPT_NAME [OPTIES]

Start de KDG Kiosk-browser in beveiligde modus.

Opties:
  --help         Toon deze helptekst en sluit af.
  --version      Toon versie-informatie en sluit af.

Configuratie:
  Dit script gebruikt instellingen uit:
    /usr/share/kdg-kiosk/kiosk-config.sh

EOF
}

# ========================
# ARGUMENT PARSING
# ========================
if [[ $# -gt 0 ]]; then
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --version|-v)
            echo "$SCRIPT_NAME versie $VERSION"
            exit 0
            ;;
        *)
            echo "Onbekende optie: $1" >&2
            echo "Gebruik man $SCRIPT_NAME voor hulp." >&2
            exit 1
            ;;
    esac
fi
trap cleanup EXIT

# ========================
# BROWSER CHECK
# ========================
# Check if browser exists
if ! command -v "$BROWSER" &> /dev/null; then
    log "ERROR: Browser '$BROWSER' not found in PATH"
    log "Available browsers:"
    command -v chromium &> /dev/null && log "  - chromium"
    command -v firefox &> /dev/null && log "  - firefox"
    command -v google-chrome &> /dev/null && log "  - google-chrome"
    
    # Try to find an alternative
    if command -v chromium &> /dev/null; then
        log "Falling back to chromium"
        BROWSER="chromium"
    elif command -v firefox &> /dev/null; then
        log "Falling back to firefox"
        BROWSER="firefox"
    else
        log "ERROR: No supported browser found. Please install chromium or firefox."
        exit 1
    fi
fi

log "Using browser: $BROWSER"

# ========================
# KEYBOARD LOCKDOWN
# ========================
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
if xbindkeys -f "$XBINDKEYS_CONFIG"; then
    log "xbindkeys started successfully"
else
    log "WARNING: xbindkeys failed to start, continuing without key binding"
    exit 1
fi

# Clearing modifiers
log "Clearing modifiers..."
xmodmap -e "clear control"
# xmodmap -e "clear mod1" # alt
xmodmap -e "clear mod4" # Super/Windows

# Unbinding keys
log "Unbinding keys..."
xmodmap -e "keycode 37 = NoSymbol"    # Control_L
xmodmap -e "keycode 105 = NoSymbol"   # Control_R
# xmodmap -e "keycode 64 = NoSymbol"   # Alt_L
# xmodmap -e "keycode 108 = NoSymbol"   # Alt_R
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

# Proxy-env vars voor Firefox
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"

# Kill any existing browser instances to prevent conflicts
log "Checking for existing browser instances..."
pkill -f "$BROWSER" 2>/dev/null || true
sleep 1

if [[ "$BROWSER" == "chromium" || "$BROWSER" == "google-chrome" ]]; then
    log "Launching Chromium/Chrome in kiosk mode..."
    "$BROWSER" \
      --kiosk \
      --incognito \
      --no-first-run \
      --noerrdialogs \
      --disable-infobars \
      --disable-gpu \
      --no-sandbox \
      --disable-dev-shm-usage \
      --disable-software-rasterizer \
      --disable-pdf-extension \
      --proxy-server="${PROXY_URL}" \
      --new-window \
      "$URL" >> "$LOGFILE" 2>&1 &

elif [[ "$BROWSER" == "firefox" ]]; then
    log "Launching Firefox in kiosk mode..."
    # Firefox ondersteunt andere vlaggen
    "$BROWSER" \
      --kiosk \
      "$URL" \
      --safe-mode \
      --no-remote 2>&1 &

else
    log "WARNING: Unsupported browser '$BROWSER'. Falling back to Chromium."
    chromium \
      --kiosk \
      --incognito \
      --disable-gpu \
      --no-sandbox \
      --disable-dev-shm-usage \
      --disable-software-rasterizer \
      --disable-pdf-extension \
      --proxy-server="${PROXY_URL}" \
      "$URL" 2>&1 &
fi

BROWSER_PID=$!
log "Browser started with PID $BROWSER_PID"

# Wait for browser to exit (either normally or by exit key)
log "Kiosk running. Press exit key to stop."
wait $BROWSER_PID
EXIT_CODE=$?
log "Browser exited with code $EXIT_CODE"
