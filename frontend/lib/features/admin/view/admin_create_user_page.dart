import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

// Dùng lại Dio đã có
import 'package:qlgd_lhk/features/admin/presentation/admin_providers.dart'
    show dioProvider;

class AdminCreateUserPage extends ConsumerStatefulWidget {
  const AdminCreateUserPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCreateUserPage> createState() =>
      _AdminCreateUserPageState();
}

class _AdminCreateUserPageState extends ConsumerState<AdminCreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();

  String _role = 'GIANG_VIEN'; // mặc định
  bool _requireChange = true; // bắt đổi pass khi đăng nhập lần đầu
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  String _genPwd([int len = 12]) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#\$%';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dio = ref.read(dioProvider);
    setState(() => _submitting = true);

    final payload = {
      'name': _nameCtl.text.trim(),
      'email': _emailCtl.text.trim(),
      'phone': _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
      'role': _role, // 'ADMIN' | 'DAO_TAO' | 'GIANG_VIEN'
      'password': _passwordCtl.text.isEmpty
          ? _genPwd()
          : _passwordCtl.text, // giữ nguyên logic ban đầu
      'force_change': _requireChange,
    };

    try {
      final res = await dio.post('/api/admin/users', data: payload);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;

      if (!mounted) return;
      final shownPwd = payload['password'] as String;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tạo tài khoản thành công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tên: ${payload['name']}'),
              Text('Email: ${payload['email']}'),
              const SizedBox(height: 8),
              const Text('Mật khẩu khởi tạo:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectableText(
                shownPwd,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shownPwd));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã copy mật khẩu')),
                );
              },
              child: const Text('Sao chép'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (data is Map && data['id'] != null) {
        context.go('/admin/users/${data['id']}');
      } else {
        context.go('/admin/users');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Không thể tạo tài khoản';
      if (e.response?.statusCode == 422 && e.response?.data is Map) {
        final m = e.response!.data as Map;
        if (m['errors'] is Map && (m['errors'] as Map).isNotEmpty) {
          final firstKey = (m['errors'] as Map).keys.first;
          final firstErr =
          (m['errors'][firstKey] as List?)?.first?.toString();
          if (firstErr != null) msg = firstErr;
        } else if (m['message'] is String) {
          msg = m['message'];
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Bottom nav: định tuyến 3 tab
  int _navIndex(BuildContext context) {
    final loc =
        GoRouter.of(context).routeInformationProvider.value.location;
    if (loc.startsWith('/admin/account')) return 2;
    if (loc.startsWith('/admin/notifications')) return 1;
    return 0;
  }

  void _goNotifications(BuildContext context) {
    try {
      context.goNamed('adminNotifications');
    } catch (_) {
      context.go('/admin/notifications');
    }
  }

  void _goAccount(BuildContext context) {
    try {
      context.goNamed('adminAccount');
    } catch (_) {
      context.go('/admin/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ===== Header trường =====
            Text(
              'TRƯỜNG ĐẠI HỌC THỦY LỢI',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.blue[800],
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'TẠO TÀI KHOẢN',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // ===== Nội dung căn giữa trong Card =====
            Expanded(
              child: ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // --- Họ tên ---
                                _RoundedField(
                                  controller: _nameCtl,
                                  label: 'Họ và tên',
                                  icon: Icons.badge_outlined,
                                  validator: (v) => (v == null ||
                                      v.trim().isEmpty)
                                      ? 'Vui lòng nhập họ tên'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // --- Email ---
                                _RoundedField(
                                  controller: _emailCtl,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null ||
                                        v.trim().isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    final ok = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+$')
                                        .hasMatch(v.trim());
                                    return ok ? null : 'Email không hợp lệ';
                                  },
                                ),
                                const SizedBox(height: 12),

                                // --- Số điện thoại (tuỳ chọn) ---
                                _RoundedField(
                                  controller: _phoneCtl,
                                  label: 'Số điện thoại (tuỳ chọn)',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),

                                // --- Vai trò (radio card) ---
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Vai trò',
                                      style: theme.textTheme.labelLarge),
                                ),
                                const SizedBox(height: 8),
                                _RoleTile(
                                  value: 'GIANG_VIEN',
                                  group: _role,
                                  onChanged: (v) =>
                                      setState(() => _role = v),
                                  icon: Icons.school_outlined,
                                  title: 'Giảng viên',
                                  subtitle:
                                  'Xem & cập nhật buổi dạy, điểm danh',
                                ),
                                _RoleTile(
                                  value: 'DAO_TAO',
                                  group: _role,
                                  onChanged: (v) =>
                                      setState(() => _role = v),
                                  icon: Icons.badge_outlined,
                                  title: 'Phòng đào tạo',
                                  subtitle:
                                  'Duyệt nghỉ dạy, điều phối lịch',
                                ),
                                _RoleTile(
                                  value: 'ADMIN',
                                  group: _role,
                                  onChanged: (v) =>
                                      setState(() => _role = v),
                                  icon: Icons.admin_panel_settings_outlined,
                                  title: 'Admin',
                                  subtitle:
                                  'Quản trị hệ thống, nhật ký',
                                ),
                                const SizedBox(height: 12),

                                // --- Mật khẩu + nút random ---
                                _PasswordField(
                                  controller: _passwordCtl,
                                  onGenerate: () => setState(
                                          () => _passwordCtl.text = _genPwd()),
                                ),

                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _requireChange,
                                  onChanged: (b) => setState(
                                          () => _requireChange = b ?? true),
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  title: const Text(
                                      'Bắt buộc đổi mật khẩu khi đăng nhập lần đầu',
                                      style: TextStyle(fontSize: 13)),
                                  contentPadding: EdgeInsets.zero,
                                ),

                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                    _submitting ? null : _submit,
                                    icon: _submitting
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Icon(Icons
                                        .person_add_alt_1_outlined),
                                    label: Text(_submitting
                                        ? 'Đang tạo…'
                                        : 'Tạo tài khoản'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset + 8),
                ],
              ),
            ),
          ],
        ),
      ),

      // ===== Bottom Navigation như các trang khác =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex(context),
        onTap: (i) {
          if (i == 0) {
            context.go('/dashboard');
          } else if (i == 1) {
            _goNotifications(context);
          } else if (i == 2) {
            _goAccount(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

/// --------- Widgets phụ cho UI mềm mại ---------

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _RoundedField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String value;
  final String group;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoleTile({
    Key? key,
    required this.value,
    required this.group,
    required this.onChanged,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFEFF4FF) : Colors.white,
        elevation: selected ? 2.5 : 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Radio<String>(
                  value: value,
                  groupValue: group,
                  onChanged: (v) => onChanged(v!),
                ),
                const SizedBox(width: 2),
                Icon(icon,
                    color: selected ? Colors.blue[700] : Colors.black54),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.blue[900]
                                : Colors.black87,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.blueGrey[700]
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onGenerate;
  const _PasswordField(
      {required this.controller, required this.onGenerate});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: 'Mật khẩu khởi tạo (bỏ trống để tự tạo)',
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Tạo ngẫu nhiên',
              onPressed: widget.onGenerate,
              icon: const Icon(Icons.autorenew_rounded),
            ),
            IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            ),
          ],
        ),
      ),
    );
  }
}
