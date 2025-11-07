import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';
import 'package:qlgd_lhk/core/models.dart';

class AuthRepo {
  final _api = ApiClient.create();
  final _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final r = await _api.dio.post('/api/login', data: {'email': email, 'password': password});
    final token = r.data['token']?.toString();
    if (token==null || token.isEmpty) { throw Exception('No token returned'); }
    await _storage.write(key: 'auth_token', value: token);
    final me = await _api.dio.get('/api/me');
    return User.fromJson(me.data as Map<String,dynamic>);
  }

  Future<User> me() async {
    final me = await _api.dio.get('/api/me');
    return User.fromJson(me.data as Map<String,dynamic>);
  }
}
