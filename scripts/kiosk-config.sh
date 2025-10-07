URL="https://www.kdg.be"
EXIT_KEY="Ctrl+Shift+K"
BROWSER="chromium"
PROXY_URL="http://192.168.57.102:3128"
PIDFILE="/tmp/kiosk.pid"
LOGFILE="$HOME/Documenten/Scripts/kiosk.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYLISTENER_SCRIPT="$SCRIPT_DIR/kiosk_keylistener.py"


# Proxy instellingen
export PROXY_IP="192.168.57.102"
export PROXY_PORT="3128"
export PROXY_URL="http://${PROXY_IP}:${PROXY_PORT}"

# Pad naar Squid-template
export SQUID_TEMPLATE="/etc/squid/squid.conf.template"
export SQUID_CONFIG="/etc/squid/squid.conf"

# HTML-pagina’s
export BLOCKED_PAGE_URL="http://${PROXY_IP}/blocked.html"
export DENIED_PAGE_URL="http://${PROXY_IP}/denied.html"
