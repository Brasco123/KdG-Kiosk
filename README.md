# KdG-Kiosk

A secure kiosk browser solution for Linux with integrated web filtering and keyboard lockdown.

## Overview

KdG-Kiosk is designed for public terminals and kiosk environments. It locks down the system by:
- Running the browser in fullscreen kiosk mode
- Blocking most keyboard shortcuts and function keys (Ctrl, Alt, Windows, Esc, Tab, F-keys)
- Filtering web access through a Squid proxy with whitelist support
- Preventing downloads and access to blocked content
- Providing an easy-to-use GUI setup wizard

## Features

- 🔒 **Keyboard Lockdown**: Disables dangerous key combinations while allowing custom exit keybind
- 🌐 **Web Filtering**: Squid proxy with whitelist-based access control
- 🖥️ **Browser Support**: Works with Chromium and Firefox
- ⚙️ **Easy Setup**: GUI wizard for initial configuration
- 📝 **Comprehensive Logging**: Detailed logs for troubleshooting
- 🔄 **Auto-Recovery**: Automatic browser fallback and dependency checking

## Requirements

- Debian 11+ or Ubuntu 20.04+
- X11 display server (not Wayland)
- Chromium or Firefox
- Python 3.6+
- PyQt5 (for GUI setup wizard - auto-installed if missing)

## Installation

### Quick Install (Recommended)

Download and run the installer with GUI:

```bash
wget https://kdg-kiosk.web.app/install-kdg-kiosk.py
sudo python3 install-kdg-kiosk.py
```

The installer will:
- ✅ Check system compatibility
- ✅ Automatically install missing dependencies (including PyQt5)
- ✅ Download the latest release from GitHub
- ✅ Install the `.deb` package
- ✅ Offer to launch the setup wizard

### CLI Installation

If you prefer command-line mode or don't have a GUI:

```bash
sudo python3 install-kdg-kiosk.py --cli
```

### From GitHub Release

