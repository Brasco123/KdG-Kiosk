#!/bin/bash
set -e

source "$(dirname "$0")/kiosk-config.sh"
rm -f "$EXIT_FLAG"

shortcuts=(
switch-applications
switch-applications-backward
switch-group
switch-group-backward
switch-input-source
switch-input-source-backward
switch-panels
switch-panels-backward
switch-to-workspace-1
switch-to-workspace-10
switch-to-workspace-11
switch-to-workspace-12
switch-to-workspace-2
switch-to-workspace-3
switch-to-workspace-4
switch-to-workspace-5
switch-to-workspace-6
switch-to-workspace-7
switch-to-workspace-8
switch-to-workspace-9
switch-to-workspace-down
switch-to-workspace-last
switch-to-workspace-left
switch-to-workspace-right
switch-to-workspace-up
switch-windows
switch-windows-backward
)

disable() {
  for k in "${shortcuts[@]}"; do
    echo "Disabling $k"
    gsettings set org.gnome.desktop.wm.keybindings "$k" "[]"
  done
}

enable() {
  for k in "${shortcuts[@]}"; do
    echo "Resetting $k"
    gsettings reset org.gnome.desktop.wm.keybindings "$k"
  done
}

disable

chromium --kiosk --incognito --noerrdialogs \
  --disable-session-crashed-bubble --disable-infobars "$URL" &
CHROMIUM_PID=$!
echo "[*] Chromium gestart met PID $CHROMIUM_PID"

python3 "$(dirname "$0")/listener.py" &
KEY_PID=$!
echo "[*] Keylistener gestart met PID $KEY_PID"

while kill -0 "$CHROMIUM_PID" 2>/dev/null; do
  if [[ -f "$EXIT_FLAG" ]]; then
    pkill -9 -f '/snap/chromium/.*/chrome' || true
    kill "$CHROMIUM_PID" 2>/dev/null || true
    break
  fi
  sleep 1
done

kill "$KEY_PID" 2>/dev/null
rm -f "$EXIT_FLAG"
echo "[*] Kiosk afgesloten."

enable
