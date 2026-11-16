import 'package:dio/dio.dart';

class CloudAuthService {
  CloudAuthService(this._dio);

  final Dio _dio;

  Future<String> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final cleanUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final response = await _dio.post(
      '$cleanUrl/auth/login',
      data: {'email': email, 'password': password},
      options: Options(
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['token'] is String) {
      return data['token'] as String;
    }
    throw StateError('Invalid response from cloud auth endpoint.');
  }
}
