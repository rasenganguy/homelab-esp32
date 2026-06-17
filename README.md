# homelab-esp32

> **ESP32 sensor nodes for the YouShallNotPass homelab**  
> Room presence detection · Air quality monitoring · Thermal sensing · Full Home Assistant integration

[![Validate ESPHome Configs](https://github.com/rasenganguy/homelab-esp32/actions/workflows/validate.yml/badge.svg)](https://github.com/rasenganguy/homelab-esp32/actions)

---

## 📦 What You Have (From Seeed Invoice #4000537861, Jun 10 2026)

| Board/Sensor | Qty | What it's for in this project |
|---|---|---|
| Seeed XIAO ESP32-S3 Sense | 2 | The "brain" of each sensor node — tiny computer with WiFi |
| Seeed XIAO ESP32-C6 | 2 | Environmental monitor (temperature/humidity) |
| Seeed 24GHz mmWave Sensor | 4 | Detects if a person is in a room — even if sitting still |

---

## 🗂️ What's In This Repo

```
homelab-esp32/
│
├── 📁 presence-sensor/          ← Main project: room presence detection
│   ├── esphome/                 ← The code that runs ON the ESP32 boards
│   └── ha-automations/          ← Home Assistant rules (lights, HVAC, alerts)
│
├── 📁 air-quality-monitor/      ← CO₂, dust, VOC, pressure sensor node
│   └── esphome/
│
├── 📁 thermal-presence/         ← Thermal camera for heat-based presence
│   └── esphome/
│
├── 📁 esp32-c6-gateway/         ← Temperature/humidity node using C6 board
│   └── esphome/
│
├── 📁 n8n-workflows/            ← Pre-built automation workflows for n8n
├── 📁 ansible/                  ← Ansible playbook (for advanced deployment)
├── 📁 tools/                    ← Scripts to make setup easier
│   ├── windows/                 ← Setup and flash scripts for Windows
│   └── linux/                   ← Setup and flash scripts for Linux/Mac
│
├── secrets.yaml.example         ← Template for your WiFi/HA credentials
└── README.md                    ← This file
```

---

## 🧠 How Does This All Work? (Start Here If Confused)

Before touching any hardware, read this — it'll make everything else make sense.

### The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Your House                                  │
│                                                                     │
│  [ESP32 in Office]──WiFi──►[HA MQTT Broker]──►[Home Assistant]     │
│  [ESP32 in Bedroom]─WiFi──►    192.168.50.127    │    │            │
│  [ESP32 Air Quality]─WiFi──►                     │    │            │
│                                                   ▼    ▼            │
│                                              [n8n]  [Grafana]       │
│                                              Alerts  Charts         │
│                                                │                    │
│                                                ▼                    │
│                                          [Telegram]                 │
│                                         Your Phone                  │
└─────────────────────────────────────────────────────────────────────┘
```

### What Is an ESP32?

An ESP32 is a tiny computer chip — about the size of your thumbnail. It has:
- A processor (runs your sensor code)
- Built-in WiFi (connects to your network)
- Input/Output pins (connects to sensors via wires)
- It runs on 3.3 volts (from USB or a power adapter)

You write code for it, flash (copy) that code onto it once, and then it just runs forever without needing a computer attached.

### What Is ESPHome?

ESPHome is the tool that turns a `.yaml` config file into firmware (the code that runs on the ESP32). You describe what sensors are connected and what to do with them in YAML, and ESPHome compiles it into machine code and flashes it onto the board.

**You don't need to know any programming.** You just edit a few lines in the YAML file (room name, WiFi password) and run a single command.

### What Is Firmware?

Firmware is the software that lives permanently on a microcontroller. Think of it like the operating system on your phone — but much simpler. You load it once over USB, and after that the board runs it automatically every time it powers on.

### The YAML Files Explained

Every `.yaml` file in this repo is a configuration file for one ESP32 board. It tells ESPHome:
- What board type it is
- What WiFi to connect to
- What sensors are connected and which pins they use
- What to do with the sensor data (send to HA, publish to MQTT, etc.)

You never need to write code. You just edit the `substitutions:` block at the top of each file.

---

## 🛒 What Else You Need To Buy

The Seeed boards are ordered. Here's what else you need depending on which projects you build.

### Project 1 — Presence Sensor (MOST IMPORTANT — Start Here)

| Item | Where to Buy | Price | Notes |
|------|-------------|-------|-------|
| HLK-LD2410C 24GHz mmWave Radar | Amazon ASIN **B0CS9GLD7X** (5-pack) | ~$20 | The stationary presence radar. Buy 5-pack for best value |
| AM312 Mini PIR Sensor | Amazon ASIN **B09X38GPMN** (5-pack) | ~$9 | Fast motion trigger |
| Female-to-Female Dupont wires 20cm | Amazon ASIN **B07GD2BWPY** | ~$6 | The jumper wires to connect everything |
| USB-C cable (short, 30cm) | Any | ~$5 | For initial flashing from PC |

**Total: ~$40 for 2 full presence nodes** (you have 2 S3 boards)

### Project 2 — Air Quality Monitor (Optional but great)

| Item | Where to Buy | Price |
|------|-------------|-------|
| SCD40 CO₂ Sensor (Adafruit, Qwiic) | Adafruit #5187 | ~$50 |
| SEN55 Multi-sensor module | Mouser or Digi-Key | ~$45 |
| ENS160 + AHT21 breakout | Amazon ASIN **B0C2F7KSGC** | ~$12 |
| BMP280 (Qwiic) | Adafruit #2651 | ~$10 |
| Qwiic cables (10cm, 5-pack) | Amazon ASIN **B08FMKFQB2** | ~$8 |

### Project 3 — Thermal Presence (Bonus)

| Item | Where to Buy | Price |
|------|-------------|-------|
| AMG8833 Grid-EYE breakout (Adafruit, Qwiic) | Adafruit #3538 | ~$35 |
| Qwiic cable | Already listed above | — |

---

## 💻 Step 1 — Set Up Your PC (Windows)

You'll do this once on your Windows PC. After that, all future updates can happen over WiFi.

### 1.1 Install Python

Python is required to run ESPHome.

1. Go to: **https://www.python.org/downloads/**
2. Click the big yellow "Download Python 3.x" button
3. Run the installer
4. ⚠️ **CRITICAL**: On the first screen, check the box **"Add Python to PATH"** before clicking Install Now

To verify it worked, open Command Prompt (press `Win+R`, type `cmd`, press Enter) and run:
```
python --version
```
You should see something like `Python 3.12.0`. If you get an error, Python isn't in PATH — reinstall with that checkbox checked.

### 1.2 Run the Automated Setup Script

Double-click `tools\windows\setup.bat` (right-click → Run as Administrator).

This script will:
- Verify Python is installed
- Install ESPHome automatically
- Install esptool (manual flash tool)
- Open the CP210x USB driver download page

You'll need to install the **CP210x USB driver** from Silabs — this is what lets Windows recognize the ESP32 when you plug it in via USB. The script opens the download page for you.

**What driver to download:** On the Silabs page, download **"CP210x Universal Windows Driver"**, unzip it, run `CP210xVCPInstaller_x64.exe`.

### 1.3 Verify ESPHome Works

Open a new Command Prompt window and run:
```
esphome version
```
You should see a version number like `2024.x.x`. If you see an error, close the window, open a new one, and try again.

---

## 🔑 Step 2 — Create Your Secrets File

The `secrets.yaml` file holds your WiFi password and other credentials. It is **never committed to git** (it's in `.gitignore`).

1. In the repo folder, copy the example file:
   ```
   copy secrets.yaml.example secrets.yaml
   ```
   Or in Windows Explorer: right-click `secrets.yaml.example` → Copy → Paste → Rename to `secrets.yaml`

2. Open `secrets.yaml` in Notepad (right-click → Open with → Notepad)

3. Fill in your values:

```yaml
# Your IoT WiFi network (VLAN 5 in UniFi — the IoT SSID)
wifi_ssid: "YourIoTSSID"
wifi_password: "YourWiFiPassword"

# Fallback hotspot password — can be anything
wifi_fallback_password: "homelabfallback"

# Generate an API key: open Command Prompt and run:
# python -c "import secrets; print(secrets.token_urlsafe(32))"
# Copy the output and paste it here (keep the quotes)
ha_api_key: "paste_your_generated_key_here"

# OTA password — can be anything, just remember it
ha_ota_password: "myotapassword"

# MQTT — your HA broker is at 192.168.50.127
mqtt_broker: "192.168.50.127"
mqtt_username: "homelab"
mqtt_password: "your_mqtt_password"

# InfluxDB on CT109
influxdb_host: "192.168.10.83"
influxdb_port: "8086"
influxdb_db: "esp32_sensors"
influxdb_username: "esp32"
influxdb_password: "your_influxdb_password"
```

**How to generate the API key** (run this in Command Prompt):
```
python -c "import secrets; print(secrets.token_urlsafe(32))"
```
Copy the output — it'll look like `dGVzdGtleWZvcmNpdGVzdGluZ29ubHkxMjM0NTY3`

---

## 🔧 Step 3 — Build the Hardware

### Project 1: Presence Sensor Node

#### What You're Building

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   [XIAO ESP32-S3]  ←── 4 wires ──→  [LD2410C Radar]    │
│         │                                                │
│         └───── 3 wires ──→  [AM312 PIR]                 │
│                                                          │
│   All powered from USB-C (wall charger or USB adapter)  │
└──────────────────────────────────────────────────────────┘
```

#### Components Explained

**XIAO ESP32-S3 Sense** — This is the brain. It's a small PCB about 2cm × 2cm. It has:
- A USB-C port (for power and initial programming)
- A row of pins along each side (labelled 3V3, GND, D0–D10)
- A tiny RGB LED (shows status)
- A button labelled BOOT (used when flashing)
- A button labelled RESET

**LD2410C** — This is the radar. It looks like a small green board with a chip on it. It sends out 24GHz radio waves and measures how they bounce back. It can tell if something is in the room even if it's completely still (detecting breathing micro-motion).

**AM312 PIR** — This is the motion sensor. It looks like a hemisphere on a small PCB. It detects infrared heat movement (like the ones on outdoor lights). It reacts instantly when you walk in, which is faster than the radar.

#### Pin Reference — XIAO ESP32-S3 Sense

Here's a diagram of the board with pins labeled:

```
           USB-C
         ┌───────┐
    5V ──┤1     14├── BAT+
   3V3 ──┤2     13├── GND
   GND ──┤3     12├── D10 (GPIO9)
    D0 ──┤4     11├── D9  (GPIO8)
    D1 ──┤5     10├── D8  (GPIO7)
    D2 ──┤6      9├── D7  (GPIO44) ← LD2410C TX goes here (UART RX)
    D3 ──┤7      8├── D6  (GPIO43) ← LD2410C RX goes here (UART TX)
         └───────┘
              │
         BOOT  RESET
         button button
```

Also:
- **3V3** = 3.3V power output (pin 2)
- **GND** = Ground (pins 3 and 13)
- **D1** (GPIO2) = AM312 signal wire

#### Wiring — Step by Step

> **No soldering required.** You use Dupont jumper wires — they click onto the pins like Lego.

**Connecting LD2410C to ESP32-S3:**

The XIAO ESP32-S3 has pre-soldered pins (you bought the pre-soldered version). The LD2410C also has pins.

| LD2410C Label | Wire Color (suggested) | Connect To | XIAO Label |
|--------------|----------------------|------------|-----------|
| VCC | Red | → | 3V3 |
| GND | Black | → | GND |
| TX | Yellow | → | D7 |
| RX | White | → | D6 |

⚠️ **TX goes to RX and RX goes to TX — this is correct!** TX (transmit) of one device goes to RX (receive) of the other. Don't let this confuse you.

**Connecting AM312 PIR to ESP32-S3:**

The AM312 has 3 pins. Look at the flat side (with the text) — pins are: GND, VCC, OUT (left to right when flat side faces you).

| AM312 Label | Wire Color (suggested) | Connect To | XIAO Label |
|------------|----------------------|------------|-----------|
| VCC | Red | → | 3V3 |
| GND | Black | → | GND |
| OUT | Green | → | D1 |

**That's it!** 7 wires total. No soldering, no resistors, nothing else.

#### Visual Wiring Diagram

```
XIAO ESP32-S3 Sense
┌─────────────────────┐
│ 3V3 ●───────────────┼──────────────► LD2410C VCC (red)
│ GND ●───────────────┼──┬─────────► LD2410C GND (black)
│                     │  │
│  D6 ●───────────────┼──┼─────────► LD2410C RX  (white)
│  D7 ●◄──────────────┼──┼─────────── LD2410C TX  (yellow)
│                     │  │
│ 3V3 ●───────────────┼──┼───────────► AM312 VCC  (red)
│ GND ●───────────────┼──┼──────────► AM312 GND  (black)
│  D1 ●◄──────────────┼──┴─────────── AM312 OUT   (green)
└─────────────────────┘
```

> 💡 **Tip**: Use different colored jumper wires for power (red), ground (black), and signals (any other color). This makes troubleshooting much easier later.

---

## ⚡ Step 4 — Flash the First Node

"Flashing" means copying the firmware onto the ESP32. You do this once via USB. After that, you can update the firmware over WiFi (OTA).

### 4.1 Enter Boot Mode

**This step is critical. If you skip it, the flash will fail.**

The XIAO ESP32-S3 has two buttons: **BOOT** and **RESET**. To put it in flash mode:

1. Hold down the **BOOT** button (keep holding)
2. While still holding BOOT, plug the USB-C cable into the board
3. Wait 2 seconds
4. Release the BOOT button

The board is now in flash mode. It won't show any lights — that's normal.

> 💡 **Tip**: If the flash fails with "No serial port found", it's almost always because you didn't hold BOOT when connecting. Unplug, and try again — hold BOOT first, then plug in.

### 4.2 Flash From Windows

Open Command Prompt in the repo folder (hold Shift, right-click → "Open PowerShell/Command Prompt here") and run:

```
tools\windows\flash-windows.bat presence-office
```

The script will:
1. Find the config file automatically
2. Check that `secrets.yaml` exists
3. Compile the firmware (takes 2-5 minutes on first run — it downloads dependencies)
4. Flash it to the board

**What you'll see during compilation:**

```
INFO Reading configuration...
INFO Generating C++ source...
INFO Compiling app...
INFO Linking...
INFO Creating binary...
INFO Uploading...
```

If you see `SUCCESS`, you're done. The board will restart and connect to WiFi.

### 4.3 What To Do If Flash Fails

| Error Message | What It Means | Fix |
|---|---|---|
| `No serial port found` | Board not in flash mode | Unplug, hold BOOT, replug |
| `Permission denied /dev/ttyUSB0` | (Linux only) No dialout access | Run setup.sh, log out, log back in |
| `Failed to connect to ESP32` | Wrong mode or bad cable | Try a different USB cable (some are charge-only) |
| `secrets.yaml not found` | You forgot to create it | Copy `secrets.yaml.example` to `secrets.yaml` |
| `Compilation error` | Bad YAML syntax | Check your edits — YAML is spaces-sensitive |

---

## 🏠 Step 5 — Connect to Home Assistant

After the board is flashed and powered on:

1. Wait about 60 seconds for the board to boot and connect to WiFi
2. Open Home Assistant: **http://192.168.50.127:8123**
3. Go to **Settings → Devices & Services**
4. You should see a new notification: **"ESPHome device discovered"** — click Configure
5. Enter your API key (the one from `secrets.yaml`)
6. Click Submit

The device is now integrated! You'll see all the sensors appear automatically:
- `binary_sensor.office_presence_occupied_combined` → True/False room occupancy
- `binary_sensor.office_presence_still_presence` → True/False still target
- `binary_sensor.office_presence_motion` → True/False movement
- `sensor.office_presence_still_distance` → Distance in cm
- And more...

### 5.1 Verify It's Working

In Home Assistant, go to **Developer Tools → States** (top right of dev tools). Type "office_presence" in the search box. You should see your sensors. Walk in front of the radar — the `occupied_combined` sensor should turn `on`.

---

## 📡 Step 6 — Flash the Remaining Nodes

For each additional room, you just flash a different YAML file. No USB needed after the first one — use OTA (over-the-air).

### Flashing Additional Rooms (OTA — No USB!)

After the first node is working, you can flash others over WiFi:

```
tools\windows\flash-windows.bat presence-livingroom
tools\windows\flash-windows.bat presence-bedroom
tools\windows\flash-windows.bat seeed-mmwave-kitchen
```

ESPHome will automatically detect the board's IP and push the update wirelessly.

### Adding a New Room

1. Copy a room config:
   ```
   copy presence-sensor\esphome\presence-office.yaml presence-sensor\esphome\presence-nursery.yaml
   ```

2. Open `presence-nursery.yaml` in Notepad and change the top section only:
   ```yaml
   substitutions:
     node_name: "presence-nursery"        # ← Change this
     node_friendly: "Nursery Presence"    # ← Change this
     room_name: "nursery"                 # ← Change this
     ld2410_max_distance: "4m"           # Leave rest as-is
     ld2410_still_threshold: "20"
     ld2410_move_threshold: "20"
     pir_delay_off: "15s"
     update_interval: "5s"
     log_level: "INFO"
   ```

3. Flash it:
   ```
   tools\windows\flash-windows.bat presence-nursery
   ```

4. HA auto-discovers it. Done.

---

## 🌡️ Project 2: Air Quality Monitor

### What It Measures and Why It Matters

| Reading | Normal | Warning | What To Do |
|---------|--------|---------|------------|
| CO₂ | < 800 ppm | > 1000 ppm | Open a window, run Aprilaire |
| CO₂ | < 800 ppm | > 2000 ppm | Open windows immediately — causes headaches |
| PM2.5 | < 12 µg/m³ | > 25 µg/m³ | Run air purifier |
| VOC | < 150 | > 200 | Ventilate — likely paint fumes, cleaning products |
| AQI | 1-2 (Good) | 4-5 (Poor) | Investigate source, ventilate |

### Wiring — I2C Daisy Chain

All four sensors share the same two wires (SDA and SCL). This is called I2C (Inter-Integrated Circuit). Each sensor has a unique address so they don't interfere.

**You connect them in a chain using Qwiic cables:**

```
XIAO D4 (SDA) ──Qwiic──► SCD40 ──Qwiic──► SEN55 ──Qwiic──► ENS160 ──Qwiic──► BMP280
XIAO D5 (SCL) ──same chain (all in parallel)──────────────────────────────────────────
XIAO 3V3 ──────power all
XIAO GND ──────ground all
```

If you use Qwiic breakout boards (Adafruit or SparkFun), just daisy-chain them with the small JST cables. No jumper wires needed for I2C.

### Flash It

```
tools\windows\flash-windows.bat air-quality-main
```

---

## 🔥 Project 3: Thermal Presence Sensor (Bonus)

### What Is an AMG8833?

The AMG8833 is an 8×8 pixel thermal imaging sensor. Imagine a grid of 64 thermometers — it reads the temperature at each point in its field of view 10 times per second.

It's useful for:
- Presence detection based on body heat (not just motion)
- Rough person counting (1 person vs 2 people)
- Seeing heat in the dark
- Detecting if an appliance was left on (oven, stove)

### Wiring (Qwiic — single cable)

```
AMG8833 SDA → XIAO D4 (GPIO5) via Qwiic cable
AMG8833 SCL → XIAO D5 (GPIO6)
AMG8833 VCC → XIAO 3V3
AMG8833 GND → XIAO GND
```

### Flash It

```
tools\windows\flash-windows.bat thermal-sensor-office
```

---

## 🔵 Project 4: ESP32-C6 Environmental Monitor

### Why the C6 is Different

The C6 uses RISC-V architecture instead of Xtensa (used by S3). This means:
- It **requires** `esp-idf` framework (not Arduino) — already set in the config
- Different pin numbers from the S3 (D4=GPIO6, D5=GPIO7 on C6 vs D4=GPIO5, D5=GPIO6 on S3)
- Only 512KB RAM — not enough for complex sensors, but great for BME280

### Wiring

```
BME280 SDA → XIAO C6 D4 (GPIO6)
BME280 SCL → XIAO C6 D5 (GPIO7)
BME280 VCC → XIAO C6 3V3
BME280 GND → XIAO C6 GND
```

### Flash It

```
tools\windows\flash-windows.bat c6-env-monitor
```

---

## 🤖 n8n Automation Workflows

Two pre-built workflows are included in `n8n-workflows/`. Import them into your n8n at `http://192.168.10.60:5678`.

### Importing a Workflow

1. Open n8n
2. Click **Workflows** in the left sidebar
3. Click **Import from File** (top right)
4. Upload the JSON file
5. Open the workflow and configure credentials:
   - **MQTT**: Add broker `192.168.50.127`, port `1883`, username/password from secrets.yaml
   - **Telegram**: Use your existing HomeLab bot credentials

### Available Workflows

**`presence-alerts-workflow.json`**  
Subscribes to `homelab/presence/+/occupied` via MQTT. When any room changes, it sends a Telegram message to your HomeLab group and updates a HA state.

**`air-quality-workflow.json`**  
Subscribes to `homelab/air_quality/#`. When CO₂ or PM2.5 thresholds are crossed, sends Telegram alerts and writes data to InfluxDB.

---

## 📊 Grafana Dashboard

A pre-built dashboard JSON is in `presence-sensor/grafana/esp32-dashboard.json`.

### Import Into Grafana

1. Open Grafana at `http://192.168.10.83:3000`
2. Click **Dashboards** (left sidebar) → **Import**
3. Click **Upload JSON file** → select the JSON
4. When asked for datasource, select your InfluxDB datasource
5. Click **Import**

### What You'll See

- CO₂ levels over 24 hours with color-coded thresholds
- PM2.5 and PM10 particle trends
- Room occupancy status (colored green/gray for occupied/empty)
- Temperature and humidity
- VOC and NOx air quality indices
- Radar detection distance history

---

## 🔧 Tuning Your Sensors

After everything is working, you can tune the sensors from Home Assistant — **no reflashing needed**.

### Tuning the LD2410C Radar

In HA, go to your presence sensor device and look for these controls:

| Control | What It Does | Recommendation |
|---------|-------------|----------------|
| **Max Move Distance** | How far away moving targets are detected (gates 1-8, each ~0.75m) | Set to match your room size |
| **Max Still Distance** | How far away still targets are detected | Usually same as above |
| **Radar Timeout** | How many seconds after no target before sensor reports empty | 5-10s for most rooms, 30s for bedroom |
| **Still Threshold** | Energy level to consider a still target real (lower = more sensitive) | Start at 20, try 10 for sleeping detection |
| **Move Threshold** | Energy level to consider a moving target real | Start at 20 |

**Golden rule**: If you're getting false positives (room shows occupied when empty), increase the thresholds. If you're getting false negatives (room shows empty when occupied), decrease them.

### Tuning Tips Per Room

| Room | Max Distance | Still Threshold | Notes |
|------|-------------|-----------------|-------|
| Home office | 3-4m | 15-20 | Aim at your desk, not through walls |
| Living room | 5-6m | 15-20 | Mount in corner for best coverage |
| Bedroom | 3-4m | 8-12 | Low threshold to detect sleeping |
| Bathroom | 2m | 20-25 | Scene mode: Toilet in Seeed sensor |
| Kitchen | 4m | 20 | Microwave can cause false positives — point away |

### Mounting Position

- Mount the LD2410C on a wall or ceiling, pointing toward the main occupancy zone
- **Ceiling**: 2-3m height, pointing straight down or slightly angled
- **Wall**: At desk height (1-1.5m), pointing toward where people sit/stand
- Avoid pointing directly at windows (sunlight changes IR temperature)
- Avoid pointing at HVAC vents (air movement can confuse PIR)

---

## 📡 UniFi Configuration

Your ESP32 nodes should be on **VLAN 5 (IoT, 192.168.5.0/24)**.

### Create an IoT SSID (If Not Already Done)

1. UniFi Network → **WiFi** → **Add WiFi Network**
2. Name: `HomeLab-IoT` (or anything memorable)
3. Password: Whatever you want
4. Under **Advanced** → **VLAN** → select **5**
5. Disable **Band Steering** (helps ESP32 stay on 2.4GHz)
6. Save

Put this SSID name in your `secrets.yaml` as `wifi_ssid`.

### Firewall Rules (IoT → HA MQTT)

ESP32 nodes need to reach your HA MQTT broker.

In UniFi → **Firewall & Security** → **Traffic Rules**:

| Rule | From | To | Port | Action |
|------|------|----|------|--------|
| Allow IoT MQTT | IoT (VLAN 5) | `192.168.50.127` | 1883 | Allow |
| Allow IoT HA API | IoT (VLAN 5) | `192.168.50.127` | 8123 | Allow |
| Block IoT to LAN | IoT (VLAN 5) | LAN | Any | Block |

---

## 🔒 Security Notes

- **Never commit `secrets.yaml`** — it's in `.gitignore` but double-check
- All ESP32 ↔ HA communication is encrypted (AES-128 via the API key)
- OTA updates are password-protected
- Nodes are isolated on VLAN 5 — they can only reach HA MQTT, nothing else on your LAN

---

## 🚨 Troubleshooting

### Node won't flash

**Problem**: `A fatal error occurred: Failed to connect to ESP32`  
**Fix**: You didn't hold the BOOT button. Unplug, hold BOOT, plug in, release BOOT. Try again.

**Problem**: `No serial port found / No such file /dev/ttyUSB0`  
**Fix on Windows**: Install the CP210x driver (run setup.bat, it opens the download page)  
**Fix on Linux**: `sudo usermod -aG dialout $USER` then log out and log back in

**Problem**: Compilation fails with YAML errors  
**Fix**: YAML is very sensitive to indentation. Use spaces, never tabs. Each level is 2 spaces.

### Node appears in HA but sensors show unavailable

Wait 60 seconds. If still unavailable, check the board's fallback hotspot:
1. On your phone/PC, look for a WiFi network named `presence-office-fallback`
2. Connect to it (password from `secrets.yaml`)
3. Browse to `http://192.168.4.1` — you'll see an error page if WiFi credentials are wrong

### LD2410C not detecting still presence

1. Enable **Engineering Mode** in HA for the device
2. Watch the **Still Energy** sensor value — if it stays at 0 even when you're sitting still, the sensitivity is too low
3. Lower **Still Threshold** to 10 or even 5
4. Make sure the radar is pointed at where you sit, not at a wall

### Node keeps disconnecting

1. Check the WiFi signal strength sensor in HA — below -80 dBm is too weak
2. Move the node closer to an AP, or add a UniFi AP closer
3. Make sure you're connecting to a 2.4GHz SSID (ESP32 doesn't support 5GHz)

### OTA update fails

The node might be offline. Check Uptime Kuma or ping the device IP. If offline, do a USB flash to recover:
1. Connect via USB, hold BOOT
2. Run: `tools\windows\flash-windows.bat <node-name>`

### HA doesn't discover the device

1. Make sure your PC and HA are on the same subnet for mDNS discovery
2. Or manually add it: HA → Settings → Devices → Add Integration → ESPHome → enter the board's IP address

---

## 📋 Reference: All MQTT Topics

Every sensor publishes to MQTT so n8n and Grafana can consume the data independently of HA.

| Topic | Value | Description |
|-------|-------|-------------|
| `homelab/presence/{room}/occupied` | `true`/`false` | Room occupancy |
| `homelab/presence/{room}/status` | `online`/`offline` | Node connectivity |
| `homelab/air_quality/{location}/alerts/co2` | `normal`/`warning`/`critical` | CO₂ level category |
| `homelab/air_quality/{location}/alerts/pm25` | `normal`/`warning` | PM2.5 level category |
| `homelab/thermal/{room}/hot_pixels` | `0`–`64` | Number of hot pixels in thermal frame |

---

## 📋 Reference: File Descriptions

| File | What It Is | When To Edit |
|------|-----------|-------------|
| `secrets.yaml` | Your WiFi/HA credentials | Once, during setup |
| `presence-sensor/esphome/presence-node.yaml` | Shared base config for all presence nodes | When adding new sensors |
| `presence-sensor/esphome/presence-office.yaml` | Office-specific settings | To rename or retune |
| `presence-sensor/esphome/presence-bedroom.yaml` | Bedroom-specific settings | Same |
| `presence-sensor/esphome/seeed-mmwave-24ghz.yaml` | Config for your 4x Seeed MR24HPC1 sensors | To rename/retune |
| `air-quality-monitor/esphome/air-quality-node.yaml` | Air quality node config | To change thresholds |
| `thermal-presence/esphome/thermal-sensor.yaml` | Thermal camera node config | To change temp threshold |
| `esp32-c6-gateway/esphome/c6-env-monitor.yaml` | C6 temp/humidity node | To add more locations |
| `presence-sensor/ha-automations/presence-automations.yaml` | HA automation rules | To customize light/HVAC behavior |
| `n8n-workflows/presence-alerts-workflow.json` | n8n workflow for Telegram alerts | Import once |
| `tools/windows/setup.bat` | One-time Windows setup | Run once |
| `tools/windows/flash-windows.bat` | Flashes any node from Windows | Use every time you flash |

---

## 🗺️ Roadmap

- [ ] **BLE Phone Tracking** — use ESP32 BLE to detect your phone's MAC for person-level presence
- [ ] **Acoustic Monitoring** — use the XIAO S3's built-in microphone for glass break, smoke alarm detection  
- [ ] **Rover Integration** — mount an ESP32-S3 on the UGV rover as a mobile presence probe
- [ ] **AMG8833 Heatmap Card** — live 8×8 thermal visualization in HA Lovelace
- [ ] **ESP32-C6 Thread/Matter** — future use as a Thread border router once ESPHome supports it

---

## 📚 References

- [Seeed XIAO ESP32-S3 Sense Pinout & Wiki](https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/)
- [Seeed XIAO ESP32-C6 Pinout & Wiki](https://wiki.seeedstudio.com/xiao_esp32c6_getting_started/)
- [ESPHome LD2410 Docs](https://esphome.io/components/sensor/ld2410.html)
- [ESPHome Seeed MR24HPC1 Docs](https://esphome.io/components/sensor/seeed_mr24hpc1.html)
- [ESPHome SCD4x Docs (CO₂)](https://esphome.io/components/sensor/scd4x.html)
- [ESPHome SEN5x Docs (Particulates)](https://esphome.io/components/sensor/sen5x.html)
- [ESPHome AMG8833 Docs](https://esphome.io/components/sensor/amg8833.html)
- [ESPHome Secrets Docs](https://esphome.io/guides/faq.html#how-do-i-use-my-home-assistant-secrets-yaml)
- [CP210x Driver Download (Silabs)](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)

---

*Part of the rasenganguy homelab. See also: [homelab-robotics](https://github.com/rasenganguy/homelab-robotics)*
