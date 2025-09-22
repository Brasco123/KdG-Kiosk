# KdG-Kiosk

## Kiosk Mode

### Bestanden
- `scripts/startkiosk.sh`: Start Chromium of Firefox in kiosk-modus op basis van `kiosk.conf`
- `scripts/exitkiosk.sh`: Sluit de browser via een toetscombinatie (`Alt + q`)
- `scripts/kiosk.conf`: Configuratiebestand (URL en browser)
- `~/.xbindkeysrc`: Sneltoets om kiosk-modus te verlaten
- `~/.config/autostart/Kiosk.desktop`: Autostart bij login

### Toetscombinatie
> `Alt + q` om kioskmodus te verlaten

### Requirements
- Chromium of Firefox
- `xbindkeys` geïnstalleerd
