// core/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qlgd_lhk/core/network_config.dart';

class ApiClient {
  late Dio dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    // Khởi tạo Dio với cấu hình timeout cao hơn và baseUrl đúng
    dio = Dio(
      BaseOptions(
        baseUrl: NetworkConfig.apiBaseUrl, // Sử dụng NetworkConfig thay vì hardcode
        connectTimeout: const Duration(seconds: 60), // Tăng timeout
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _installAuth();

    // THÊM LOG INTERCEPTOR
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) {
        if (kDebugMode) print('🛰️ $obj');
      },
    ));
  }

  void _installAuth() {
    // Thêm auth interceptor nếu cần
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Thêm token vào header nếu có
        // final token = await getToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Xử lý lỗi rõ ràng
        if (e.type == DioExceptionType.connectionTimeout) {
          if (kDebugMode) print('❌ Connection timeout -> check backend is running');
        } else if (e.type == DioExceptionType.connectionError) {
          if (kDebugMode) print('❌ Connection error: ${e.message}');
        } else if (e.response != null) {
          if (kDebugMode) print('❌ HTTP ${e.response?.statusCode}: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));
  }
}
