import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/api.dart'; // Api() của bạn

// ====================
// MODEL STATE
// ====================
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
  }) {
    return LoginState(
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: errorMessage,
    );
  }
}

// ====================
// VIEWMODEL
// ====================
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel() : super(const LoginState());

  final api = Api();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // ---- Toggle ẩn/hiện mật khẩu
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  // ---- Validate form
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email không được để trống';
    if (!value.contains('@')) return 'Email không hợp lệ';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải ít nhất 6 ký tự';
    return null;
  }

  // ---- LOGIN FUNCTION
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoggingIn: true, errorMessage: null);

    try {
      // GỌI API ĐĂNG NHẬP (Laravel: thường là /api/login)
      final res = await api.dio.post('/api/login', data: {
        'email': email,
        'password': password,
      });

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      // linh hoạt lấy token theo nhiều format trả về
      final token = (data['token'] ??
              data['access_token'] ??
              data['data']?['token'] ??
              data['data']?['access_token'])
          ?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Không nhận được token từ máy chủ');
      }

      // Lưu token -> dùng cho AuthGate + những lần mở app sau
      await _storage.write(key: _tokenKey, value: token);

      // Gắn header Authorization cho các request tiếp theo của Dio
      api.dio.options.headers['Authorization'] = 'Bearer $token';

      state = state.copyWith(isLoggingIn: false, errorMessage: null);
    } on DioException catch (e) {
      // cố lấy message rõ ràng từ backend
      String msg = 'Đăng nhập thất bại';
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else if (e.message != null) {
        msg = e.message!;
      }

      state = state.copyWith(isLoggingIn: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoggingIn: false, errorMessage: e.toString());
    }
  }

  // (tuỳ chọn) Đăng xuất nhanh tại ViewModel
  Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
    } finally {
      api.dio.options.headers.remove('Authorization');
    }
  }
}

// ====================
// PROVIDER
// ====================
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>(
  (ref) => LoginViewModel(),
);
