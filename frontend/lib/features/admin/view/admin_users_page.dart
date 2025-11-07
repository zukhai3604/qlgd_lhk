import 'dart:convert'; // <-- thêm để decode JWT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/core/network_config.dart';
import '../presentation/admin_view_model.dart';
import '../presentation/admin_providers.dart';

/// ====== MODEL ======
class AdminUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.department,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    return AdminUser(
      id: j['id'] as int,
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      role: (j['role'] ?? '').toString(),
      isActive: (j['is_active'] is bool)
          ? (j['is_active'] as bool)
          : (j['is_active'] == 1 || j['status'] == 'ACTIVE' || j['status'] == 'active'),
      department: j['department_name'] ?? j['khoa'] ?? j['bo_mon'],
    );
  }
}

/// ====== DIO CLIENT ======
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );

  final auth = ref.watch(authStateProvider);
  final token = auth?.token;
  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  return dio;
});

/// Từ khóa tìm kiếm
final userSearchQueryProvider = StateProvider.autoDispose<String>((_) => '');

/// ===== Helpers: trích xuất id/email từ auth (kể cả giải mã JWT) =====
int? _extractUserId(dynamic auth) {
  try {
    final int? id = (auth?.user?.id ?? auth?.id) as int?;
    if (id != null) return id;
  } catch (_) {}
  try {
    final int? id = (auth?['user']?['id'] ?? auth?['id']) as int?;
    if (id != null) return id;
  } catch (_) {}

  // Fallback: decode JWT -> sub
  final token = auth?.token ?? auth?['token'];
  if (token is String && token.contains('.')) {
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final sub = payload['sub'];
        if (sub is int) return sub;
        if (sub is String) {
          final n = int.tryParse(sub);
          if (n != null) return n;
        }
      }
    } catch (_) {}
  }
  return null;
}

String? _extractEmail(dynamic auth) {
  try {
    final String? email = (auth?.user?.email ?? auth?.email) as String?;
    if (email != null && email.isNotEmpty) return email;
  } catch (_) {}
  try {
    final String? email = (auth?['user']?['email'] ?? auth?['email']) as String?;
    if (email != null && email.isNotEmpty) return email;
  } catch (_) {}

  // Fallback: decode JWT -> email/preferred_username/upn
  final token = auth?.token ?? auth?['token'];
  if (token is String && token.contains('.')) {
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final e = payload['email'] ?? payload['preferred_username'] ?? payload['upn'];
        if (e is String && e.isNotEmpty) return e;
      }
    } catch (_) {}
  }
  return null;
}

bool _isCurrentUser(AdminUser u, dynamic auth) {
  final uid = _extractUserId(auth);
  if (uid != null && u.id == uid) return true;
  final email = _extractEmail(auth);
  if (email != null && email.isNotEmpty && u.email.toLowerCase() == email.toLowerCase()) return true;
  return false;
}

/// Danh sách người dùng (fetch từ API) + loại bỏ chính mình
final usersFutureProvider =
    FutureProvider.autoDispose<List<AdminUser>>((ref) async {
  final dio = ref.watch(dioProvider);
  final auth = ref.watch(authStateProvider);

  final res = await dio.get('/api/admin/users', queryParameters: {'page': 1});
  final data = res.data;

  List<dynamic> rawList;
  if (data is Map<String, dynamic> && data['data'] is List) {
    rawList = data['data'] as List;
  } else if (data is List) {
    rawList = data;
  } else {
    rawList = [];
  }

  final all = rawList
      .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
      .toList();

  // 🔥 LỌC BỎ CHÍNH TÀI KHOẢN HIỆN TẠI
  return all.where((u) => !_isCurrentUser(u, auth)).toList();
});

/// ====== PAGE ======
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersFutureProvider);
    final keyword = ref.watch(userSearchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(usersFutureProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Center(
                    child: Text(
                      'TRƯỜNG ĐẠI HỌC THỦY LỢI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Ô tìm kiếm
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _SearchField(
                    controller: _searchCtrl,
                    hint: 'Tìm theo tên, email, giảng viên…',
                    onChanged: (v) =>
                        ref.read(userSearchQueryProvider.notifier).state = v.trim(),
                  ),
                ),
              ),

              // Danh sách
              usersAsync.when(
                data: (users) {
                  final filtered = users.where((u) {
                    final k = keyword.toLowerCase();
                    if (k.isEmpty) return true;
                    return u.name.toLowerCase().contains(k) ||
                        u.email.toLowerCase().contains(k) ||
                        u.role.toLowerCase().contains(k) ||
                        (u.department ?? '').toLowerCase().contains(k);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: Text('Không tìm thấy người dùng')),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 24 + kBottomNavigationBarHeight,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _UserCard(user: filtered[index]),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, st) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          const Text('Không thể tải danh sách người dùng'),
                          const SizedBox(height: 8),
                          Text('$e', textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(usersFutureProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.go('/admin/notifications');
          } else if (index == 2) {
            context.go('/admin/account');
          } else if (index == 0) {
            context.go('/dashboard');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Thông báo"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Tài khoản"),
        ],
      ),
    );
  }
}

/// ====== WIDGETS ======
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _SearchField({Key? key, required this.controller, required this.hint, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(24),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  const _UserCard({Key? key, required this.user}) : super(key: key);

  Color get statusColor =>
      user.isActive ? const Color(0xFFE6F7EE) : const Color(0xFFFFE9E7);
  Color get statusTextColor =>
      user.isActive ? const Color(0xFF1F8C50) : const Color(0xFFCC3A2B);
  String get statusText => user.isActive ? 'Hoạt động' : 'Khóa';

  String readableRole(String r) {
    switch (r) {
      case 'ADMIN': return 'Quản trị viên';
      case 'DAO_TAO': return 'Phòng đào tạo';
      case 'GIANG_VIEN': return 'Giảng viên';
      default: return r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/admin/users/${user.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF2F2F2),
                child: Icon(Icons.person, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(user.email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${readableRole(user.role)}'
                          '${user.department != null && user.department!.isNotEmpty ? "  •  ${user.department}" : ""}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor, borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusTextColor, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
