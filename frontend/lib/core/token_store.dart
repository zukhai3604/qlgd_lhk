import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class TokenStore {
  static const _k = 'auth_token';
  final _s = const FlutterSecureStorage();
  Future<void> save(String t) => _s.write(key: _k, value: t);
  Future<String?> read() => _s.read(key: _k);
  Future<void> clear() => _s.delete(key: _k);
}
