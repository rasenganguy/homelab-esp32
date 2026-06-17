#!/bin/bash
# ============================================================
#  Flash an ESP32 node — Linux/Mac
#  Usage: ./tools/linux/flash.sh <node-name>
#  Example: ./tools/linux/flash.sh presence-office
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NODE="$1"

if [ -z "$NODE" ]; then
    echo ""
    echo "Usage: $0 <node-name>"
    echo ""
    echo "Available nodes:"
    echo "  presence-office         (room presence - office)"
    echo "  presence-livingroom     (room presence - living room)"
    echo "  presence-bedroom        (room presence - bedroom)"
    echo "  seeed-mmwave-kitchen    (Seeed 24GHz mmWave)"
    echo "  air-quality-main        (air quality monitor)"
    echo "  thermal-sensor-office   (thermal presence)"
    echo "  c6-env-monitor          (ESP32-C6 env monitor)"
    echo ""
    exit 1
fi

# Find config file
CONFIG_FILE=""
for dir in presence-sensor air-quality-monitor thermal-presence esp32-c6-gateway; do
    if [ -f "$REPO_ROOT/$dir/esphome/$NODE.yaml" ]; then
        CONFIG_FILE="$REPO_ROOT/$dir/esphome/$NODE.yaml"
        break
    fi
done

if [ -z "$CONFIG_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Could not find config for node: $NODE"
    exit 1
fi

# Check secrets
if [ ! -f "$REPO_ROOT/secrets.yaml" ]; then
    echo -e "${RED}[ERROR]${NC} secrets.yaml not found! Copy secrets.yaml.example and fill it in."
    exit 1
fi

echo ""
echo "============================================================"
echo " Flashing: $NODE"
echo " Config:   $CONFIG_FILE"
echo "============================================================"
echo ""

# Detect serial port
echo -e "${YELLOW}Detecting connected ESP32...${NC}"
PORTS=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true)
if [ -z "$PORTS" ]; then
    echo -e "${RED}[ERROR]${NC} No serial device found!"
    echo ""
    echo "Make sure:"
    echo "  1. USB cable is plugged in"
    echo "  2. You held the BOOT button when plugging in"
    echo "  3. You ran setup.sh and logged out/in to get dialout access"
    echo ""
    echo "Try: ls /dev/ttyUSB* /dev/ttyACM*"
    exit 1
fi
echo -e "${GREEN}Found:${NC} $PORTS"
echo ""

echo "Starting flash... (1-2 minutes, don't unplug!)"
echo ""

cd "$REPO_ROOT"
esphome run "$CONFIG_FILE" --no-logs

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN} SUCCESS! $NODE flashed!${NC}"
    echo ""
    echo " The board will restart and connect to your WiFi."
    echo " Check Home Assistant > Settings > Devices & Services"
    echo " in a few minutes — the device will appear automatically."
    echo -e "${GREEN}============================================================${NC}"
else
    echo ""
    echo -e "${RED}[ERROR]${NC} Flash failed! See output above."
    echo ""
    echo "Common fixes:"
    echo "  - Hold BOOT button when plugging in USB"
    echo "  - Run: sudo usermod -aG dialout \$USER  then log out/in"
    echo "  - Check secrets.yaml has correct WiFi SSID/password"
fi
echo ""
