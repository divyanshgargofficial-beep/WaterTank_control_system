import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';

class ControllerRepository {
  ControllerRepository(this._api, this._prefs);

  final ControllerApiService _api;
  final SharedPreferences _prefs;
  static const _cacheKey = 'lastControllerStatus';

  ControllerStatus? loadCachedStatus() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    return ControllerStatus.fromCache(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ControllerStatus> fetchStatus(String ip) async {
    final status = await _api.fetchStatus(ip);
    await _prefs.setString(_cacheKey, jsonEncode(status.toJson()));
    return status;
  }

  Future<void> startPump(String ip) => _api.startPump(ip);
  Future<void> stopPump(String ip) => _api.stopPump(ip);
  Future<void> resetLockout(String ip) => _api.resetLockout(ip);
}
