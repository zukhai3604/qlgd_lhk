import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/auth/view/widgets/login_header.dart';
import 'package:qlgd_lhk/features/auth/view_model/login_view_model.dart';
import 'package:qlgd_lhk/core/api_client.dart'; // <-- thêm để gọi /me

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
      FocusScope.of(context).unfocus(); // ẩn bàn phím
      ref.read(loginViewModelProvider.notifier).login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  /// Sau khi login thành công, gọi /me để lấy role rồi điều hướng
  Future<void> _routeByRole() async {
    try {
      final api = ApiClient.create();
      final res = await api.dio.get('/me');
      final data = res.data as Map<String, dynamic>;

      // tuỳ payload backend, lấy role linh hoạt
      final role = (data['role'] ??
              data['user']?['role'] ??
              data['data']?['role'] ??
              '')
          .toString()
          .toLowerCase()
          .trim();

      // các biến thể tên role có thể gặp
      final isLecturer =
          role == 'lecturer' || role == 'giang_vien' || role == 'giangvien';

      if (!mounted) return;

      if (isLecturer) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else {
        // Nếu bạn đã có route cho admin/training, thêm điều hướng ở đây
        // else if (role == 'admin') { Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false); }
        // else if (role == 'training' || role == 'dao_tao' || role == 'daotao') { ... }

        // Mặc định: không đúng quyền => ở lại login + báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản không có quyền phù hợp để vào ứng dụng giảng viên.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xác định được quyền: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm  = ref.watch(loginViewModelProvider);
    final vmN = ref.read(loginViewModelProvider.notifier);
    final cs  = Theme.of(context).colorScheme;

    // Lắng nghe trạng thái login để điều hướng theo role
    ref.listen(loginViewModelProvider, (prev, next) async {
      final wasLoading  = prev?.isLoggingIn == true;
      final doneLoading = next.isLoggingIn == false;

      if (wasLoading && doneLoading) {
        if (next.errorMessage == null) {
          if (!mounted) return;
          await _routeByRole(); // <-- kiểm tra role trước khi vào app
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
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

                    // ---- Email
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

                    // ---- Password
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

                    // ---- Button
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

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.error),
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
