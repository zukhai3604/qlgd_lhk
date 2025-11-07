import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/core/network_config.dart';

/// ===== MODEL =====
class AdminProfile {
  final int id;
  final int userId;
  final String email;
  final String? phone;
  final String? gender;
  final DateTime? dob;
  final String? address;
  final String? citizenId;
  final String? avatarUrl;

  AdminProfile({
    required this.id,
    required this.userId,
    required this.email,
    this.phone,
    this.gender,
    this.dob,
    this.address,
    this.citizenId,
    this.avatarUrl,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> j) {
    DateTime? _parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return AdminProfile(
      id: j['id'] ?? 0,
      userId: j['user_id'] ?? 0,
      email: j['email'] ?? '',
      phone: j['phone'],
      gender: j['gender'],
      dob: _parseDate(j['date_of_birth']),
      address: j['address'],
      citizenId: j['citizen_id'],
      avatarUrl: j['avatar_url'],
    );
  }
}

/// ===== DIO =====
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkConfig.apiBaseUrl,
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

/// ===== PROVIDER: /api/me =====
final meProvider = FutureProvider<AdminProfile>((ref) async {
  final dio = ref.watch(_dioProvider);
  final res = await dio.get('/api/me');
  final data = (res.data is Map<String, dynamic>) ? res.data['admin'] as Map<String, dynamic> : <String, dynamic>{};
  return AdminProfile.fromJson(data);
});

/// ===== PAGE =====
class AdminAccountPage extends ConsumerWidget {
  const AdminAccountPage({Key? key}) : super(key: key);

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: me.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _ErrorBox(
            title: 'Không thể tải thông tin tài khoản',
            detail: '$e',
            onRetry: () => ref.invalidate(meProvider),
          ),
          data: (p) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Center(
                    child: Text(
                      'TRƯỜNG ĐẠI HỌC THỦY LỢI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFF2F2F2),
                            backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                                ? NetworkImage(p.avatarUrl!)
                                : null,
                            child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 32, color: Colors.black54)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin TLU',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(p.email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Chỉnh sửa',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Thông tin cá nhân
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _InfoCard(title: 'Ngày sinh', value: _fmtDate(p.dob)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _InfoCard(title: 'Giới tính', value: p.gender ?? '—')),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoCard(title: 'Số điện thoại', value: p.phone ?? '—')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(title: 'Email', value: p.email),
                    const SizedBox(height: 10),
                    _InfoCard(title: 'Địa chỉ', value: p.address ?? '—'),
                    const SizedBox(height: 10),
                    _InfoCard(title: 'CCCD', value: p.citizenId ?? '—'),
                    const SizedBox(height: 18),
                    Text('Cài đặt',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _SettingTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Chỉnh sửa tài khoản',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      icon: Icons.help_outline,
                      title: 'Trợ giúp',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24 + kBottomNavigationBarHeight),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) context.go('/dashboard');
          if (i == 1) context.go('/admin/notifications');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

/// ===== WIDGETS =====
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: .5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorBox({required this.title, required this.detail, required this.onRetry});

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
          Text(detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }
}
