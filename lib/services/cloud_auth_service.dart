import 'package:dio/dio.dart';

class CloudAuthService {
  CloudAuthService(this._dio);

  final Dio _dio;

  Future<String> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_normalizeBaseUrl(baseUrl)}/auth/login',
      data: {'email': email, 'password': password},
      options: Options(validateStatus: (status) => status == 200),
    );
    final token = response.data?['token'];
    if (token is! String || token.isEmpty) {
      throw StateError('Cloud login did not return a JWT.');
    }
    return token;
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
