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
  static const _commandPollDelay = Duration(milliseconds: 900);
  static const _statusPollDelay = Duration(milliseconds: 2200);
  static const _commandTimeout = Duration(seconds: 25);

  @override
  String get endpoint => cloudUrl;

  @override
  Future<ControllerStatus> fetchStatus() async {
    final response = await _request(
      method: 'GET',
      path: '/app/status',
      validateStatus: (status) => status == 200,
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
    final data = {'deviceId': _deviceId};
    final response = await _request(
      method: 'POST',
      path: path,
      body: data,
      validateStatus: (status) => status != null && status < 500,
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
    await _waitForCompletion(commandId, label: label, expected: expected);
  }

  Future<void> _waitForCompletion(
    String commandId, {
    required String label,
    required bool Function(ControllerStatus status) expected,
  }) async {
    var attempt = 0;
    final deadline = DateTime.now().add(_commandTimeout);
    var nextStatusCheck = DateTime.now();
    var delivered = false;
    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      if (attempt > 1) await Future<void>.delayed(_commandPollDelay);
      Response<Map<String, dynamic>> response;
      try {
        response = await _request(
          method: 'GET',
          path: '/app/command/$commandId',
          validateStatus: (status) => status == 200,
        );
      } catch (error) {
        debugPrint(
          '[CloudController] command $label id=$commandId attempt=$attempt poll error=$error',
        );
        continue;
      }
      final status = '${response.data?['status'] ?? ''}';
      final error = '${response.data?['error'] ?? ''}';
      final device = response.data?['device'];
      final lockout = device is Map && device['lockout'] == true;
      final controllerStatus = _statusFromCommandDevice(device);
      debugPrint(
        '[CloudController] command $label id=$commandId attempt=$attempt status=$status error=$error lockout=$lockout',
      );
      if (controllerStatus != null && expected(controllerStatus)) {
        debugPrint(
          '[CloudController] command $label satisfied by command device state',
        );
        return;
      }
      if (status == 'DELIVERED') {
        delivered = true;
      }
      if (status == 'ACKED') {
        debugPrint('[CloudController] command $label acknowledged');
        return;
      }
      if (status == 'FAILED') {
        if (error.toLowerCase().contains('lockout') || lockout) {
          throw const ControllerLockoutException();
        }
        throw StateError('Cloud command rejected by controller: $error');
      }
      if (DateTime.now().isAfter(nextStatusCheck)) {
        try {
          final liveStatus = await fetchStatus();
          debugPrint(
            '[CloudController] live status $label attempt=$attempt pump=${liveStatus.pumpRunning} tankFull=${liveStatus.tankFull} lockout=${liveStatus.lockout}',
          );
          if (expected(liveStatus)) {
            debugPrint(
              '[CloudController] command $label satisfied by live status before ack',
            );
            return;
          }
        } catch (error) {
          debugPrint(
            '[CloudController] live status $label attempt=$attempt error=$error',
          );
        }
        nextStatusCheck = DateTime.now().add(_statusPollDelay);
      }
    }
    debugPrint(
      '[CloudController] command $label id=$commandId not confirmed within ${_commandTimeout.inSeconds}s delivered=$delivered',
    );
    throw StateError(
      delivered
          ? 'Cloud command was delivered but not confirmed by controller.'
          : 'Cloud command was not delivered to controller.',
    );
  }

  ControllerStatus? _statusFromCommandDevice(Object? device) {
    if (device is! Map) return null;
    final json = Map<String, dynamic>.from(device.cast<dynamic, dynamic>());
    if (!json.containsKey('receivedAt')) {
      json['receivedAt'] = DateTime.now().toIso8601String();
    }
    json.putIfAbsent('currentRuntimeSeconds', () => json['runtime'] ?? 0);
    json.putIfAbsent('totalRuntimeSeconds', () => json['totalRuntime'] ?? 0);
    json.putIfAbsent('wifiConnected', () => json['online'] == true);
    return ControllerStatus.fromJson(json);
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
        Headers.contentTypeHeader: 'application/json',
        'authorization': 'Bearer $token',
        'x-device-id': _deviceId,
      },
      validateStatus: validateStatus,
    );
  }

  Future<Response<Map<String, dynamic>>> _request({
    required String method,
    required String path,
    required bool Function(int?) validateStatus,
    Map<String, dynamic>? body,
  }) async {
    final url = '${_normalizeBaseUrl(endpoint)}$path';
    final options = await _options(validateStatus: validateStatus);
    final redactedHeaders = Map<String, dynamic>.from(options.headers ?? {});
    if (redactedHeaders['authorization'] != null) {
      redactedHeaders['authorization'] = 'Bearer <redacted>';
    }
    final started = DateTime.now();
    debugPrint(
      '[CloudController] REQUEST method=$method url=$url headers=$redactedHeaders body=${body ?? {}} timeout=${_dio.options.connectTimeout}',
    );
    try {
      final response = method == 'POST'
          ? await _dio.post<Map<String, dynamic>>(
              url,
              data: body,
              options: options,
            )
          : await _dio.get<Map<String, dynamic>>(url, options: options);
      debugPrint(
        '[CloudController] RESPONSE method=$method url=$url status=${response.statusCode} elapsedMs=${DateTime.now().difference(started).inMilliseconds} body=${response.data}',
      );
      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '[CloudController] EXCEPTION method=$method url=$url error=$error stack=$stackTrace',
      );
      rethrow;
    }
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
