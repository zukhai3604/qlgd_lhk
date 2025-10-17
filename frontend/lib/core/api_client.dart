// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._(this.dio);
  final Dio dio;

  /// Tạo Dio đã cấu hình:
  /// - baseUrl lấy từ --dart-define=API_BASE (mặc định http://127.0.0.1:8888)
  /// - bật LogInterceptor (in request/response)
  /// - set header mặc định cho Laravel
  /// - timeout hợp lý.
  static ApiClient create() {
    const base = String.fromEnvironment(
      'API_BASE',
      defaultValue: 'http://127.0.0.1:8888',
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',       // Laravel thường yêu cầu
          'Content-Type': 'application/json', // mặc định JSON
        },
        // Cho phép đọc cả mã 4xx để lấy message từ backend
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    // 🔎 Log toàn bộ request/response (debug)
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );

    // (tuỳ chọn) Gắn Authorization tự động nếu đã có token lưu
    if (!kIsWeb) {
      final storage = const FlutterSecureStorage();
      storage.read(key: 'access_token').then((tkn) {
        if (tkn != null && tkn.isNotEmpty) {
          dio.options.headers['Authorization'] = 'Bearer $tkn';
        } else {
          // tương thích key cũ nếu bạn dùng 'auth_token'
          storage.read(key: 'auth_token').then((old) {
            if (old != null && old.isNotEmpty) {
              dio.options.headers['Authorization'] = 'Bearer $old';
            }
          });
        }
      });
    }

    return ApiClient._(dio);
  }
}
