#!/bin/bash

log() {
    echo "[KEYBIND-DISABLE] $*"
}

# Bekende sneltoetsen uitschakelen
log "Disabling window switching and terminal shortcuts..."
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-group "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-group "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-panels "[]"
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]"

log "Disabling common launchers..."
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys search "[]"

log "Disabling system keys..."
gsettings set org.gnome.settings-daemon.plugins.media-keys logout "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "[]"

log "Disabling super/overlay key..."
gsettings set org.gnome.mutter overlay-key ''

log "✅ All common keybindings disabled."
