import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import tương đối theo cấu trúc hiện tại
import 'widgets/login_header.dart';
import '../presentation/view_model/login_view_model.dart';
import '../../../core/api_client.dart'; // gọi /auth/me hoặc /me

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

  /// Gọi /me với token để lấy role rồi điều hướng
  Future<void> _routeByRole() async {
    try {
      // 1) Lấy token (tương thích key cũ/mới)
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      token ??= await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy token. Vui lòng đăng nhập lại.')),
        );
        return;
      }

      // 2) Dùng ApiClient & gắn Authorization
      final dio = ApiClient.create().dio;
      final opts = Options(headers: {'Authorization': 'Bearer $token'});

      // 3) Thử các endpoint /me phổ biến
      final paths = ['/auth/me', '/me', '/api/me', '/api/user'];
      Response res = await _getMeFlexible(dio, opts, paths);

      // 4) Parse role linh hoạt
      final data = (res.data as Map).cast<String, dynamic>();
      final role = (data['role'] ??
          data['user']?['role'] ??
          data['data']?['role'] ??
          '')
          .toString()
          .toLowerCase()
          .trim();

      final isLecturer =
          role == 'lecturer' || role == 'giang_vien' || role == 'giangvien';

      if (!mounted) return;
      if (isLecturer) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(role.isEmpty
              ? 'Không xác định được quyền từ máy chủ.'
              : 'Tài khoản không có quyền giảng viên (role: $role).')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map && (e.response!.data['message'] != null))
          ? e.response!.data['message'].toString()
          : 'Không xác định được quyền (HTTP $code)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xác định được quyền: $e')),
      );
    }
  }

  /// Thử nhiều đường dẫn /me, trả response đầu tiên < 500
  Future<Response> _getMeFlexible(Dio dio, Options opts, List<String> paths) async {
    DioException? last;
    for (final p in paths) {
      try {
        final r = await dio.get(p, options: opts);
        if (r.statusCode != null && r.statusCode! < 500) return r;
      } on DioException catch (e) {
        last = e;
        if (e.response?.statusCode == 401) rethrow; // token sai/hết hạn
        // 404 -> thử path tiếp theo
      }
    }
    if (last != null) throw last;
    throw Exception('Không tìm thấy endpoint /me phù hợp.');
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
          await _routeByRole(); // kiểm tra role trước khi vào app
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
