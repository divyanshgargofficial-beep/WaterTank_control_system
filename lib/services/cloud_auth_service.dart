import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CloudAuthService {
  CloudAuthService(this._dio);

  final Dio _dio;

  Future<String> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final url = '${_normalizeBaseUrl(baseUrl)}/auth/login';
    final body = {'email': email, 'password': '<redacted>'};
    final started = DateTime.now();
    debugPrint(
      '[CloudAuth] REQUEST method=POST url=$url headers={accept: application/json, content-type: application/json} body=$body timeout=${_dio.options.connectTimeout}',
    );
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: {'email': email, 'password': password},
        options: Options(validateStatus: (status) => status == 200),
      );
      debugPrint(
        '[CloudAuth] RESPONSE status=${response.statusCode} elapsedMs=${DateTime.now().difference(started).inMilliseconds} body=${response.data}',
      );
      final token = response.data?['token'];
      if (token is! String || token.isEmpty) {
        throw StateError('Cloud login did not return a JWT.');
      }
      return token;
    } catch (error, stackTrace) {
      debugPrint(
        '[CloudAuth] EXCEPTION method=POST url=$url error=$error stack=$stackTrace',
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
