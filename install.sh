#!/bin/bash
# KdG Kiosk Quick Installer
# This script downloads and runs the Python installer

set -e

REPO_RAW="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/KdG-Kiosk/main"
INSTALLER_URL="$REPO_RAW/install-kdg-kiosk.py"

echo ""
echo "========================================"
echo "  KdG Kiosk Quick Installer"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This installer requires sudo privileges."
    echo ""
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed."
    echo ""
    echo "Installing Python 3..."
    apt update && apt install -y python3
fi

# Download and run installer
echo "📥 Downloading installer..."
TMP_INSTALLER=$(mktemp --suffix=.py)

if command -v wget &> /dev/null; then
    wget -q -O "$TMP_INSTALLER" "$INSTALLER_URL"
elif command -v curl &> /dev/null; then
    curl -sSL -o "$TMP_INSTALLER" "$INSTALLER_URL"
else
    echo "❌ Neither wget nor curl is available. Please install one of them."
    exit 1
fi

echo "🚀 Running installer..."
echo ""

# Run the installer
python3 "$TMP_INSTALLER" "$@"

# Cleanup
rm -f "$TMP_INSTALLER"

echo ""
echo "Done!"

