// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/presentation/view_model/schedule_detail_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/attendance/attendance_page.dart';

class LecturerScheduleDetailPage extends ConsumerWidget {
  final int sessionId;
  final Map<String, dynamic>? sessionData; // Session data đã gộp từ home page
  
  const LecturerScheduleDetailPage({
    super.key,
    required this.sessionId,
    this.sessionData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleDetailViewModelProvider(sessionId));
    final viewModel = ref.read(scheduleDetailViewModelProvider(sessionId).notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Không tải được dữ liệu.\n${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => viewModel.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail ?? {};
    final materials = state.materials;

    // ===== Normalize fields for display =====
    // Subject/Class
    final subjVal = detail['subject'];
    final asg = detail['assignment'];
    final subjMap = (subjVal is Map)
        ? subjVal
        : (asg is Map && asg['subject'] is Map ? asg['subject'] : null);
    final subject = (subjMap is Map
            ? (subjMap['name'] ?? subjMap['code'])
            : (subjVal ?? ''))
        .toString();

    final cuVal = detail['class_unit'] ?? detail['class'];
    final cuMap = (cuVal is Map)
        ? cuVal
        : (asg is Map && asg['classUnit'] is Map ? asg['classUnit'] : null);
    final className = (cuMap is Map
            ? (cuMap['name'] ?? cuMap['code'])
            : (detail['class_name'] ?? ''))
        .toString();

    // Date
    final rawDate = ((detail['date'] ??
                detail['session_date'] ??
                detail['sessionDate']) ??
            '')
        .toString();
    final dateOnly = rawDate.contains(' ') ? rawDate.split(' ').first : rawDate;
    final date = _fmtDate(dateOnly);

    // Time - Nếu có sessionData đã gộp từ home page, ưu tiên dùng thời gian đã gộp
    String start = '';
    String end = '';
    
    if (sessionData != null) {
      // Nếu có session data đã gộp, dùng thời gian đã gộp (cả buổi)
      final mergedStart = sessionData!['start_time'];
      final mergedEnd = sessionData!['end_time'];
      if (mergedStart != null) start = _hhmm(mergedStart);
      if (mergedEnd != null) end = _hhmm(mergedEnd);
    }
    
    // Nếu không có hoặc thiếu, lấy từ detail API (cho trường hợp load trực tiếp từ URL)
    if (start.isEmpty || end.isEmpty) {
      final ts = detail['timeslot'];
      start = _hhmm(detail['start_time'] ??
          detail['start'] ??
          (ts is Map ? ts['start_time'] : null));
      end = _hhmm(detail['end_time'] ??
          detail['end'] ??
          (ts is Map ? ts['end_time'] : null));
    }

    // Room
    final r = detail['room'];
    final room = (r is Map
            ? (r['name']?.toString() ?? r['code']?.toString() ?? '')
            : r?.toString() ?? '')
        .trim();

    final TextEditingController _newMaterialCtrl = TextEditingController();
    final TextEditingController _noteCtrl = TextEditingController();
    if (state.note.isNotEmpty && _noteCtrl.text.isEmpty) {
      _noteCtrl.text = state.note;
    }

    return Scaffold(
      appBar: const TluAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(
                      '$subject - $className',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          // Kiểm tra xem có _grouped_session_ids không (buổi học đã được gộp)
                          final groupedIds = sessionData?['_grouped_session_ids'] as List?;
                          
                          context.push(
                            '/attendance/$sessionId',
                            extra: {
                              'subjectName': subject,
                              'className': className,
                              'groupedSessionIds': groupedIds, // Truyền danh sách session IDs đã gộp
                            },
                          );
                        },
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text('Điểm danh sinh viên'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _kv('Ca',
                        (start.isEmpty && end.isEmpty) ? '-' : '$start - $end'),
                    _kv('Ngày', date.isEmpty ? '-' : date),
                    _kv('Phòng', room.isEmpty ? '-' : room),
                    const SizedBox(height: 12),
                    Text(
                      'Nội dung bài học',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (materials.isEmpty)
                      _materialTile(
                        theme,
                        title: 'Chưa có nội dung',
                        disabled: true,
                      )
                    else
                      ...materials.map(
                        (m) => _materialTile(
                          theme,
                          title: (m['title'] ?? '').toString(),
                          subtitle: (m['uploaded_at'] ?? '').toString(),
                          url: (m['file_url'] ?? '').toString(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newMaterialCtrl,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.add),
                              hintText: 'Thêm nội dung bài học',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final title = _newMaterialCtrl.text.trim();
                            if (title.isEmpty) return;
                            final success = await viewModel.addMaterial(title);
                            if (success && context.mounted) {
                              _newMaterialCtrl.clear();
                            }
                          },
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: state.status,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái giảng dạy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'done',
                          child: Text('Đã hoàn thành'),
                        ),
                        DropdownMenuItem(
                          value: 'teaching',
                          child: Text('Đang dạy'),
                        ),
                        DropdownMenuItem(
                          value: 'canceled',
                          child: Text('Hủy buổi'),
                        ),
                      ],
                      onChanged: _canEndLesson(detail) // Chỉ cho phép thay đổi khi chưa kết thúc
                          ? (v) => viewModel.updateStatus(v ?? 'done')
                          : null, // Disable khi đã kết thúc
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => viewModel.updateNote(v),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Bottom buttons area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Kết thúc buổi học" button - chỉ hiển thị khi status là PLANNED hoặc TEACHING
                  if (_canEndLesson(detail))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleEndLesson(context, viewModel, state),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Kết thúc buổi học'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade700, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  // "Lưu" button
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final success = await viewModel.submitReport();
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu báo cáo buổi học')),
                          );
                        } else if (context.mounted && state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${state.error}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(dynamic s) {
    final str = (s ?? '').toString();
    return str.length >= 5 ? str.substring(0, 5) : str;
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  /// Check xem có thể kết thúc buổi học không (chỉ khi status là PLANNED hoặc TEACHING)
  bool _canEndLesson(Map<String, dynamic> detail) {
    final rawStatus = (detail['status'] ?? '').toString().toUpperCase();
    return rawStatus == 'PLANNED' || rawStatus == 'TEACHING';
  }

  /// Xử lý logic kết thúc buổi học
  Future<void> _handleEndLesson(
    BuildContext context,
    ScheduleDetailViewModel viewModel,
    ScheduleDetailState state,
  ) async {
    // Nếu không có attendance, hiển thị dialog xác nhận
    if (state.hasAttendance == false) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chưa điểm danh sinh viên'),
          content: const Text(
            'Bạn chưa điểm danh sinh viên cho buổi học này. '
            'Nếu kết thúc buổi học, hệ thống sẽ đánh dấu lớp là HUỶ. '
            'Bạn có chắc chắn muốn kết thúc không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Kết thúc buổi học'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) {
        return;
      }
    }

    // Gọi API để kết thúc buổi học
    final success = await viewModel.endLesson(confirmed: true);

    if (!context.mounted) return;

    if (success) {
      final finalStatus = viewModel.state.status.toLowerCase();
      final message = finalStatus == 'done'
          ? 'Buổi học đã được kết thúc (ĐÃ HOÀN THÀNH).'
          : 'Buổi học đã được kết thúc (ĐÃ HUỶ).';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: finalStatus == 'done' ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${viewModel.state.error ?? "Không thể kết thúc buổi học"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 145,
              child: Text(
                '$k:',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _materialTile(
    ThemeData theme, {
    required String title,
    String? subtitle,
    String? url,
    bool disabled = false,
  }) {
    final hasUrl = (url ?? '').isNotEmpty;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        enabled: !disabled,
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        subtitle:
            (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        onTap: hasUrl ? () {} : null,
        dense: true,
      ),
    );
  }
}
