import 'package:water_tank_controller/core/firmware_contract.dart';

class AppSettings {
  const AppSettings({
    required this.controllerIp,
    required this.refreshIntervalSeconds,
    required this.notificationsEnabled,
    required this.highContrast,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      controllerIp: FirmwareContract.defaultControllerIp,
      refreshIntervalSeconds: 2,
      notificationsEnabled: true,
      highContrast: false,
    );
  }

  final String controllerIp;
  final int refreshIntervalSeconds;
  final bool notificationsEnabled;
  final bool highContrast;

  AppSettings copyWith({
    String? controllerIp,
    int? refreshIntervalSeconds,
    bool? notificationsEnabled,
    bool? highContrast,
  }) {
    return AppSettings(
      controllerIp: controllerIp ?? this.controllerIp,
      refreshIntervalSeconds:
          refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}
