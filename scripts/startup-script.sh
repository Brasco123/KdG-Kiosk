#!/bin/bash

#!/bin/bash

# Pad naar configbestand
CONFIG="/home/christoph/Documenten/Scripts/kiosk.conf"

# Configbestand inlezen
if [ -f "$CONFIG" ]; then
    source "$CONFIG"
else
    echo "Configuratiebestand niet gevonden: $CONFIG"
    exit 1
fi

# Fallbacks als iets ontbreekt
: "${URL:=https://www.kdg.be}"
: "${BROWSER:=chromium}"

# Browser starten
case "$BROWSER" in
  chromium)
    chromium-browser --kiosk "$URL"
    ;;
  firefox)
    firefox --kiosk "$URL"
    ;;
  *)
    echo "Ongeldige browser: $BROWSER"
    exit 1
    ;;
esac








## chromium-browser --kiosk https://www.kdg.be
