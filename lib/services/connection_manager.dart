import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/cloud_controller_service.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';
import 'package:water_tank_controller/services/local_controller_service.dart';

class ControllerReadResult {
  const ControllerReadResult({required this.status, required this.connection});

  final ControllerStatus status;
  final ConnectionInfo connection;
}

class ConnectionManager {
  ConnectionManager(this._api, this._cloudFactory);

  final ControllerApiService _api;
  final CloudControllerService Function(String cloudUrl) _cloudFactory;
  ConnectionMode? _lastMode;

  Future<ControllerReadResult> fetchStatus(AppSettings settings) async {
    final local = LocalControllerService(_api, settings.controllerIp);
    try {
      final started = DateTime.now();
      final status = await local.fetchStatus();
      return ControllerReadResult(
        status: status,
        connection: _info(
          mode: ConnectionMode.local,
          endpoint: local.endpoint,
          elapsed: DateTime.now().difference(started),
          timeoutSeconds: settings.connectionTimeoutSeconds,
        ),
      );
    } catch (_) {
      final cloud = _cloudFactory(settings.cloudUrl);
      final started = DateTime.now();
      final status = await cloud.fetchStatus();
      return ControllerReadResult(
        status: status,
        connection: _info(
          mode: ConnectionMode.cloud,
          endpoint: cloud.endpoint,
          elapsed: DateTime.now().difference(started),
          timeoutSeconds: settings.connectionTimeoutSeconds,
        ),
      );
    }
  }

  Future<void> startPump(AppSettings settings) => _active(settings).startPump();
  Future<void> stopPump(AppSettings settings) => _active(settings).stopPump();
  Future<void> resetLockout(AppSettings settings) =>
      _active(settings).resetLockout();

  ControllerService _active(AppSettings settings) {
    return switch (_lastMode) {
      ConnectionMode.cloud => _cloudFactory(settings.cloudUrl),
      _ => LocalControllerService(_api, settings.controllerIp),
    };
  }

  ConnectionInfo _info({
    required ConnectionMode mode,
    required String endpoint,
    required Duration elapsed,
    required int timeoutSeconds,
  }) {
    _lastMode = mode;
    final timeoutMs = timeoutSeconds * 1000;
    final used = elapsed.inMilliseconds.clamp(0, timeoutMs);
    final quality = (100 - ((used / timeoutMs) * 70)).round().clamp(20, 100);
    return ConnectionInfo(
      mode: mode,
      qualityPercent: quality,
      endpoint: endpoint,
      switchedAt: DateTime.now(),
    );
  }
}
