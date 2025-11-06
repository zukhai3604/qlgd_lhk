import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/features/lecturer/home/presentation/view_model/home_view_model.dart';

class LecturerHomePage extends ConsumerWidget {
  const LecturerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final lecturerName = authState?.name ?? 'Giảng viên';
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      // SafeArea để box chào không sát camera / tai thỏ
      body: SafeArea(
        child: _buildBody(context, lecturerName, homeState, homeViewModel),
      ),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> s) {
    final id = s['id'];
    if (id != null) {
      context.push('/schedule/$id', extra: s);
    }
  }

  Widget _buildBody(
    BuildContext context,
    String lecturerName,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => viewModel.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _buildHeader(lecturerName, cs, textTheme),
          const SizedBox(height: 16),

          // ==== THỐNG KÊ NHANH ====
          _buildSectionHeader(
            context,
            'Thống kê nhanh',
            _buildSemesterDropdown(context, cs, state, viewModel),
          ),
          const SizedBox(height: 8),
          _buildStatsGrid(context, state.stats),

          // ==== CÔNG CỤ ====
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Công cụ', null),
          const SizedBox(height: 8),
          _buildToolsGrid(context),

          // ==== LỊCH GIẢNG DẠY HÔM NAY (ngày ở bên phải) ====
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            'Lịch giảng dạy hôm nay',
            Text(
              _formatDate(DateTime.now()),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8),
          _buildTodayScheduleList(context, cs, textTheme, state),

          const SizedBox(height: 8),
          if (state.todaySchedule.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () => viewModel.toggleShowAllSessions(),
                icon: Icon(
                  state.showAllSessions ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(
                  state.showAllSessions
                      ? 'Thu gọn'
                      : 'Xem thêm (${state.todaySchedule.length - 3} buổi)',
                ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            const SizedBox(height: 10),
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
                    Icons.person,
                    size: 26,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Header 1 dòng, dùng cho "Thống kê nhanh", "Công cụ", "Lịch giảng dạy hôm nay"
  /// trailing (như Học kỳ I 2025, ngày tháng) nằm bên phải nhưng vẫn co lại để tránh overflow.
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Widget? trailing,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: trailing,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSemesterDropdown(
    BuildContext context,
    ColorScheme cs,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    // Hiển thị semester hiện tại từ API (không cho chọn vì API chỉ trả về stats cho semester hiện tại)
    return Text(
      state.selectedSemester,
      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: .85,
      children: [
        _stat(
          context,
          'Đã dạy',
          stats['taught'] as int? ?? 0,
          Colors.green,
        ),
        _stat(
          context,
          'Số buổi còn lại',
          stats['remaining'] as int? ?? 0,
          Colors.blue,
        ),
        _stat(
          context,
          'Buổi nghỉ',
          stats['leave_count'] as int? ?? 0,
          Colors.red,
        ),
        _stat(
          context,
          'Dạy bù',
          stats['makeup_count'] as int? ?? 0,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    int value,
    MaterialColor color,
  ) {
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color.shade600,
              ),
            ),
          ),
          const SizedBox(height: 4), // giảm từ 6 xuống 4 cho gọn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
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
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayScheduleList(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
    HomeState state,
  ) {
    if (state.todaySchedule.isEmpty) {
      return Card(
        elevation: 0,
        color: cs.surfaceVariant.withOpacity(0.5),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Hôm nay không có lịch dạy.'),
        ),
      );
    }

    final sessionsToShow =
        state.todaySchedule.length > 3 && !state.showAllSessions
            ? state.todaySchedule.take(3).toList()
            : state.todaySchedule;

    return Column(
      children: sessionsToShow
          .map((s) => _buildScheduleCard(context, s, cs, textTheme))
          .toList(),
    );
  }

  /// ===== CARD BUỔI HỌC =====
  Widget _buildScheduleCard(
    BuildContext context,
    Map<String, dynamic> s,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    String _safeTime(dynamic t) {
      final str = (t ?? '').toString();
      if (str.isEmpty || str == '--:--') return '--:--';
      return str.length >= 5 ? str.substring(0, 5) : str;
    }

    final subject = (s['subject'] ?? 'Môn học').toString();
    // Lấy mã lớp (code) thay vì tên lớp
    String className = '';
    if (s['assignment'] is Map) {
      final assignment = s['assignment'] as Map;
      if (assignment['class_unit'] is Map) {
        final classUnit = assignment['class_unit'] as Map;
        className = (classUnit['code'] ?? classUnit['class_code'] ?? '').toString();
      }
    }
    if (className.isEmpty) {
      className = (s['class_code'] ?? s['class_name'] ?? '').toString();
    }
    if (className.isEmpty) className = 'Lớp';

    final r = s['room'];
    final room = (r is Map
            ? (r['name']?.toString() ?? r['code']?.toString() ?? '-')
            : r?.toString() ?? '-')
        .trim();

    final start = _safeTime(s['start_time']);
    final end = _safeTime(s['end_time']);
    final timeLine = '$start - $end';
    final status = (s['status'] ?? 'PLANNED').toString();

    final defaultInfo = _getStatusInfo(status, cs);

    Color borderColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    final rawStatus = status.toUpperCase();

    // Kiểm tra xem schedule đã qua thời gian chưa
    bool isPastTime = false;
    if (end.isNotEmpty && end != '--:--') {
      try {
        final now = DateTime.now();
        DateTime? scheduleDate;
        
        // Lấy session_date hoặc date nếu có
        final dateValue = s['session_date'] ?? s['date'];
        if (dateValue != null) {
          final dateStr = dateValue.toString().split(' ').first; // Lấy phần date trước dấu cách
          scheduleDate = DateTime.tryParse(dateStr);
        }
        
        // Nếu không có session_date, dùng ngày hôm nay
        scheduleDate ??= DateTime(now.year, now.month, now.day);
        
        final endParts = end.split(':');
        if (endParts.length >= 2) {
          final endHour = int.tryParse(endParts[0]) ?? 0;
          final endMinute = int.tryParse(endParts[1]) ?? 0;
          final endDateTime = DateTime(
            scheduleDate.year,
            scheduleDate.month,
            scheduleDate.day,
            endHour,
            endMinute,
          );
          isPastTime = now.isAfter(endDateTime);
        }
      } catch (e) {
        // Nếu parse lỗi, bỏ qua kiểm tra
      }
    }

    if (rawStatus == 'DONE' || rawStatus == 'COMPLETED') {
      borderColor = Colors.green.shade300;
      statusColor = Colors.green.shade600;
      statusIcon = Icons.check_circle;
      statusText = 'Lớp học đã hoàn thành';
    } else if (rawStatus == 'CANCELED' || isPastTime) {
      // Nếu status là CANCELED hoặc đã qua thời gian nhưng status vẫn là PLANNED
      // (theo logic backend, buổi học sẽ bị hủy do không có điểm danh)
      borderColor = Colors.red.shade300;
      statusColor = Colors.red.shade600;
      statusIcon = Icons.cancel;
      statusText = 'Lớp học bị hủy';
    } else if (rawStatus == 'TEACHING') {
      borderColor = cs.primary.withOpacity(0.7);
      statusColor = cs.primary;
      statusIcon = Icons.play_circle_fill;
      statusText = 'Lớp học đang diễn ra';
    } else {
      borderColor = defaultInfo.color.withOpacity(0.7);
      statusColor = defaultInfo.color;
      statusIcon = defaultInfo.icon;
      statusText = 'Lớp học sắp tới';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _openDetail(context, s),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BÊN TRÁI
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (room.isNotEmpty && room != '-')
                      Text(
                        'Phòng học: $room',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (className.isNotEmpty && className != 'Lớp')
                      Text(
                        'Lớp: $className',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // BÊN PHẢI
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.end,
                      children: [
                        Text(
                          statusText,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (timeLine.trim().isNotEmpty &&
                        timeLine != '--:-- - --:--')
                      Text(
                        timeLine,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const SizedBox(height: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Bấm để xem chi tiết',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  ({Color color, String text, IconData icon}) _getStatusInfo(
    String status,
    ColorScheme cs,
  ) {
    switch (status.toUpperCase()) {
      case 'DONE':
        return (
          color: Colors.green,
          text: 'Đã dạy',
          icon: Icons.check_circle,
        );
      case 'TEACHING':
        return (
          color: cs.primary,
          text: 'Đang dạy',
          icon: Icons.schedule,
        );
      case 'CANCELED':
        return (
          color: Colors.red,
          text: 'Đã hủy',
          icon: Icons.cancel,
        );
      default:
        return (
          color: cs.primary,
          text: 'Sắp tới',
          icon: Icons.access_time_filled,
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
      7: 'Chủ Nhật',
    };
    return 'Thứ ${dow[date.weekday]}, ngày ${DateFormat('dd/MM/yyyy').format(date)}';
  }
}
