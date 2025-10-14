import 'package:dio/dio.dart';
import 'package:qlgd_lhk/data/storage/secure_storage.dart';

// This would be a real implementation
// final secureStorage = SecureStorageService();

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // In a real app, you would get the token from secure storage
    // final token = await secureStorage.getToken();
    const token = null; // Placeholder

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle token expiration and refresh logic here if needed
    super.onError(err, handler);
  }
}
