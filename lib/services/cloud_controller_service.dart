import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';

class CloudControllerService implements ControllerService {
  CloudControllerService(this._dio, this.cloudUrl, this._tokenProvider);

  final Dio _dio;
  final String cloudUrl;
  final Future<String?> Function() _tokenProvider;
  static const _deviceId = 'package-1';

  @override
  String get endpoint => cloudUrl;

  @override
  Future<ControllerStatus> fetchStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_normalizeBaseUrl(endpoint)}/app/status',
      options: await _options(validateStatus: (status) => status == 200),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Cloud returned an empty status response.');
    }
    return ControllerStatus.fromJson(data);
  }

  @override
  Future<void> startPump() => _postAndWait(
    '/app/pump/on',
    expected: (status) => status.pumpRunning,
    label: 'pump on',
  );

  @override
  Future<void> stopPump() => _postAndWait(
    '/app/pump/off',
    expected: (status) => !status.pumpRunning,
    label: 'pump off',
  );

  @override
  Future<void> resetLockout() => _postAndWait(
    '/app/reset',
    expected: (status) => !status.lockout,
    label: 'reset lockout',
  );

  Future<void> _postAndWait(
    String path, {
    required bool Function(ControllerStatus status) expected,
    required String label,
  }) async {
    final url = '${_normalizeBaseUrl(endpoint)}$path';
    final data = {'deviceId': _deviceId};
    debugPrint('[CloudController] POST $url body=$data');
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: data,
      options: await _options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    debugPrint(
      '[CloudController] POST $path status=${response.statusCode} response=${response.data}',
    );
    if (response.statusCode == 423) {
      throw ControllerLockoutException();
    }
    if (response.statusCode != 200 || response.data?['success'] != true) {
      throw StateError('Cloud rejected the command.');
    }
    final commandId = response.data?['commandId'];
    if (commandId is! String || commandId.isEmpty) {
      throw StateError('Cloud did not return a command id.');
    }
    await _waitForCommandResult(commandId, label: label);
    await _waitForStatus(label: label, expected: expected);
  }

  Future<void> _waitForCommandResult(
    String commandId, {
    required String label,
  }) async {
    const attempts = 12;
    const delay = Duration(milliseconds: 700);
    for (var attempt = 1; attempt <= attempts; attempt++) {
      await Future<void>.delayed(delay);
      final response = await _dio.get<Map<String, dynamic>>(
        '${_normalizeBaseUrl(endpoint)}/app/command/$commandId',
        options: await _options(validateStatus: (status) => status == 200),
      );
      final status = '${response.data?['status'] ?? ''}';
      final error = '${response.data?['error'] ?? ''}';
      final device = response.data?['device'];
      final lockout = device is Map && device['lockout'] == true;
      debugPrint(
        '[CloudController] command $label id=$commandId attempt=$attempt status=$status error=$error lockout=$lockout',
      );
      if (status == 'ACKED') return;
      if (status == 'FAILED') {
        if (error.toLowerCase().contains('lockout') || lockout) {
          throw const ControllerLockoutException();
        }
        throw StateError('Cloud command rejected by controller: $error');
      }
    }
    throw StateError('Cloud command was delivered but not acknowledged.');
  }

  Future<void> _waitForStatus({
    required String label,
    required bool Function(ControllerStatus status) expected,
  }) async {
    const attempts = 10;
    const delay = Duration(milliseconds: 800);
    for (var attempt = 1; attempt <= attempts; attempt++) {
      await Future<void>.delayed(delay);
      final status = await fetchStatus();
      debugPrint(
        '[CloudController] wait $label attempt=$attempt pump=${status.pumpRunning} tankFull=${status.tankFull} lockout=${status.lockout}',
      );
      if (expected(status)) return;
    }
    debugPrint('[CloudController] wait $label timed out; continuing refresh');
  }

  Future<Options> _options({
    required bool Function(int?) validateStatus,
  }) async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('Cloud authentication is not available.');
    }
    return Options(
      headers: {
        Headers.acceptHeader: 'application/json',
        'authorization': 'Bearer $token',
        'x-device-id': _deviceId,
      },
      validateStatus: validateStatus,
    );
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    return withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
  }
}
