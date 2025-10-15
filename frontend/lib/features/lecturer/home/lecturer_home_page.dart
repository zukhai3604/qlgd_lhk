import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ====== MODELS (gộp vào 1 file cho dễ compile) ======
enum ScheduleStatus { done, teaching, canceled }

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  User({required this.id, required this.name, required this.email, required this.role});
}

class ScheduleItem {
  final int id;
  final DateTime date;
  final String subject;
  final String room;
  final String className;
  final String start;
  final String end;
  final ScheduleStatus status;

  ScheduleItem({
    required this.id,
    required this.date,
    required this.subject,
    required this.room,
    required this.className,
    required this.start,
    required this.end,
    required this.status,
  });

  String get timeLabel => '$start - $end';
  bool isSameDate(DateTime d) => d.year == date.year && d.month == date.month && d.day == date.day;
}

/// ====== PROVIDERS (stub tạm để compile, sau nối API thật) ======
final termProvider = StateProvider<String>((_) => '2025-1');

final meProvider = FutureProvider<User>((ref) async {
  // TODO: thay bằng gọi API /me sau
  return User(id: 1, name: 'Nguyễn Văn A', email: 'a@tlu.edu.vn', role: 'lecturer');
});

final todayScheduleProvider = FutureProvider<List<ScheduleItem>>((ref) async {
  // TODO: thay bằng gọi API /lecturer/schedule/week rồi lọc hôm nay
  final now = DateTime.now();
  return <ScheduleItem>[
    ScheduleItem(
      id: 1001,
      date: now,
      subject: 'Cơ sở dữ liệu',
      room: 'B202',
      className: 'K20-IT3',
      start: '07:00',
      end: '09:00',
      status: ScheduleStatus.teaching,
    ),
  ];
});

/// ====== WIDGETS PHỤ ======
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: .5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.item});
  final ScheduleItem item;

  Color _statusColor() {
    if (item.status == ScheduleStatus.done) return const Color(0xFF2ECC71);
    if (item.status == ScheduleStatus.canceled) return const Color(0xFFFF3B30);
    return const Color(0xFF3498DB);
  }

  String _statusLabel() {
    if (item.status == ScheduleStatus.done) return 'Lớp đã hoàn thành';
    if (item.status == ScheduleStatus.canceled) return 'Lớp đã huỷ';
    return 'Lớp đang giảng dạy';
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c, width: 1.6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                item.subject,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_statusLabel(), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Phòng học: ${item.room}'),
          Text('Lớp: ${item.className}'),
          const SizedBox(height: 6),
          Text(item.timeLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// ====== TRANG CHỦ GIẢNG VIÊN ======
class LecturerHomePage extends ConsumerWidget {
  const LecturerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final today = ref.watch(todayScheduleProvider);
    final term = ref.watch(termProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ giảng viên'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: xoá token trong storage nếu bạn đang lưu ở đây
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(meProvider);
          ref.invalidate(todayScheduleProvider);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TRƯỜNG ĐẠI HỌC THỦY LỢI', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  me.when(
                    data: (u) => Text(
                      'Chào giảng viên ${u.name} !!!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    loading: () => const Text('Đang tải...'),
                    error: (_, __) => const Text('Không tải được người dùng'),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Thống kê nhanh', style: TextStyle(fontWeight: FontWeight.w700)),
                    DropdownButton<String>(
                      value: term,
                      items: const [
                        DropdownMenuItem(value: '2025-1', child: Text('Học kỳ I / 2025')),
                        DropdownMenuItem(value: '2025-2', child: Text('Học kỳ II / 2025')),
                      ],
                      onChanged: (v) {
                        if (v != null) ref.read(termProvider.notifier).state = v;
                      },
                    ),
                  ]),
                ]),
              ),

              // Tools (đã sửa overflow)
              SectionCard(
                child: LayoutBuilder(
                  builder: (context, cst) {
                    final crossAxis = cst.maxWidth < 360 ? 3 : 4; // màn nhỏ 3 cột
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.82, // làm item cao hơn để không tràn
                      ),
                      children: [
                        _tool(context, Icons.calendar_month, 'Lịch giảng dạy', () {}),
                        _tool(context, Icons.insert_chart, 'Báo cáo dạy học', () {}),
                        _tool(context, Icons.event_busy, 'Xin nghỉ', () {}),
                        _tool(context, Icons.event_available, 'Đăng ký dạy bù', () {}),
                      ],
                    );
                  },
                ),
              ),

              // Today
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Lịch giảng dạy hôm nay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              today.when(
                data: (list) => list.isEmpty
                    ? const Text('Hôm nay không có buổi học.')
                    : Column(children: list.map((e) => ScheduleCard(item: e)).toList()),
                loading: () => const LinearProgressIndicator(),
                error: (e, __) => Text('Không tải được lịch hôm nay: $e'),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigator.pushNamed(context, '/schedule');  // Mở “Lịch tuần”
        },
        icon: const Icon(Icons.view_week),
        label: const Text('Lịch tuần'),
      ),
    );
  }

  Widget _tool(BuildContext c, IconData i, String t, VoidCallback onTap) {
    final color = Theme.of(c).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: color, size: 22),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
