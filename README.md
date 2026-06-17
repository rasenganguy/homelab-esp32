# homelab-esp32

> **ESP32-based sensor nodes for the YouShallNotPass homelab**  
> Presence detection · Air quality monitoring · Thermal sensing · Home Assistant integration

[![Validate ESPHome Configs](https://github.com/rasenganguy/homelab-esp32/actions/workflows/validate.yml/badge.svg)](https://github.com/rasenganguy/homelab-esp32/actions)

---

## Hardware Inventory (From Invoice #4000537861, Jun 10 2026)

| Item | SKU | Qty | Unit | Use |
|------|-----|-----|------|-----|
| Seeed XIAO ESP32-S3 Sense (Pre-Soldered) | 102010635 | 2 | $14.24 | Presence sensor nodes |
| Seeed XIAO ESP32-C6 (Pre-Soldered) | 102010636 | 2 | $5.89 | Environmental monitor nodes |
| 24GHz mmWave Human Static Presence Sensor | 101010001 | 4 | $4.49 | Standalone static presence |

Additional recommended hardware (not in invoice) is listed per-project below.

---

## Project Overview

```
homelab-esp32/
├── presence-sensor/          # ESP32-S3 + LD2410C mmWave + AM312 PIR (primary presence nodes)
├── air-quality-monitor/      # ESP32-S3 + SCD40 + SEN55 + ENS160 + BMP280
├── thermal-presence/         # ESP32-S3 + AMG8833 8x8 thermal grid (bonus: person counting)
├── esp32-c6-gateway/         # ESP32-C6 as WiFi 6 environmental monitor
├── n8n-workflows/            # Pre-built n8n automation workflows
├── ansible/                  # Ansible playbook to deploy ESPHome
└── .github/workflows/        # CI — validates all ESPHome configs on push
```

---

## Network Architecture

All ESP32 nodes connect to **VLAN 5 (IoT, 192.168.5.0/24)** via a dedicated IoT SSID.

```
ESP32 Nodes (VLAN 5)
      │
      ▼ MQTT (port 1883)
HA MQTT Broker @ 192.168.50.127 (VLAN 50)
      │                    │
      ▼ Native API          ▼ MQTT
Home Assistant         n8n (CT123, 192.168.10.60)
      │                    │
      ▼                    ▼
InfluxDB (CT109)      Telegram Alerts
      │
      ▼
Grafana Dashboard
```

---

## Project 1: Room Presence Sensor

**Best accuracy room presence detection using radar + PIR fusion.**

### How It Works

| Sensor | Role | What It Detects |
|--------|------|-----------------|
| **LD2410C mmWave 24GHz** | Primary detector | Moving AND still humans (breathing micro-motion), up to 6m |
| **AM312 PIR** | Fast trigger | Rapid motion entry — fires instantly, wakes LD2410C from low power |
| **Virtual "Combined"** | HA binary sensor | OR of LD2410C presence + PIR — zero false negatives |

**Why LD2410C and not WiFi CSI alone?** CSI is excellent for motion but fails with stationary humans (someone sitting still reading). The LD2410C detects micro-motion from breathing and heartbeat, making it the gold standard for "is anyone actually in this room."

### Hardware Required (per node)

| Component | Source | ~Price | Notes |
|-----------|--------|--------|-------|
| XIAO ESP32-S3 Sense (Pre-Soldered) | Already purchased | $14.24 | 8MB PSRAM, dual-core LX7 |
| HLK-LD2410C 24GHz mmWave | Amazon ASIN B0CS9GLD7X (5-pack) | ~$4/ea | UART + GPIO output, 6m range |
| AM312 Mini PIR | Amazon ASIN B09X38GPMN (5-pack) | ~$2/ea | 3.3V native, no level shifter |
| Female-to-female Dupont jumpers | Amazon | ~$5/bag | 20cm length ideal |
| USB-C cable | Any | ~$5 | For initial flashing |

**Total per node: ~$20**

### Wiring Diagram

```
XIAO ESP32-S3 Sense                LD2410C mmWave
┌─────────────────┐               ┌──────────────────┐
│            3.3V ├──────────────►│ VCC              │
│             GND ├──────────────►│ GND              │
│   D6 (GPIO43/TX)├──────────────►│ RX               │
│   D7 (GPIO44/RX)│◄──────────────┤ TX               │
│   D0 (GPIO1)    │◄──────────────┤ OUT (optional)   │
└─────────────────┘               └──────────────────┘

XIAO ESP32-S3 Sense                AM312 PIR
┌─────────────────┐               ┌──────────────────┐
│            3.3V ├──────────────►│ VCC              │
│             GND ├──────────────►│ GND              │
│   D1 (GPIO2)    │◄──────────────┤ OUT              │
└─────────────────┘               └──────────────────┘

⚠️ IMPORTANT: TX → RX cross-connection (TX of one to RX of other)
⚠️ ALL components run on 3.3V — no level shifters needed
```

### Step-by-Step Setup

#### Step 1: Install ESPHome

**Option A — Via Python (recommended for CT101 Semaphore host):**
```bash
# On CT101 (192.168.10.228) or any LXC
pip3 install esphome --break-system-packages
```

**Option B — Via Docker on Proxmox host:**
```bash
docker run -d \
  --name esphome \
  --network=host \
  -v /opt/esphome/config:/config \
  ghcr.io/esphome/esphome
# Dashboard available at http://<host>:6052
```

**Option C — ESPHome Add-on in Home Assistant (simplest):**  
Settings → Add-ons → ESPHome → Install

#### Step 2: Configure Secrets

```bash
cp secrets.yaml.example /opt/esphome/config/secrets.yaml
nano /opt/esphome/config/secrets.yaml
```

Edit these values:
```yaml
wifi_ssid: "YourIoTSSID"          # VLAN 5 IoT SSID in UniFi
wifi_password: "YourPassword"
ha_api_key: "base64key"           # Generate: python3 -c "import secrets; print(secrets.token_urlsafe(32))"
ha_ota_password: "YourOTAPass"
mqtt_broker: "192.168.50.127"     # HA MQTT broker
mqtt_username: "homelab"
mqtt_password: "YourMQTTPass"
```

#### Step 3: Copy ESPHome Configs

```bash
cp presence-sensor/esphome/*.yaml /opt/esphome/config/
cp presence-sensor/esphome/pin-reference.yaml /opt/esphome/config/
```

#### Step 4: Initial Flash via USB

Connect XIAO ESP32-S3 to your PC via USB-C. **On the XIAO S3, hold the BOOT button while connecting USB** to enter flash mode.

```bash
# From your ESPHome config directory
esphome run presence-office.yaml

# If port not found:
ls /dev/ttyUSB* /dev/ttyACM*  # Linux
# or check Device Manager on Windows
```

**For WSL2 users:**
```bash
# Install usbipd-win on Windows, then:
usbipd list
usbipd attach --wsl --busid <BUSID>
# Now flash from WSL
```

#### Step 5: Verify in Home Assistant

1. Go to **Settings → Devices & Services**
2. You should see ESPHome integration auto-discovered
3. Click **Configure** and enter your API key
4. Verify entities appear: `binary_sensor.office_presence_occupied_combined`, etc.

#### Step 6: Add Template Sensors

Paste contents of `presence-sensor/ha-automations/template-sensors.yaml` into your HA `configuration.yaml` (or use packages).

```bash
# In HA config directory
nano /config/configuration.yaml

# Add:
homeassistant:
  packages:
    esp32_presence: !include_dir_named packages/esp32/
```

Or paste directly under `template:` and `input_boolean:` sections.

#### Step 7: Import Automations

1. HA → Settings → Automations → **⋮** → Import
2. Upload `presence-sensor/ha-automations/presence-automations.yaml`
3. Adjust entity IDs to match your actual sensor names

#### Step 8: Deploy More Nodes (OTA)

Once one node is flashed and on WiFi, deploy others over-the-air:

```bash
# Edit substitutions in presence-livingroom.yaml, then:
esphome run presence-livingroom.yaml
# No USB needed — pushes via WiFi OTA
```

#### Step 9: Tune LD2410C (optional)

Via Home Assistant entities or the LD2410C Bluetooth app (HLKRadarTool):
- **Max Distance Gate** — reduce if getting false detections from adjacent room
- **Still Threshold** — lower for more sensitive still detection (useful for sleeping)
- **Timeout** — how long after last detection before "unoccupied" fires (default 5s)

**Recommended settings per room type:**

| Room | Max Distance | Still Threshold | Timeout |
|------|-------------|-----------------|---------|
| Office (desk work) | 4m | 15 | 10s |
| Living room | 6m | 20 | 5s |
| Bedroom (sleep detect) | 4m | 10 | 30s |
| Bathroom | 2m | 20 | 30s |

---

## Project 2: Seeed 24GHz mmWave Static Presence Sensor

The **Seeed 101010001** from your invoice is the MR24HPC1 — Seeed's own 24GHz FMCW radar. It has native ESPHome support with more advanced features than the LD2410C.

### When to Use MR24HPC1 vs LD2410C

| | MR24HPC1 (Seeed, your invoice) | LD2410C (add-on purchase) |
|--|--|--|
| ESPHome support | ✅ Native (`seeed_mr24hpc1`) | ✅ Native (`ld2410`) |
| Scene modes | ✅ Standard/Area/Toilet | ❌ |
| Respiratory rate | ✅ (experimental) | ❌ |
| Price | $4.49 (your invoice) | ~$4 |
| Range | 5m | 6m |
| Best for | Kitchen, bathroom, complex rooms | Bedroom, office |

### Wiring (same as LD2410C)

```
XIAO ESP32-S3           MR24HPC1
3V3     ──────────────► VCC
GND     ──────────────► GND
GPIO43  ──────────────► RX
GPIO44  ◄────────────── TX
```

### Setup

Same ESPHome flow as Project 1. Use config file: `presence-sensor/esphome/seeed-mmwave-24ghz.yaml`

Edit `substitutions` at the top to set room name and detection parameters.

---

## Project 3: Air Quality Monitor

**Full indoor air quality node with CO₂, particulates, VOC, NOx, pressure.**

### Sensors

| Sensor | Measures | Protocol | I2C Addr |
|--------|----------|----------|----------|
| **SCD40** (Sensirion) | CO₂ (400–5000ppm), Temp, Humidity | I2C | 0x62 |
| **SEN55** (Sensirion) | PM1/2.5/4/10, VOC Index, NOx, Temp, RH | I2C | 0x69 |
| **ENS160** (ScioSense) | AQI (1–5), eCO₂, TVOC | I2C | 0x53 |
| **BMP280** | Barometric pressure, temp | I2C | 0x76 |

### Hardware Required

| Component | Amazon ASIN | ~Price |
|-----------|------------|--------|
| XIAO ESP32-S3 Sense | Already purchased | — |
| SCD40 CO₂ sensor (Qwiic) | B09W4N7LL8 | ~$30 |
| SEN55 module | B0B66ZQPGX | ~$45 |
| ENS160 + AHT21 breakout | B0C2F7KSGC | ~$12 |
| BMP280 (Qwiic) | B07D8T4HP6 | ~$10 |
| Qwiic cables (10cm, 5-pack) | B08FMKFQB2 | ~$8 |

**Total: ~$105** (SEN55 is the expensive part — optional, SCD40 alone is $30)

### Wiring (Daisy Chain — No Soldering)

```
XIAO D4(SDA) ──┐
XIAO D5(SCL) ──┤──► SCD40 ──► SEN55 ──► ENS160 ──► BMP280
XIAO 3V3     ──┤    (Qwiic cable chain, all 3.3V)
XIAO GND     ──┘
```

All sensors are on the shared I2C bus. Each has a unique address — no conflicts.

### Setup

```bash
cp air-quality-monitor/esphome/air-quality-node.yaml /opt/esphome/config/
esphome run air-quality-node.yaml
```

### Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| CO₂ | 1000 ppm | 2000 ppm | Open windows / trigger Aprilaire |
| PM2.5 | 25 µg/m³ | — | Run air purifier |
| VOC Index | 200 | — | Ventilate |
| AQI | 3 | 4+ | Telegram alert |

---

## Project 4: XIAO ESP32-C6 — WiFi 6 Environmental Monitor

> **Why NOT CSI with C6?**  
> The C6 has only 512KB SRAM — insufficient to buffer CSI subcarrier data. The S3's 8MB PSRAM is required for CSI. Use C6 for lightweight sensing with deep sleep for battery-powered deployments.

### C6 Best Use Cases

- Battery-powered environmental sensor (BME280/SHT31)
- Future Matter/Thread border router (requires different firmware)
- WiFi 6 network probe node

### Setup

```bash
cp esp32-c6-gateway/esphome/c6-env-monitor.yaml /opt/esphome/config/
esphome run c6-env-monitor.yaml
```

Note: C6 **requires** `framework: esp-idf` — Arduino framework is not supported on this chip.

---

## Project 5: Thermal Presence Sensor (Bonus)

**AMG8833 8x8 thermal grid sensor for heat-based presence detection with crude person counting.**

### Why Add Thermal?

- Detects **heat signatures** — works even when mmWave is fooled
- Can detect pets vs humans (temperature difference)
- Provides **room heatmap** visualization in HA
- Rough **person count** (1 person / 2+ people) based on hot pixel area
- Detects warm objects mmWave misses (oven left on, hot appliances)

### Hardware Required

| Component | Amazon ASIN | ~Price |
|-----------|------------|--------|
| AMG8833 Grid-EYE (Adafruit or SparkFun, Qwiic) | B07DL6SB4J | ~$35 |
| XIAO ESP32-S3 Sense | Already purchased | — |
| Qwiic cable | B08FMKFQB2 | ~$8 |

### Wiring

```
XIAO D4(SDA/GPIO5) ──► AMG8833 SDA  (Qwiic)
XIAO D5(SCL/GPIO6) ──► AMG8833 SCL  (Qwiic)
XIAO 3V3           ──► AMG8833 VCC
XIAO GND           ──► AMG8833 GND
```

### Setup

```bash
cp thermal-presence/esphome/thermal-sensor.yaml /opt/esphome/config/
esphome run thermal-sensor.yaml
```

### Tuning `human_temp_threshold`

| Scenario | Recommended Threshold |
|----------|----------------------|
| Summer (warm environment) | 30.0°C |
| Winter (cold environment) | 26.0°C |
| Detecting pets too | 25.0°C |
| Humans only, no pets | 31.0°C |

---

## n8n Workflows

### Import Instructions

1. Open n8n at `http://192.168.10.60:5678`
2. **Workflows → Import from File**
3. Import each JSON from `n8n-workflows/`
4. Configure credentials:
   - **MQTT**: broker `192.168.50.127`, port `1883`
   - **Telegram**: use existing HomeLab Telegram bot
5. Activate workflows

### Available Workflows

| File | Purpose |
|------|---------|
| `presence-alerts-workflow.json` | MQTT → parse room → Telegram alert + HA state update |
| `air-quality-workflow.json` | MQTT air quality events → Telegram alerts + InfluxDB write |

---

## Grafana Dashboard

### Import Instructions

1. Open Grafana at `http://192.168.10.83:3000`
2. **Dashboards → Import → Upload JSON file**
3. Upload `presence-sensor/grafana/esp32-dashboard.json`
4. Select your InfluxDB datasource when prompted
5. Panels auto-populate once sensors are reporting

### Dashboard Panels

- CO₂ levels (24h) with WHO threshold annotations
- PM2.5 / PM10 particulates
- Room occupancy current state (color-coded)
- Temperature & Humidity (dual-axis)
- VOC & NOx Index trends
- LD2410C detection distances

---

## Ansible Deployment

Deploy and manage ESPHome from CT101 (Semaphore):

```bash
# From CT101 (192.168.10.228)
cd /home/semaphore/playbooks
git clone https://github.com/rasenganguy/homelab-esp32.git
cd homelab-esp32

# Deploy ESPHome environment
ansible-playbook ansible/deploy-esphome.yml -i ansible/inventory.yml

# OTA update all nodes
ansible-playbook ansible/deploy-esphome.yml -i ansible/inventory.yml --tags ota

# Flash specific node via USB
ansible-playbook ansible/deploy-esphome.yml -i ansible/inventory.yml --tags flash \
  -e "node_config=presence-office"
```

---

## UniFi / VLAN Configuration

### Required UniFi Settings

1. **Create IoT SSID** (if not already done):
   - UniFi → WiFi → Add WiFi Network
   - Name: `YourHomeIoT` (or whatever matches your `wifi_ssid` in secrets)
   - VLAN: 5
   - Security: WPA2-Personal
   - Disable: Band Steering, Fast Roaming (improves ESP32 compatibility)

2. **Firewall Rules** — IoT VLAN to HA MQTT:
   - Allow: `192.168.5.0/24` → `192.168.50.127` port `1883` (MQTT)
   - Allow: `192.168.5.0/24` → `192.168.50.127` port `8123` (HA API/OTA)
   - Block: `192.168.5.0/24` → All other LANs

3. **AdGuard DNS** (CT124, `192.168.10.227`):
   - Add local DNS: `*.iot.local` → `192.168.5.x` (per node)
   - This enables `presence-office.iot.local` hostname resolution

---

## Home Assistant MQTT Broker Setup

If MQTT broker isn't already configured in HA:

```bash
# HA → Settings → Add-ons → Mosquitto broker → Install
```

Or if using external MQTT (already configured at `192.168.50.127`):

```yaml
# configuration.yaml
mqtt:
  broker: 192.168.50.127
  port: 1883
  username: homelab
  password: !secret mqtt_password
  discovery: true
  discovery_prefix: homeassistant
```

Create MQTT user in Mosquitto:
```bash
# On HA host
ha core exec mosquitto_passwd -c /share/mosquitto/passwd homelab
```

---

## Multi-Node Deployment — Adding Rooms

To add a new room presence node:

1. **Copy a room config:**
   ```bash
   cp presence-sensor/esphome/presence-office.yaml presence-sensor/esphome/presence-nursery.yaml
   ```

2. **Edit substitutions** in `presence-nursery.yaml`:
   ```yaml
   substitutions:
     node_name: "presence-nursery"
     node_friendly: "Nursery Presence"
     room_name: "nursery"
     ld2410_max_distance: "4m"
     ld2410_still_threshold: "10"   # Very sensitive for detecting sleeping infant
   ```

3. **Wire up the hardware** (same wiring as all other nodes)

4. **Flash via USB** first time:
   ```bash
   esphome run presence-sensor/esphome/presence-nursery.yaml
   ```

5. **Add to HA automations** — duplicate the office automation block, change entity IDs.

---

## Troubleshooting

### Node won't appear in HA

```bash
# Check ESPHome logs
esphome logs presence-office.yaml

# Verify MQTT messages arriving
mosquitto_sub -h 192.168.50.127 -u homelab -P <pass> -t "homelab/presence/#" -v
```

### LD2410C not detecting still presence

- Enable **Engineering Mode** via HA entity `switch.office_presence_engineering_mode`
- Watch energy values in Grafana — increase sensitivity if still energy stays at 0
- Ensure sensor is aimed at the detection zone (typically 30–60° downward angle works best)
- Reduce `still_threshold` in substitutions (try `10` instead of `20`)

### ESP32-S3 fails to flash on Linux

```bash
# Add user to dialout group
sudo usermod -aG dialout $USER
# Log out and back in

# Check port
ls -la /dev/ttyACM* /dev/ttyUSB*

# Force bootloader mode: hold BOOT button before plugging USB
```

### ESP32-C6 compile fails with Arduino framework error

C6 requires ESP-IDF, not Arduino. Ensure your config has:
```yaml
framework:
  type: esp-idf
```

### XIAO S3 NeoPixel LED shows wrong colors

The XIAO S3 onboard LED is on GPIO21, GRB order (not RGB). The config already handles this — if colors are wrong, verify `rgb_order: GRB` in the light config.

### Node goes offline after OTA update

Check if there's a captive portal fallback AP appearing (named `<node>-fallback`). Connect to it and verify WiFi credentials. This usually means the IoT SSID credentials changed or the VLAN assignment shifted.

---

## Roadmap / Future Enhancements

- [ ] **BLE Proximity Tracking** — use XIAO S3 BLE scanner to track phone MACs for person-level presence
- [ ] **Jetson CSI Analysis** — stream CSI data from ESP32-S3 to Jetson Orin for ML-based activity classification
- [ ] **Rover Integration** — mount ESP32-S3 on UGV rover as a mobile presence probe sweeping all rooms
- [ ] **AMG8833 Heatmap** — HA Lovelace card with live 8x8 thermal visualization
- [ ] **ESP32-C6 Thread Mesh** — deploy C6 nodes as Thread/Matter border routers once ESPHome adds support
- [ ] **Acoustic Detection** — use XIAO S3 onboard microphone for glass break, smoke alarm, dog bark detection
- [ ] **Homepage Widget** — add ESP32 sensor summary widget to "The Palantír" dashboard

---

## References

- [ESPHome LD2410 Component Docs](https://esphome.io/components/sensor/ld2410.html)
- [ESPHome Seeed MR24HPC1 Docs](https://esphome.io/components/sensor/seeed_mr24hpc1.html)
- [ESPHome SCD4x Docs](https://esphome.io/components/sensor/scd4x.html)
- [ESPHome SEN5x Docs](https://esphome.io/components/sensor/sen5x.html)
- [ESPHome ENS160 Docs](https://esphome.io/components/sensor/ens160.html)
- [Seeed XIAO ESP32-S3 Sense Wiki](https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/)
- [Seeed XIAO ESP32-C6 Wiki](https://wiki.seeedstudio.com/xiao_esp32c6_getting_started/)

---

*Part of the rasenganguy homelab stack. See also: [homelab-robotics](https://github.com/rasenganguy/homelab-robotics)*
