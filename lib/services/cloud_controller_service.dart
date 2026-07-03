import 'package:dio/dio.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';

class CloudControllerService implements ControllerService {
  CloudControllerService(this._dio, this.cloudUrl, this._tokenProvider);

  final Dio _dio;
  final String cloudUrl;
  final Future<String?> Function() _tokenProvider;

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
  Future<void> startPump() => _post('/app/pump/on');

  @override
  Future<void> stopPump() => _post('/app/pump/off');

  @override
  Future<void> resetLockout() => _post('/app/reset');

  Future<void> _post(String path) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_normalizeBaseUrl(endpoint)}$path',
      options: await _options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (response.statusCode == 423) {
      throw ControllerLockoutException();
    }
    if (response.statusCode != 200 || response.data?['success'] != true) {
      throw StateError('Cloud rejected the command.');
    }
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
