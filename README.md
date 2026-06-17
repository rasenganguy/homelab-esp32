# homelab-esp32

> **ESP32 sensor nodes for the YouShallNotPass homelab**  
> Room presence · Air quality · Thermal sensing · Standalone MQTT · HA optional

[![Validate ESPHome Configs](https://github.com/rasenganguy/homelab-esp32/actions/workflows/validate.yml/badge.svg)](https://github.com/rasenganguy/homelab-esp32/actions)

---

## 📦 Hardware Inventory (Invoice #4000537861, Jun 10 2026)

| Board / Sensor | Qty | Role |
|---|---|---|
| Seeed XIAO ESP32-S3 Sense (Pre-Soldered) | 2 | Brain of each sensor node — tiny WiFi computer |
| Seeed XIAO ESP32-C6 (Pre-Soldered) | 2 | Environmental monitor (temp/humidity) |
| Seeed 24GHz mmWave Human Static Presence Sensor | 4 | Detects occupancy — even a still, seated person |

---

## 🗂️ Repo Structure

```
homelab-esp32/
├── presence-sensor/
│   ├── esphome/            ← Firmware configs flashed onto the boards
│   ├── ha-automations/     ← Home Assistant rules (optional)
│   └── grafana/            ← Grafana dashboard JSON
├── air-quality-monitor/esphome/
├── thermal-presence/esphome/
├── esp32-c6-gateway/esphome/
├── n8n-workflows/          ← Pre-built n8n automation workflows
├── ansible/                ← Ansible deployment playbook
├── docs/                   ← Extra documentation
├── tools/windows/          ← setup.bat + flash-windows.bat
├── tools/linux/            ← setup.sh + flash.sh
├── secrets.yaml.example    ← Template for credentials
└── README.md
```

---

## 🧠 Concepts — Read This First

### What Is an ESP32?

A tiny WiFi-enabled computer chip roughly the size of a postage stamp. It runs code you flash onto it once, then operates independently forever — no PC attached, no cloud needed. It connects to sensors via physical wires and sends data over WiFi to whatever you want.

### What Is ESPHome?

ESPHome converts a simple `.yaml` config file into firmware for the ESP32. You describe your hardware in YAML (what sensors are connected, which pins, what to publish) and ESPHome compiles it into machine code and flashes it. **No programming knowledge required** — you only edit a few lines of config.

### What Is Firmware?

The software permanently stored on the microcontroller. Like a phone OS but far simpler. You load it once over USB. After that it runs automatically every power-on.

### HA-Independent Architecture

**Home Assistant is completely optional.** All nodes publish to MQTT directly. Your existing Mosquitto broker (already on HA at `192.168.50.127`) receives every sensor reading. From there:

- **Node-RED** (CT159, already in your stack) provides a standalone dashboard — no HA needed
- **Grafana** (CT109) shows historical charts — no HA needed
- **n8n** (CT123) handles automation and Telegram alerts — no HA needed
- HA integration is a bonus layer you can add later via the ESPHome API

```
[ESP32 Node] ──MQTT──► [Mosquitto] ──► [Node-RED dashboard]  ← standalone
                              │       ──► [Grafana charts]      ← standalone
                              │       ──► [n8n automations]     ← standalone
                              │
                              └──────► [Home Assistant]         ← optional
```

---

## 🛒 Additional Hardware to Buy

You have the boards. Here's what else you need per project.

### Project 1 — Presence Sensor (Start Here)

| Item | Amazon ASIN | ~Price | Notes |
|------|------------|--------|-------|
| HLK-LD2410C 24GHz Radar (5-pack) | B0CS9GLD7X | ~$20 | The stationary presence radar |
| AM312 PIR Sensor (5-pack) | B09X38GPMN | ~$9 | Fast motion trigger |
| Female-to-Female Dupont jumpers 20cm | B07GD2BWPY | ~$6 | The connecting wires |
| USB-C cable (data cable, not charge-only) | Any | ~$5 | Initial flash only |
| USB-C wall charger 5V/1A | Any | ~$8 | Powers node permanently |

**Total per 2 nodes: ~$48** (you have 2 S3 boards)

### Project 2 — Air Quality (Optional)

| Item | Where | ~Price |
|------|-------|--------|
| SCD40 CO₂ sensor (Adafruit #5187, Qwiic) | adafruit.com | ~$50 |
| SEN55 module | mouser.com | ~$45 |
| ENS160+AHT21 breakout | Amazon B0C2F7KSGC | ~$12 |
| BMP280 (Adafruit #2651, Qwiic) | adafruit.com | ~$10 |
| Qwiic cables 10cm 5-pack | Amazon B08FMKFQB2 | ~$8 |

### Project 3 — Thermal Presence (Bonus)

| Item | Where | ~Price |
|------|-------|--------|
| AMG8833 Grid-EYE Qwiic (Adafruit #3538) | adafruit.com | ~$35 |
| Qwiic cable 10cm | Already above | — |

---

## 🔧 Part 1 — Hardware Assembly & Wiring Schematics

> **No soldering required.** All connections use Dupont jumper wires (press-fit) or Qwiic cables (click-in JST connectors). No heat gun, no soldering iron, no electronics experience needed.

---

### 1A — Presence Node: XIAO ESP32-S3 + LD2410C + AM312

#### The Three Parts

**XIAO ESP32-S3 Sense** — the main board. About 21×17mm. Has USB-C for power/programming, a row of pins along each long edge, a tiny RGB LED, and two small buttons (BOOT and RESET).

**HLK-LD2410C** — the green radar board. About 22×16mm. Emits invisible 24GHz radio waves and measures reflections. Detects humans even when completely still, sensing micro-motion from breathing. Range: up to 6 meters.

**AM312 PIR** — small hemispheric dome on a PCB. Detects movement via infrared heat. Reacts in milliseconds — much faster than radar. Used as a fast "wake" trigger.

#### Physical Pin Identification

**XIAO ESP32-S3 Sense — pin layout:**

```
                    ┌── USB-C ──┐
                    │           │
              5V ── ┤ ●       ● ├ ── BAT+
             3V3 ── ┤ ●       ● ├ ── GND
             GND ── ┤ ●       ● ├ ── D10
              D0 ── ┤ ●       ● ├ ── D9
              D1 ── ┤ ●       ● ├ ── D8
              D2 ── ┤ ●       ● ├ ── D7  ← LD2410C TX connects here
              D3 ── ┤ ●       ● ├ ── D6  ← LD2410C RX connects here
              D4 ── ┤ ●       ● ├ ── D5
                    └───────────┘
                    [BOOT]  [RST]
                   (tiny buttons, bottom edge)

    Pins on LEFT side (top to bottom):  5V, 3V3, GND, D0, D1, D2, D3, D4
    Pins on RIGHT side (top to bottom): BAT+, GND, D10, D9, D8, D7, D6, D5

    The labels are printed on the back of the board.
    3V3 = 3.3V power out  |  GND = Ground  |  D1 = Digital pin 1, etc.
```

**LD2410C — pin layout:**

```
    LD2410C (view of the pin row, component side up)

    ┌────────────────────────────────────────────┐
    │  ●    ●    ●    ●    ●    ●                 │
    │ VCC  GND   TX   RX  OT1  OT2               │
    └────────────────────────────────────────────┘
         ↑         ↑    ↑
       Power     Sends  Receives
       3.3V      data   commands
                to D7  from D6
```

**AM312 PIR — pin layout:**

```
    AM312 PIR (flat/label side facing you, dome on other side)

         Dome →  ╭────╮
                 │    │
                 ╰────╯
    ┌───────────────────────────┐
    │  ●         ●        ●     │
    │ GND       VCC       OUT   │
    └───────────────────────────┘
     (Black)   (Red)    (Green)
                ↑
            3.3V power
```

#### Step-by-Step Wiring

Cut 7 Dupont jumper wires. Use different colors if you have them.

**Wire 1 — Power the radar:**
```
XIAO 3V3 pin  ──[RED wire]──►  LD2410C VCC pin
```

**Wire 2 — Ground the radar:**
```
XIAO GND pin  ──[BLACK wire]──►  LD2410C GND pin
```

**Wire 3 — Radar sends data to ESP32:**
```
LD2410C TX pin  ──[YELLOW wire]──►  XIAO D7 pin
```
(TX = Transmit. Radar's transmit goes to ESP32's receive = D7/GPIO44)

**Wire 4 — ESP32 sends commands to radar:**
```
XIAO D6 pin  ──[WHITE wire]──►  LD2410C RX pin
```
(D6 = GPIO43. Usually you don't need to send commands but wire it anyway)

**Wire 5 — Power the PIR:**
```
XIAO 3V3 pin  ──[RED wire]──►  AM312 VCC pin
```

**Wire 6 — Ground the PIR:**
```
XIAO GND pin  ──[BLACK wire]──►  AM312 GND pin
```

**Wire 7 — PIR signal:**
```
AM312 OUT pin  ──[GREEN wire]──►  XIAO D1 pin
```

#### Complete Wiring Summary Diagram

```
╔══════════════════════════════════════════════════════════════════════════╗
║  PRESENCE NODE — Complete Wiring                                         ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║   XIAO ESP32-S3 Sense                                                    ║
║   ┌──────────────────────┐                                               ║
║   │ 3V3 ●────────────────┼──RED──────────────────────► LD2410C VCC      ║
║   │ GND ●────────────────┼──BLK──────────┬──────────► LD2410C GND      ║
║   │  D6 ●────────────────┼──WHT──────────┼──────────► LD2410C RX       ║
║   │  D7 ●◄───────────────┼──YEL──────────┼─────────── LD2410C TX       ║
║   │                      │               │                               ║
║   │ 3V3 ●────────────────┼──RED──────────┼──────────► AM312 VCC        ║
║   │ GND ●────────────────┼──BLK──────────┴──────────► AM312 GND        ║
║   │  D1 ●◄───────────────┼──GRN──────────────────────  AM312 OUT       ║
║   └──────────────────────┘                                               ║
║                                                                          ║
║   Power: USB-C wall charger (5V/1A) into XIAO USB-C port                ║
╚══════════════════════════════════════════════════════════════════════════╝
```

> ⚠️ **TX goes to D7, RX goes to D6.** This seems backwards but is correct. TX (transmit) of one device always connects to RX (receive) of the other device.

> ⚠️ **3V3, not 5V.** The LD2410C can take 5V but the AM312 is 3.3V only. Using 3V3 for both is safe and simple.

---

### 1B — Seeed 24GHz MR24HPC1 Wiring (Your Invoice Sensors)

The MR24HPC1 sensors from your Seeed invoice use a different protocol than the LD2410C (115200 baud vs 256000) but the wiring is identical.

```
╔══════════════════════════════════════════════════════════════════════╗
║  MR24HPC1 Wiring                                                     ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   XIAO ESP32-S3                    Seeed MR24HPC1                   ║
║   ┌────────────────┐               ┌──────────────────────────────┐  ║
║   │ 3V3 ●──────────┼───RED────────►│ Pin 1: VCC                  │  ║
║   │ GND ●──────────┼───BLK────────►│ Pin 2: GND                  │  ║
║   │  D6 ●──────────┼───WHT────────►│ Pin 4: RX                   │  ║
║   │  D7 ●◄─────────┼───YEL─────────│ Pin 3: TX                   │  ║
║   └────────────────┘               └──────────────────────────────┘  ║
║                                                                      ║
║   MR24HPC1 has a JST connector. Pin 1 is marked with a white dot     ║
║   or triangle on the board silkscreen.                                ║
║   Order: VCC | GND | TX | RX | IO1 | GND                            ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

### 1C — Air Quality Monitor Wiring (I2C Daisy Chain)

All four sensors share two wires: SDA (data) and SCL (clock). Each sensor has a unique address, so they coexist on the same wire pair.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  AIR QUALITY MONITOR — I2C Daisy Chain                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  XIAO D4(SDA) ──Qwiic────► SCD40 ────Qwiic────► SEN55 ────Qwiic────► ...   ║
║  XIAO D5(SCL) ─────────────(same 4-wire Qwiic cable carries SDA+SCL+V+G)   ║
║  XIAO 3V3     ─────────────(Qwiic red wire)                                 ║
║  XIAO GND     ─────────────(Qwiic black wire)                               ║
║                                                                              ║
║  Full chain:  XIAO ──► SCD40 ──► SEN55 ──► ENS160 ──► BMP280               ║
║               (0x62)  (0x69)   (0x53)    (0x76)                            ║
║                                                                              ║
║  Qwiic cable color standard:                                                 ║
║    ⚫ Black = GND                                                             ║
║    🔴 Red   = 3.3V                                                           ║
║    🔵 Blue  = SDA (data)                                                     ║
║    🟡 Yellow = SCL (clock)                                                   ║
║                                                                              ║
║  If sensor has no Qwiic port (uses standard pins):                           ║
║    Sensor SDA → XIAO D4 (GPIO5)                                             ║
║    Sensor SCL → XIAO D5 (GPIO6)                                             ║
║    Sensor VCC → XIAO 3V3                                                    ║
║    Sensor GND → XIAO GND                                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**I2C addresses — why they must be unique:**

Each sensor has a fixed I2C address burned into it. Think of it like a phone extension number. The ESP32 calls "Hey 0x62!" and only the SCD40 answers.

| Sensor | I2C Address | Can Change? |
|--------|------------|------------|
| SCD40 | 0x62 | No |
| SEN55 | 0x69 | No |
| ENS160 | 0x53 | Yes (SDO pin to GND = 0x52) |
| BMP280 | 0x76 | Yes (SDO pin to VCC = 0x77) |

---

### 1D — Thermal Sensor Wiring (AMG8833)

Single Qwiic cable, one minute of work.

```
╔══════════════════════════════════════════════════════════════════════╗
║  THERMAL SENSOR — AMG8833                                            ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   XIAO ESP32-S3 Sense             AMG8833 Grid-EYE                  ║
║   ┌────────────────────┐          ┌──────────────────────────────┐  ║
║   │ D4 (GPIO5/SDA) ●───┼──BLU────►│ SDA                         │  ║
║   │ D5 (GPIO6/SCL) ●───┼──YEL────►│ SCL                         │  ║
║   │ 3V3            ●───┼──RED────►│ VCC (3.3V only! Not 5V)     │  ║
║   │ GND            ●───┼──BLK────►│ GND                         │  ║
║   │ D0 (GPIO1)     ●◄──┼──[opt]───│ INT (optional interrupt pin) │  ║
║   └────────────────────┘          └──────────────────────────────┘  ║
║                                                                      ║
║   If using Adafruit/SparkFun Qwiic breakout:                         ║
║   One Qwiic cable. Plug one end to XIAO Qwiic port, other to board.  ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

### 1E — ESP32-C6 Environmental Monitor Wiring

**Important:** The C6 has different GPIO numbers than the S3 for the same silk-screen labels.

```
╔══════════════════════════════════════════════════════════════════════╗
║  ESP32-C6 ENVIRONMENTAL MONITOR                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   XIAO ESP32-C6                   BME280                            ║
║   ┌────────────────────┐          ┌────────────────────────────┐    ║
║   │ D4 (GPIO6/SDA) ●───┼──BLU────►│ SDA                       │    ║
║   │ D5 (GPIO7/SCL) ●───┼──YEL────►│ SCL                       │    ║
║   │ 3V3            ●───┼──RED────►│ VCC                       │    ║
║   │ GND            ●───┼──BLK────►│ GND                       │    ║
║   └────────────────────┘          │                           │    ║
║                                   │ SDO ────────────────► GND │    ║
║   ⚠️ C6 uses GPIO6 for SDA         │ (sets I2C address 0x76)   │    ║
║   ⚠️ S3 uses GPIO5 for SDA         └────────────────────────────┘    ║
║   Both boards label it "D4" on silk — the GPIO number differs!       ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

### 1F — Full System Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════════════════════╗
║  HOMELAB ESP32 — FULL SYSTEM OVERVIEW                                                ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                      ║
║  YOUR HOME                           VLAN 5 (IoT)          VLAN 10 (Servers)        ║
║  ┌─────────────────────────────┐      ┌──────────────────────────────────────────┐  ║
║  │ [Presence Node — Office]    │      │                                          │  ║
║  │  ESP32-S3 + LD2410C + AM312 ├─WiFi─► Mosquitto MQTT (192.168.50.127:1883)     │  ║
║  │                             │      │            │                              │  ║
║  │ [Presence Node — Bedroom]   │      │            ▼                              │  ║
║  │  ESP32-S3 + LD2410C + AM312 ├─WiFi─►    ┌──────────────┐                     │  ║
║  │                             │      │    │  Node-RED    │ ← Standalone         │  ║
║  │ [Seeed 24GHz — Kitchen]     │      │    │  CT159       │   dashboard/UI        │  ║
║  │  ESP32-S3 + MR24HPC1        ├─WiFi─►    │  :1880       │                     │  ║
║  │                             │      │    └──────────────┘                     │  ║
║  │ [Air Quality Monitor]       │      │            │                              │  ║
║  │  ESP32-S3 + SCD40+SEN55+... ├─WiFi─►            ▼                              │  ║
║  │                             │      │    ┌──────────────┐                     │  ║
║  │ [Thermal Sensor]            │      │    │  InfluxDB    │                     │  ║
║  │  ESP32-S3 + AMG8833         ├─WiFi─►    │  CT109       │                     │  ║
║  │                             │      │    │  :8086       │                     │  ║
║  │ [C6 Env Monitor]            │      │    └──────┬───────┘                     │  ║
║  │  ESP32-C6 + BME280          ├─WiFi─►           │                              │  ║
║  └─────────────────────────────┘      │            ▼                              │  ║
║                                       │    ┌──────────────┐                     │  ║
║                                       │    │  Grafana     │ ← Charts/history     │  ║
║                                       │    │  CT109       │                     │  ║
║                                       │    │  :3000       │                     │  ║
║                                       │    └──────────────┘                     │  ║
║                                       │            │                              │  ║
║                                       │            ▼                              │  ║
║                                       │    ┌──────────────┐                     │  ║
║                                       │    │  n8n         │ ← Automations        │  ║
║                                       │    │  CT123       │   + Telegram         │  ║
║                                       │    │  :5678       │                     │  ║
║                                       │    └──────────────┘                     │  ║
║                                       │                                          │  ║
║                                       │    ┌──────────────┐                     │  ║
║                                       │    │  Home        │ ← OPTIONAL layer     │  ║
║                                       │    │  Assistant   │                     │  ║
║                                       │    │  :8123       │                     │  ║
║                                       │    └──────────────┘                     │  ║
║                                       └──────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════════════════╝
```

---

## 💻 Part 2 — Software Setup (Windows)

### Step 1: Install Python

1. Go to **https://www.python.org/downloads/**
2. Click the big yellow "Download Python 3.x" button
3. Run the installer
4. **CRITICAL:** On the first screen, check **"Add Python to PATH"** before clicking Install Now

Verify it worked — open Command Prompt (`Win+R` → type `cmd` → Enter):
```
python --version
```
Expected output: `Python 3.12.x`

### Step 2: Run the Setup Script

Double-click `tools\windows\setup.bat` → right-click → **Run as Administrator**.

This installs ESPHome, esptool, and opens the USB driver download page.

**Install the USB driver** from the page it opens: download "CP210x Universal Windows Driver", unzip, run `CP210xVCPInstaller_x64.exe`. This is what lets Windows talk to the ESP32.

### Step 3: Create Secrets File

```
copy secrets.yaml.example secrets.yaml
```

Open `secrets.yaml` in Notepad and fill in:

```yaml
wifi_ssid: "YourIoTSSID"           # VLAN 5 IoT SSID from UniFi
wifi_password: "YourWiFiPassword"
wifi_fallback_password: "homelabfallback"
ha_api_key: "paste_key_here"       # Generate below
ha_ota_password: "anypassword"
mqtt_broker: "192.168.50.127"
mqtt_username: "homelab"
mqtt_password: "your_mqtt_password"
influxdb_host: "192.168.10.83"
influxdb_port: "8086"
influxdb_db: "esp32_sensors"
influxdb_username: "esp32"
influxdb_password: "your_influxdb_password"
```

Generate the API key (run in Command Prompt):
```
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## ⚡ Part 3 — Flashing Firmware

"Flashing" = copying firmware onto the board. Done once via USB. All updates after that happen over WiFi (OTA).

### Enter Boot Mode (Critical Step)

The XIAO ESP32-S3 must be in "bootloader mode" to accept firmware. Two small buttons are on the bottom edge of the board — one says **BOOT**, one says **RST**.

**Procedure:**
1. Hold down the **BOOT** button — keep holding
2. While still holding BOOT, plug the USB-C cable into the board
3. Count to 2 seconds
4. Release the BOOT button

The board is now in flash mode. No lights — that's normal.

> If flash fails with "Failed to connect to ESP32" — you didn't hold BOOT when plugging in. Unplug, try again.

### Flash a Node (Windows)

Open Command Prompt in the repo folder. Run:
```
tools\windows\flash-windows.bat presence-office
```

Available node names:
| Command | What it flashes |
|---------|----------------|
| `presence-office` | Office presence node |
| `presence-livingroom` | Living room presence node |
| `presence-bedroom` | Bedroom presence node |
| `seeed-mmwave-kitchen` | Kitchen Seeed 24GHz sensor |
| `air-quality-main` | Air quality monitor |
| `thermal-sensor-office` | Thermal camera |
| `c6-env-monitor` | C6 environmental monitor |

### What Happens During Flash

```
INFO Reading configuration...          ← ESPHome reads your YAML
INFO Generating C++ source...          ← Converts YAML to code
INFO Compiling app...                  ← Takes 2-5 minutes FIRST TIME
INFO Linking...                        ← Building the binary
INFO Creating binary...
INFO Uploading...                      ← Copying to the board (30 sec)
INFO Successfully uploaded             ← Done!
```

The board restarts, connects to WiFi, and starts publishing data.

### OTA Updates (No USB After First Flash)

After a node is working, all future updates happen over WiFi:
```
tools\windows\flash-windows.bat presence-bedroom
```
ESPHome automatically finds the board's IP and pushes wirelessly.

---

## 📡 Part 4 — Standalone Operation (No Home Assistant Required)

This section sets up the full sensor stack using only MQTT + Node-RED + Grafana. Home Assistant is not involved.

### 4A — Verify Mosquitto MQTT Is Running

Your MQTT broker is at `192.168.50.127:1883`. Test it:

```bash
# On any machine on your network:
mosquitto_sub -h 192.168.50.127 -u homelab -P <password> -t "homelab/#" -v
```

When you walk past a presence node, you should see messages appear like:
```
homelab/presence/office/occupied  true
homelab/presence/office/status    online
```

If you don't have `mosquitto_sub`, install it:
```bash
# Ubuntu/Debian:
sudo apt install mosquitto-clients
```

### 4B — Node-RED Standalone Dashboard

Node-RED is already at CT159 (`192.168.0.159`). Open it at `http://192.168.0.159:1880`.

#### Import the Presence Dashboard Flow

1. In Node-RED, click the **hamburger menu** (top right) → **Import**
2. Paste this JSON (copy the whole block):

```json
[
  {
    "id": "mqtt-presence-in",
    "type": "mqtt in",
    "name": "All Presence Events",
    "topic": "homelab/presence/#",
    "qos": "1",
    "broker": "mqtt-broker-config",
    "x": 120, "y": 100
  },
  {
    "id": "parse-presence",
    "type": "function",
    "name": "Parse Room State",
    "func": "const parts = msg.topic.split('/');\nconst room = parts[2];\nconst key = parts[3];\nif (key !== 'occupied') return null;\nmsg.payload = { room: room, occupied: msg.payload === 'true', ts: new Date().toLocaleTimeString() };\nreturn msg;",
    "x": 350, "y": 100
  },
  {
    "id": "presence-ui",
    "type": "ui_text",
    "name": "Room Status",
    "group": "presence-group",
    "order": 1,
    "label": "{{msg.payload.room}}",
    "format": "{{msg.payload.occupied ? '🟢 Occupied' : '⚪ Empty'}}",
    "x": 580, "y": 100
  },
  {
    "id": "mqtt-aq-in",
    "type": "mqtt in",
    "name": "Air Quality",
    "topic": "homelab/air_quality/#",
    "qos": "1",
    "broker": "mqtt-broker-config",
    "x": 120, "y": 200
  },
  {
    "id": "aq-chart",
    "type": "ui_chart",
    "name": "CO2 History",
    "group": "aq-group",
    "label": "CO2 (ppm)",
    "chartType": "line",
    "x": 580, "y": 200
  }
]
```

3. Configure the MQTT broker node: set host `192.168.50.127`, port `1883`, user/pass from secrets.yaml
4. Click **Deploy**
5. Open the dashboard at `http://192.168.0.159:1880/ui`

You now have a live presence dashboard with no Home Assistant involved.

### 4C — MQTT Topics Reference

Every sensor publishes to these topics automatically:

| Topic | Payload | Description |
|-------|---------|-------------|
| `homelab/presence/{room}/occupied` | `true` / `false` | Main presence state |
| `homelab/presence/{room}/status` | `online` / `offline` | Node connectivity |
| `homelab/air_quality/{loc}/alerts/co2` | `normal` / `warning` / `critical` | CO₂ alert level |
| `homelab/air_quality/{loc}/alerts/pm25` | `normal` / `warning` | PM2.5 alert level |
| `homelab/thermal/{room}/hot_pixels` | `0`–`64` | Thermal hot pixel count |

### 4D — InfluxDB Direct Write (For Grafana Without HA)

Add this to your ESPHome config to write metrics directly to InfluxDB from the node — bypassing HA entirely:

Each ESPHome config already publishes to MQTT. To get data into InfluxDB, configure Node-RED to bridge MQTT → InfluxDB:

1. In Node-RED, add a **`node-red-contrib-influxdb`** node (install via Palette Manager)
2. Connect: `mqtt in` → `function (format line protocol)` → `influxdb out`
3. InfluxDB server: `192.168.10.83:8086`, database: `esp32_sensors`

Or run this one-time Telegraf config on CT109 to auto-bridge all MQTT to InfluxDB:

```toml
# /etc/telegraf/telegraf.d/mqtt-esp32.conf
[[inputs.mqtt_consumer]]
  servers = ["tcp://192.168.50.127:1883"]
  topics = ["homelab/presence/#", "homelab/air_quality/#", "homelab/thermal/#"]
  username = "homelab"
  password = "YOUR_MQTT_PASSWORD"
  data_format = "value"
  data_type = "string"

[[outputs.influxdb]]
  urls = ["http://192.168.10.83:8086"]
  database = "esp32_sensors"
```

### 4E — n8n Automation Without HA

The n8n workflows in `n8n-workflows/` connect directly to MQTT — zero HA dependency. Import them as described in the n8n section. They handle:
- Telegram alerts when rooms change state
- CO₂ and PM2.5 threshold notifications
- Direct InfluxDB writes

---

## 🏠 Part 5 — Optional Home Assistant Integration

If you want HA integration on top of the standalone stack:

1. Go to **Settings → Devices & Services**
2. The node should appear automatically as "ESPHome device discovered"
3. Click **Configure** → enter your API key from `secrets.yaml`
4. All sensors appear as HA entities immediately

### Disabling HA API (Pure MQTT Mode)

If you want the nodes to be completely HA-independent, remove the API section from the config and add `api: false`:

```yaml
# In presence-node.yaml, replace the api: block with:
# api:             ← remove this
#   encryption:    ← remove this
#     key: ...     ← remove this

# The node will only communicate via MQTT. HA cannot control it directly.
# You lose: OTA from HA dashboard, HA entity auto-discovery
# You keep: full MQTT operation, Node-RED, Grafana, n8n, web server at node IP
```

---

## 🗺️ Part 6 — 3D Presence Visualization

Visualizing where your presence sensors are covering in your floor plan helps with:
- Deciding where to mount sensors for best coverage
- Understanding blind spots in the radar's field of view
- Planning how many sensors you need per room

### Recommended Tool: Home Assistant Floor Plan (Free, Easiest)

Even if you don't use HA for automation, its floor plan card is the best free tool for showing sensor coverage in 2D/3D.

**How to set it up:**

1. In HA, go to **Overview → Edit Dashboard → Add Card → Picture Elements**
2. Upload a PNG floor plan of your home
3. Add sensor overlays at the correct coordinates

This gives you a live map where circles turn green/red based on real MQTT sensor data.

### Option 1: Floorplanner.com (Best for 3D, Free Tier)

**Website:** https://www.floorplanner.com  
**Platform:** Browser-based, no install

**Why use it:**
- Draw your floor plan in 2D, switch to 3D with one click
- Place furniture and visualize realistic room layouts
- Export as images to embed in README or Node-RED dashboard
- The free tier is sufficient for home layouts

**How to use for sensor placement:**
1. Create a new project → draw your rooms
2. Use the "Furniture" library → search for "camera" or "sensor" to place markers
3. Switch to 3D view → position sensors on walls/ceiling
4. The 3D view shows approximately what the sensor will "see"

### Option 2: FreeCAD (Free, Most Powerful, Offline)

**Website:** https://www.freecad.org  
**Platform:** Windows/Linux/Mac, free, open source

**Why use it:**
- Full parametric 3D modeling — draw exact dimensions
- Import DXF floor plans from architects
- Create accurate cone-of-detection models for each sensor
- Best for engineering-level documentation
- Steeper learning curve but more precise

**Beginner workflow:**
1. Download FreeCAD → use the **Arch workbench** for floor plans
2. Draw walls as rectangles at exact dimensions
3. Add cylinders/cones to represent radar detection zones:
   - LD2410C: 6m range, roughly 60° detection angle
   - AMG8833: 7m range, 60°×60° field of view
   - AM312 PIR: 3m range, 100° detection angle

### Option 3: Excalidraw (Quickest, Browser-Based)

**Website:** https://excalidraw.com  
**Platform:** Browser, free, no login needed

**Why use it:**
- Draw a rough floor plan in 5 minutes
- Add sensor positions with cone-of-detection arrows
- Export as PNG/SVG for documentation
- Not 3D, but the fastest way to sketch sensor coverage

**Template to sketch a room:**
```
      ┌──────────────────────────────────────┐
      │                                      │
      │  [Desk]                              │
      │                                      │
      │         ◉ LD2410C (mounted at 1.5m)  │
      │        /│\                           │
      │       / │ \  ← 60° detection angle   │
      │      /  │  \                         │
      │     /   │   \                        │
      │    ▼         ▼                       │
      │  [6m range cone]                     │
      └──────────────────────────────────────┘
```

### Option 4: Home Assistant + Lovelace-Floorplan (Live 3D-ish)

**GitHub:** https://github.com/ExperienceLovelace/ha-floorplan  
**Platform:** Home Assistant add-on

This is the most powerful option if you use HA — it overlays live sensor data on an SVG floor plan. Sensors pulse green when occupied, turn red for air quality alerts, etc. Effectively creates a live animated presence map.

**Setup:**
1. Install via HACS (Home Assistant Community Store)
2. Create an SVG version of your floor plan (use Inkscape — free)
3. Map sensor entity IDs to SVG elements
4. Each sensor node shows real-time status on the plan

### Sensor Detection Geometry Reference

Use these specs when placing sensors in your floor plan tool:

| Sensor | Range | Detection Angle | Best Mount Height | Notes |
|--------|-------|-----------------|-------------------|-------|
| LD2410C radar | 6m | ~60° horizontal | 1.0–2.5m | Aim at occupancy zone center |
| Seeed MR24HPC1 | 5m | ~60° | 1.0–2.5m | Scene mode for bathroom |
| AM312 PIR | 3m | 100° | 1.5–2.0m | Point slightly downward |
| AMG8833 thermal | 7m | 60°×60° | ceiling (2.5m) | Best overhead for person counting |

**LD2410C coverage cone (top-down view):**
```
               Radar (mounted on wall)
                     ●
                    /|\
                   / | \
                  /  |  \   30° each side
                 /   |   \  = 60° total
                /    |    \
               /     |     \
              ▼      ▼      ▼
         ◄────────── 6m ──────────►
```

**AMG8833 coverage (mounted on ceiling, looking down):**
```
         Ceiling mount point
               ●
              /|\
             / | \
            /  |  \   30° each side
           /60°|60°\  = 60°×60° FOV
          /    |    \
         ─────────────
              ~7m
          (footprint at floor: ~8m×8m from 2.5m height)
```

---

## ⚙️ Part 7 — Configuration Details

### Understanding the YAML Structure

Every sensor node has two files:
1. A **shared base** (e.g., `presence-node.yaml`) — contains all the logic
2. A **room instance** (e.g., `presence-office.yaml`) — contains only the room-specific settings

You never touch the base file. You only edit the room instance.

**The substitutions block in a room instance:**
```yaml
substitutions:
  node_name: "presence-office"      ← Internal ID (no spaces, lowercase)
  node_friendly: "Office Presence"  ← Name shown in HA / web interface
  room_name: "office"               ← Used in MQTT topics
  ld2410_max_distance: "4m"         ← Radar range
  ld2410_still_threshold: "20"      ← Lower = more sensitive (10 for sleeping)
  ld2410_move_threshold: "20"       ← Moving target sensitivity
  pir_delay_off: "15s"              ← How long PIR stays true after motion
  update_interval: "5s"             ← How often to report to MQTT
  log_level: "INFO"                 ← DEBUG for troubleshooting
```

### Adding a New Room

```bash
# Copy an existing room config:
copy presence-sensor\esphome\presence-office.yaml presence-sensor\esphome\presence-nursery.yaml

# Edit the substitutions block in presence-nursery.yaml
# Change: node_name, node_friendly, room_name
# Flash it:
tools\windows\flash-windows.bat presence-nursery
```

---

## 🔧 Part 8 — Tuning Sensors

After deploying, tune via Home Assistant sliders (no reflashing) or by editing the config substitutions.

### LD2410C Tuning Guide

| Room Type | Max Distance | Still Threshold | Timeout | Notes |
|-----------|-------------|-----------------|---------|-------|
| Home office | 3–4m | 15–20 | 10s | Point at desk |
| Living room | 5–6m | 15–20 | 5s | Mount corner for wide coverage |
| Bedroom | 3–4m | 8–12 | 30s | Low threshold detects sleeping |
| Bathroom | 2m | 20–25 | 30s | Use MR24HPC1 Toilet mode |
| Kitchen | 4m | 20 | 5s | Avoid pointing at microwave |
| Hallway | 4–6m | 20 | 3s | Set along hall axis |

**Troubleshooting false positives** (shows occupied when empty):
- Increase `still_threshold` (from 20 to 30)
- Reduce `max_still_distance_gate` in HA
- Avoid pointing at HVAC vents or windows

**Troubleshooting false negatives** (shows empty when occupied):
- Decrease `still_threshold` (from 20 to 10)
- Enable **Engineering Mode** in HA to see live energy values
- Reposition sensor — make sure detection cone covers the occupancy zone

### AMG8833 Temperature Threshold

The `human_temp_threshold` value in `thermal-sensor.yaml` determines what counts as a "human":

| Season / Situation | Recommended Threshold |
|---|---|
| Summer (warm house) | 30.0°C |
| Winter (cold house) | 26.0°C |
| Detect pets too | 25.0°C |
| Humans only, exclude pets | 31.0°C |

---

## 📡 Part 9 — UniFi Configuration

### Create IoT SSID for VLAN 5

1. UniFi Network → **WiFi** → **Add WiFi Network**
2. Name: `HomeLab-IoT` (this is your `wifi_ssid` in secrets.yaml)
3. Password: anything
4. Advanced → VLAN → **5**
5. Disable **Band Steering** (ESP32 needs 2.4GHz)
6. Save

### Firewall Rules

| Rule | Source | Dest | Port | Action |
|------|--------|------|------|--------|
| IoT → MQTT | VLAN 5 | `192.168.50.127` | 1883 | Allow |
| IoT → HA API | VLAN 5 | `192.168.50.127` | 8123 | Allow |
| IoT → InfluxDB | VLAN 5 | `192.168.10.83` | 8086 | Allow |
| Block IoT → LAN | VLAN 5 | All LAN | Any | Block |

---

## 🚨 Part 10 — Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Flash fails: "Failed to connect" | Not in boot mode | Hold BOOT, then plug USB |
| Flash fails: "No serial port found" | No USB driver | Run setup.bat, install CP210x driver |
| Node won't join WiFi | Wrong SSID/password | Connect to fallback hotspot `<node>-fallback`, browse to `192.168.4.1` |
| No MQTT messages | Wrong MQTT credentials | Check `mqtt_broker`, `mqtt_username`, `mqtt_password` in secrets.yaml |
| Radar shows empty when occupied | Sensitivity too low | Lower `still_threshold` to 10, or reduce `max_still_distance_gate` |
| Radar shows occupied when empty | False positive | Increase `still_threshold` to 30, check for HVAC vents in detection zone |
| C6 won't compile | Wrong framework | Ensure `framework: type: esp-idf` — C6 doesn't support Arduino |
| I2C sensors not found | Wrong wiring or address | Enable `scan: true` in i2c config, check logs for found addresses |
| OTA fails | Node offline | Do a USB flash to recover; hold BOOT and replug |

---

## 📋 MQTT Topic Reference

| Topic | Values | Description |
|-------|--------|-------------|
| `homelab/presence/{room}/occupied` | `true`/`false` | Room occupancy (main sensor) |
| `homelab/presence/{room}/status` | `online`/`offline` | Node alive status |
| `homelab/air_quality/{loc}/alerts/co2` | `normal`/`warning`/`critical` | CO₂ alert level |
| `homelab/air_quality/{loc}/alerts/pm25` | `normal`/`warning` | PM2.5 alert level |
| `homelab/thermal/{room}/hot_pixels` | `0`–`64` | Thermal hot pixels above threshold |

---

## 🗺️ Roadmap

- [ ] BLE phone tracking — detect your phone MAC for person-level presence
- [ ] Acoustic detection — use XIAO S3 built-in mic for glass break, smoke alarm
- [ ] Rover integration — mount ESP32-S3 on UGV as mobile presence probe
- [ ] AMG8833 live heatmap — Node-RED dashboard card showing 8×8 thermal grid
- [ ] ESP32-C6 Thread/Matter — future border router once ESPHome supports it

---

## 📚 References

- [Seeed XIAO ESP32-S3 Sense Wiki & Pinout](https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/)
- [Seeed XIAO ESP32-C6 Wiki & Pinout](https://wiki.seeedstudio.com/xiao_esp32c6_getting_started/)
- [ESPHome LD2410 Component](https://esphome.io/components/sensor/ld2410.html)
- [ESPHome Seeed MR24HPC1 Component](https://esphome.io/components/sensor/seeed_mr24hpc1.html)
- [ESPHome SCD4x (CO₂)](https://esphome.io/components/sensor/scd4x.html)
- [ESPHome SEN5x (Particulates)](https://esphome.io/components/sensor/sen5x.html)
- [ESPHome AMG8833 (Thermal)](https://esphome.io/components/sensor/amg8833.html)
- [CP210x USB Driver (Silabs)](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- [Floorplanner.com — 3D Floor Plan Tool](https://www.floorplanner.com)
- [FreeCAD — Free 3D CAD](https://www.freecad.org)
- [ha-floorplan — Live HA Presence Map](https://github.com/ExperienceLovelace/ha-floorplan)

---

*Part of the rasenganguy homelab. See also: [homelab-robotics](https://github.com/rasenganguy/homelab-robotics)*
