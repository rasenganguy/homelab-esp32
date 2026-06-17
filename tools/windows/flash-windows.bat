@echo off
REM ============================================================
REM  Flash an ESP32 node from Windows
REM  Usage: flash-windows.bat <node-name>
REM  Example: flash-windows.bat presence-office
REM           flash-windows.bat air-quality-main
REM           flash-windows.bat thermal-sensor-office
REM           flash-windows.bat c6-env-monitor
REM ============================================================

if "%1"=="" (
    echo.
    echo Usage: flash-windows.bat ^<node-name^>
    echo.
    echo Available nodes:
    echo   presence-office        ^(room presence sensor - office^)
    echo   presence-livingroom    ^(room presence sensor - living room^)
    echo   presence-bedroom       ^(room presence sensor - bedroom^)
    echo   seeed-mmwave-kitchen   ^(Seeed 24GHz mmWave sensor^)
    echo   air-quality-main       ^(air quality monitor^)
    echo   thermal-sensor-office  ^(thermal presence sensor^)
    echo   c6-env-monitor         ^(ESP32-C6 environmental monitor^)
    echo.
    pause
    exit /b 1
)

set NODE=%1
echo.
echo  ============================================================
echo   Flashing node: %NODE%
echo  ============================================================
echo.

REM Check if secrets.yaml exists
if not exist "secrets.yaml" (
    echo ERROR: secrets.yaml not found!
    echo Please copy secrets.yaml.example to secrets.yaml and fill in your details.
    pause
    exit /b 1
)

REM Find the config file
set CONFIG_FILE=""
if exist "presence-sensor\esphome\%NODE%.yaml" set CONFIG_FILE=presence-sensor\esphome\%NODE%.yaml
if exist "air-quality-monitor\esphome\%NODE%.yaml" set CONFIG_FILE=air-quality-monitor\esphome\%NODE%.yaml
if exist "thermal-presence\esphome\%NODE%.yaml" set CONFIG_FILE=thermal-presence\esphome\%NODE%.yaml
if exist "esp32-c6-gateway\esphome\%NODE%.yaml" set CONFIG_FILE=esp32-c6-gateway\esphome\%NODE%.yaml

if %CONFIG_FILE%=="" (
    echo ERROR: Could not find config file for node: %NODE%
    echo Make sure the node name is correct.
    pause
    exit /b 1
)

echo Config file: %CONFIG_FILE%
echo.
echo IMPORTANT: Before clicking OK...
echo   1. Connect your XIAO ESP32 board to this PC via USB-C cable
echo   2. HOLD the BOOT button on the board (small button near USB port)
echo   3. While HOLDING BOOT, plug in the USB cable
echo   4. Release the BOOT button after 2 seconds
echo   5. The board is now in flash mode
echo.
echo Press any key when the board is connected and in flash mode...
pause >nul

echo.
echo Starting flash process... (this takes 1-2 minutes, don't unplug!)
echo.

esphome run %CONFIG_FILE% --no-logs

if %errorLevel% NEQ 0 (
    echo.
    echo ERROR: Flash failed!
    echo.
    echo Common fixes:
    echo   - Did you hold the BOOT button when plugging in? Try again.
    echo   - Wrong COM port? Check Device Manager for the COM port number.
    echo   - Driver not installed? Run tools\windows\setup.bat first.
    echo   - Secrets wrong? Check secrets.yaml has correct WiFi details.
) else (
    echo.
    echo  ============================================================
    echo   SUCCESS! Node %NODE% has been flashed!
    echo.
    echo   The board will restart and connect to your WiFi.
    echo   Check Home Assistant in a few minutes - the device should
    echo   appear automatically under Settings ^> Devices ^& Services.
    echo  ============================================================
)

echo.
pause
