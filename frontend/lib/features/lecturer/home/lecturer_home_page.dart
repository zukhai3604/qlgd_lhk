import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
// service thật của lịch giảng dạy
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
  bool _showAllSessions = false; // Để track xem có expand danh sách không

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
      // === CỘNG NGUỒN VỚI MÓN LỊCH ===
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
      todaySchedule.sort((a, b) =>
          (a['start_time'] ?? '').toString().compareTo((b['start_time'] ?? '').toString()));

      // Gộp các tiết liền kề nhau của cùng môn học
      todaySchedule = _groupConsecutiveSessions(todaySchedule);

      // số liệu (tùy backend sau này, tạm đặt placeholder)
      stats = {'taught': 10, 'remaining': 34, 'leave_count': 0, 'makeup_count': 2};
    } catch (e) {
      error = 'Không tải được dữ liệu: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openDetail(Map<String, dynamic> s) {
    final id = s['id'];
    if (id != null) {
      // Truyền session data qua extra để detail page có thể hiển thị thông tin đã gộp
      context.push('/schedule/$id', extra: s);
    }
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
          if (todaySchedule.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllSessions = !_showAllSessions;
                  });
                },
                icon: Icon(_showAllSessions ? Icons.expand_less : Icons.expand_more),
                label: Text(_showAllSessions ? 'Thu gọn' : 'Xem thêm (${todaySchedule.length - 3} buổi)'),
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
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/images/penguin.png'),
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
          // ✅ Đường dẫn mới (thay cho /makeup-request)
          onTap: () => context.go('/lecturer/makeup'),
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
    
    // Nếu có trên 3 buổi và chưa expand, chỉ hiển thị 3 buổi đầu
    final sessionsToShow = todaySchedule.length > 3 && !_showAllSessions
        ? todaySchedule.take(3).toList()
        : todaySchedule;
    
    return Column(
      children:
      sessionsToShow.map((s) => _buildScheduleCard(s, cs, textTheme)).toList(),
    );
  }

  Widget _buildScheduleCard(
      Map<String, dynamic> s, ColorScheme cs, TextTheme textTheme) {
    final subject = (s['subject'] ?? 'Môn học').toString();
    final className = (s['class_name'] ?? 'Lớp').toString();
    final r = s['room'];
    final room = (r is Map
        ? (r['name']?.toString() ?? r['code']?.toString() ?? '-')
        : r?.toString() ?? '-')
        .trim();
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
              Text(
                statusInfo.text,
                style: TextStyle(
                  color: statusInfo.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        return (color: cs.primary, text: 'Sắp tới', icon: Icons.access_time_filled);
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
    // Ví dụ: "Thứ Hai, ngày 01/11/2025"
  }

  /// Gộp các tiết liền kề nhau của cùng môn học thành 1 buổi
  List<Map<String, dynamic>> _groupConsecutiveSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return [];

    // Sắp xếp theo thời gian bắt đầu
    final sorted = List<Map<String, dynamic>>.from(sessions);
    sorted.sort((a, b) {
      final startA = (a['start_time'] ?? '').toString();
      final startB = (b['start_time'] ?? '').toString();
      return startA.compareTo(startB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = (current['subject'] ?? 'Môn học').toString();
      final className = (current['class_name'] ?? 'Lớp').toString();
      
      // Extract room
      final r = current['room'];
      final room = (r is Map
          ? (r['name']?.toString() ?? r['code']?.toString() ?? '-')
          : r?.toString() ?? '-')
          .trim();
      
      // Tìm các tiết liền kề có cùng subject, class, room
      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];
      
      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;
        
        final next = sorted[j];
        final nextSubject = (next['subject'] ?? 'Môn học').toString();
        final nextClassName = (next['class_name'] ?? 'Lớp').toString();
        
        // Extract room
        final nextR = next['room'];
        final nextRoom = (nextR is Map
            ? (nextR['name']?.toString() ?? nextR['code']?.toString() ?? '-')
            : nextR?.toString() ?? '-')
            .trim();
        
        // Kiểm tra cùng môn, lớp, phòng
        if (subject != nextSubject || 
            className != nextClassName || 
            room != nextRoom) {
          break;
        }
        
        // Kiểm tra liền kề (end_time của tiết trước gần start_time của tiết sau <= 10 phút)
        final lastEndStr = (group.last['end_time'] ?? '--:--').toString();
        final nextStartStr = (next['start_time'] ?? '--:--').toString();
        
        final lastEnd = _parseTimeToMinutes(lastEndStr);
        final nextStart = _parseTimeToMinutes(nextStartStr);
        
        if (lastEnd == null || nextStart == null) break;
        
        // Nếu gap <= 10 phút, coi là liền kề
        final gap = nextStart - lastEnd;
        if (gap <= 10 && gap >= 0) {
          group.add(next);
          groupIndices.add(j);
        } else {
          break;
        }
      }
      
      // Đánh dấu đã xử lý
      for (final idx in groupIndices) {
        processed.add(idx);
      }
      
      // Nếu chỉ có 1 tiết, giữ nguyên
      if (group.length == 1) {
        result.add(current);
      } else {
        // Gộp thành 1 buổi: lấy start_time từ tiết đầu, end_time từ tiết cuối
        final first = group.first;
        final last = group.last;
        
        final merged = Map<String, dynamic>.from(first);
        
        // Lấy start_time từ tiết đầu
        final startTime = (first['start_time'] ?? '--:--').toString();
        
        // Lấy end_time từ tiết cuối
        final endTime = (last['end_time'] ?? '--:--').toString();
        
        // Cập nhật thời gian
        merged['start_time'] = startTime;
        merged['end_time'] = endTime;
        
        // Lưu danh sách các session IDs gốc để có thể xử lý khi cần
        final sessionIds = group
            .map((s) {
              final id = s['id'];
              return id != null ? int.tryParse('$id') : null;
            })
            .whereType<int>()
            .toList();
        merged['_grouped_session_ids'] = sessionIds;
        
        result.add(merged);
      }
    }

    return result;
  }

  /// Parse thời gian HH:mm:ss hoặc HH:mm thành số phút (ví dụ: "15:40:00" -> 940, "15:40" -> 940)
  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}
