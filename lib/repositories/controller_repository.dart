import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/connection_manager.dart';

class ControllerRepository {
  ControllerRepository(this._connectionManager, this._preferences);

  final ConnectionManager _connectionManager;
  final SharedPreferences _preferences;

  static const _cachedStatusKey = 'controller.cachedStatus.v1';

  ControllerStatus? loadCachedStatus() {
    final raw = _preferences.getString(_cachedStatusKey);
    if (raw == null) return null;
    try {
      return ControllerStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<({ControllerStatus status, ConnectionInfo connection})> fetchStatus(
    AppSettings settings,
  ) async {
    final result = await _connectionManager.fetchStatus(settings);
    await _preferences.setString(
      _cachedStatusKey,
      jsonEncode(result.status.toJson()),
    );
    return result;
  }

  Future<void> startPump(AppSettings settings) =>
      _connectionManager.startPump(settings);

  Future<void> stopPump(AppSettings settings) =>
      _connectionManager.stopPump(settings);

  Future<void> resetLockout(AppSettings settings) =>
      _connectionManager.resetLockout(settings);
}
