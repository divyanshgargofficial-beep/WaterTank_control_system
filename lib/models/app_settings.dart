import 'package:water_tank_controller/core/firmware_contract.dart';

class AppSettings {
  const AppSettings({
    required this.controllerIp,
    required this.cloudUrl,
    required this.refreshIntervalSeconds,
    required this.notificationsEnabled,
    required this.adminNotificationsEnabled,
    required this.familyNotificationsEnabled,
    required this.connectionTimeoutSeconds,
    required this.themeMode,
    required this.highContrast,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      controllerIp: FirmwareContract.defaultControllerIp,
      cloudUrl: 'https://water-tank-controller.example.com',
      refreshIntervalSeconds: 3,
      notificationsEnabled: true,
      adminNotificationsEnabled: true,
      familyNotificationsEnabled: true,
      connectionTimeoutSeconds: 5,
      themeMode: AppThemeMode.dark,
      highContrast: false,
    );
  }

  final String controllerIp;
  final String cloudUrl;
  final int refreshIntervalSeconds;
  final bool notificationsEnabled;
  final bool adminNotificationsEnabled;
  final bool familyNotificationsEnabled;
  final int connectionTimeoutSeconds;
  final AppThemeMode themeMode;
  final bool highContrast;

  AppSettings copyWith({
    String? controllerIp,
    String? cloudUrl,
    int? refreshIntervalSeconds,
    bool? notificationsEnabled,
    bool? adminNotificationsEnabled,
    bool? familyNotificationsEnabled,
    int? connectionTimeoutSeconds,
    AppThemeMode? themeMode,
    bool? highContrast,
  }) {
    return AppSettings(
      controllerIp: controllerIp ?? this.controllerIp,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      refreshIntervalSeconds:
          refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      adminNotificationsEnabled:
          adminNotificationsEnabled ?? this.adminNotificationsEnabled,
      familyNotificationsEnabled:
          familyNotificationsEnabled ?? this.familyNotificationsEnabled,
      connectionTimeoutSeconds:
          connectionTimeoutSeconds ?? this.connectionTimeoutSeconds,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

enum AppThemeMode { dark, light, system }
