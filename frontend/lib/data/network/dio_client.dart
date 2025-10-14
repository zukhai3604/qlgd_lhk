import 'package:dio/dio.dart';
import 'package:qlgd_lhk/common/constants/env.dart';
import 'package:qlgd_lhk/data/network/interceptors/auth_interceptor.dart';
import 'package:qlgd_lhk/data/network/interceptors/log_interceptor.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(),
    AppLogInterceptor(),
  ]);

  return dio;
}
