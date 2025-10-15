import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';

abstract class AuthRepository {
  Future<void> login({required String email, required String password});
}

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  // Thử nhiều endpoint phổ biến
  static const _paths = ['/auth/login', '/login', '/api/login'];

  Future<Response> loginFlexible(Map<String, dynamic> body) async {
    DioException? lastErr;
    for (final p in _paths) {
      try {
        final res = await _dio.post(p, data: body);
        if (res.statusCode != null && res.statusCode! < 500) return res;
      } on DioException catch (e) {
        lastErr = e;
        // nếu 404 hoặc 405 => thử path khác
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          continue;
        }
        // nếu 401/422/400 => trả luôn để hiển thị lỗi từ backend
        rethrow;
      }
    }
    if (lastErr != null) throw lastErr;
    throw Exception('Không gọi được endpoint đăng nhập');
  }
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  final TokenStorage storage;
  AuthRepositoryImpl(this.api, this.storage);

  @override
  Future<void> login({required String email, required String password}) async {
    // Thử cả email/password và username/password
    final bodies = [
      {'email': email, 'password': password},
      {'username': email, 'password': password},
    ];

    Response res;
    DioException? lastErr;
    for (final body in bodies) {
      try {
        res = await api.loginFlexible(body);
        // Parse token theo nhiều format
        final data = res.data;
        String? token;

        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          token = (m['access_token'] ?? m['token'] ?? m['data']?['token'] ?? m['meta']?['token'])
              ?.toString();
          final ttype = (m['token_type'] ?? m['type'])?.toString();
          if ((ttype?.toLowerCase() == 'bearer') && token != null && token.isNotEmpty) {
            // ok
          }
        }

        if (token == null || token.isEmpty) {
          // Laravel Sanctum/Passport có thể trả khác; cho phép backend trả cookie (session)
          // nhưng để client tiếp gọi /auth/me thì vẫn cần token → coi như lỗi có message
          final msg = _extractMessage(res);
          throw Exception(msg ?? 'Không nhận được access_token từ backend');
        }

        await storage.setAccessToken(token);
        // Tương thích key cũ (nếu chỗ khác đang đọc 'auth_token')
        await storage.setAuthTokenCompat(token);
        return;
      } on DioException catch (e) {
        lastErr = e;
        // 401/422 => show lỗi rồi dừng
        final sc = e.response?.statusCode ?? 0;
        if (sc == 400 || sc == 401 || sc == 422) {
          final msg = _extractMessage(e.response);
          throw Exception(msg ?? 'Sai tài khoản hoặc mật khẩu');
        }
        // Các lỗi khác thử body tiếp theo
        continue;
      }
    }
    if (lastErr != null) rethrow;
    throw Exception('Đăng nhập thất bại (không xác định)');
  }

  String? _extractMessage(Response? res) {
    try {
      final d = res?.data;
      if (d is Map) {
        final m = Map<String, dynamic>.from(d);
        return (m['message'] ?? m['error'] ?? m['detail'])?.toString();
      }
    } catch (_) {}
    return null;
  }
}

// ===== Providers =====
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final dioProvider = Provider<Dio>((ref) => buildDio());

final authApiProvider  = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));
final authRepoProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(ref.read(authApiProvider), ref.read(tokenStorageProvider)));
