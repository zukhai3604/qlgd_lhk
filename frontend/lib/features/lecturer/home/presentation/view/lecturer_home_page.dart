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
      body: _buildBody(context, lecturerName, homeState, homeViewModel),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> s) {
    final id = s['id'];
    if (id != null) {
      context.push('/schedule/$id', extra: s);
    }
  }

  Widget _buildBody(BuildContext context, String lecturerName, HomeState state, HomeViewModel viewModel) {
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
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(lecturerName, cs, textTheme),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Thống kê nhanh', _buildSemesterDropdown(context, cs, state, viewModel)),
          const SizedBox(height: 12),
          _buildStatsGrid(context, state.stats),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Công cụ', null),
          const SizedBox(height: 12),
          _buildToolsGrid(context),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Lịch giảng dạy hôm nay',
            Text(_formatDate(DateTime.now()), style: textTheme.bodyMedium),
          ),
          const SizedBox(height: 12),
          _buildTodayScheduleList(context, cs, textTheme, state),

          const SizedBox(height: 8),
          if (state.todaySchedule.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () => viewModel.toggleShowAllSessions(),
                icon: Icon(state.showAllSessions ? Icons.expand_less : Icons.expand_more),
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

  Widget _buildSectionHeader(BuildContext context, String title, Widget? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSemesterDropdown(BuildContext context, ColorScheme cs, HomeState state, HomeViewModel viewModel) {
    return DropdownButton<String>(
      value: state.selectedSemester,
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      elevation: 8,
      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      underline: Container(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          viewModel.changeSemester(newValue);
        }
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

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: .85,
      children: [
        _stat(context, 'Đã dạy', stats['taught'] as int? ?? 0, Colors.green),
        _stat(context, 'Số buổi còn lại', stats['remaining'] as int? ?? 0, Colors.blue),
        _stat(context, 'Buổi nghỉ', stats['leave_count'] as int? ?? 0, Colors.red),
        _stat(context, 'Dạy bù', stats['makeup_count'] as int? ?? 0, Colors.orange),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, int value, MaterialColor color) {
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

  Widget _buildTodayScheduleList(BuildContext context, ColorScheme cs, TextTheme textTheme, HomeState state) {
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

    // Nếu có trên 3 buổi và chưa expand, chỉ hiển thị 3 buổi đầu
    final sessionsToShow = state.todaySchedule.length > 3 && !state.showAllSessions
        ? state.todaySchedule.take(3).toList()
        : state.todaySchedule;

    return Column(
      children: sessionsToShow.map((s) => _buildScheduleCard(context, s, cs, textTheme)).toList(),
    );
  }

  /// ===== CARD BUỔI HỌC – GIỮ FORM CŨ, CHỈ CHỈNH HỢP LÝ HƠN =====
  Widget _buildScheduleCard(
      BuildContext context, Map<String, dynamic> s, ColorScheme cs, TextTheme textTheme) {
    // Helper để tránh lỗi substring khi chuỗi ngắn / null
    String _safeTime(dynamic t) {
      final str = (t ?? '').toString();
      if (str.isEmpty || str == '--:--') return '--:--';
      return str.length >= 5 ? str.substring(0, 5) : str;
    }

    final subject = (s['subject'] ?? 'Môn học').toString();
    final className = (s['class_name'] ?? 'Lớp').toString();

    // Phòng học
    final r = s['room'];
    final room = (r is Map
            ? (r['name']?.toString() ?? r['code']?.toString() ?? '-')
            : r?.toString() ?? '-')
        .trim();

    final start = _safeTime(s['start_time']);
    final end = _safeTime(s['end_time']);
    final timeLine = '$start - $end';
    final status = (s['status'] ?? 'PLANNED').toString();

    // Lấy info mặc định từ helper (dùng cho case PLANNED/khác)
    final defaultInfo = _getStatusInfo(status, cs);

    // Xác định màu border và icon theo trạng thái (kỹ hơn một chút)
    Color borderColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    final rawStatus = status.toUpperCase();

    if (rawStatus == 'DONE' || rawStatus == 'COMPLETED') {
      // Đã dạy
      borderColor = Colors.green.shade300;
      statusColor = Colors.green.shade600;
      statusIcon = Icons.check_circle;
      statusText = 'Lớp học đã hoàn thành';
    } else if (rawStatus == 'CANCELED') {
      // Đã huỷ
      borderColor = Colors.red.shade300;
      statusColor = Colors.red.shade600;
      statusIcon = Icons.cancel;
      statusText = 'Lớp học đã huỷ';
    } else if (rawStatus == 'TEACHING') {
      // Đang diễn ra
      borderColor = cs.primary.withOpacity(0.7);
      statusColor = cs.primary;
      statusIcon = Icons.play_circle_fill;
      statusText = 'Lớp học đang diễn ra';
    } else {
      // PLANNED và các trạng thái khác coi là sắp tới
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
              // ===== BÊN TRÁI: Môn học, phòng, lớp =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên môn học (in đậm)
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
                    // Phòng học
                    if (room.isNotEmpty && room != '-')
                      Text(
                        'Phòng học: $room',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    // Lớp
                    if (className.isNotEmpty && className != 'Lớp')
                      Text(
                        'Lớp: $className',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),

              // ===== BÊN PHẢI: Trạng thái + thời gian + hint =====
              SizedBox(
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status indicator (text + icon)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),

                    // Thời gian (lớn) hoặc placeholder
                    if (timeLine.trim().isNotEmpty &&
                        timeLine != '--:-- - --:--')
                      Text(
                        timeLine,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    else
                      const SizedBox(height: 20),

                    // Hướng dẫn
                    Text(
                      'Bấm để xem chi tiết',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal,
                      ),
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

}
