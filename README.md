# KdG-Kiosk

## 1. Vereisten
Installeer eerst deze packages op Ubuntu:

```bash
sudo apt update
sudo apt install -y chromium python3 python3-venv python3-pip evtest
```

Installeer vervolgens de Python module evdev:

```bash
pip3 install evdev
```
## 2. Runnen

Maak de scripts uitvoerbaar:

```bash
chmod +x scripts/kiosk.sh scripts/kiosk_keylistener.py
```

## 3. Starten
Run vanaf de `scripts` map:

```bash
./kiosk.sh
```

Dit doet:
- Start Chromium in kiosk-modus op de ingestelde URL
- Start een Python-keylistener die op **Ctrl+Alt+I** wacht
- Als je **Ctrl+Alt+I** indrukt, wordt `/tmp/kiosk-exit.flag` aangemaakt en sluit Chromium automatisch

## 3. Mogelijks probleem
- Permissie-fouten op `/tmp/kiosk-exit.flag`? Run `sudo rm /tmp/kiosk-exit.flag` voordat je opnieuw start.
