import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../data/api.dart'; // file Api bạn đã tạo ở phần trước

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
      // GỌI API ĐĂNG NHẬP
      final res = await api.dio.post('/api/login', data: {
        'email': email,
        'password': password,
      });

      final data = res.data as Map<String, dynamic>;

      // lấy token (tuỳ backend trả)
      final token = data['token'] as String?;
      if (token == null) throw Exception('Không nhận được token');

      // lưu token vào header cho các API tiếp theo
      api.dio.options.headers['Authorization'] = 'Bearer $token';

      // bạn có thể lưu token vào secure storage nếu muốn
      // await const FlutterSecureStorage().write(key: 'token', value: token);

      state = state.copyWith(isLoggingIn: false, errorMessage: null);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message;
      state = state.copyWith(
        isLoggingIn: false,
        errorMessage: 'Đăng nhập thất bại: $msg',
      );
    } catch (e) {
      state = state.copyWith(
        isLoggingIn: false,
        errorMessage: e.toString(),
      );
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
