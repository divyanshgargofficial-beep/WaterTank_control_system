import 'package:dio/dio.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_service.dart';

class CloudControllerService implements ControllerService {
  CloudControllerService(this._dio, this._baseUrl, this._tokenProvider);

  final Dio _dio;
  final String _baseUrl;
  final Future<String?> Function() _tokenProvider;

  String get _cleanUrl => _baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<Options> _authOptions() async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Cloud authentication is not available.');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  @override
  Future<({ControllerStatus status, ConnectionInfo connection})> fetchStatus() async {
    final stopwatch = Stopwatch()..start();
    final options = await _authOptions();
    final response = await _dio.get('$_cleanUrl/app/status', options: options);
    stopwatch.stop();

    final data = response.data as Map<String, dynamic>;
    final device = data['device'] as Map<String, dynamic>? ?? {};
    final status = ControllerStatus.fromJson(device);

    return (
      status: status,
      connection: ConnectionInfo(
        mode: ConnectionMode.cloud,
        endpoint: _cleanUrl,
        latencyMs: stopwatch.elapsedMilliseconds,
      ),
    );
  }

  @override
  Future<void> startPump() async {
    final options = await _authOptions();
    await _dio.post('$_cleanUrl/app/pump/on', options: options);
  }

  @override
  Future<void> stopPump() async {
    final options = await _authOptions();
    await _dio.post('$_cleanUrl/app/pump/off', options: options);
  }

  @override
  Future<void> resetLockout() async {
    final options = await _authOptions();
    await _dio.post('$_cleanUrl/app/pump/reset', options: options);
  }
}
