import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/network_config.dart';
import 'admin_view_model.dart';

// Provider cho Dio client với timeout cao hơn và Auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Add auth interceptor to automatically include token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? 
                     await storage.read(key: 'auth_token');
      
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔑 Added token to request: ${options.uri}');
      } else {
        print('⚠️ No token found for request: ${options.uri}');
      }
      
      handler.next(options);
    },
    onError: (error, handler) {
      print('❌ Request error: ${error.response?.statusCode} ${error.message}');
      handler.next(error);
    },
  ));

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
    logPrint: (obj) => print('🛰️ $obj'),
  ));

  return dio;
});

final adminViewModelProvider = ChangeNotifierProvider<AdminViewModel>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminViewModel(dio: dio); // Truyền dio vào AdminViewModel
});