import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/controller_status.dart';

class ControllerApiService {
  ControllerApiService(this._dio);

  final Dio _dio;
  static const _retryDelay = Duration(milliseconds: 450);

  String _baseUrl(String ip) => 'http://$ip';

  Future<ControllerStatus> fetchStatus(String ip) async {
    final response = await _getStatusWithSingleRetry(ip);
    final data = response.data;
    if (data == null) {
      throw StateError('Controller returned an empty status response.');
    }
    return ControllerStatus.fromJson(data);
  }

  Future<Response<Map<String, dynamic>>> _getStatusWithSingleRetry(
    String ip,
  ) async {
    try {
      return await _getStatus(ip, attempt: 1);
    } on DioException catch (error) {
      debugPrint(
        '[ControllerApi] GET ${FirmwareContract.statusPath} attempt=1 failed type=${error.type}',
      );
      await Future<void>.delayed(_retryDelay);
      return _getStatus(ip, attempt: 2);
    }
  }

  Future<Response<Map<String, dynamic>>> _getStatus(
    String ip, {
    required int attempt,
  }) async {
    debugPrint('[ControllerApi] GET ${FirmwareContract.statusPath} start');
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl(ip)}${FirmwareContract.statusPath}',
      options: Options(
        headers: const {'connection': 'close'},
        validateStatus: (status) => status == 200,
      ),
    );
    debugPrint(
      '[ControllerApi] GET ${FirmwareContract.statusPath} success attempt=$attempt',
    );
    return response;
  }

  Future<void> startPump(String ip) =>
      _postControl(ip, FirmwareContract.startPumpPath);
  Future<void> stopPump(String ip) =>
      _postControl(ip, FirmwareContract.stopPumpPath);
  Future<void> resetLockout(String ip) =>
      _postControl(ip, FirmwareContract.resetLockoutPath);

  Future<void> _postControl(String ip, String path) async {
    debugPrint('[ControllerApi] POST $path start');
    final response = await _dio.post<Map<String, dynamic>>(
      '${_baseUrl(ip)}$path',
      options: Options(
        headers: const {'connection': 'close'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (response.statusCode == 423) {
      throw ControllerLockoutException();
    }
    if (response.statusCode != 200 || response.data?['success'] != true) {
      throw StateError('Controller rejected the command.');
    }
    debugPrint('[ControllerApi] POST $path success');
  }
}

class ControllerLockoutException implements Exception {}
