# Water Tank Controller

Premium Flutter Android client for the existing ESP8266 firmware in `WaterTankController_Package1.ino`.

## Firmware API Contract

The app uses only endpoints implemented by the firmware:

- `GET /api/status`
- `POST /api/pump/on`
- `POST /api/pump/off`
- `POST /api/pump/reset`

Default controller IP: `192.168.1.13`.

Status JSON fields:

- `pumpRunning`
- `tankFull`
- `lockout`
- `currentRuntimeSeconds`
- `totalRuntimeSeconds`
- `wifiConnected`

## Flutter Structure

- `lib/core` constants and design tokens
- `lib/models` firmware and app state models
- `lib/services` Dio API and local notifications
- `lib/repositories` persistence and controller repositories
- `lib/providers` Riverpod state controllers
- `lib/screens` dashboard, control, history, statistics, settings
- `lib/widgets` reusable glass UI components
- `lib/theme` Material 3 dark theme
- `lib/utils` formatting helpers
