#!/bin/bash
set -e

source "$(dirname "$0")/kiosk-config.sh"

rm -f "$EXIT_FLAG"

chromium --kiosk --incognito --noerrdialogs \
  --disable-session-crashed-bubble --disable-infobars "$URL" &
CHROMIUM_PID=$!
echo "[*] Chromium gestart met PID $CHROMIUM_PID"

"$(dirname "$0")/kiosk_keylistener.py" &
KEY_PID=$!
echo "[*] Keylistener gestart met PID $KEY_PID"

while kill -0 "$CHROMIUM_PID" 2>/dev/null; do
  if [[ -f "$EXIT_FLAG" ]]; then
    echo "[*] Exit-flag gevonden, Chromium stoppen..."
    kill "$CHROMIUM_PID"
    break
  fi
  sleep 1
done

kill "$KEY_PID" 2>/dev/null
rm -f "$EXIT_FLAG"
echo "[*] Kiosk afgesloten."
