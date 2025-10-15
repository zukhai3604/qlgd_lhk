import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

class ApiClient {
  ApiClient._(this.dio);
  final Dio dio;

  static final _storage = const FlutterSecureStorage();

  static ApiClient create() {
    final dio = Dio(BaseOptions(
      baseUrl: '${Env.baseUrl}/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(onRequest: (opt, handler) async {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        opt.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(opt);
    }));

    return ApiClient._(dio);
  }
}
