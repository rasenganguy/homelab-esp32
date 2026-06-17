#!/bin/bash
# ============================================================
#  homelab-esp32 — Linux/Mac Setup & Flash Script
#  Usage: ./tools/linux/setup.sh
#         ./tools/linux/flash.sh presence-office
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "============================================================"
echo " homelab-esp32 Linux/Mac Setup"
echo "============================================================"
echo ""

# ============================================================
# Check Python
# ============================================================
log_info "Checking Python..."
if ! command -v python3 &>/dev/null; then
    log_error "Python3 not found!"
    echo ""
    echo "Install Python3:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip"
    echo "  Mac:           brew install python3"
    exit 1
fi
log_ok "Python3 found: $(python3 --version)"

# ============================================================
# Install ESPHome
# ============================================================
log_info "Installing ESPHome..."
pip3 install esphome --break-system-packages 2>/dev/null || pip3 install esphome
log_ok "ESPHome installed: $(esphome version)"

# ============================================================
# Install esptool
# ============================================================
log_info "Installing esptool..."
pip3 install esptool --break-system-packages 2>/dev/null || pip3 install esptool
log_ok "esptool installed"

# ============================================================
# Linux: add user to dialout group (serial port access)
# ============================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "Adding user to dialout group (needed for USB serial access)..."
    sudo usermod -aG dialout "$USER"
    log_warn "You must log out and log back in for this to take effect!"
fi

# ============================================================
# Check secrets.yaml
# ============================================================
if [ ! -f "$REPO_ROOT/secrets.yaml" ]; then
    log_warn "secrets.yaml not found — creating from example..."
    cp "$REPO_ROOT/secrets.yaml.example" "$REPO_ROOT/secrets.yaml"
    log_warn "Edit $REPO_ROOT/secrets.yaml with your WiFi and HA details before flashing!"
fi

echo ""
echo "============================================================"
echo " Setup Complete!"
echo ""
echo " Next steps:"
echo "   1. Edit secrets.yaml with your WiFi/HA details"
echo "   2. Connect XIAO ESP32 via USB-C, hold BOOT button"
echo "   3. Run: ./tools/linux/flash.sh presence-office"
echo "============================================================"
echo ""
