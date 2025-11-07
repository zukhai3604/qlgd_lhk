import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/admin_providers.dart';

/// Lấy tên admin từ /api/me
final meNameProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    print('🌐 Calling /api/me...');
    
    final res = await dio.get('/api/me');
    print('✅ /api/me status: ${res.statusCode}');
    print('📦 /api/me data type: ${res.data.runtimeType}');
    print('📦 /api/me full response: ${res.data}');

    final data = res.data;
    String? name;

    if (data is Map) {
      print('🔑 Available keys: ${data.keys.toList()}');
      
      // /api/me có thể trả về:
      // 1. Flat: { id: 1, name: "System Administrator", ... }
      // 2. Nested: { id: 1, name: "System Administrator", admin: { name: "..." }, ... }
      
      // Ưu tiên 1: name trực tiếp
      name = data['name']?.toString().trim();
      print('📝 data["name"]: "$name"');
      
      // Ưu tiên 2: admin.name (nested object như account page)
      if ((name == null || name.isEmpty) && data['admin'] is Map) {
        name = data['admin']['name']?.toString().trim();
        print('📝 data["admin"]["name"]: "$name"');
      }
      
      // Fallback: email
      if (name == null || name.isEmpty) {
        name = data['email']?.toString().trim();
        print('📧 Using email as fallback: $name');
      }
    } else {
      print('⚠️ Response is not a Map!');
    }

    print('👤 Final name: "$name"');
    return name ?? 'Quản trị viên';
  } catch (e, stackTrace) {
    print('❌ Error loading admin name: $e');
    print('📚 Stack trace: $stackTrace');
    return 'Quản trị viên';
  }
});

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminViewModelProvider).loadDashboard();
    });
  }

  int _navIndex(BuildContext context) {
    final router = GoRouter.of(context);
    final loc = router.routeInformationProvider.value.location; // go_router >= 13
    if (loc.startsWith('/admin/account')) return 2;
    if (loc.startsWith('/admin/notifications')) return 1;
    return 0;
  }

  void _goAccount(BuildContext context) {
    try {
      context.goNamed('adminAccount');
    } catch (_) {
      context.go('/admin/account');
    }
  }

  void _goNotifications(BuildContext context) {
    try {
      context.goNamed('adminNotifications');
    } catch (_) {
      context.go('/admin/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminViewModelProvider);
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: vm.isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async => vm.loadDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Text(
                          "TRƯỜNG ĐẠI HỌC THỦY LỢI",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Welcome Card: tên động từ /api/me
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/penguin.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Chào quản trị viên",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final nameAsync = ref.watch(meNameProvider);
                                        return nameAsync.when(
                                          data: (n) => Text(
                                            n.isNotEmpty ? n : 'Quản trị viên',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          loading: () => const Text(
                                            'Đang tải…',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          error: (e, __) {
                                            print('❌ meNameProvider error: $e');
                                            return const Text(
                                              'Quản trị viên',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Quản trị hệ thống",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final itemW = (w - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SystemPill(
                                width: itemW,
                                label: "Quản lý người dùng",
                                icon: Icons.person_outline,
                                onTap: () => context.go('/admin/users'),
                              ),
                              _SystemPill(
                                width: itemW,
                                label: "Tạo tài khoản mới",
                                icon: Icons.badge_outlined,
                                onTap: () => context.goNamed('adminUserCreate'),
                              ),
                              _SystemPill(
                                width: itemW,
                                label: "Báo cáo hệ thống",
                                icon: Icons.bug_report_outlined,
                                onTap: () => context.goNamed('admin_reports'),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 24 + bottomPad),
                    ],
                  ),
                ),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex(context),
        onTap: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            _goNotifications(context);
          } else if (index == 2) {
            _goAccount(context);
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

class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SmallStatCard(this.title, this.value, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const SizedBox.shrink(),
                Text(
                  title,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  const _SystemPill({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: width,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
