// lib/data/api.dart
import 'package:dio/dio.dart';
import '../app/env.dart';

class Api {
  final dio = Dio(BaseOptions(
    baseUrl: AppEnv.baseUrl, // KHÔNG thêm /api ở đây
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
}
