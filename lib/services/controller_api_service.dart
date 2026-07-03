import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/controller_status.dart';

class ControllerApiService {
  ControllerApiService(this._dio);

  final Dio _dio;
  static const _retryDelay = Duration(milliseconds: 450);

  Future<ControllerStatus> fetchStatus(String baseUrl) async {
    final response = await _getStatusWithSingleRetry(baseUrl);
    final data = response.data;
    if (data == null) {
      throw StateError('Controller returned an empty status response.');
    }
    return ControllerStatus.fromJson(data);
  }

  Future<Response<Map<String, dynamic>>> _getStatusWithSingleRetry(
    String baseUrl,
  ) async {
    try {
      return await _getStatus(baseUrl, attempt: 1);
    } on DioException catch (error) {
      debugPrint(
        '[ControllerApi] GET ${FirmwareContract.statusPath} attempt=1 failed type=${error.type}',
      );
      await Future<void>.delayed(_retryDelay);
      return _getStatus(baseUrl, attempt: 2);
    }
  }

  Future<Response<Map<String, dynamic>>> _getStatus(
    String baseUrl, {
    required int attempt,
  }) async {
    debugPrint('[ControllerApi] GET ${FirmwareContract.statusPath} start');
    final response = await _dio.get<Map<String, dynamic>>(
      '${_normalizeBaseUrl(baseUrl)}${FirmwareContract.statusPath}',
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

  Future<void> startPump(String baseUrl) =>
      _postControl(baseUrl, FirmwareContract.startPumpPath);
  Future<void> stopPump(String baseUrl) =>
      _postControl(baseUrl, FirmwareContract.stopPumpPath);
  Future<void> resetLockout(String baseUrl) =>
      _postControl(baseUrl, FirmwareContract.resetLockoutPath);

  Future<void> _postControl(String baseUrl, String path) async {
    debugPrint('[ControllerApi] POST $path start');
    final response = await _dio.post<Map<String, dynamic>>(
      '${_normalizeBaseUrl(baseUrl)}$path',
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

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'http://$trimmed';
    return withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
  }
}

class ControllerLockoutException implements Exception {}
