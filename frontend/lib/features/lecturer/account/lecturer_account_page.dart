import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/providers/auth_state_provider.dart';
import '../../../services/profile_service.dart';

class LecturerAccountPage extends ConsumerStatefulWidget {
  const LecturerAccountPage({super.key});

  @override
  ConsumerState<LecturerAccountPage> createState() =>
      _LecturerAccountPageState();
}

class _LecturerAccountPageState extends ConsumerState<LecturerAccountPage> {
  bool _loading = true;
  bool _saving = false;
  bool _loadingDepartments = false;
  String? _error;

  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>>? _cachedFaculties;
  final Map<int, List<Map<String, dynamic>>> _cachedDepartments = {};

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _dob;
  String? _genderCode;
  int? _facultyId;
  int? _departmentId;

  ProfileService get _service => ref.read(profileServiceProvider);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(fn);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _fetchProfile() async {
    safeSetState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getProfile();
      safeSetState(() {
        _profile = data;
        _loading = false;
        _error = null;
      });
      _syncFormStateFromProfile();
    } on DioException catch (e) {
      await _handleDioError(e);
    } catch (e) {
      safeSetState(() {
        _loading = false;
        _error = 'Không thể tải hồ sơ: $e';
      });
    }
  }

  Future<void> _handleDioError(DioException e) async {
    if (e.response?.statusCode == 401) {
      await _handleUnauthorized();
      return;
    }

    final message = e.response?.data is Map
        ? (e.response?.data['message']?.toString() ??
            e.response?.data['error']?.toString() ??
            'Không thể tải hồ sơ.')
        : 'Không thể tải hồ sơ.';

    safeSetState(() {
      _error = message;
      _loading = false;
    });
  }

  Future<void> _handleUnauthorized() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'auth_token');

    if (!mounted) return;
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  Future<bool> _updateProfile(Map<String, dynamic> patch) async {
    safeSetState(() {
      _saving = true;
    });

    try {
      final updated = await _service.updateProfile(patch);
      safeSetState(() {
        _profile = updated;
        _saving = false;
        _error = null;
      });
      _syncFormStateFromProfile();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleUnauthorized();
        return false;
      }

      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString() ??
              'Cập nhật thất bại.')
          : 'Cập nhật thất bại.';

      safeSetState(() => _saving = false);
      _showSnackBar(message);
      return false;
    } catch (e) {
      safeSetState(() => _saving = false);
      _showSnackBar('Cập nhật thất bại: $e');
      return false;
    }
  }

  void _syncFormStateFromProfile() {
    final name = _profile['name']?.toString() ?? '';
    if (_nameCtrl.text != name) {
      _nameCtrl.text = name;
    }

    final email = _profile['email']?.toString() ?? '';
    if (_emailCtrl.text != email) {
      _emailCtrl.text = email;
    }

    final phone = _profile['phone']?.toString() ?? '';
    if (_phoneCtrl.text != phone) {
      _phoneCtrl.text = phone;
    }

    final dobStr = _profile['date_of_birth']?.toString();
    DateTime? dob;
    if (dobStr != null && dobStr.isNotEmpty) {
      dob = DateTime.tryParse(dobStr);
    }

    final genderRaw = _profile['gender']?.toString();
    final genderCode = _genderCodeFromProfileValue(genderRaw);

    final lecturer = _profile['lecturer'];
    final departmentId =
        _asNullableInt(lecturer is Map ? lecturer['department_id'] : null);
    final facultyId = _asNullableInt(
      lecturer is Map && lecturer['department'] is Map
          ? lecturer['department']['faculty'] is Map
              ? lecturer['department']['faculty']['id']
              : null
          : null,
    );

    safeSetState(() {
      _dob = dob;
      _genderCode = genderCode;
      _departmentId = departmentId;
      _facultyId = facultyId;
    });
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String? _genderCodeFromProfileValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'nam') return 'Nam';
    if (normalized == 'female' || normalized == 'nữ' || normalized == 'nu') {
      return 'Nữ';
    }
    return null;
  }

  Future<void> _ensureFacultyCache() async {
    if (_cachedFaculties != null) {
      if (_facultyId != null && !_cachedDepartments.containsKey(_facultyId!)) {
        await _loadDepartments(_facultyId!);
      }
      return;
    }

    try {
      final faculties = await _service.listFaculties();
      safeSetState(() {
        _cachedFaculties = faculties;
      });
      if (_facultyId != null) {
        await _loadDepartments(_facultyId!);
      }
    } catch (_) {
      _showSnackBar('Không thể tải danh sách khoa.');
    }
  }

  Future<void> _loadDepartments(int facultyId) async {
    safeSetState(() {
      _loadingDepartments = true;
    });

    try {
      final fetched = await _service.listDepartments(facultyId: facultyId);
      safeSetState(() {
        _cachedDepartments[facultyId] =
            List<Map<String, dynamic>>.from(fetched);
      });
    } catch (_) {
      _showSnackBar('Không thể tải danh sách bộ môn.');
    } finally {
      safeSetState(() {
        _loadingDepartments = false;
      });
    }
  }

  List<Map<String, dynamic>> _departmentsForFaculty(int? facultyId) {
    if (facultyId == null) return const [];
    return List<Map<String, dynamic>>.from(
      _cachedDepartments[facultyId] ?? const <Map<String, dynamic>>[],
    );
  }

  String _roleLabel(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'DAO_TAO':
      case 'TRAINING_DEPARTMENT':
        return 'Phòng đào tạo';
      case 'GIANG_VIEN':
      case 'LECTURER':
        return 'Giảng viên';
      default:
        return value.isEmpty ? 'Chưa xác định' : value;
    }
  }

  String _textOrPlaceholder(String? value) {
    if (value == null || value.trim().isEmpty) return '---';
    return value.trim();
  }

  Future<void> _pickDob() async {
    final initial = _dob ?? DateTime(1990, 1, 1);
    final lastDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: lastDate,
    );
    if (picked != null) {
      safeSetState(() {
        _dob = picked;
      });
    }
  }

  // ---------- MỚI: helper trang trí input cho đẹp ----------
  InputDecoration _dec(BuildContext ctx, String label,
      {IconData? icon, String? hint}) {
    final scheme = Theme.of(ctx).colorScheme;
    OutlineInputBorder _b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(0.35),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _b(Colors.grey.shade300),
      focusedBorder: _b(scheme.primary),
      errorBorder: _b(Colors.red.shade300),
      focusedErrorBorder: _b(Colors.red.shade400),
    );
  }

  // ========= mở popup chỉnh sửa =========
  Future<void> _openEditSheet() async {
    await _ensureFacultyCache();

    final tmpNameCtrl = TextEditingController(text: _nameCtrl.text);
    final tmpEmailCtrl = TextEditingController(text: _emailCtrl.text);
    final tmpPhoneCtrl = TextEditingController(text: _phoneCtrl.text);
    DateTime? tmpDob = _dob;
    String? tmpGender = _genderCode;
    int? tmpFacultyId = _facultyId;
    int? tmpDepartmentId = _departmentId;

    final formKey = GlobalKey<FormState>();
    bool submitting = false;
    bool localLoadingDepartments = false;

    Future<void> _loadDepsInSheet(StateSetter refresh, int facultyId) async {
      refresh(() => localLoadingDepartments = true);
      try {
        await _loadDepartments(facultyId);
        final deps = _departmentsForFaculty(facultyId);
        if (!deps.any((d) => _asNullableInt(d['id']) == tmpDepartmentId)) {
          tmpDepartmentId = null;
        }
      } finally {
        refresh(() => localLoadingDepartments = false);
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refresh) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 8,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉnh sửa hồ sơ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      // Họ và tên
                      TextFormField(
                        controller: tmpNameCtrl,
                        decoration: _dec(sheetContext, 'Họ và tên',
                            icon: Icons.person_outline, hint: 'Nhập họ và tên'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Họ và tên không được để trống'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Ngày sinh (readOnly cho đồng bộ UI)
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: tmpDob != null
                              ? DateFormat('dd/MM/yyyy').format(tmpDob!)
                              : '',
                        ),
                        decoration: _dec(sheetContext, 'Ngày sinh',
                                icon: Icons.calendar_today_outlined,
                                hint: 'Chọn ngày sinh')
                            .copyWith(suffixIcon: const Icon(Icons.expand_more)),
                        onTap: () async {
                          final init = tmpDob ?? DateTime(1990, 1, 1);
                          final last = DateTime.now();
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: init.isAfter(last) ? last : init,
                            firstDate: DateTime(1950, 1, 1),
                            lastDate: last,
                          );
                          if (picked != null) {
                            refresh(() => tmpDob = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Giới tính
                      DropdownButtonFormField<String?>(
                        value: tmpGender,
                        isExpanded: true,
                        decoration: _dec(sheetContext, 'Giới tính',
                            icon: Icons.wc_outlined, hint: 'Chọn giới tính'),
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Không chọn')),
                          DropdownMenuItem<String?>(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem<String?>(value: 'Nữ', child: Text('Nữ')),
                        ],
                        onChanged: (v) => refresh(() => tmpGender = v),
                      ),
                      const SizedBox(height: 12),

                      // Số điện thoại
                      TextFormField(
                        controller: tmpPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _dec(sheetContext, 'Số điện thoại',
                            icon: Icons.phone_outlined, hint: 'Nhập số điện thoại'),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          return RegExp(r'^[0-9+() -]{6,30}$').hasMatch(s)
                              ? null
                              : 'Số điện thoại không hợp lệ';
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: tmpEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _dec(sheetContext, 'Email',
                            icon: Icons.alternate_email_outlined, hint: 'Nhập email'),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email không hợp lệ';
                          return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s)
                              ? null
                              : 'Email không hợp lệ';
                        },
                      ),
                      const SizedBox(height: 12),

                      // Khoa
                      DropdownButtonFormField<int?>(
                        value: tmpFacultyId,
                        isExpanded: true,
                        decoration: _dec(sheetContext, 'Khoa',
                            icon: Icons.school_outlined, hint: 'Chọn khoa'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Không chọn')),
                          ...?_cachedFaculties?.map((f) => DropdownMenuItem<int?>(
                                value: _asNullableInt(f['id']),
                                child: Text(f['name']?.toString() ?? ''),
                              )),
                        ],
                        onChanged: (v) async {
                          refresh(() {
                            tmpFacultyId = v;
                            tmpDepartmentId = null;
                          });
                          if (v != null) {
                            await _loadDepsInSheet(refresh, v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Bộ môn
                      DropdownButtonFormField<int?>(
                        value: tmpDepartmentId,
                        isExpanded: true,
                        decoration: _dec(sheetContext, 'Bộ môn',
                            icon: Icons.account_tree_outlined, hint: 'Chọn bộ môn'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Không chọn')),
                          ..._departmentsForFaculty(tmpFacultyId).map((d) =>
                              DropdownMenuItem<int?>(
                                value: _asNullableInt(d['id']),
                                child: Text(d['name']?.toString() ?? ''),
                              )),
                        ],
                        onChanged: localLoadingDepartments
                            ? null
                            : (v) => refresh(() => tmpDepartmentId = v),
                      ),
                      if (localLoadingDepartments) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(false),
                            child: const Text('Hủy'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ?? false)) return;

                                    final patch = <String, dynamic>{};
                                    void addChange(String key, dynamic newValue, dynamic originalValue) {
                                      if (newValue is String && newValue.isEmpty) newValue = null;
                                      if (originalValue is String && originalValue.isEmpty) originalValue = null;
                                      if (newValue == originalValue) return;
                                      patch[key] = newValue;
                                    }

                                    addChange('name',  tmpNameCtrl.text.trim(), _profile['name']?.toString() ?? '');
                                    addChange('email', tmpEmailCtrl.text.trim(), _profile['email']?.toString() ?? '');
                                    addChange('phone', tmpPhoneCtrl.text.trim(), _profile['phone']?.toString() ?? '');

                                    final origDob = _profile['date_of_birth']?.toString();
                                    final newDobStr = tmpDob != null ? DateFormat('yyyy-MM-dd').format(tmpDob!) : null;
                                    addChange('date_of_birth', newDobStr, (origDob?.isEmpty == true) ? null : origDob);

                                    final origGender = _genderCodeFromProfileValue(_profile['gender']?.toString());
                                    addChange('gender', tmpGender, origGender);

                                    final origFacultyId = _asNullableInt(
                                      _profile['lecturer'] is Map &&
                                              _profile['lecturer']['department'] is Map &&
                                              _profile['lecturer']['department']['faculty'] is Map
                                          ? _profile['lecturer']['department']['faculty']['id']
                                          : null,
                                    );
                                    addChange('faculty_id', tmpFacultyId, origFacultyId);

                                    final origDepartmentId = _asNullableInt(
                                      _profile['lecturer'] is Map ? _profile['lecturer']['department_id'] : null,
                                    );
                                    addChange('department_id', tmpDepartmentId, origDepartmentId);

                                    if (patch.isEmpty) {
                                      _showSnackBar('Không có thay đổi nào để lưu');
                                      Navigator.of(sheetContext).pop(false);
                                      return;
                                    }

                                    refresh(() => submitting = true);
                                    final ok = await _updateProfile(patch);
                                    if (!mounted) return;
                                    if (ok) {
                                      _nameCtrl.text  = tmpNameCtrl.text.trim();
                                      _emailCtrl.text = tmpEmailCtrl.text.trim();
                                      _phoneCtrl.text = tmpPhoneCtrl.text.trim();
                                      _dob            = tmpDob;
                                      _genderCode     = tmpGender;
                                      _facultyId      = tmpFacultyId;
                                      _departmentId   = tmpDepartmentId;

                                      _showSnackBar('Cập nhật hồ sơ thành công');
                                      Navigator.of(sheetContext).pop(true);
                                    } else {
                                      refresh(() => submitting = false);
                                    }
                                  },
                            child: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Lưu'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // dọn controller tạm
    tmpNameCtrl.dispose();
    tmpEmailCtrl.dispose();
    tmpPhoneCtrl.dispose();

    // saved==true nghĩa là đã lưu trong sheet; ở lại trang account
  }
  // ========= END popup =========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: null,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Đã xảy ra lỗi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _fetchProfile,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final formattedDob = _dob != null
        ? DateFormat('dd/MM/yyyy').format(_dob!)
        : _textOrPlaceholder(_profile['date_of_birth']?.toString());

    final roleName = _profile['role']?.toString() ?? '';

    final facultyName = _textOrPlaceholder(_profile['faculty']?.toString());
    final departmentName = _textOrPlaceholder(_profile['department']?.toString());
    final genderDisplay = _genderCode ??
        _genderCodeFromProfileValue(_profile['gender']?.toString()) ??
        '---';

    final avatarUrl = _profile['avatar_url']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (_saving) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'TRƯỜNG ĐẠI HỌC THỦY LỢI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: avatarUrl.startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.startsWith('http')
                  ? null
                  : const Icon(Icons.person_outline, size: 42),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.icon(
              onPressed: _saving ? null : _openEditSheet,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa'),
            ),
          ),
          const SizedBox(height: 24),

          _infoCard(
            label: 'Họ và tên',
            child: Text(
              _textOrPlaceholder(_profile['name']?.toString()),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Ngày sinh',
            child: Text(
              formattedDob,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Giới tính',
            child: Text(
              genderDisplay,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Số điện thoại',
            child: Text(
              _textOrPlaceholder(_profile['phone']?.toString()),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Email',
            child: Text(
              _textOrPlaceholder(_profile['email']?.toString()),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Khoa',
            child: Text(
              facultyName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Bộ môn',
            child: Text(
              departmentName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _infoCard(
            label: 'Vai trò',
            child: Text(
              _roleLabel(roleName),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Cài đặt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Đổi mật khẩu'),
                  onTap: _changePassword,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content:
                            const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
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
        ],
      ),
    );
  }

  Widget _infoCard({required String label, required Widget child}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool submitting = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;
    bool sheetActive = true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refresh) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đổi mật khẩu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: oldCtrl,
                          obscureText: obscureOld,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu hiện tại',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureOld
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                refresh(() {
                                  obscureOld = !obscureOld;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu hiện tại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newCtrl,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                refresh(() {
                                  obscureNew = !obscureNew;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            final newPassword = value?.trim() ?? '';
                            if (newPassword.isEmpty) {
                              return 'Vui lòng nhập mật khẩu mới';
                            }
                            if (newPassword.length < 8) {
                              return 'Mật khẩu phải tối thiểu 8 ký tự';
                            }
                            final hasLetter =
                                RegExp(r'[A-Za-z]').hasMatch(newPassword);
                            final hasNumber =
                                RegExp(r'[0-9]').hasMatch(newPassword);
                            if (!hasLetter || !hasNumber) {
                              return 'Mật khẩu phải có cả chữ và số';
                            }
                            if (newPassword == oldCtrl.text.trim()) {
                              return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmCtrl,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                refresh(() {
                                  obscureConfirm = !obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            final confirm = value?.trim() ?? '';
                            if (confirm.isEmpty) {
                              return 'Vui lòng nhập lại mật khẩu mới';
                            }
                            if (confirm != newCtrl.text.trim()) {
                              return 'Xác nhận mật khẩu không khớp';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Hủy'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) {
                                  return;
                                }
                                refresh(() {
                                  submitting = true;
                                  errorMessage = null;
                                });
                                try {
                                  await _service.changePassword(
                                    oldPassword: oldCtrl.text.trim(),
                                    newPassword: newCtrl.text.trim(),
                                  );
                                  if (!sheetActive) return;
                                  Navigator.of(sheetContext).pop(true);
                                } on DioException catch (e) {
                                  if (e.response?.statusCode == 401) {
                                    Navigator.of(sheetContext).pop(false);
                                    await _handleUnauthorized();
                                    return;
                                  }
                                  final msg = e.response?.data is Map
                                      ? (e.response?.data['message']?.toString() ??
                                          e.response?.data['error']?.toString() ??
                                          'Đổi mật khẩu thất bại.')
                                      : 'Đổi mật khẩu thất bại.';
                                  refresh(() {
                                    submitting = false;
                                    errorMessage = msg;
                                  });
                                } catch (err) {
                                  refresh(() {
                                    submitting = false;
                                    errorMessage = err.toString();
                                  });
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => sheetActive = false);

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (result == true) {
      _showSnackBar('Đổi mật khẩu thành công');
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'auth_token');

    if (!mounted) return;
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }
}
