import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/features/admin/view/admin_users_page.dart' show dioProvider;

/// ===== MODEL =====
class AdminUserDetail {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // ADMIN | DAO_TAO | GIANG_VIEN
  final bool isActive;
  final DateTime? createdAt;

  AdminUserDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.createdAt,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> j) {
    DateTime? _parse(String? s) {
      if (s == null || s.isEmpty) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }
    return AdminUserDetail(
      id: j['id'] as int,
      name: (j['name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString().isEmpty ? null : (j['phone'] ?? '').toString(),
      role: (j['role'] ?? '').toString(),
      isActive: (j['is_active'] is bool)
          ? j['is_active'] as bool
          : (j['is_active'] == 1 || j['status'] == 'ACTIVE' || j['status'] == 'active'),
      createdAt: _parse((j['created_at'] ?? '').toString()),
    );
  }
}

/// ===== ACTIVITY MODEL (mới) =====
class UserActivity {
  final int? id;
  final String text;          // nội dung chính hiển thị đậm
  final DateTime createdAt;

  UserActivity({this.id, required this.text, required this.createdAt});

  factory UserActivity.fromJson(Map<String, dynamic> j) {
    String? _firstStr(List keys) {
      for (final k in keys) {
        final v = j[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    DateTime _ts() {
      final s = _firstStr(const ['created_at','time','timestamp','occurred_at']);
      if (s == null) return DateTime.now();
      try { return DateTime.parse(s); } catch (_) { return DateTime.now(); }
    }

    return UserActivity(
      id: j['id'] is int ? j['id'] as int : null,
      text: _firstStr(const ['title','message','action','description','event']) ?? 'Hoạt động',
      createdAt: _ts(),
    );
  }
}

/// ===== PROVIDERS =====
final userDetailProvider =
FutureProvider.family<AdminUserDetail, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/admin/users/$id');
  final data =
  (res.data is Map<String, dynamic> && res.data['data'] != null) ? res.data['data'] : res.data;
  return AdminUserDetail.fromJson(data as Map<String, dynamic>);
});

/// Hoạt động (mới)
final userActivityProvider =
FutureProvider.family<List<UserActivity>, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/admin/users/$id/activity');
  final raw = (res.data is Map && (res.data as Map).containsKey('data'))
      ? (res.data['data'] ?? [])
      : res.data;
  if (raw is List) {
    return raw.map((e) => UserActivity.fromJson((e as Map).cast<String, dynamic>())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // mới nhất trước
  }
  return const <UserActivity>[];
});

final _userActionProvider =
Provider.family<_UserActions, int>((ref, id) => _UserActions(ref, id));

class _UserActions {
  final Ref ref;
  final int id;
  _UserActions(this.ref, this.id);

  Dio get _dio => ref.read(dioProvider);

  Future<void> lock() async {
    await _dio.post('/api/admin/users/$id/lock');
    ref.invalidate(userDetailProvider(id));
  }

  Future<void> unlock() async {
    await _dio.post('/api/admin/users/$id/unlock');
    ref.invalidate(userDetailProvider(id));
  }

  Future<String?> resetPassword({String? tempPwd, bool forceChange = false}) async {
    final res = await _dio.post(
      '/api/admin/users/$id/reset-password',
      data: {
        if (tempPwd != null && tempPwd.isNotEmpty) 'temporary_password': tempPwd,
        'force_change': forceChange,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['new_password'] ??
          data['password'] ??
          (data['data'] is Map ? (data['data'] as Map)['new_password'] : null) ??
          tempPwd;
    }
    return tempPwd;
  }

  /// GIỮ NGUYÊN LOGIC PHÂN QUYỀN (đa endpoint)
  Future<void> updateRole(String newRole, {String? currentRole}) async {
    if (currentRole != null && currentRole == newRole) return;

    final payload = {'role': newRole};
    Response? res;
    DioException? lastErr;

    try {
      res = await _dio.post('/api/admin/users/$id/role',
          data: payload, options: Options(headers: {'Content-Type': 'application/json'}));
    } on DioException catch (e) { lastErr = e; }

    if (res == null || res.statusCode == 404) {
      try {
        res = await _dio.put('/api/admin/users/$id/role',
            data: payload, options: Options(headers: {'Content-Type': 'application/json'}));
      } on DioException catch (e) { lastErr = e; }
    }

    if (res == null || (res.statusCode ?? 500) >= 400) {
      try {
        res = await _dio.patch('/api/admin/users/$id',
            data: payload, options: Options(headers: {'Content-Type': 'application/json'}));
      } on DioException catch (e) { lastErr = e; }
    }

    if (res == null || (res.statusCode ?? 500) >= 400) {
      if (lastErr != null) throw lastErr;
      throw DioException(requestOptions: RequestOptions(path: ''), error: 'Role update failed');
    }

    ref.invalidate(userDetailProvider(id));
  }

  Future<void> logoutAll() async {
    await _dio.post('/api/logout-all');
  }
}

/// ===== PAGE =====
class AdminUserDetailPage extends ConsumerStatefulWidget {
  final int userId;
  const AdminUserDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage> {
  // 0 Info, 1 Role, 2 Security, 3 Activity
  int _tab = 0;
  int _bottomIndex = 0;

  bool _isToggling = false;
  bool _isResetting = false;
  bool _savingRole = false;
  String? _pickedRole;

  // UI constants
  static const double sectionGap = 20;
  static const double cardGap = 14;

  String _roleName(String r) {
    switch (r) {
      case 'ADMIN': return 'Admin';
      case 'DAO_TAO': return 'Phòng đào tạo';
      case 'GIANG_VIEN': return 'Giảng viên';
      default: return r;
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final two = (int n) => (n < 10 ? '0$n' : '$n');
    return '${two(d.day)}-${two(d.month)}-${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  // cho Activity
  String _relativeLabel(DateTime dt) {
    final now = DateTime.now();
    DateTime atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = atMidnight(now);
    final that = atMidnight(dt);
    final diff = today.difference(that).inDays;

    String hhmm(DateTime d) {
      final t = (int n) => n < 10 ? '0$n' : '$n';
      return '${t(d.hour)}:${t(d.minute)}';
    }

    if (diff == 0) return 'Hôm nay ${hhmm(dt)}';
    if (diff == 1) return 'Hôm qua ${hhmm(dt)}';
    final dd = dt.day.toString().padLeft(2,'0');
    final mm = dt.month.toString().padLeft(2,'0');
    return '$dd/$mm ${hhmm(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider); // ensure token
    final theme = Theme.of(context);
    final actions = ref.watch(_userActionProvider(widget.userId));
    final detailAsync = ref.watch(userDetailProvider(widget.userId));
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // khoảng cách so với BottomNavigationBar
    final double navH = kBottomNavigationBarHeight;
    const double gapAboveBottomNav = 2.0; // Giảm xuống 2.0 để đưa nút sát bottom nav hơn

    // padding đáy cho nội dung các tab (để không che cụm nút)
    final double bottomPadAllTabs =
        sectionGap + safeBottom + navH + 50; // Đơn giản hoá và tăng padding cho content

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _SimpleError(
            title: 'Không thể tải dữ liệu',
            detail: '$e',
            onRetry: () => ref.invalidate(userDetailProvider(widget.userId)),
          ),
          data: (u) {
            _pickedRole ??= u.role;
            final statusColor = u.isActive ? const Color(0xFFE6F7EE) : const Color(0xFFFFE9E7);
            final statusTextColor = u.isActive ? const Color(0xFF1F8C50) : const Color(0xFFCC3A2B);

            return Stack(
              children: [
                Column(
                  children: [
                    // App bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Center(
                              child: Text(
                                'TRƯỜNG ĐẠI HỌC THỦY LỢI',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    // Header card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(0xFFF2F2F2),
                                child: Icon(Icons.person, color: Colors.black54, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(u.email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(_roleName(u.role), style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(999)),
                                child: Text(u.isActive ? 'Hoạt động' : 'Khóa',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: statusTextColor, fontWeight: FontWeight.w800,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(child: _Segment(text: 'Thông tin', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                            const SizedBox(width: 8),
                            Expanded(child: _Segment(text: 'Vai trò', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
                            const SizedBox(width: 8),
                            Expanded(child: _Segment(text: 'Bảo mật', selected: _tab == 2, onTap: () => setState(() => _tab = 2))),
                            const SizedBox(width: 8),
                            Expanded(child: _Segment(text: 'Hoạt động', selected: _tab == 3, onTap: () => setState(() => _tab = 3))),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Nội dung tab
                    Expanded(child: _buildTabContent(context, u, actions, bottomPadAllTabs)),
                  ],
                ),

                // GLOBAL ACTION BAR — dạng compact, căn giữa ngay trên bottom nav
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 5, // Đặt bottom = 0 để các nút dính hoàn toàn với bottom navigation
                  child: _ActionBar(
                    isResetting: _isResetting,
                    isToggling: _isToggling,
                    active: u.isActive,
                    onReset: () async {
                      final r = await _showResetPasswordDialog(context);
                      if (r == null) return;
                      setState(() => _isResetting = true);
                      try {
                        final pwd = await actions.resetPassword(
                          tempPwd: r.temporaryPassword,
                          forceChange: r.forceChangeNextLogin,
                        );
                        if (!mounted) return;
                        if (pwd != null && pwd.isNotEmpty) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Mật khẩu mới'),
                              content: SelectableText(pwd, style: const TextStyle(fontWeight: FontWeight.bold)),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: pwd));
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã copy mật khẩu')),
                                    );
                                  },
                                  child: const Text('Copy'),
                                ),
                                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đặt lại mật khẩu thành công')),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      } finally {
                        if (mounted) setState(() => _isResetting = false);
                      }
                    },
                    onToggle: () async {
                      final ok = await _confirmLock(context, locking: u.isActive);
                      if (ok != true) return;
                      setState(() => _isToggling = true);
                      try {
                        if (u.isActive) {
                          await actions.lock();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã khóa tài khoản')));
                          }
                        } else {
                          await actions.unlock();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mở khóa tài khoản')));
                          }
                        }
                        await ref.refresh(userDetailProvider(widget.userId).future);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _isToggling = false);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);
          if (i == 0) context.go('/dashboard');
          if (i == 1) context.go('/admin/notifications');
          if (i == 2) context.go('/admin/account');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context,
      AdminUserDetail u,
      _UserActions actions,
      double bottomPadAllTabs,
      ) {
    switch (_tab) {
      case 0:
      // ===== THÔNG TIN =====
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, sectionGap, 16, bottomPadAllTabs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(title: 'Tên giảng viên', value: u.name),
              SizedBox(height: cardGap),
              _InfoCard(title: 'Email', value: u.email),
              SizedBox(height: cardGap),
              _InfoCard(title: 'Số điện thoại', value: u.phone ?? '—'),
              SizedBox(height: cardGap),
              Row(
                children: [
                  Expanded(child: _InfoCard(title: 'Vai trò', value: _roleName(u.role))),
                  const SizedBox(width: cardGap),
                  Expanded(child: _InfoCard(title: 'Ngày tạo', value: _fmtDate(u.createdAt))),
                ],
              ),
            ],
          ),
        );

      case 1:
      // ===== VAI TRÒ =====
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, sectionGap, 16, bottomPadAllTabs + 48),
              child: Column(
                children: [
                  _RoleTile(
                    icon: Icons.school_outlined,
                    title: 'Giảng viên',
                    subtitle: 'Quyền xem & cập nhật buổi dạy, điểm danh',
                    checked: _pickedRole == 'GIANG_VIEN',
                    onChanged: (_) => setState(() => _pickedRole = 'GIANG_VIEN'),
                  ),
                  SizedBox(height: cardGap),
                  _RoleTile(
                    icon: Icons.badge_outlined,
                    title: 'Phòng đào tạo',
                    subtitle: 'Duyệt nghỉ dạy, điều phối lịch',
                    checked: _pickedRole == 'DAO_TAO',
                    onChanged: (_) => setState(() => _pickedRole = 'DAO_TAO'),
                  ),
                  SizedBox(height: cardGap),
                  _RoleTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin',
                    subtitle: 'Quản trị hệ thống, nhật ký',
                    checked: _pickedRole == 'ADMIN',
                    onChanged: (_) => setState(() => _pickedRole = 'ADMIN'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadAllTabs - 16,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_pickedRole == null || _savingRole)
                      ? null
                      : () async {
                    setState(() => _savingRole = true);
                    try {
                      await ref
                          .read(_userActionProvider(widget.userId))
                          .updateRole(_pickedRole!, currentRole: u.role);
                      if (!mounted) return;
                      await ref.refresh(userDetailProvider(widget.userId).future);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu phân quyền')),
                      );
                    } on DioException catch (e) {
                      if (!mounted) return;
                      final code = e.response?.statusCode;
                      String msg = 'Lỗi máy chủ';
                      final data = e.response?.data;
                      if (data is Map && data['message'] != null) msg = data['message'].toString();
                      if (code == 422 && data is Map && data['errors'] != null) {
                        msg = data['errors'].toString();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lưu phân quyền thất bại ($code): $msg')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    } finally {
                      if (mounted) setState(() => _savingRole = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingRole
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu phân quyền'),
                ),
              ),
            ),
          ],
        );

      case 2:
      // ===== BẢO MẬT =====
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, sectionGap, 16, bottomPadAllTabs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecurityBlock(
                title: 'Bật xác thực 2 lớp (2FA)',
                subtitle: 'Khuyến nghị cho vai trò quản trị',
                trailing: Checkbox(value: false, onChanged: (_) {}),
              ),
              SizedBox(height: cardGap),

              // Thiết lập đăng nhập - 2 checkbox riêng biệt
              Text('Thiết lập đăng nhập',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Material(
                elevation: 1.5,
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Hết hạn phiên sau 24h',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Checkbox(value: false, onChanged: (_) {}),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(Icons.devices, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Giới hạn thiết bị (2)',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Checkbox(value: false, onChanged: (_) {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: sectionGap),
              Text('Hành động bảo mật',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: cardGap + 12),

              // Nút đăng xuất mọi thiết bị
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await _confirm(context,
                        title: 'Đăng xuất mọi thiết bị',
                        message: 'Bạn có chắc muốn đăng xuất người dùng này khỏi tất cả thiết bị?',
                        okText: 'Đăng xuất');
                    if (ok != true) return;
                    try {
                      await ref.read(_userActionProvider(widget.userId)).logoutAll();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Đã đăng xuất mọi thiết bị')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất mọi thiết bị'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: cardGap),

              // Nút tạo mật khẩu tạm
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final r = await _showResetPasswordDialog(context);
                    if (r == null) return;
                    setState(() => _isResetting = true);
                    try {
                      final pwd = await ref.read(_userActionProvider(widget.userId)).resetPassword(
                        tempPwd: r.temporaryPassword,
                        forceChange: r.forceChangeNextLogin,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo mật khẩu tạm thành công')));
                      if (pwd != null && pwd.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: pwd));
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    } finally {
                      if (mounted) setState(() => _isResetting = false);
                    }
                  },
                  icon: const Icon(Icons.key),
                  label: const Text('Tạo mật khẩu tạm'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
      // ===== HOẠT ĐỘNG =====
        final actsAsync = ref.watch(userActivityProvider(u.id));
        return actsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _SimpleError(
            title: 'Không tải được hoạt động',
            detail: '$e',
            onRetry: () => ref.invalidate(userActivityProvider(u.id)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(16, sectionGap, 16, bottomPadAllTabs),
                children: const [
                  SizedBox(height: 16),
                  Center(child: Text('Chưa có hoạt động nào')),
                ],
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16, sectionGap, 16, bottomPadAllTabs),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = items[i];
                return Material(
                  color: Colors.white,
                  elevation: 1.5,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _relativeLabel(a.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.text,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
    }
  }

  // ===== Dialogs & helpers =====
  Future<_ResetPwdResult?> _showResetPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool obscure = true;
    bool forceChange = false;

    String _genPwd([int len = 12]) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#\$%';
      final rnd = Random.secure();
      return List.generate(len, (_) => chars[rnd.nextInt(chars.length)]).join();
    }

    return showDialog<_ResetPwdResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lock_reset, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text('Đặt lại mật khẩu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu tạm thời...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => controller.text = _genPwd()),
                    icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: const Text('Tự động tạo'),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(value: forceChange, onChanged: (v) => setState(() => forceChange = v ?? false)),
                    const Expanded(child: Text('Bắt buộc đổi mật khẩu sau khi đăng nhập', style: TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: () => Navigator.pop<_ResetPwdResult?>(context, null), child: const Text('Hủy')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final pwd = controller.text.trim();
                      Navigator.pop<_ResetPwdResult>(
                        context,
                        _ResetPwdResult(
                          temporaryPassword: pwd.isEmpty ? _genPwd() : pwd,
                          forceChangeNextLogin: forceChange,
                        ),
                      );
                    },
                    child: const Text('Xác nhận'),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<bool?> _confirmLock(BuildContext context, {required bool locking}) {
    final title = locking ? 'KHÓA TÀI KHOẢN NGƯỜI DÙNG' : 'MỞ KHÓA TÀI KHOẢN NGƯỜI DÙNG';
    final message = locking
        ? 'Bạn có chắc chắn muốn khóa tài khoản người dùng này không?'
        : 'Bạn có chắc chắn muốn mở khóa tài khoản người dùng này không?';
    return _confirm(context, title: title, message: message, okText: 'Xác nhận');
  }

  Future<bool?> _confirm(BuildContext context,
      {required String title, required String message, required String okText}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(okText)),
        ],
      ),
    );
  }
}

/// ====== UI bits ======
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7FF),
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                ]),
              ),
              Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Compact action bar (2 nút nhỏ, căn giữa) =====
class _ActionBar extends StatelessWidget {
  final bool isResetting;
  final bool isToggling;
  final bool active;
  final VoidCallback onReset;
  final VoidCallback onToggle;

  const _ActionBar({
    required this.isResetting,
    required this.isToggling,
    required this.active,
    required this.onReset,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isResetting ? null : onReset,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              side: BorderSide(color: Colors.grey.shade400),
              foregroundColor: Colors.black87,
            ),
            child: Text(isResetting ? 'Đang đặt lại…' : 'Đặt lại mật khẩu'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isToggling ? null : onToggle,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              backgroundColor: active ? const Color(0xFFD32F2F) : const Color(0xFF1F8C50),
            ),
            child: Text(
              isToggling
                  ? (active ? 'Đang khóa…' : 'Đang mở…')
                  : (active ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SecurityBlock({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF3F3F7), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.schedule, size: 22, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              ]),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFEDE7F6) : Colors.white;
    final border = selected ? Colors.transparent : Colors.grey.shade300;

    return Material(
      color: bg,
      elevation: selected ? 1 : 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActivityRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SimpleError extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;
  const _SimpleError({required this.title, required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _ResetPwdResult {
  final String temporaryPassword;
  final bool forceChangeNextLogin;
  _ResetPwdResult({required this.temporaryPassword, required this.forceChangeNextLogin});
}
