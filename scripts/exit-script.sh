#!/bin/bash
echo "[KIOSK EXIT] $(date) - Browser wordt afgesloten..." >> /tmp/kiosk-exit.log

pkill -f chromium-browser
pkill -f firefox
