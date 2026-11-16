import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';
import 'package:water_tank_controller/services/local_controller_service.dart';

class ConnectionManager {
  ConnectionManager(this._localApi, this._cloudFactory);

  final ControllerApiService _localApi;
  final ControllerService Function(String cloudUrl) _cloudFactory;

  ControllerService _getService(AppSettings settings) {
    return switch (settings.connectionPreference) {
      ConnectionPreference.local => LocalControllerService(_localApi, settings.controllerIp),
      ConnectionPreference.cloud => _cloudFactory(settings.cloudUrl),
      ConnectionPreference.auto => LocalControllerService(_localApi, settings.controllerIp),
    };
  }

  Future<({ControllerStatus status, ConnectionInfo connection})> fetchStatus(
    AppSettings settings,
  ) async {
    if (settings.connectionPreference == ConnectionPreference.auto) {
      try {
        final local = LocalControllerService(_localApi, settings.controllerIp);
        return await local.fetchStatus();
      } catch (_) {
        final cloud = _cloudFactory(settings.cloudUrl);
        return await cloud.fetchStatus();
      }
    }
    return _getService(settings).fetchStatus();
  }

  Future<void> startPump(AppSettings settings) async {
    if (settings.connectionPreference == ConnectionPreference.auto) {
      try {
        final local = LocalControllerService(_localApi, settings.controllerIp);
        await local.startPump();
        return;
      } catch (_) {
        final cloud = _cloudFactory(settings.cloudUrl);
        await cloud.startPump();
        return;
      }
    }
    await _getService(settings).startPump();
  }

  Future<void> stopPump(AppSettings settings) async {
    if (settings.connectionPreference == ConnectionPreference.auto) {
      try {
        final local = LocalControllerService(_localApi, settings.controllerIp);
        await local.stopPump();
        return;
      } catch (_) {
        final cloud = _cloudFactory(settings.cloudUrl);
        await cloud.stopPump();
        return;
      }
    }
    await _getService(settings).stopPump();
  }

  Future<void> resetLockout(AppSettings settings) async {
    if (settings.connectionPreference == ConnectionPreference.auto) {
      try {
        final local = LocalControllerService(_localApi, settings.controllerIp);
        await local.resetLockout();
        return;
      } catch (_) {
        final cloud = _cloudFactory(settings.cloudUrl);
        await cloud.resetLockout();
        return;
      }
    }
    await _getService(settings).resetLockout();
  }
}
