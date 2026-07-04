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
  static const _localRetryCooldown = Duration(seconds: 60);
  ConnectionMode? _lastMode;
  DateTime? _nextLocalProbeAt;

  void resetRouting() {
    _lastMode = null;
    _nextLocalProbeAt = null;
  }

  Future<ControllerReadResult> fetchStatus(AppSettings settings) async {
    if (settings.connectionPreference == ConnectionPreference.local) {
      return _fetchLocal(settings);
    }
    if (settings.connectionPreference == ConnectionPreference.cloud) {
      return _fetchCloud(settings);
    }
    return _fetchAuto(settings);
  }

  Future<ControllerReadResult> _fetchAuto(AppSettings settings) async {
    final now = DateTime.now();
    final shouldTryCloudFirst =
        _lastMode == ConnectionMode.cloud &&
        _nextLocalProbeAt != null &&
        now.isBefore(_nextLocalProbeAt!);

    if (shouldTryCloudFirst) {
      try {
        return await _fetchCloud(settings);
      } catch (_) {
        _nextLocalProbeAt = null;
        return _fetchLocal(settings);
      }
    }

    try {
      final result = await _fetchLocal(settings);
      _nextLocalProbeAt = null;
      return result;
    } catch (_) {
      final result = await _fetchCloud(settings);
      _nextLocalProbeAt = DateTime.now().add(_localRetryCooldown);
      return result;
    }
  }

  Future<void> startPump(AppSettings settings) => _active(settings).startPump();
  Future<void> stopPump(AppSettings settings) => _active(settings).stopPump();
  Future<void> resetLockout(AppSettings settings) =>
      _active(settings).resetLockout();

  ControllerService _active(AppSettings settings) {
    if (settings.connectionPreference == ConnectionPreference.local) {
      return LocalControllerService(_api, settings.controllerIp);
    }
    if (settings.connectionPreference == ConnectionPreference.cloud) {
      return _cloudFactory(settings.cloudUrl);
    }
    return switch (_lastMode) {
      ConnectionMode.cloud => _cloudFactory(settings.cloudUrl),
      _ => LocalControllerService(_api, settings.controllerIp),
    };
  }

  Future<ControllerReadResult> _fetchLocal(AppSettings settings) async {
    final local = LocalControllerService(_api, settings.controllerIp);
    final started = DateTime.now();
    final status = await local.fetchStatus();
    return ControllerReadResult(
      status: status,
      connection: _info(
        mode: ConnectionMode.local,
        endpoint: local.endpoint,
        elapsed: DateTime.now().difference(started),
        timeoutSeconds: settings.connectionTimeoutSeconds.clamp(2, 4),
      ),
    );
  }

  Future<ControllerReadResult> _fetchCloud(AppSettings settings) async {
    final cloud = _cloudFactory(settings.cloudUrl);
    final started = DateTime.now();
    final status = await cloud.fetchStatus();
    return ControllerReadResult(
      status: status,
      connection: _info(
        mode: ConnectionMode.cloud,
        endpoint: cloud.endpoint,
        elapsed: DateTime.now().difference(started),
        timeoutSeconds: settings.connectionTimeoutSeconds < 12
            ? 12
            : settings.connectionTimeoutSeconds,
      ),
    );
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
