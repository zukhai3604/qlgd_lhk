import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';

/// ====================
/// MODEL STATE
/// ====================
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

/// ====================
/// VIEWMODEL
/// ====================
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel() : super(const LoginState());

  final api = ApiClient.create();
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kCompat = 'auth_token';

  /// Toggle ẩn/hiện mật khẩu
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Clear error thủ công (nếu UI cần)
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Validate
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

  /// LOGIN
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, clearError: true);

    // Thử nhiều endpoint & payload để tương thích backend
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

      // Lưu cả 2 key để AuthGate/legacy code đều đọc được
      await _storage.write(key: _kAccess, value: token);
      await _storage.write(key: _kCompat, value: token);

      // Set header Authorization cho các request sau
      api.dio.options.headers['Authorization'] = 'Bearer $token';

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

  /// LOGOUT (nếu cần dùng)
  Future<void> logout() async {
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kCompat);
    } catch (_) {}
  }

  /// ---- helpers

  Future<Response> _tryLogin(List<String> paths, List<Map<String, dynamic>> bodies) async {
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
          // Nếu <500 coi như có phản hồi, để parse message hoặc token
          if (res.statusCode != null && res.statusCode! < 500) return res;
        } on DioException catch (e) {
          lastErr = e;
          // 404/405 -> thử endpoint khác; 401/422 -> ném ngay để UI hiện lỗi hợp lệ
          final sc = e.response?.statusCode ?? 0;
          if (sc == 401 || sc == 422 || sc == 400) rethrow;
          // tiếp tục thử biến thể kế tiếp
        }
      }
    }
    if (lastErr != null) throw lastErr;
    throw Exception('Không gọi được endpoint đăng nhập');
  }

  String? _extractToken(dynamic data) {
    try {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return (m['access_token'] ??
            m['token'] ??
            m['data']?['access_token'] ??
            m['data']?['token'] ??
            m['meta']?['token'])
            ?.toString();
      }
    } catch (_) {}
    return null;
  }

  String? _extractMessage(dynamic data) {
    try {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return (m['message'] ?? m['error'] ?? m['detail'])?.toString();
      }
    } catch (_) {}
    return null;
  }
}

/// ====================
/// PROVIDER
/// ====================
final loginViewModelProvider =
StateNotifierProvider<LoginViewModel, LoginState>(
      (ref) => LoginViewModel(),
);
