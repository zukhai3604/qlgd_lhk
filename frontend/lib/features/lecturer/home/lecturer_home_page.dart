// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
// ✅ service thật của lịch giảng dạy
import 'package:qlgd_lhk/features/lecturer/schedule/service.dart';

class LecturerHomePage extends ConsumerStatefulWidget {
  const LecturerHomePage({super.key});
  @override
  ConsumerState<LecturerHomePage> createState() => _LecturerHomePageState();
}

class _LecturerHomePageState extends ConsumerState<LecturerHomePage> {
  final _svc = LecturerScheduleService();
  String _selectedSemester = 'Học kỳ I 2025';

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> todaySchedule = [];
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // === CÙNG NGUỒN VỚI MÀN LỊCH ===
      final today = DateTime.now();
      final iso = DateFormat('yyyy-MM-dd').format(today);
      final scheduleRes = await _svc.getWeek(date: iso);

      final List raw = (scheduleRes['data'] as List?) ?? const [];
      final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // BE có thể trả "YYYY-MM-DD" hoặc "YYYY-MM-DD HH:mm:ss"
      bool isSameDay(dynamic d) {
        final s = (d ?? '').toString();
        final only = s.split(' ').first;
        return only == iso;
      }

      todaySchedule = list.where((x) => isSameDay(x['date'])).toList();

      // sắp theo start_time (chuỗi HH:mm:ss -> safe so sánh chuỗi)
      todaySchedule.sort((a, b) => (a['start_time'] ?? '')
          .toString()
          .compareTo((b['start_time'] ?? '').toString()));

      // số liệu (tùy backend sau này, tạm đặt placeholder)
      stats = {
        'taught': 10,
        'remaining': 34,
        'leave_count': 0,
        'makeup_count': 2
      };
    } catch (e) {
      error = 'Không tải được dữ liệu: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openDetail(Map<String, dynamic> s) {
    final id = s['id'];
    if (id != null) context.push('/schedule/$id');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final lecturerName = authState?.name ?? 'Giảng viên';

    return Scaffold(
      body: _buildBody(lecturerName),
    );
  }

  Widget _buildBody(String lecturerName) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(lecturerName, cs, textTheme),
          const SizedBox(height: 24),
          _buildSectionHeader('Thống kê nhanh', _buildSemesterDropdown(cs)),
          const SizedBox(height: 12),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader('Công cụ', null),
          const SizedBox(height: 12),
          _buildToolsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Lịch giảng dạy hôm nay',
            Text(_formatDate(DateTime.now()), style: textTheme.bodyMedium),
          ),
          const SizedBox(height: 12),
          _buildTodayScheduleList(cs, textTheme),
          const SizedBox(height: 8),
          if (todaySchedule.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => context.go('/schedule'),
                child: const Text('xem thêm'),
              ),
            ),
        ],
      ),
    );
  }

  // ========================= UI PARTS =========================

  Widget _buildHeader(String name, ColorScheme cs, TextTheme textTheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'TRƯỜNG ĐẠI HỌC THỦY LỢI',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chào giảng viên\n$name !!!',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_outline,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Widget? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSemesterDropdown(ColorScheme cs) {
    return DropdownButton<String>(
      value: _selectedSemester,
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      elevation: 8,
      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      underline: Container(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSemester = newValue!;
          _load();
        });
      },
      items: const ['Học kỳ I 2025', 'Học kỳ II 2024']
          .map<DropdownMenuItem<String>>(
            (String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: .85,
      children: [
        _stat('Đã dạy', stats['taught'] as int, Colors.green),
        _stat('Số buổi còn lại', stats['remaining'] as int, Colors.blue),
        _stat('Buổi nghỉ', stats['leave_count'] as int, Colors.red),
        _stat('Dạy bù', stats['makeup_count'] as int, Colors.orange),
      ],
    );
  }

  Widget _stat(String label, int value, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildToolButton(
          label: 'Lịch giảng dạy',
          icon: Icons.calendar_today,
          onTap: () => context.go('/schedule'),
          color: Colors.green,
        ),
        _buildToolButton(
          label: 'Báo cáo chi tiết',
          icon: Icons.bar_chart,
          onTap: () => context.go('/report'),
          color: Colors.blue,
        ),
        _buildToolButton(
          label: 'Xin nghỉ',
          icon: Icons.edit_calendar,
          onTap: () => context.go('/leave/choose'),
          color: Colors.red,
        ),
        _buildToolButton(
          label: 'Đăng ký dạy bù',
          icon: Icons.add_task,
          onTap: () => context.go('/makeup-request'),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayScheduleList(ColorScheme cs, TextTheme textTheme) {
    if (todaySchedule.isEmpty) {
      return Card(
        elevation: 0,
        color: cs.surfaceVariant.withOpacity(0.5),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Hôm nay không có lịch dạy.'),
        ),
      );
    }
    return Column(
      children: todaySchedule
          .map((s) => _buildScheduleCard(s, cs, textTheme))
          .toList(),
    );
  }

  Widget _buildScheduleCard(
      Map<String, dynamic> s, ColorScheme cs, TextTheme textTheme) {
    final subject = (s['subject'] ?? 'Môn học').toString();
    final className = (s['class_name'] ?? 'Lớp').toString();
    final room = (s['room'] ?? '-').toString();
    final start = (s['start_time'] ?? '--:--').toString().substring(0, 5);
    final end = (s['end_time'] ?? '--:--').toString().substring(0, 5);
    final status = (s['status'] ?? 'PLANNED').toString();

    final statusInfo = _getStatusInfo(status, cs);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusInfo.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDetail(s),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(statusInfo.icon, color: statusInfo.color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Lớp: $className • Phòng: $room'),
                    const SizedBox(height: 4),
                    Text('$start - $end',
                        style: textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(statusInfo.text,
                  style: TextStyle(
                      color: statusInfo.color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, String text, IconData icon}) _getStatusInfo(
      String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'DONE':
        return (color: Colors.green, text: 'Đã dạy', icon: Icons.check_circle);
      case 'TEACHING':
        return (color: cs.primary, text: 'Đang dạy', icon: Icons.schedule);
      case 'CANCELED':
        return (color: Colors.red, text: 'Đã hủy', icon: Icons.cancel);
      // PLANNED và mọi trạng thái khác trong hôm nay: coi là sắp tới
      default:
        return (
          color: cs.primary,
          text: 'Sắp tới',
          icon: Icons.access_time_filled
        );
    }
  }

  String _formatDate(DateTime date) {
    final dow = {
      1: 'Hai',
      2: 'Ba',
      3: 'Tư',
      4: 'Năm',
      5: 'Sáu',
      6: 'Bảy',
      7: 'Chủ Nhật'
    };
    return 'Thứ ${dow[date.weekday]}, ngày ${DateFormat('dd/MM/yyyy').format(date)}';
  }
}
