# IoT Water Tank Controller & Monitoring System

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Firmware: ESP8266](https://img.shields.io/badge/Firmware-ESP8266%20%7C%20Arduino-orange.svg)](https://arduino.cc)
[![Backend: Node.js / Express](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express%20%7C%20TypeScript-green.svg)](https://nodejs.org)
[![Mobile: Flutter](https://img.shields.io/badge/Mobile-Flutter%20%7C%20Dart%20%7C%20Riverpod-02569B.svg)](https://flutter.dev)

An enterprise-grade, end-to-end IoT automation platform designed to prevent water wastage, automate electric water pump cycling, protect motors against dry runs, and provide resilient local and remote cloud controls with offline fallbacks.

---

## 🏛️ System Architecture

The system operates across three interconnected layers designed for fault tolerance and zero-delay response:

```text
┌─────────────────────────┐
│     Water Sensors       │ (Overhead & Underground Float / Probe Sensors)
└───────────┬─────────────┘
            │ GPIO Signals
┌───────────▼─────────────┐          Local Wi-Fi (HTTP REST)
│    ESP8266 Controller   │◄──────────────────────────────────────────────┐
│  - Relay Activation     │                                               │
│  - Dry-Run Lockout      │                                               │
│  - Health Diagnostics   │                                               │
└───────────┬─────────────┘                                               │
            │ Cloud Sync (HTTPS + Token Auth)                             │
┌───────────▼─────────────┐                                               │
│     Render Backend      │                                               │
│  - PostgreSQL Database  │                                               │
│  - JWT Authentication   │                                               │
│  - Command Queue & ACK  │                                               │
└───────────▲─────────────┘                                               │
            │ Cloud REST API (HTTPS)                                      │
┌───────────┴─────────────────────────────────────────────────────────────┴─┐
│                           Flutter Mobile Client                           │
│  - Real-time Glassmorphic Dashboard                                       │
│  - Dual Connection Routing (Auto Fallback: Local LAN <-> Render Cloud)    │
│  - Role-based Access Control (Administrator vs. Family Member)            │
│  - Audit Logging & Runtime Analytics                                      │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- **Automated Overflow & Dry-Run Protection:** Automatic pump shutdown when the tank reaches maximum capacity, with hardware safety lockout timers to prevent pump damage.
- **Dual-Mode Connectivity Engine:** Mobile app dynamically routes commands directly to the ESP8266 via local LAN IP when on the home Wi-Fi for sub-50ms latency, seamlessly falling back to cloud relay over Render when away.
- **Hardware-Level Reliability:**
  - Fast watchdog timer reset and heap memory leak monitoring.
  - EEPROM persistence for runtime counters across power cycles.
  - Non-blocking Wi-Fi auto-reconnection and exponential backoff retry for cloud sync.
- **Role-Based Access Control (RBAC):**
  - **Admin:** Full manual pump control, lockout clearing, system configuration, timer settings.
  - **Family:** View-only live telemetry, tank levels, and notifications.

---

## 📂 Repository Structure

```text
├── WaterTankController_Package1.ino   # ESP8266 C++ firmware with local HTTP + cloud client
├── backend/                           # Node.js TypeScript cloud backend
│   ├── src/                           # Express REST API, auth controllers, database routes
│   ├── prisma/                        # Database schema and migrations
│   ├── Dockerfile                     # Production containerization
│   └── .env.example                   # Environment configuration template
├── lib/                               # Flutter cross-platform mobile client
│   ├── core/                          # Firmware contract, API endpoints, tokens
│   ├── models/                        # Controller status, user models, settings
│   ├── providers/                     # Riverpod state management & connection controllers
│   ├── repositories/                  # Auth, persistence, and network repositories
│   ├── screens/                       # Dashboard, manual control, settings, analytics
│   ├── services/                      # Connection routing (LAN fast-fail vs. Cloud)
│   └── widgets/                       # Custom glassmorphism UI components
├── android/                           # Native Android build configurations & manifests
├── render.yaml                        # Infrastructure-as-code for Render cloud deploy
└── LICENSE                            # GNU General Public License v3.0
```

---

## 🛠️ Getting Started

### 1. Firmware Setup (ESP8266)

1. Open `WaterTankController_Package1.ino` in the Arduino IDE or PlatformIO.
2. Ensure you have the `ESP8266` board package installed.
3. Configure your Wi-Fi credentials and device token:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   const char* deviceToken = "YOUR_CUSTOM_SECRET_DEVICE_TOKEN";
   const char* cloudBaseUrl = "https://your-cloud-backend.onrender.com";
   ```
4. Connect your hardware:
   - **Relay Control Pin:** Pin `GPIO 5` (D1)
   - **Status LED:** Pin `GPIO 2` (D4 / Builtin LED)
5. Flash the sketch to your ESP8266 board.

#### Firmware REST API Specification (Local LAN)
- `GET /api/status`: Returns current pump state, float sensor status, runtime timers, and lockout flag.
- `POST /api/pump/on`: Energizes relay to start the water pump.
- `POST /api/pump/off`: De-energizes relay to halt the water pump.
- `POST /api/pump/reset`: Clears dry-run or error lockout states.

---

### 2. Cloud Backend Setup (Render / Docker)

1. Navigate to `backend/`:
   ```bash
   cd backend
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in your values:
   ```bash
   cp .env.example .env
   ```
3. Start the local development server:
   ```bash
   npm run dev
   ```
4. **Deploy to Render:** Push this repository to GitHub and connect it to Render using the included `render.yaml` blueprint.

---

### 3. Flutter Mobile Application Setup

1. Prerequisites: Flutter SDK `>=3.3.0` and Dart SDK.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on your connected device or emulator:
   ```bash
   flutter run
   ```
4. In the app settings screen:
   - Configure the static local IP of your ESP8266 (default: `192.168.1.13`).
   - Enter your deployed backend cloud URL.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for complete details.

```text
Copyright (C) 2026 Divyansh Garg

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```
