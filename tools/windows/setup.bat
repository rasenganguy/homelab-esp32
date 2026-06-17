@echo off
REM ============================================================
REM  homelab-esp32 — Windows Setup Script
REM  Run this ONCE on your Windows PC before doing anything else
REM  Right-click → "Run as Administrator"
REM ============================================================
echo.
echo  ============================================================
echo   homelab-esp32 Windows Setup
echo   This will install everything you need to flash ESP32 boards
echo  ============================================================
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Please right-click this file and choose "Run as Administrator"
    pause
    exit /b 1
)

echo [Step 1/5] Checking for Python...
python --version >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Python not found. Opening download page...
    echo Please install Python 3.11 or newer from https://www.python.org/downloads/
    echo IMPORTANT: Check the box "Add Python to PATH" during installation!
    start https://www.python.org/downloads/
    echo After installing Python, run this script again.
    pause
    exit /b 1
) else (
    python --version
    echo [OK] Python found
)

echo.
echo [Step 2/5] Installing ESPHome...
pip install esphome
if %errorLevel% NEQ 0 (
    echo ERROR: ESPHome install failed. Try running: pip install esphome --user
    pause
    exit /b 1
)
echo [OK] ESPHome installed

echo.
echo [Step 3/5] Installing esptool (for manual flashing if needed)...
pip install esptool
echo [OK] esptool installed

echo.
echo [Step 4/5] Installing CP210x USB driver...
echo This driver lets Windows talk to the ESP32 over USB.
echo.
echo Opening Silabs driver download page...
start https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers?tab=downloads
echo.
echo Download "CP210x Universal Windows Driver" and install it.
echo After installing the driver, continue here.
pause

echo.
echo [Step 5/5] Verifying ESPHome installation...
esphome version
if %errorLevel% NEQ 0 (
    echo ERROR: ESPHome not found in PATH. Try closing and reopening this window.
    pause
    exit /b 1
)
echo [OK] ESPHome is working!

echo.
echo  ============================================================
echo   Setup Complete!
echo.
echo   Next steps:
echo   1. Edit secrets.yaml with your WiFi and HA details
echo   2. Connect your XIAO ESP32-S3 via USB-C
echo   3. Hold the BOOT button on the board, then plug in USB
echo   4. Run: flash-windows.bat presence-office
echo  ============================================================
echo.
pause
