#!/bin/bash

# Pad naar de custom keybinding
KEYBIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kiosk-exit/"

# Huidige custom keybindings ophalen
CURRENT=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Als onze binding er nog niet in zit, voeg hem toe
if [[ "$CURRENT" != *"$KEYBIND_PATH"* ]]; then
    if [[ "$CURRENT" == "@as []" ]]; then
        NEW="[\"$KEYBIND_PATH\"]"
    else
        NEW=$(echo "$CURRENT" | sed "s/]$/, \"$KEYBIND_PATH\"]/")
    fi
    echo "Updating custom keybindings to: $NEW"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW"
fi

# Instellen van de keybinding zelf (let op de :)
SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBIND_PATH"

gsettings set "$SCHEMA" name 'Exit Kiosk'
gsettings set "$SCHEMA" command 'touch /tmp/kiosk-exit.flag'
gsettings set "$SCHEMA" binding '<Control><Shift>K'

echo "Keybinding <Ctrl><Shift>K toegevoegd. Deze maakt nu /tmp/kiosk-exit.flag aan."
