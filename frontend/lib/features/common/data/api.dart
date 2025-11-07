// lib/data/api.dart
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

class Api {
  final dio = Dio(BaseOptions(
    baseUrl: Env.baseUrl, // KHÔNG thêm /api ở đây
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
}
