import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

import 'widgets/login_header.dart';
import '../presentation/view_model/login_view_model.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ref.read(loginViewModelProvider.notifier).login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm  = ref.watch(loginViewModelProvider);
    final vmN = ref.read(loginViewModelProvider.notifier);
    final cs  = Theme.of(context).colorScheme;

    // Listen for errors from the view model and show a snackbar
    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    // Listen for auth state changes and redirect according to role.
    ref.listen<AuthState?>(authStateProvider, (previous, next) {
      if (next == null) return; // logged out or nothing
      // Only navigate when user just logged in (previous == null) or role changed
      final prevRole = previous?.role;
      final nextRole = next.role;
      if (prevRole == nextRole) return;
      if (!mounted) return;
      switch (nextRole) {
        case Role.DAO_TAO:
          context.go('/training-dept/home');
          break;
        case Role.GIANG_VIEN:
          context.go('/home');
          break;
        case Role.ADMIN:
          context.go('/users');
          break;
        default:
          context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const LoginHeader(),
                    const SizedBox(height: 24),

                    Text('Tài khoản', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'GiangVien@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      validator: vmN.validateEmail,
                      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),

                    const SizedBox(height: 16),

                    Text('Mật khẩu', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: vm.obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        suffixIcon: IconButton(
                          tooltip: vm.obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          icon: Icon(vm.obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: vmN.togglePasswordVisibility,
                        ),
                      ),
                      validator: vmN.validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển')),
                        ),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: vm.isLoggingIn ? null : _submit,
                        child: vm.isLoggingIn
                            ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Đăng nhập'),
                      ),
                    ),

                    // Hiển thị lỗi màu đỏ dưới button
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 36),
                    const Text(
                      '© 2025 LHK',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
