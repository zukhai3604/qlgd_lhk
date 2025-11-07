import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Dùng lại Dio từ dự án của bạn
import 'package:qlgd_lhk/features/admin/view/admin_users_page.dart' show dioProvider;

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends ConsumerState<AdminNotificationsPage> {
  bool _loading = true;
  bool _readingAll = false;
  List<Map<String, dynamic>> _items = [];
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);

      // Danh sách thông báo
      final res = await dio.get('/api/admin/notifications', queryParameters: {'type': 'report'});
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List) ? (raw['data'] as List)
                : (raw is List ? raw : const <dynamic>[]);

      // Chuyển thành List<Map>
      _items = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Unread count
      final c = await dio.get('/api/admin/notifications/unread_count');
      _unread = (c.data is Map && c.data['unread'] is int) ? c.data['unread'] as int : 0;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải thông báo: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/admin/notifications/$id/read');
      // Cập nhật local
      final idx = _items.indexWhere((x) => (x['id'] ?? -1) == id);
      if (idx != -1) {
        _items[idx] = {..._items[idx], 'read_at': DateTime.now().toIso8601String()};
      }
      if (_unread > 0) _unread -= 1;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không đánh dấu được: $e')));
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _readingAll = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/admin/notifications/read_all');
      _items = _items.map((n) => {...n, 'read_at': DateTime.now().toIso8601String()}).toList();
      _unread = 0;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể đọc tất cả: $e')));
    } finally {
      if (mounted) setState(() => _readingAll = false);
    }
  }

  String _fmt(DateTime d) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    }

  DateTime _parseDt(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }

  Map<String, dynamic>? _decodeData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try { return Map<String, dynamic>.from(jsonDecode(raw)); } catch (_) {}
    }
    return null;
  }

  int _navIndex(BuildContext context) {
    final router = GoRouter.of(context);
    final loc = router.routeInformationProvider.value.location; // go_router 13.x
    if (loc.startsWith('/admin/account')) return 2;
    if (loc.startsWith('/admin/notifications')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: _readingAll ? null : _markAllRead,
            child: _readingAll
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đọc tất cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_items.isEmpty
                  ? const Center(child: Text('Chưa có thông báo'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12 + kBottomNavigationBarHeight),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = _items[i];
                        final type = (n['type'] ?? '').toString();
                        final title = (n['title'] ?? '').toString();
                        final content = (n['content'] ?? '').toString();
                        final createdAt = _parseDt(n['created_at']);
                        final read = n['read_at'] != null;
                        final data = _decodeData(n['data']);

                        return Material(
                          elevation: 1.5,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            leading: Icon(
                              type == 'report' ? Icons.bug_report_outlined : Icons.notifications_outlined,
                              color: read ? Colors.grey : Colors.redAccent,
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (content.isNotEmpty)
                                  Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_fmt(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            trailing: read
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.mark_email_read_outlined),
                                    onPressed: () => _markRead(n['id'] as int),
                                  ),
                            onTap: () {
                              final reportId = data?['report_id'];
                              if (reportId != null) {
                                // TODO: tạo route chi tiết báo cáo khi sẵn sàng
                                context.push('/admin/reports/$reportId');
                              } else if (!read) {
                                _markRead(n['id'] as int);
                              }
                            },
                          ),
                        );
                      },
                    )),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex(context),
        onTap: (i) {
          if (i == 0) context.go('/dashboard');
          if (i == 1) {/* đang ở đây */}
          if (i == 2) context.go('/admin/account');
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(
            // Badge thủ công
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unread > 0)
                  Positioned(
                    right: -6,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        _unread > 99 ? '99+' : '$_unread',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
