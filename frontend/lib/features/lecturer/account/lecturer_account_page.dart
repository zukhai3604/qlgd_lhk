import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../common/providers/auth_state_provider.dart';
import '../../../common/providers/role_provider.dart';
import '../../../core/api_client.dart';

/// Cho phép LecturerAccountPage tự mở đúng bottom sheet khi được điều hướng tới
/// /account/edit    -> AccountSheet.edit
/// /account/change-password -> AccountSheet.changePassword
enum AccountSheet { none, edit, changePassword }

class LecturerAccountPage extends ConsumerStatefulWidget {
  const LecturerAccountPage({
    super.key,
    this.initialSheet = AccountSheet.none,
  });

  /// Sheet muốn tự mở khi vào trang (dùng cho deep-link từ router)
  final AccountSheet initialSheet;

  @override
  ConsumerState<LecturerAccountPage> createState() => _LecturerAccountPageState();
}

class _LecturerAccountPageState extends ConsumerState<LecturerAccountPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic> me = {};

  @override
  void initState() {
    super.initState();
    _loadMe();

    // Nếu route con yêu cầu mở sheet ngay khi vào
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (widget.initialSheet) {
        case AccountSheet.edit:
          _showEditAccountSheet(context);
          break;
        case AccountSheet.changePassword:
          _showChangePasswordSheet(context);
          break;
        case AccountSheet.none:
          break;
      }
    });
  }

  // ===== Helpers chọn endpoint theo ROLE =====
  Role _role() {
    final s = ref.read(authStateProvider);
    return s?.role ?? Role.UNKNOWN;
  }

  // GET profile theo role (có fallback /api/me)
  List<String> _profileGetUrls(Role r) {
    switch (r) {
      case Role.DAO_TAO:
        return ['/api/training_department/me/profile', '/api/me'];
      case Role.GIANG_VIEN:
        return ['/api/lecturer/me/profile', '/api/me'];
      case Role.ADMIN:
        return ['/api/admin/me/profile', '/api/me'];
      default:
        return ['/api/me'];
    }
  }

  // UPDATE profile theo role (thử lần lượt)
  List<({String method, String url})> _profileUpdateEndpoints(Role r) {
    switch (r) {
      case Role.DAO_TAO:
        return [
          (method: 'PATCH', url: '/api/training_department/me/profile'),
          (method: 'POST', url: '/api/me/update'),
        ];
      case Role.GIANG_VIEN:
        return [
          (method: 'PATCH', url: '/api/lecturer/me/profile'),
          (method: 'POST', url: '/api/me/update'),
        ];
      case Role.ADMIN:
        return [
          (method: 'PATCH', url: '/api/admin/me/profile'),
          (method: 'POST', url: '/api/me/update'),
        ];
      default:
        return [
          (method: 'POST', url: '/api/me/update'),
        ];
    }
  }

  // CHANGE-PASSWORD (ưu tiên chung /api/me/change-password, thêm fallback theo role nếu có)
  List<String> _changePasswordUrls(Role r) {
    return [
      '/api/me/change-password',
      if (r == Role.GIANG_VIEN) '/api/lecturer/me/change-password',
      if (r == Role.DAO_TAO) '/api/training_department/me/change-password',
      if (r == Role.ADMIN) '/api/admin/me/change-password',
    ];
  }

  Future<void> _loadMe() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    final dio = ApiClient().dio;
    final urls = _profileGetUrls(_role());

    DioException? lastErr;
    for (final u in urls) {
      try {
        final res = await dio.get(u);
        final body = res.data;
        final map = (body is Map && body['data'] is Map) ? body['data'] : body;
        if (map is! Map) throw Exception('Dữ liệu hồ sơ không hợp lệ.');

        if (!mounted) return;
        setState(() {
          me = Map<String, dynamic>.from(map);
          loading = false;
          error = null;
        });
        return;
      } on DioException catch (e) {
        lastErr = e;
        final code = e.response?.statusCode ?? 0;
        // 404/405 -> thử URL tiếp theo
        if (code == 404 || code == 405) continue;
        continue;
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      error = lastErr != null
          ? 'Lỗi tải hồ sơ (HTTP ${lastErr.response?.statusCode ?? 'null'})'
          : 'Không tải được hồ sơ';
      loading = false;
    });
  }

  // Helper: lấy chuỗi từ map lồng nhau
  String _pickS(List<String> keys, [String defaultValue = '---']) {
    for (final k in keys) {
      dynamic cur = me;
      for (final p in k.split('.')) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && '$cur'.trim().isNotEmpty) return '$cur'.trim();
    }
    return defaultValue;
  }

  String _fmtDob(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _vnRole(String r) {
    switch (r.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị';
      case 'TRAINING_DEPARTMENT':
      case 'DAO_TAO':
        return 'Phòng Đào tạo';
      case 'LECTURER':
      case 'GIANG_VIEN':
        return 'Giảng viên';
      default:
        return r;
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'auth_token');

    if (mounted) {
      ref.read(authStateProvider.notifier).logout();
      context.go('/login');
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMe,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    // ==== Map dữ liệu ra UI ====
    final name = _pickS(['user.name', 'name', 'full_name']);
    final dobRaw = _pickS(['lecturer.date_of_birth', 'date_of_birth', 'dob'], '');
    final dob = dobRaw.isEmpty ? '---' : _fmtDob(dobRaw);
    final gender = _pickS(['lecturer.gender', 'gender']);
    final phone = _pickS(['user.phone', 'phone']);
    final email = _pickS(['user.email', 'email']);
    final department = _pickS(['lecturer.department.name', 'department.name', 'lecturer.department']);
    final faculty = _pickS(['lecturer.department.faculty.name', 'department.faculty.name', 'faculty.name']);
    final roleStr = _pickS(['user.role', 'role'], '');
    final role = roleStr.isEmpty ? '---' : _vnRole(roleStr);
    final avatar = _pickS(['avatar_url', 'avatar'], '');

    return RefreshIndicator(
      onRefresh: _loadMe,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          const Text(
            'TRƯỜNG ĐẠI HỌC THỦY LỢI',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: (avatar.isNotEmpty && avatar.startsWith('http')) ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 44) : null,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Tên giảng viên', name),
          _buildInfoCard('Ngày sinh', dob),
          Row(
            children: [
              Expanded(child: _buildInfoCard('Giới tính', gender)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoCard('Số điện thoại', phone)),
            ],
          ),
          _buildInfoCard('Email', email),
          _buildInfoCard('Bộ môn', department),
          Row(
            children: [
              Expanded(child: _buildInfoCard('Vai trò', role)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoCard('Khoa', faculty)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Cài đặt', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.settings_outlined,
                  title: 'Chỉnh sửa tài khoản',
                  onTap: () => _showEditAccountSheet(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  onTap: () => _showChangePasswordSheet(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  color: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _logout();
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// ====== POPUP: Đổi mật khẩu (bottom sheet Android-style) ======
  Future<void> _showChangePasswordSheet(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;
    bool ob1 = true, ob2 = true, ob3 = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Text('Đổi mật khẩu', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: currentCtrl,
                      obscureText: ob1,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setS(() => ob1 = !ob1),
                          icon: Icon(ob1 ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: newCtrl,
                      obscureText: ob2,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (≥ 6 ký tự)',
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: IconButton(
                          onPressed: () => setS(() => ob2 = !ob2),
                          icon: Icon(ob2 ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
                        if (v.trim().length < 6) return 'Mật khẩu phải từ 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: ob3,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setS(() => ob3 = !ob3),
                          icon: Icon(ob3 ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu';
                        if (v != newCtrl.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        TextButton(
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: submitting ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => submitting = true);
                            try {
                              final dio = ApiClient().dio;
                              final urls = _changePasswordUrls(_role());
                              DioException? lastErr;

                              for (final u in urls) {
                                try {
                                  await dio.post(u, data: {
                                    'current_password': currentCtrl.text.trim(),
                                    'password': newCtrl.text.trim(),
                                    'password_confirmation': confirmCtrl.text.trim(),
                                  });
                                  if (mounted) {
                                    Navigator.of(ctx).pop();
                                    _showSnack('Đổi mật khẩu thành công');
                                  }
                                  return;
                                } on DioException catch (e) {
                                  lastErr = e;
                                  // 422: hiển thị chi tiết ngay và dừng
                                  if (e.response?.statusCode == 422) {
                                    final data = e.response?.data;
                                    if (data is Map && data['errors'] is Map) {
                                      final errs = (data['errors'] as Map).entries
                                          .expand((kv) => (kv.value as List).map((x) => '- ${kv.key}: $x'))
                                          .join('\n');
                                      _showSnack(errs.isEmpty ? 'Dữ liệu không hợp lệ' : errs, error: true);
                                      setS(() => submitting = false);
                                      return;
                                    }
                                  }
                                  // 404/405 -> thử URL tiếp
                                  final code = e.response?.statusCode ?? 0;
                                  if (code == 404 || code == 405) continue;
                                  // lỗi khác -> thử tiếp URL sau
                                  continue;
                                }
                              }

                              setS(() => submitting = false);
                              _showSnack('Lỗi đổi mật khẩu (HTTP ${lastErr?.response?.statusCode ?? 'null'})', error: true);
                            } catch (e) {
                              setS(() => submitting = false);
                              _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
                            }
                          },
                          icon: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_outlined),
                          label: const Text('Lưu'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  /// ====== POPUP: Chỉnh tài khoản (bottom sheet Android-style) ======
  Future<void> _showEditAccountSheet(BuildContext context) async {
    // Pre-fill từ me
    final nameCtrl = TextEditingController(text: _pickS(['user.name', 'name', 'full_name'], ''));
    final phoneCtrl = TextEditingController(text: _pickS(['user.phone', 'phone'], ''));
    final email = _pickS(['user.email', 'email'], ''); // read-only

    // Gender
    final genderRaw = _pickS(['lecturer.gender', 'gender'], '');
    String gender = (['Nam', 'Nữ', 'Khác'].contains(genderRaw))
        ? genderRaw
        : (genderRaw.isEmpty ? 'Khác' : genderRaw);

    // DOB
    DateTime? dob;
    final dobRaw = _pickS(['lecturer.date_of_birth', 'date_of_birth', 'dob'], '');
    if (dobRaw.isNotEmpty) {
      try {
        dob = DateTime.parse(dobRaw);
      } catch (_) {}
    }

    // Faculty/Department
    final departmentIdRaw = _pickS(['lecturer.department_id', 'department_id'], '');
    int? departmentId = int.tryParse(departmentIdRaw);
    String departmentName = _pickS(['lecturer.department.name', 'department.name', 'lecturer.department'], '---');
    String facultyName = _pickS(['lecturer.department.faculty.name', 'department.faculty.name', 'faculty.name'], '---');

    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    // DS chọn
    List<Map<String, dynamic>> faculties = [];
    List<Map<String, dynamic>> departments = [];
    int? facultyId; // chọn Khoa → load lại Bộ môn

    String fmtDob(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    Future<void> fetchFaculties(Function(void Function()) setS) async {
      try {
        final dio = ApiClient().dio;
        final res = await dio.get('/api/faculties');
        final data = res.data;
        final list = (data is Map && data['data'] is List) ? data['data'] : data;
        if (list is List) {
          setS(() {
            faculties = List<Map<String, dynamic>>.from(
              list.map((e) => Map<String, dynamic>.from(e)),
            );
            // nếu tìm ra facultyId theo facultyName hiện tại thì gán để tự load department
            final found = faculties.firstWhere(
              (f) => (f['name']?.toString() ?? '').trim() == facultyName.trim(),
              orElse: () => {},
            );
            if (found.isNotEmpty) {
              facultyId = int.tryParse('${found['id']}');
            }
          });
        }
      } catch (e) {
        // 404/405 -> không có API danh mục, giữ nguyên fallback read-only
      }
    }

    Future<void> fetchDepartments(Function(void Function()) setS, {int? byFacultyId}) async {
      if (byFacultyId == null) {
        setS(() => departments = []);
        return;
      }
      try {
        final dio = ApiClient().dio;
        final res = await dio.get('/api/departments', queryParameters: {'faculty_id': byFacultyId});
        final data = res.data;
        final list = (data is Map && data['data'] is List) ? data['data'] : data;
        if (list is List) {
          setS(() {
            departments = List<Map<String, dynamic>>.from(
              list.map((e) => Map<String, dynamic>.from(e)),
            );
            // nếu đang có sẵn departmentId mà không thuộc faculty mới → clear
            if (departmentId != null && !departments.any((d) => '${d['id']}' == '$departmentId')) {
              departmentId = null;
            }
          });
        }
      } catch (e) {
        // 404/405 -> không có API danh mục, giữ fallback read-only
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool firstBuild = true;
        return StatefulBuilder(
          builder: (ctx, setS) {
            // Lần đầu: thử fetch danh mục (nếu có)
            if (firstBuild) {
              firstBuild = false;
              // tải danh sách khoa → rồi tải bộ môn theo khoa đoán được
              fetchFaculties(setS).then((_) => fetchDepartments(setS, byFacultyId: facultyId));
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Text('Chỉnh sửa tài khoản', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),

                    // Họ tên
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),

                    // SĐT
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // cho phép bỏ trống
                        final p = v.replaceAll(RegExp(r'\s+'), '');
                        if (!RegExp(r'^[0-9+\-]{8,15}$').hasMatch(p)) return 'Số điện thoại không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Giới tính
                    DropdownButtonFormField<String>(
                      value: (['Nam','Nữ','Khác'].contains(gender)) ? gender : 'Khác',
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                      ],
                      onChanged: (v) => setS(() => gender = v ?? 'Khác'),
                    ),
                    const SizedBox(height: 12),

                    // Ngày sinh
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final initial = dob ?? DateTime(now.year - 20, now.month, now.day);
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: initial,
                          firstDate: DateTime(1950, 1, 1),
                          lastDate: DateTime(now.year, now.month, now.day),
                        );
                        if (picked != null) setS(() => dob = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(dob == null ? 'Chạm để chọn' : fmtDob(dob!)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email (read-only)
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email (không chỉnh sửa)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Khoa + Bộ môn
                    if (faculties.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        value: facultyId,
                        decoration: const InputDecoration(
                          labelText: 'Khoa',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        items: faculties.map((f) {
                          return DropdownMenuItem(
                            value: int.tryParse('${f['id']}'),
                            child: Text('${f['name'] ?? '---'}'),
                          );
                        }).toList(),
                        onChanged: (v) async {
                          setS(() {
                            facultyId = v;
                            departments = [];
                            departmentId = null;
                          });
                          await fetchDepartments(setS, byFacultyId: v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: departmentId,
                        decoration: const InputDecoration(
                          labelText: 'Bộ môn',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: departments.map((d) {
                          return DropdownMenuItem(
                            value: int.tryParse('${d['id']}'),
                            child: Text('${d['name'] ?? '---'}'),
                          );
                        }).toList(),
                        onChanged: (v) => setS(() => departmentId = v),
                        validator: (_) => null, // cho phép để trống nếu BE không bắt buộc
                      ),
                    ] else ...[
                      // Fallback: không có API danh mục, hiển thị read-only
                      TextFormField(
                        initialValue: facultyName,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Khoa (không chỉnh được – thiếu API danh mục)',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: departmentName,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Bộ môn (không chỉnh được – thiếu API danh mục)',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        TextButton(
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: submitting ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => submitting = true);
                            try {
                              final dio = ApiClient().dio;

                              // Chuẩn payload
                              final payload = {
                                'name': nameCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                'gender': gender,
                                if (dob != null) 'date_of_birth': ymd(dob!),
                                if (departmentId != null) 'department_id': departmentId,
                              };

                              final endpoints = _profileUpdateEndpoints(_role());
                              DioException? lastErr;

                              for (final ep in endpoints) {
                                try {
                                  late Response res;
                                  switch (ep.method) {
                                    case 'PUT':
                                      res = await dio.put(ep.url, data: payload);
                                      break;
                                    case 'PATCH':
                                      res = await dio.patch(ep.url, data: payload);
                                      break;
                                    default:
                                      res = await dio.post(ep.url, data: payload);
                                  }

                                  if (!mounted) return;
                                  Navigator.of(ctx).pop();
                                  _showSnack('Cập nhật tài khoản thành công');
                                  await _loadMe();
                                  return;
                                } on DioException catch (e) {
                                  lastErr = e;
                                  final code = e.response?.statusCode ?? 0;

                                  // 422: hiển thị chi tiết và dừng
                                  if (code == 422) {
                                    final data = e.response?.data;
                                    if (data is Map && data['errors'] is Map) {
                                      final errs = (data['errors'] as Map).entries
                                          .expand((kv) => (kv.value as List).map((x) => '- ${kv.key}: $x'))
                                          .join('\n');
                                      _showSnack(errs.isEmpty ? 'Dữ liệu không hợp lệ' : errs, error: true);
                                      setS(() => submitting = false);
                                      return;
                                    }
                                    _showSnack('Dữ liệu không hợp lệ', error: true);
                                    setS(() => submitting = false);
                                    return;
                                  }

                                  // 404/405 -> thử endpoint kế
                                  if (code == 404 || code == 405) continue;

                                  // lỗi khác -> thử tiếp endpoint sau
                                  continue;
                                }
                              }

                              setS(() => submitting = false);
                              _showSnack('Lỗi cập nhật (HTTP ${lastErr?.response?.statusCode ?? 'null'})', error: true);
                            } catch (e) {
                              setS(() => submitting = false);
                              _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
                            }
                          },
                          icon: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_outlined),
                          label: const Text('Lưu'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}
