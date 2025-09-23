#!/usr/bin/env python3
import evdev, os

EXIT_FLAG = '/tmp/kiosk-exit.flag'

def find_keyboard():
    for path in evdev.list_devices():
        dev = evdev.InputDevice(path)
        if ('keyboard' in dev.name.lower()
            or 'kbd' in dev.name.lower()
            or 'AT Translated' in dev.name):
            print(f"[keylistener] Using {path} ({dev.name})")
            return dev
    raise RuntimeError("Geen keyboard device gevonden")
    
device = find_keyboard()

KEY_LEFTCTRL = evdev.ecodes.KEY_LEFTCTRL
KEY_RIGHTCTRL = evdev.ecodes.KEY_RIGHTCTRL
KEY_LEFTALT = evdev.ecodes.KEY_LEFTALT
KEY_RIGHTALT = evdev.ecodes.KEY_RIGHTALT
KEY_I = evdev.ecodes.KEY_I

ctrl_pressed = False
alt_pressed = False

print("[keylistener] Listening for Ctrl+Alt+I…")

for event in device.read_loop():
    if event.type == evdev.ecodes.EV_KEY:
        key_event = evdev.categorize(event)
        code = key_event.scancode
        if code in (KEY_LEFTCTRL, KEY_RIGHTCTRL):
            ctrl_pressed = key_event.keystate == 1
        elif code in (KEY_LEFTALT, KEY_RIGHTALT):
            alt_pressed = key_event.keystate == 1
        elif code == KEY_I and key_event.keystate == 1:
            if ctrl_pressed and alt_pressed:
                print("[keylistener] Ctrl+Alt+I pressed, writing flag")
                open(EXIT_FLAG, 'w').close()
                os.chmod(EXIT_FLAG, 0o666)
