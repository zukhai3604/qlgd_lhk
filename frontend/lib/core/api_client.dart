import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // ---------- Singleton ----------
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;

  // Giữ tương thích với code cũ: ApiClient.create()
  static ApiClient create() => ApiClient();

  ApiClient._internal() {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }


  // ---------- Config ----------
  static const _defaultBase =
  String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8888');

  final Dio dio = Dio(BaseOptions(
    baseUrl: _defaultBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));

  final _storage = const FlutterSecureStorage();

  // ---------- Token helpers ----------
  Future<String?> _readToken() async =>
      await _storage.read(key: 'access_token') ??
          await _storage.read(key: 'auth_token');

  Future<void> setToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'auth_token');
  }

  // ---------- Interceptors ----------
  void _installAuth() {
    // tránh lắp trùng
    dio.interceptors.removeWhere((_) => true);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await _readToken();
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        // Với web, bật credentials nếu backend cho phép CORS cookie (không bắt buộc)
        if (kIsWeb) {
          options.extra['withCredentials'] = true;
        }
        handler.next(options);
      },
      onError: (e, handler) {
        // Bạn có thể bắt 401 để điều hướng ra màn login tại đây nếu muốn
        handler.next(e);
      },
    ));
  }
}
