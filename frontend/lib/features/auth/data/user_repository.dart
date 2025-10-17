import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../domain/user_profile.dart';

class UserRepository {
  final Dio dio = ApiClient.create().dio;
  final storage = const FlutterSecureStorage();

  Future<UserProfile> fetchMe() async {
    String? token = await storage.read(key: 'access_token') ?? await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) throw Exception('No token');

    final opts = Options(headers: {'Authorization': 'Bearer $token'});
    final paths = ['/auth/me', '/me', '/api/me', '/api/user'];
    DioException? last;
    for (final p in paths) {
      try {
        final r = await dio.get(p, options: opts);
        if (r.statusCode != null && r.statusCode! < 500) {
          final data = (r.data as Map).cast<String, dynamic>();
          return UserProfile.fromMap(data);
        }
      } on DioException catch (e) {
        last = e;
        if (e.response?.statusCode == 401) rethrow;
      }
    }
    if (last != null) throw last;
    throw Exception('No /me endpoint matched');
  }
}
