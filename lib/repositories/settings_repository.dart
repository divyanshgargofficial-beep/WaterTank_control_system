import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _controllerIpKey = 'settings.controllerIp.v1';
  static const _cloudUrlKey = 'settings.cloudUrl.v1';
  static const _connectionPreferenceKey = 'settings.connectionPreference.v1';
  static const _refreshIntervalKey = 'settings.refreshInterval.v1';
  static const _notificationsEnabledKey = 'settings.notificationsEnabled.v1';
  static const _adminNotificationsEnabledKey = 'settings.adminNotificationsEnabled.v1';
  static const _familyNotificationsEnabledKey = 'settings.familyNotificationsEnabled.v1';
  static const _connectionTimeoutKey = 'settings.connectionTimeout.v1';
  static const _themeModeKey = 'settings.themeMode.v1';
  static const _highContrastKey = 'settings.highContrast.v1';

  AppSettings load() {
    final defaults = AppSettings.defaults();
    final modeName = _preferences.getString(_themeModeKey);
    final preferenceName = _preferences.getString(_connectionPreferenceKey);

    return AppSettings(
      controllerIp:
          _preferences.getString(_controllerIpKey) ?? defaults.controllerIp,
      cloudUrl: _preferences.getString(_cloudUrlKey) ?? defaults.cloudUrl,
      connectionPreference: ConnectionPreference.values.firstWhere(
        (e) => e.name == preferenceName,
        orElse: () => defaults.connectionPreference,
      ),
      refreshIntervalSeconds:
          _preferences.getInt(_refreshIntervalKey) ??
          defaults.refreshIntervalSeconds,
      notificationsEnabled:
          _preferences.getBool(_notificationsEnabledKey) ??
          defaults.notificationsEnabled,
      adminNotificationsEnabled:
          _preferences.getBool(_adminNotificationsEnabledKey) ??
          defaults.adminNotificationsEnabled,
      familyNotificationsEnabled:
          _preferences.getBool(_familyNotificationsEnabledKey) ??
          defaults.familyNotificationsEnabled,
      connectionTimeoutSeconds:
          _preferences.getInt(_connectionTimeoutKey) ??
          defaults.connectionTimeoutSeconds,
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == modeName,
        orElse: () => defaults.themeMode,
      ),
      highContrast:
          _preferences.getBool(_highContrastKey) ?? defaults.highContrast,
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _preferences.setString(_controllerIpKey, settings.controllerIp),
      _preferences.setString(_cloudUrlKey, settings.cloudUrl),
      _preferences.setString(
        _connectionPreferenceKey,
        settings.connectionPreference.name,
      ),
      _preferences.setInt(
        _refreshIntervalKey,
        settings.refreshIntervalSeconds,
      ),
      _preferences.setBool(
        _notificationsEnabledKey,
        settings.notificationsEnabled,
      ),
      _preferences.setBool(
        _adminNotificationsEnabledKey,
        settings.adminNotificationsEnabled,
      ),
      _preferences.setBool(
        _familyNotificationsEnabledKey,
        settings.familyNotificationsEnabled,
      ),
      _preferences.setInt(
        _connectionTimeoutKey,
        settings.connectionTimeoutSeconds,
      ),
      _preferences.setString(_themeModeKey, settings.themeMode.name),
      _preferences.setBool(_highContrastKey, settings.highContrast),
    ]);
  }
}
