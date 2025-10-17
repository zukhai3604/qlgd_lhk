import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kCompat = 'auth_token';
  final FlutterSecureStorage? _secure = kIsWeb ? null : const FlutterSecureStorage();

  Future<String?> getAccessToken() async => kIsWeb ? null : _secure?.read(key: _kAccess);
  Future<void> setAccessToken(String v) async => kIsWeb ? Future.value() : _secure?.write(key: _kAccess, value: v);

  // thêm tương thích
  Future<void> setAuthTokenCompat(String v) async => kIsWeb ? Future.value() : _secure?.write(key: _kCompat, value: v);

  Future<void> clear() async { if (!kIsWeb) await _secure?.deleteAll(); }
}
