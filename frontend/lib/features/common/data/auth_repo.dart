// lib/data/auth_repo.dart
import 'package:dio/dio.dart';
import 'api.dart';

class AuthRepo {
  final api = Api();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await api.dio.post('/api/login', data: {
      'email': email,
      'password': password, // giống hệt Postman
    });
    return Map<String, dynamic>.from(res.data);
  }
}
