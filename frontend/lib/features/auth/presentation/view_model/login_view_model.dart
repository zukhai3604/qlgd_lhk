import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/core/api_client.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

class LoginState {
  final bool isLoggingIn;
  final bool obscurePassword;
  final String? errorMessage;

  const LoginState({
    this.isLoggingIn = false,
    this.obscurePassword = true,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoggingIn,
    bool? obscurePassword,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref);
});

class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._ref) : super(const LoginState());

  final Ref _ref;

  final api = ApiClient.create();
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kCompat = 'auth_token';

  void togglePasswordVisibility() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void clearError() => state = state.copyWith(clearError: true);

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Email không đúng định dạng';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  // Maps the backend string to our standardized Role enum
  Role _mapBackendRole(String? raw) {
    final normalized = (raw ?? '').toLowerCase().trim();
    switch (normalized) {
      case 'admin':
        return Role.ADMIN;
      case 'training':
      case 'dao_tao':
        return Role.DAO_TAO;
      case 'lecturer':
      case 'giang_vien':
        return Role.GIANG_VIEN;
      default:
        return Role.UNKNOWN;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, clearError: true);

    const paths = [
      '/api/login',
      '/auth/login',
      '/login'
    ]; // <-- Ưu tiên /api/login
    final bodies = [
      {'email': email, 'password': password},
    ];

    try {
      final res = await _tryLogin(paths, bodies);

      final token = _extractToken(res.data);
      if (token == null || token.isEmpty) {
        final msg =
            _extractMessage(res.data) ?? 'Không nhận được token từ máy chủ';
        throw Exception(msg);
      }

      await _storage.write(key: _kAccess, value: token);
      await _storage.write(key: _kCompat, value: token);

      api.dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Try to extract role directly from login response (some backends return user in the login payload)
      try {
        final initialRole = _mapRoleFromResponse(res.data);
        if (initialRole != Role.UNKNOWN) {
          // set auth state immediately so redirect can happen even if /me endpoints fail
          _ref.read(authStateProvider.notifier).login(token, initialRole);
          try {
            // ignore: avoid_print
            print('DEBUG: initial role from login response -> $initialRole');
          } catch (_) {}
        }
      } catch (_) {}

      // Fetch profile and update global auth state (fallback / authoritative)
      await _fetchProfileAndSetAuth(token);

      state = state.copyWith(isLoggingIn: false);
    } on DioException catch (e) {
      final msg = _extractMessage(e.response?.data) ??
          ((e.response?.statusCode == 401 || e.response?.statusCode == 422)
              ? 'Sai tài khoản hoặc mật khẩu'
              : 'Đang nhập thất bại. Vui lòng thử lại.');
      state = state.copyWith(isLoggingIn: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(
        isLoggingIn: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _setAuthFromLoginResponse(dynamic data, String token) {
    if (data is! Map) {
      throw Exception('Login response không hợp lệ');
    }

    final m = Map<String, dynamic>.from(data);

    // Backend trả về: {"token":"...", "user":{...}}
    final user = m['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw Exception('Không tìm thấy thông tin user trong response');
    }

    final id = user['id'] ?? 0;
    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    // Ưu tiên role_mapped, fallback về role
    final backendRole = user['role_mapped']?.toString() ?? user['role']?.toString();

    final role = _mapBackendRole(backendRole);

    debugPrint('✅ Login SUCCESS! ID: $id, Name: $name, Role: $backendRole → $role');

    _ref.read(authStateProvider.notifier).login(
      token,
      role,
      id: int.tryParse(id.toString()) ?? 0,
      name: name,
      email: email,
    );
  }

  Future<void> _fetchProfileAndSetAuth(String token) async {
    try {
      const mePaths = ['/api/me', '/auth/me', '/me', '/api/user'];
      final res = await _getMeFlexible(mePaths);

    // GỘP VÀO ĐÂY: Dòng print để kiểm tra lỗi
    debugPrint(
        '👤 /api/me response -> Status: ${res.statusCode}, Data: ${res.data}');

    Map<String, dynamic> m;
    if (res.data is Map && (res.data['data'] is Map)) {
      m = Map<String, dynamic>.from(res.data['data']);
    } else if (res.data is Map) {
      m = Map<String, dynamic>.from(res.data);
    } else {
      throw Exception('Dữ liệu hồ sơ không hợp lệ');
    }

    // Extract fields với nhiều fallback
    final id = (m['id'] ?? m['user']?['id'] ?? m['data']?['id']) ?? 0;
    final name = (m['name'] ??
                m['full_name'] ??
                m['user']?['name'] ??
                m['data']?['name'])
            ?.toString() ??
        '';
    final email = (m['email'] ?? m['user']?['email'] ?? m['data']?['email'])
            ?.toString() ??
        '';

    // Extract role from response
    final role = _mapRoleFromResponse(m);

    // Debug logging
    try {
      // ignore: avoid_print
      print('DEBUG: auth state set with role=$role for token=${token.substring(0, token.length > 8 ? 8 : token.length)}...');
    } catch (_) {}

    _ref.read(authStateProvider.notifier).login(
      token,
      role,
      id: int.tryParse(id.toString()) ?? 0,
      name: name,
      email: email,
    );
    } catch (e) {
      // If profile fetch fails, do NOT overwrite any existing role that we
      // may have already set from the login response. Only set Role.UNKNOWN
      // when there was no prior auth state.
      final current = _ref.read(authStateProvider);
      if (current == null) {
        _ref.read(authStateProvider.notifier).login(token, Role.UNKNOWN);
      } else {
        try {
          // ignore: avoid_print
          print('DEBUG: /me fetch failed but existing auth state present, keeping role=${current.role}');
        } catch (_) {}
      }
    }
  }

  /// Try to read role from a response payload (login response may include user)
  Role _mapRoleFromResponse(dynamic data) {
    try {
      final m = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final rawRole = (m['role'] ?? m['user']?['role'] ?? m['data']?['role'] ?? '').toString();
      final roleStr = rawRole.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final roleMap = <String, Role>{
        'lecturer': Role.GIANG_VIEN,
        'giangvien': Role.GIANG_VIEN,
        'teacher': Role.GIANG_VIEN,

        'training': Role.DAO_TAO,
        'trainingdept': Role.DAO_TAO,
        'trainingdepartment': Role.DAO_TAO,
        'daotao': Role.DAO_TAO,
        'dao_tao': Role.DAO_TAO,

        'admin': Role.ADMIN,
        'administrator': Role.ADMIN,
      };

      return roleMap[roleStr] ?? Role.UNKNOWN;
    } catch (_) {
      return Role.UNKNOWN;
    }
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/api/logout');
    } catch (_) {}
    await LoginViewModel._storage.delete(key: LoginViewModel._kAccess);
    await LoginViewModel._storage.delete(key: LoginViewModel._kCompat);
    _ref.read(authStateProvider.notifier).logout();
  }

  Future<Response> _getMeFlexible(List<String> paths) async {
    DioException? lastErr;
    for (final p in paths) {
      try {
        final r = await api.dio.get(p);
        if ((r.statusCode ?? 500) < 500) return r;
      } on DioException catch (e) {
        lastErr = e;
        if ([401, 403].contains(e.response?.statusCode)) rethrow;
      }
    }
    throw lastErr ?? Exception('Không tìm thấy endpoint /me phù hợp.');
  }

  Future<Response> _tryLogin(
      List<String> paths, List<Map<String, dynamic>> bodies) async {
    DioException? lastErr;
    for (final p in paths) {
      for (final b in bodies) {
        try {
          final res = await api.dio.post(
            p,
            data: b,
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              validateStatus: (c) => c != null && c < 500,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );
          debugPrint('✅ Login endpoint $p responded with status: ${res.statusCode}');
          if (res.statusCode != null && res.statusCode! < 500) return res;
        } on DioException catch (e) {
          debugPrint('❌ Login endpoint $p failed: ${e.type} - ${e.message}');
          lastErr = e;
          final sc = e.response?.statusCode ?? 0;
          if (sc == 401 || sc == 422 || sc == 400) rethrow;
        }
      }
    }
    if (lastErr != null) throw lastErr;
    throw Exception('Không gọi được endpoint đăng nhập');
  }

  String? _extractToken(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      // Cập nhật để khớp với response của Laravel
      return (m['token'] ?? m['access_token'] ?? m['data']?['token'])
          ?.toString();
    }
    return null;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      return (m['message'] ??
              m['error'] ??
              m['detail'] ??
              m['debug']?['message'])
          ?.toString();
    }
    return null;
  }
}
