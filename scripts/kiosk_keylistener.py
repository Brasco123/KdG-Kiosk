#!/usr/bin/env python3
from pynput import keyboard
EXIT_FILE = "/tmp/kiosk-exit.flag"
pressed = set()

def on_press(key):
    print(f"Pressed: {key}")
    pressed.add(key)
    ctrl = any(k in pressed for k in (keyboard.Key.ctrl_l, keyboard.Key.ctrl_r))
    shift = any(k in pressed for k in (keyboard.Key.shift, keyboard.Key.shift_r))
    for p in list(pressed):
        if hasattr(p, 'char') and p.char and p.char.lower() == 'k' and ctrl and shift:
            print("Exit combo pressed")
            open(EXIT_FILE, 'w').close()
            return False

def on_release(key):
    pressed.discard(key)

with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
