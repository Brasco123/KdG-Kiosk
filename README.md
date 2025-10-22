# KdG-Kiosk

A secure kiosk browser solution for Linux with integrated web filtering and keyboard lockdown.

## Overview

KdG-Kiosk is designed for public terminals and kiosk environments. It locks down the system by:
- Running the browser in fullscreen kiosk mode
- Blocking most keyboard shortcuts and function keys
- Filtering web access through a Squid proxy with whitelist support
- Preventing downloads and access to blocked content

## Requirements

- Debian 11+ or Ubuntu 20.04+
- X11 display server
- Chromium or Firefox
- Python 3.6+

## Installation

### Quick Install

```bash
wget -qO- https://kdg-kiosk.web.app/install.sh | bash
```

### Manual Install

Download and run the installer:

```bash
wget https://kdg-kiosk.web.app/install-kdg-kiosk.py
sudo python3 install-kdg-kiosk.py
```

### From GitHub Release

Download the latest `.deb` package from [Releases](https://github.com/Brasco123/KdG-Kiosk/releases) and install:

```bash
sudo apt install ./kdg-kiosk_*_amd64.deb
```

## Configuration

After installation, run the setup wizard:

```bash
python3 /usr/share/kdg-kiosk/setup_wizard.py
```

Configure:
- Browser choice (Chromium/Firefox)
- Start URL
- Whitelisted domains
- Exit key combination (default: Alt+5)

## Usage

Start the kiosk:

```bash
kdg-kiosk
```

Exit the kiosk using your configured key combination (default: Alt+5).

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

### Check logs

```bash
tail -f /tmp/kiosk.log
```

### Test proxy

```bash
curl -x http://127.0.0.1:3128 https://kdg.be
```

### Verify Squid status

```bash
sudo systemctl status squid
```

### Common Issues

**Proxy errors**: Make sure Squid is running and configured correctly.

**Browser won't start**: Check that DISPLAY is set and X11 is available.

**Whitelist not working**: Verify domains have leading dots and Squid has been restarted.

## Project Structure

```
kdg-kiosk/
├── scripts/
│   ├── startup-script.sh      # Main kiosk launcher
│   ├── kiosk-config.sh         # Configuration variables
│   ├── setup_wizard.py         # Setup wizard
│   ├── squid.conf.template     # Squid proxy template
│   └── kdg-kiosk               # CLI entry point
├── debian/                     # Package metadata
└── kiosk.desktop              # Desktop launcher
```

## License

GPL-3.0

## Contributing

Issues and pull requests welcome on [GitHub](https://github.com/Brasco123/KdG-Kiosk).

