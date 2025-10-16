import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../widgets/bottom_nav.dart'; // <-- Import the shared widget

class LecturerHomePage extends StatefulWidget {
  const LecturerHomePage({super.key});

  @override
  State<LecturerHomePage> createState() => _LecturerHomePageState();
}

class _LecturerHomePageState extends State<LecturerHomePage> {
  String? displayName;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { loading = true; error = null; });

    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token') ?? await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() { error = 'Chưa có token. Vui lòng đăng nhập lại.'; loading = false; });
        return;
      }

      final dio = ApiClient.create().dio;
      final opts = Options(headers: {'Authorization': 'Bearer $token'});
      final paths = ['/auth/me', '/me', '/api/me', '/api/user'];
      final res = await _getMeFlexible(dio, opts, paths);

      if (res.data is! Map) {
        if (!mounted) return;
        setState(() { error = 'Dữ liệu hồ sơ không hợp lệ'; loading = false; });
        return;
      }
      final data = (res.data as Map).cast<String, dynamic>();
      final name = (data['name'] ?? data['full_name'] ?? data['hoten'] ?? data['ho_ten']
          ?? data['user']?['name'] ?? data['data']?['name'] ?? data['data']?['full_name'] ?? '')
          .toString().trim();

      if (!mounted) return;
      setState(() {
        displayName = name.isEmpty ? 'Giảng viên' : name;
        loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Lỗi tải hồ sơ${e.response?.statusCode != null ? ' (HTTP ${e.response!.statusCode})' : ''}';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'Lỗi: $e'; loading = false; });
    }
  }

  Future<Response> _getMeFlexible(Dio dio, Options opts, List<String> paths) async {
    DioException? last;
    for (final p in paths) {
      try {
        final r = await dio.get(p, options: opts);
        if (r.statusCode != null && r.statusCode! < 500) return r;
      } on DioException catch (e) {
        last = e;
        if (e.response?.statusCode == 401) rethrow;
      }
    }
    if (last != null) throw last;
    throw Exception('Không tìm thấy endpoint /me phù hợp.');
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'auth_token');
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = loading ? 'Đang tải...' : (error != null ? 'Lỗi' : 'Trang chủ giảng viên');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _loadProfile),
          IconButton(tooltip: 'Đăng xuất', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0), // <-- Use the shared widget
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GreetingCard(
            name: displayName ?? 'Giảng viên',
            termText: 'Học kỳ I / 2025',
          ),
          const SizedBox(height: 12),

          Text('Thống kê nhanh', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _QuickStats(
            items: const [
              QuickStatItem(label: 'Bỏ dạy', value: '10', bg: Color(0xFFE8F5E9)),
              QuickStatItem(label: 'Buổi dạy', value: '34', bg: Color(0xFFE3F2FD)),
              QuickStatItem(label: 'Buổi nghỉ', value: '04', bg: Color(0xFFFFF3E0)),
              QuickStatItem(label: 'Số buổi dạy bù', value: '02', bg: Color(0xFFF3E5F5)),
              QuickStatItem(label: 'Số buổi nghỉ bù', value: '2',  bg: Color(0xFFFFEBEE)),
            ],
          ),
          const SizedBox(height: 16),

          Text('Công cụ', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _ToolsRow(
            tools: const [
              ToolItem(icon: Icons.calendar_month, label: 'Lịch giảng dạy', color: Color(0xFF4CAF50)),
              ToolItem(icon: Icons.folder_open,    label: 'Báo cáo điểm danh', color: Color(0xFF2196F3)),
              ToolItem(icon: Icons.assignment,     label: 'Xin nghỉ', color: Color(0xFFFF7043)),
              ToolItem(icon: Icons.help_outline,   label: 'Hỗ trợ', color: Color(0xFFFFB300)),
            ],
          ),
          const SizedBox(height: 16),

          _TodayTitle(dateText: 'Thứ 6 ngày 9/19/2025'),
          const SizedBox(height: 8),

          _ScheduleCard(
            title: 'Lập trình phân tán',
            room: '207-B5',
            clazz: '64KTPM3',
            noteRight: 'Lớp học đã hoàn thành',
            timeText: '7:00–9:00',
            status: ScheduleStatus.done,
          ),
          const SizedBox(height: 8),
          _ScheduleCard(
            title: 'Lập trình phân tán',
            room: '210-B5',
            clazz: '64KTPM3',
            noteRight: 'Lớp đang sắp tới',
            timeText: '9:10–11:10',
            status: ScheduleStatus.upcoming,
          ),
          const SizedBox(height: 8),
          _ScheduleCard(
            title: 'Lập trình phân tán',
            room: '210-B5',
            clazz: '64KTPM3',
            noteRight: 'Lớp đã huỷ',
            timeText: '10:00–11:10',
            status: ScheduleStatus.canceled,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ================== Sub-widgets for Home Page ==================

class _GreetingCard extends StatelessWidget {
  final String name;
  final String termText;
  const _GreetingCard({required this.name, required this.termText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRƯỜNG ĐẠI HỌC THỦY LỢI', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    children: [
                      const TextSpan(text: 'Chào giảng viên '),
                      TextSpan(text: name),
                      const TextSpan(text: ' !!!'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Thống kê nhanh'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: termText,
              items: const [
                DropdownMenuItem(value: 'Học kỳ I / 2025', child: Text('Học kỳ I / 2025')),
                DropdownMenuItem(value: 'Học kỳ II / 2025', child: Text('Học kỳ II / 2025')),
              ],
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStatItem {
  final String label;
  final String value;
  final Color bg;
  const QuickStatItem({required this.label, required this.value, required this.bg});
}

class _QuickStats extends StatelessWidget {
  final List<QuickStatItem> items;
  const _QuickStats({required this.items});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 480;
    final crossAxisCount = isWide ? 5 : 3;

    return GridView.builder(
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemBuilder: (_, i) {
        final it = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: it.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(it.label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        );
      },
    );
  }
}

class ToolItem {
  final IconData icon;
  final String label;
  final Color color;
  const ToolItem({required this.icon, required this.label, required this.color});
}

class _ToolsRow extends StatelessWidget {
  final List<ToolItem> tools;
  const _ToolsRow({required this.tools});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tools.map((t) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.color.withOpacity(.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: t.color,
                  child: Icon(t.icon, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(t.label, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList()
        ..removeLast()
        ..add(
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tools.last.color.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: tools.last.color,
                    child: Icon(tools.last.icon, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(tools.last.label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _TodayTitle extends StatelessWidget {
  final String dateText;
  const _TodayTitle({required this.dateText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('Lịch giảng dạy hôm nay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF1F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(dateText, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}

enum ScheduleStatus { upcoming, done, canceled }

class _ScheduleCard extends StatelessWidget {
  final String title;
  final String room;
  final String clazz;
  final String noteRight;
  final String timeText;
  final ScheduleStatus status;

  const _ScheduleCard({
    required this.title,
    required this.room,
    required this.clazz,
    required this.noteRight,
    required this.timeText,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color chipBg;
    final Color chipFg;

    switch (status) {
      case ScheduleStatus.done:
        border = const Color(0xFF81C784);
        chipBg = const Color(0xFFE8F5E9);
        chipFg = const Color(0xFF2E7D32);
        break;
      case ScheduleStatus.upcoming:
        border = const Color(0xFF64B5F6);
        chipBg = const Color(0xFFE3F2FD);
        chipFg = const Color(0xFF1565C0);
        break;
      case ScheduleStatus.canceled:
        border = const Color(0xFFE57373);
        chipBg = const Color(0xFFFFEBEE);
        chipFg = const Color(0xFFC62828);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 2),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Phòng học: $room', style: const TextStyle(color: Colors.black54)),
                Text('Lớp: $clazz', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(14)),
                child: Text(noteRight, style: TextStyle(color: chipFg, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Text(
                timeText,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
