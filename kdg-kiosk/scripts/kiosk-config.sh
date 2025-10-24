#!/bin/bash
# ==========================
# KIOSK CONFIGURATIE
# ==========================

# Browser en URL
export BROWSER="chromium"
export URL="https://www.kdg.be"

# Proxy instellingen
export PROXY_IP="127.0.0.1"
export PROXY_PORT="3128"
export PROXY_URL="http://${PROXY_IP}:${PROXY_PORT}"

# Squid template en config pad
export SQUID_TEMPLATE="/etc/squid/conf.d/squid.conf.template"
export SQUID_CONFIG="/etc/squid/squid.conf"

# Logging en PID
export LOGFILE="/tmp/kiosk.log"
export PIDFILE="/tmp/kiosk-main.pid"

# Keylistener/keyboard
export DEFAULT_KEYMAP_FILE="$HOME/.xmodmap-default"
export XBINDKEYS_CONFIG="$HOME/.xbindkeysrc_kiosk"
export KEYMAP_LANG="be"

# HTML pagina’s (voor HTTP-blokkades, optioneel)
export BLOCKED_PAGE_URL="http://${PROXY_IP}/blocked.html"
export DENIED_PAGE_URL="http://${PROXY_IP}/denied.html"

export CUSTOM_KEYBIND="Alt + 5"