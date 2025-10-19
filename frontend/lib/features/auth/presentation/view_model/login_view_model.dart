import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

// ... (LoginState class remains the same)
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


class LoginViewModel extends StateNotifier<LoginState> {
  // Inject the Ref to allow communication with other providers
  final Ref _ref;

  LoginViewModel(this._ref) : super(const LoginState());

  final api = ApiClient.create();
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kCompat = 'auth_token';

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email không được để trống';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Email không đúng định dạng';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, clearError: true);

    const paths = ['/auth/login', '/login', '/api/login'];
    final bodies = [
      {'email': email, 'password': password},
      {'username': email, 'password': password},
    ];

    try {
      Response res = await _tryLogin(paths, bodies);
      final token = _extractToken(res.data);

      if (token == null || token.isEmpty) {
        final msg = _extractMessage(res.data) ?? 'Không nhận được token từ máy chủ';
        throw Exception(msg);
      }

      await _storage.write(key: _kAccess, value: token);
      await _storage.write(key: _kCompat, value: token);
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Fetch profile and update global auth state
      await _fetchProfileAndSetAuth(token);

      state = state.copyWith(isLoggingIn: false);

    } on DioException catch (e) {
      final msg = _extractMessage(e.response?.data) ??
          (e.response?.statusCode == 401 || e.response?.statusCode == 422
              ? 'Sai tài khoản hoặc mật khẩu'
              : 'Đăng nhập thất bại. Vui lòng thử lại.');
      state = state.copyWith(isLoggingIn: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoggingIn: false, errorMessage: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // New method to get user profile and role
  Future<void> _fetchProfileAndSetAuth(String token) async {
    try {
      final paths = ['/auth/me', '/me', '/api/me', '/api/user'];
      final res = await _getMeFlexible(paths);
      final data = (res.data as Map).cast<String, dynamic>();
      final rawRole = (data['role'] ?? data['user']?['role'] ?? data['data']?['role'] ?? '').toString();

      // Normalize: remove non-alphanumeric, lowercase
      final roleStr = rawRole.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Map common server role strings (including DAO_TAO) to our Role enum
      final roleMap = <String, Role>{
        'lecturer': Role.lecturer,
        'giangvien': Role.lecturer,
        'teacher': Role.lecturer,

        'training': Role.training,
        'trainingdept': Role.training,
        'trainingdepartment': Role.training,
        'daotao': Role.training, // DAO_TAO from backend
        'dao_tao': Role.training,

        'admin': Role.admin,
        'administrator': Role.admin,
      };

      final role = roleMap[roleStr] ?? Role.unknown;

      // Update the global authentication state
      _ref.read(authStateProvider.notifier).login(token, role);

    } catch (e) {
      // If profile fetch fails, still log in with unknown role
      _ref.read(authStateProvider.notifier).login(token, Role.unknown);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kCompat);
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

  Future<Response> _tryLogin(List<String> paths, List<Map<String, dynamic>> bodies) async {
    // ... (This method remains the same)
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
            ),
          );
          if (res.statusCode != null && res.statusCode! < 500) return res;
        } on DioException catch (e) {
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
    // ... (This method remains the same)
    if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return (m['access_token'] ??
            m['token'] ??
            m['data']?['access_token'] ??
            m['data']?['token'] ??
            m['meta']?['token'])
            ?.toString();
      }
    return null;
  }

  String? _extractMessage(dynamic data) {
    // ... (This method remains the same)
    if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return (m['message'] ?? m['error'] ?? m['detail'])?.toString();
      }
    return null;
  }
}

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>(
  // Pass the ref to the ViewModel
  (ref) => LoginViewModel(ref),
);
