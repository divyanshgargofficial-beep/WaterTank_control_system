import 'package:dio/dio.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/controller_status.dart';

class ControllerApiService {
  ControllerApiService(this._dio);

  final Dio _dio;

  String _baseUrl(String ip) => 'http://$ip';

  Future<ControllerStatus> fetchStatus(String ip) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl(ip)}${FirmwareContract.statusPath}',
      options: Options(
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Controller returned an empty status response.');
    }
    return ControllerStatus.fromJson(data);
  }

  Future<void> startPump(String ip) =>
      _postControl(ip, FirmwareContract.startPumpPath);
  Future<void> stopPump(String ip) =>
      _postControl(ip, FirmwareContract.stopPumpPath);
  Future<void> resetLockout(String ip) =>
      _postControl(ip, FirmwareContract.resetLockoutPath);

  Future<void> _postControl(String ip, String path) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_baseUrl(ip)}$path',
      options: Options(
        receiveTimeout: const Duration(seconds: 4),
        sendTimeout: const Duration(seconds: 4),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (response.statusCode == 423) {
      throw ControllerLockoutException();
    }
    if (response.statusCode != 200 || response.data?['success'] != true) {
      throw StateError('Controller rejected the command.');
    }
  }
}

class ControllerLockoutException implements Exception {}
