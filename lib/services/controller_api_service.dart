import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:water_tank_controller/core/firmware_contract.dart';
import 'package:water_tank_controller/models/controller_status.dart';

class ControllerApiService {
  ControllerApiService(this._dio);

  final Dio _dio;
  static const _retryDelay = Duration(milliseconds: 180);
  static const _commandResponseTimeout = Duration(milliseconds: 2500);

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
    final url = '${_normalizeBaseUrl(baseUrl)}${FirmwareContract.statusPath}';
    final started = DateTime.now();
    debugPrint(
      '[LocalController] REQUEST method=GET url=$url attempt=$attempt timeout=${_dio.options.connectTimeout}',
    );
    final response = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(
        headers: const {'connection': 'close'},
        validateStatus: (status) => status == 200,
      ),
    );
    debugPrint(
      '[LocalController] RESPONSE method=GET url=$url attempt=$attempt status=${response.statusCode} elapsedMs=${DateTime.now().difference(started).inMilliseconds} body=${response.data}',
    );
    return response;
  }

  Future<void> startPump(String baseUrl) => _postControl(
    baseUrl,
    FirmwareContract.startPumpPath,
    label: 'start pump',
    expected: (status) => status.pumpRunning,
  );
  Future<void> stopPump(String baseUrl) => _postControl(
    baseUrl,
    FirmwareContract.stopPumpPath,
    label: 'stop pump',
    expected: (status) => !status.pumpRunning,
  );
  Future<void> resetLockout(String baseUrl) => _postControl(
    baseUrl,
    FirmwareContract.resetLockoutPath,
    label: 'reset lockout',
    expected: (status) => !status.lockout,
  );

  Future<void> _postControl(
    String baseUrl,
    String path, {
    required String label,
    required bool Function(ControllerStatus status) expected,
  }) async {
    try {
      await _postControlOnce(baseUrl, path, attempt: 1);
    } on DioException catch (error) {
      debugPrint(
        '[ControllerApi] POST $path attempt=1 failed type=${error.type} message=${error.message}',
      );
      if (await _statusConfirmsCommand(
        baseUrl,
        label: label,
        expected: expected,
      )) {
        return;
      }
      await Future<void>.delayed(_retryDelay);
      try {
        await _postControlOnce(baseUrl, path, attempt: 2);
      } on DioException catch (retryError) {
        debugPrint(
          '[ControllerApi] POST $path attempt=2 failed type=${retryError.type} message=${retryError.message}',
        );
        if (await _statusConfirmsCommand(
          baseUrl,
          label: label,
          expected: expected,
        )) {
          return;
        }
        rethrow;
      }
    }
  }

  Future<void> _postControlOnce(
    String baseUrl,
    String path, {
    required int attempt,
  }) async {
    final url = '${_normalizeBaseUrl(baseUrl)}$path';
    final started = DateTime.now();
    debugPrint(
      '[LocalController] REQUEST method=POST url=$url attempt=$attempt timeout=${_dio.options.connectTimeout}',
    );
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          receiveTimeout: _commandResponseTimeout,
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
      debugPrint(
        '[LocalController] RESPONSE method=POST url=$url attempt=$attempt status=${response.statusCode} elapsedMs=${DateTime.now().difference(started).inMilliseconds} body=${response.data}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[LocalController] EXCEPTION method=POST url=$url attempt=$attempt error=$error stack=$stackTrace',
      );
      rethrow;
    }
  }

  Future<bool> _statusConfirmsCommand(
    String baseUrl, {
    required String label,
    required bool Function(ControllerStatus status) expected,
  }) async {
    try {
      final status = await fetchStatus(baseUrl);
      debugPrint(
        '[LocalController] verification $label pump=${status.pumpRunning} tankFull=${status.tankFull} lockout=${status.lockout}',
      );
      if (expected(status)) {
        debugPrint(
          '[LocalController] command $label satisfied by status after timeout',
        );
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[LocalController] verification $label failed error=$error stack=$stackTrace',
      );
    }
    return false;
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

class ControllerLockoutException implements Exception {
  const ControllerLockoutException([
    this.message = 'Pump start rejected: controller is locked out.',
  ]);

  final String message;

  @override
  String toString() => message;
}
