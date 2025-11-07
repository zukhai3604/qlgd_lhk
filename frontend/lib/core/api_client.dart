import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/common/constants/env.dart';
import 'package:qlgd_lhk/core/network_config.dart';

class ApiClient {
  ApiClient._internal() {
    final resolvedBaseUrl = _resolveBaseUrl();

    dio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _readToken();
          if (kDebugMode) {
            print('🔑 Token for ${options.path}: ${token != null ? "✅ Present (${token.substring(0, 20)}...)" : "❌ Missing"}');
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    ]);
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  static ApiClient create() => ApiClient();

  late final Dio dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _readToken() async {
    return await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'auth_token');
  }

  String _resolveBaseUrl() {
    const compileTimeOverride = String.fromEnvironment('API_BASE_URL');
    if (compileTimeOverride.trim().isNotEmpty) {
      return _normalizeBaseUrl(compileTimeOverride);
    }

    if (Env.isInitialized) {
      final envBase = Env.baseUrl;
      if (envBase.trim().isNotEmpty) {
        return _normalizeBaseUrl(envBase);
      }
    }

    // Nếu không có compile-time override hoặc Env, dùng NetworkConfig
    final cfg = NetworkConfig.apiBaseUrl;
    if (cfg.trim().isNotEmpty) return _normalizeBaseUrl(cfg);

    return _normalizeBaseUrl('http://127.0.0.1:8888');
  }

  String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'http://127.0.0.1:8888';
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
