import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/data/storage/secure_storage.dart';
import 'package:qlgd_lhk/features/auth/model/repositories/auth_repository.dart';
import 'package:qlgd_lhk/features/auth/model/datasources/auth_remote_ds.dart';
import 'package:qlgd_lhk/features/auth/model/repositories/auth_repository_impl.dart';


// 1. Define the State
@immutable
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
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// 2. Define the ViewModel
class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;

  LoginViewModel(this._ref, this._authRepository, this._secureStorage)
      : super(const LoginState());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email không được để trống';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Email không đúng định dạng';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoggingIn: true, clearError: true);
    try {
      final (user, token) = await _authRepository.login(email, password);
      await _secureStorage.saveToken(token);

      // Update state. The router will automatically react and navigate.
      _ref.read(authStateProvider.notifier).state = user;
      _ref.read(roleProvider.notifier).state = user.role;

    } catch (e) {
      state = state.copyWith(errorMessage: 'Email hoặc mật khẩu không đúng. Vui lòng thử lại!');
    } finally {
      state = state.copyWith(isLoggingIn: false);
    }
  }
}

// 3. Define the Provider
final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return LoginViewModel(ref, authRepo, secureStorage);
});

// Mock providers for dependencies
final secureStorageProvider = Provider((ref) => SecureStorageService());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(ref.watch(authRemoteDSProvider)));
final authRemoteDSProvider = Provider<AuthRemoteDS>((ref) => AuthRemoteDSImpl());
