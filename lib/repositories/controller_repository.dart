import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/connection_manager.dart';

class ControllerRepository {
  ControllerRepository(this._connectionManager, this._prefs);

  final ConnectionManager _connectionManager;
  final SharedPreferences _prefs;
  static const _cacheKey = 'lastControllerStatus';

  ControllerStatus? loadCachedStatus() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    return ControllerStatus.fromCache(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ControllerReadResult> fetchStatus(AppSettings settings) async {
    final result = await _connectionManager.fetchStatus(settings);
    await _prefs.setString(_cacheKey, jsonEncode(result.status.toJson()));
    return result;
  }

  Future<void> startPump(AppSettings settings) =>
      _connectionManager.startPump(settings);
  Future<void> stopPump(AppSettings settings) =>
      _connectionManager.stopPump(settings);
  Future<void> resetLockout(AppSettings settings) =>
      _connectionManager.resetLockout(settings);
}
