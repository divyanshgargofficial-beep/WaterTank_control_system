import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _ipKey = 'controllerIp';
  static const _cloudUrlKey = 'cloudUrl';
  static const _refreshKey = 'refreshIntervalSeconds';
  static const _notificationsKey = 'notificationsEnabled';
  static const _adminNotificationsKey = 'adminNotificationsEnabled';
  static const _familyNotificationsKey = 'familyNotificationsEnabled';
  static const _timeoutKey = 'connectionTimeoutSeconds';
  static const _themeModeKey = 'themeMode';
  static const _contrastKey = 'highContrast';

  AppSettings load() {
    final defaults = AppSettings.defaults();
    return AppSettings(
      controllerIp: _prefs.getString(_ipKey) ?? defaults.controllerIp,
      cloudUrl: _prefs.getString(_cloudUrlKey) ?? defaults.cloudUrl,
      refreshIntervalSeconds:
          (_prefs.getInt(_refreshKey) ?? defaults.refreshIntervalSeconds).clamp(
            3,
            60,
          ),
      notificationsEnabled:
          _prefs.getBool(_notificationsKey) ?? defaults.notificationsEnabled,
      adminNotificationsEnabled:
          _prefs.getBool(_adminNotificationsKey) ??
          defaults.adminNotificationsEnabled,
      familyNotificationsEnabled:
          _prefs.getBool(_familyNotificationsKey) ??
          defaults.familyNotificationsEnabled,
      connectionTimeoutSeconds:
          (_prefs.getInt(_timeoutKey) ?? defaults.connectionTimeoutSeconds)
              .clamp(2, 20),
      themeMode: AppThemeMode.values.firstWhere(
        (item) => item.name == _prefs.getString(_themeModeKey),
        orElse: () => defaults.themeMode,
      ),
      highContrast: _prefs.getBool(_contrastKey) ?? defaults.highContrast,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_ipKey, settings.controllerIp.trim());
    await _prefs.setString(_cloudUrlKey, settings.cloudUrl.trim());
    await _prefs.setInt(
      _refreshKey,
      settings.refreshIntervalSeconds.clamp(3, 60),
    );
    await _prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await _prefs.setBool(
      _adminNotificationsKey,
      settings.adminNotificationsEnabled,
    );
    await _prefs.setBool(
      _familyNotificationsKey,
      settings.familyNotificationsEnabled,
    );
    await _prefs.setInt(
      _timeoutKey,
      settings.connectionTimeoutSeconds.clamp(2, 20),
    );
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
    await _prefs.setBool(_contrastKey, settings.highContrast);
  }
}
