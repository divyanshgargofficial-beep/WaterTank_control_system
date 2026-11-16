import 'package:dio/dio.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';

class ControllerApiService {
  ControllerApiService(this._dio);

  final Dio _dio;

  String _cleanIp(String ip) {
    var cleaned = ip.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    return cleaned.replaceAll(RegExp(r'/+$'), '');
  }

  Future<({ControllerStatus status, ConnectionInfo connection})> getStatus(
    String ip,
  ) async {
    final base = _cleanIp(ip);
    final stopwatch = Stopwatch()..start();
    final response = await _dio.get('$base${FirmwareContract.statusPath}');
    stopwatch.stop();

    final status = ControllerStatus.fromJson(
      response.data as Map<String, dynamic>,
    );

    return (
      status: status,
      connection: ConnectionInfo(
        mode: ConnectionMode.local,
        endpoint: ip,
        latencyMs: stopwatch.elapsedMilliseconds,
      ),
    );
  }

  Future<void> startPump(String ip) async {
    final base = _cleanIp(ip);
    await _dio.post('$base${FirmwareContract.startPumpPath}');
  }

  Future<void> stopPump(String ip) async {
    final base = _cleanIp(ip);
    await _dio.post('$base${FirmwareContract.stopPumpPath}');
  }

  Future<void> resetLockout(String ip) async {
    final base = _cleanIp(ip);
    await _dio.post('$base${FirmwareContract.resetLockoutPath}');
  }
}
