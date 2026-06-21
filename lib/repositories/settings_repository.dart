import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _ipKey = 'controllerIp';
  static const _refreshKey = 'refreshIntervalSeconds';
  static const _notificationsKey = 'notificationsEnabled';
  static const _contrastKey = 'highContrast';

  AppSettings load() {
    final defaults = AppSettings.defaults();
    return AppSettings(
      controllerIp: _prefs.getString(_ipKey) ?? defaults.controllerIp,
      refreshIntervalSeconds:
          _prefs.getInt(_refreshKey) ?? defaults.refreshIntervalSeconds,
      notificationsEnabled:
          _prefs.getBool(_notificationsKey) ?? defaults.notificationsEnabled,
      highContrast: _prefs.getBool(_contrastKey) ?? defaults.highContrast,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_ipKey, settings.controllerIp.trim());
    await _prefs.setInt(_refreshKey, settings.refreshIntervalSeconds);
    await _prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await _prefs.setBool(_contrastKey, settings.highContrast);
  }
}
