import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] Request: ${options.method} ${options.uri}');
      if (options.data != null) {
        print('[DIO] Request data: ${options.data}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] Response: ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('[DIO] Error: ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('[DIO] Error message: ${err.message}');
    }
    super.onError(err, handler);
  }
}