Download the latest `.deb` package from [Releases](https://github.com/Brasco123/KdG-Kiosk/releases):

```bash
wget https://github.com/Brasco123/KdG-Kiosk/releases/latest/download/kdg-kiosk_VERSION_amd64.deb
sudo apt install ./kdg-kiosk_*_amd64.deb
```

### What Gets Installed

- `/usr/bin/kdg-kiosk` - Main kiosk launcher
- `/usr/bin/kdg-kiosk-setup` - Setup wizard launcher
- `/usr/share/kdg-kiosk/` - Scripts and configuration
- `/etc/squid/` - Proxy configuration and whitelist
- Desktop shortcuts for easy access

## Configuration

### First-Time Setup

After installation, run the setup wizard:

```bash
kdg-kiosk-setup
```

Or from the applications menu: **KdG Kiosk Setup**

The wizard will guide you through:

1. **Browser Selection**: Choose Chromium or Firefox
2. **Homepage URL**: Set the initial page to display
3. **Proxy Settings**: Configure the filtering proxy (default: 127.0.0.1:3128)
4. **Keyboard Layout**: Choose your keyboard layout for when exiting kiosk mode
5. **Exit Keybind**: Set custom exit key combination (default: Alt+5)
6. **Whitelist Domains**: Add allowed websites

**Tips:**
- Homepage domain is automatically added to whitelist
- Use leading dots for domains to match subdomains (e.g., `.google.com` matches all Google domains)
- Avoid using Escape, Tab, Ctrl, or Windows keys in custom keybinds

### Reconfiguring

Run the setup wizard again anytime to change settings:

```bash
kdg-kiosk-setup
```

All existing settings will be pre-loaded for easy editing.

## Usage

### Starting the Kiosk

Start from command line:

```bash
kdg-kiosk
```

Or use the **KdG Kiosk** desktop shortcut.

### Exiting the Kiosk

Use your configured exit key combination (default: **Alt+5**).

The kiosk will:
1. Close the browser
2. Restore normal keyboard functionality
3. Restore your keyboard layout
4. Clean up temporary files

## Configuration Files

- `/usr/share/kdg-kiosk/kiosk-config.sh` - Main configuration
- `/etc/squid/squid.conf` - Proxy settings
- `/etc/squid/whitelist.acl` - Allowed domains

## Whitelist Format

Domains in `/etc/squid/whitelist.acl` should include a leading dot to match subdomains:

```
.kdg.be
.google.com
```

After modifying the whitelist, restart Squid:

```bash
sudo systemctl restart squid
```

## Building from Source

```bash
cd kdg-kiosk
dpkg-buildpackage -us -uc -b
sudo dpkg -i ../kdg-kiosk_*.deb
```

## Troubleshooting

### Check Logs

View kiosk logs in real-time:

```bash
tail -f /tmp/kiosk.log
```

Or view the full log:

```bash
cat /tmp/kiosk.log
```

The log contains:
- Startup sequence details
- Browser launch information
- Exit events
- Error messages

### Common Issues

#### 1. Setup Wizard Doesn't Open

**Symptoms**: Running `kdg-kiosk-setup` does nothing or shows errors.

**Solutions**:
```bash
# Check if PyQt5 is installed
python3 -c "import PyQt5" && echo "PyQt5 OK" || sudo apt install python3-pyqt5

# Check DISPLAY variable
echo $DISPLAY  # Should show :0 or similar

# Run wizard manually
python3 /usr/share/kdg-kiosk/setup_wizard.py
```

#### 2. Kiosk Doesn't Start

**Symptoms**: Running `kdg-kiosk` but no browser appears.

**Solutions**:
```bash
# Check if config exists
cat /usr/share/kdg-kiosk/kiosk-config.sh

# If missing, run setup
kdg-kiosk-setup

# Check if browser is installed
which chromium
which firefox

# Check logs for errors
tail -n 50 /tmp/kiosk.log
```


### Complete Reinstallation

If issues persist, try a complete reinstall:

```bash
# Remove existing installation
sudo apt remove --purge kdg-kiosk

# Clean up
sudo rm -rf /usr/share/kdg-kiosk/
sudo rm -f /usr/bin/kdg-kiosk
sudo rm -f /usr/bin/kdg-kiosk-setup
rm -f ~/.xbindkeysrc_kiosk
rm -f ~/.xmodmap-default

# Reinstall
wget https://kdg-kiosk.web.app/install-kdg-kiosk.py
sudo python3 install-kdg-kiosk.py

# Configure
kdg-kiosk-setup

# Test
kdg-kiosk
```

## Advanced Configuration

### Manual Configuration

If you prefer manual configuration or the wizard doesn't work:

**Edit main config**:
```bash
sudo nano /usr/share/kdg-kiosk/kiosk-config.sh
```

**Edit whitelist**:
```bash
sudo nano /etc/squid/whitelist.acl
```

**Restart services**:
```bash
sudo systemctl restart squid
```

### Environment Variables

The kiosk uses these environment variables (set in `/usr/share/kdg-kiosk/kiosk-config.sh`):

- `BROWSER`: Browser to use (`chromium`, `firefox`)
- `URL`: Homepage URL
- `PROXY_IP`: Proxy server IP (default: 127.0.0.1)
- `PROXY_PORT`: Proxy server port (default: 3128)
- `CUSTOM_KEYBIND`: Exit key combination (format: `Alt+5`, no spaces)
- `KEYMAP_LANG`: Keyboard layout to restore on exit (e.g., `be`, `us`, `fr`)

### Locked Keys

The following keys are disabled during kiosk mode:
- **Control** (left and right)
- **Windows/Super** (left and right)
- **Escape**
- **Tab**
- **F1-F12** (except F8 for kiosk exit key detection)

Alt keys remain enabled to allow for custom keybinds.

## Project Structure

```
kdg-kiosk/
├── scripts/
│   ├── startup-script.sh      # Main kiosk launcher
│   ├── kiosk-config.sh         # Configuration variables
│   ├── setup_wizard.py         # PyQt5 setup wizard GUI
│   ├── kdg-kiosk-setup         # Setup wizard launcher
│   ├── kdg-kiosk               # Main entry point
│   ├── squid.conf.template     # Squid proxy template
│   └── squid/
│       └── whitelist.acl       # Default whitelist
├── debian/                     # Debian package metadata
│   ├── control                 # Package dependencies
│   ├── postinst                # Post-installation script
│   └── install                 # File installation mapping
├── kiosk.desktop              # Application launcher
├── setup-kiosk.desktop        # Setup wizard launcher
└── install-kdg-kiosk.py       # Standalone installer
```
## Security Considerations

- The kiosk disables most keyboard shortcuts but **cannot prevent** physical access attacks
- Users with physical access could potentially reboot or access TTY
- Consider physical security measures for public terminals
- Whitelist only trusted domains
- Regularly review `/var/log/squid/access.log` for unusual activity
- Keep the system and browsers updated