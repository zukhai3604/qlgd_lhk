// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view_model/leave_choose_session_view_model.dart';

/// Chip trạng thái dùng chung
class _StatusChip {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusChip(this.label, this.bg, this.fg);
}

class ChooseSessionPage extends ConsumerWidget {
  const ChooseSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveChooseSessionViewModelProvider);
    final viewModel = ref.read(leaveChooseSessionViewModelProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const TluAppBar(),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorBox(message: state.error!, onRetry: () => viewModel.refresh())
              : RefreshIndicator(
                  onRefresh: () => viewModel.refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Chọn buổi cần nghỉ',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/leave/history'),
                          icon: const Icon(Icons.history),
                          label: const Text('Lịch sử xin nghỉ'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (state.dateOptions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<String>(
                            value: state.selectedDate,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: state.dateOptions
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(_formatDateLabel(d)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => viewModel.selectDate(v),
                          ),
                        ),
                      const SizedBox(height: 8),

                      if (state.filteredSessions.isEmpty)
                        _EmptyBox(onReload: () => viewModel.refresh())
                      else
                        ...state.filteredSessions.map(
                          (s) => SessionItemTile(
                            data: s,
                            onTap: () => context.push(
                              '/leave/form',
                              extra: s,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _formatDateLabel(String yyyymmdd) {
    try {
      final dt = DateTime.parse(yyyymmdd.substring(0, 10));
      const mapThu = {
        1: 'Thứ 2',
        2: 'Thứ 3',
        3: 'Thứ 4',
        4: 'Thứ 5',
        5: 'Thứ 6',
        6: 'Thứ 7',
        7: 'Chủ nhật'
      };
      final thu = mapThu[dt.weekday] ?? '';
      final dmy =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      return '$thu • $dmy';
    } catch (_) {
      return yyyymmdd;
    }
  }
}

/* ------------------------------- Session Tile ------------------------------ */

class SessionItemTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const SessionItemTile({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subject = _subjectOf(data);
    final room = _roomOf(data);
    final className = _pickStr(data, [
      'assignment.class_unit.name',
      'assignment.class_unit.code',
      'class_unit.name',
      'class_unit.code',
      'class_name',
      'class',
      'class_code',
      'group_name',
    ]);
    var cohort = _pickStr(data, ['cohort', 'k', 'course', 'batch']);
    if (cohort.isNotEmpty &&
        !cohort.toUpperCase().startsWith('K')) {
      cohort = 'K$cohort';
    }
    final timeLine = _timeRangeOf(data);
    final stt = _statusOf(data, context);

    // Mapping lại màu + icon + text cho dễ hiểu, giống home page
    Color borderColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    final rawStatus = data['status']?.toString().toUpperCase() ?? '';

    if (rawStatus == 'DONE' ||
        rawStatus == 'COMPLETED' ||
        stt.label == 'Đã qua') {
      borderColor = Colors.green.shade300;
      statusColor = Colors.green.shade600;
      statusIcon = Icons.check_circle;
      statusText = 'Lớp học đã hoàn thành';
    } else if (rawStatus == 'CANCELED' || stt.label == 'Huỷ') {
      borderColor = Colors.red.shade300;
      statusColor = Colors.red.shade600;
      statusIcon = Icons.cancel;
      statusText = 'Lớp học đã huỷ';
    } else if (rawStatus == 'ONGOING' ||
        rawStatus == 'TEACHING' ||
        stt.label == 'Đang diễn ra') {
      borderColor = cs.primary.withOpacity(0.7);
      statusColor = cs.primary;
      statusIcon = Icons.play_circle_fill;
      statusText = 'Lớp học đang diễn ra';
    } else {
      // PLANNED + mọi trạng thái khác coi là sắp tới
      borderColor = Colors.blue.shade300;
      statusColor = Colors.blue.shade600;
      statusIcon = Icons.access_time;
      statusText = 'Lớp học sắp tới';
    }

    final hasTime =
        timeLine.isNotEmpty && timeLine != '--:-- - --:--';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== BÊN TRÁI: Tên môn, phòng, lớp =====
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
                    if (room.isNotEmpty)
                      Text(
                        'Phòng học: $room',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    // Lớp + khoá
                    if (className.isNotEmpty || cohort.isNotEmpty)
                      Text(
                        'Lớp: ${className.isNotEmpty ? className : ''}'
                        '${cohort.isNotEmpty ? (className.isNotEmpty ? ' - $cohort' : cohort) : ''}',
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
                    // Hàng trạng thái: text + icon
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

                    // Giờ học (to) nếu có
                    if (hasTime)
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

                    // Hint chọn buổi
                    Text(
                      'Chạm để chọn buổi này',
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

  // === Helpers static dùng lại (giữ nguyên, chỉ sửa nhẹ logic nếu cần) ===

  static String _pickStr(Map data, List<String> paths) {
    for (final p in paths) {
      dynamic cur = data;
      for (final seg in p.split('.')) {
        if (cur is Map && cur.containsKey(seg)) {
          cur = cur[seg];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && cur.toString().trim().isNotEmpty) {
        return cur.toString().trim();
      }
    }
    return '';
  }

  static String _subjectOf(Map<String, dynamic> s) {
    return _pickStr(s, [
      'assignment.subject.name',
      'assignment.subject.title',
      'subject.name',
      'subject.title',
      'subject_name',
      'subject',
      'course_name',
      'title',
    ]).ifEmpty('Môn học');
  }

  static String _roomOf(Map<String, dynamic> s) {
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = _pickStr(
          r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    if (s['room'] is String &&
        (s['room'] as String).trim().isNotEmpty) {
      return (s['room'] as String).trim();
    }
    if (s['assignment'] is Map) {
      final a = s['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(
            r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }
    dynamic rooms =
        s['rooms'] ?? s['classrooms'] ?? s['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map) {
        final fromList = _pickStr(
            first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }
    final building = _pickStr(
        s, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(
        s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) {
      return '$building-$num';
    }
    if (num.isNotEmpty) return num;
    return '';
  }

  static String _classLineOf(Map<String, dynamic> s) {
    final className = _pickStr(s, [
      'assignment.class_unit.name',
      'assignment.class_unit.code',
      'class_unit.name',
      'class_unit.code',
      'class_name',
      'class',
      'class_code',
      'group_name',
    ]);
    var cohort = _pickStr(s, ['cohort', 'k', 'course', 'batch']);
    if (cohort.isNotEmpty &&
        !cohort.toUpperCase().startsWith('K')) {
      cohort = 'K$cohort';
    }

    final room = _roomOf(s);

    final leftParts = <String>[];
    if (className.isNotEmpty) leftParts.add('Lớp: $className');
    if (cohort.isNotEmpty) leftParts.add(cohort);

    final left = leftParts.join(' - ');
    final roomPart = room.isEmpty ? '' : ' • Phòng: $room';

    if (left.isEmpty && roomPart.isEmpty) return '';
    return left + roomPart;
  }

  static String _startOfStr(Map<String, dynamic> s) {
    final raw = _pickStr(s, [
      'timeslot.start_time',
      'timeslot.start',
      'start_time',
      'startTime',
      'slot.start',
    ]);
    return _hhmm(raw);
  }

  static String _endOfStr(Map<String, dynamic> s) {
    final raw = _pickStr(s, [
      'timeslot.end_time',
      'timeslot.end',
      'end_time',
      'endTime',
      'slot.end',
    ]);
    return _hhmm(raw);
  }

  static String _timeRangeOf(Map<String, dynamic> s) {
    final st = _startOfStr(s);
    final et = _endOfStr(s);
    if (st.isEmpty && et.isEmpty) return '';
    if (st.isEmpty) return et;
    if (et.isEmpty) return st;
    return '$st - $et';
  }

  static _StatusChip _statusOf(
      Map<String, dynamic> s, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final raw = s['status']?.toString().toUpperCase();

    if (raw == 'PLANNED') {
      return _StatusChip(
          'Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
    }
    if (raw == 'ONGOING' || raw == 'TEACHING') {
      return _StatusChip('Đang diễn ra', cs.tertiaryContainer,
          cs.onTertiaryContainer);
    }
    if (raw == 'DONE' || raw == 'COMPLETED') {
      return _StatusChip(
          'Đã qua', cs.surfaceVariant, cs.onSurfaceVariant);
    }
    if (raw == 'CANCELED') {
      return _StatusChip(
          'Huỷ', cs.errorContainer, cs.onErrorContainer);
    }

    try {
      final date =
          _pickStr(s, ['session_date', 'date']).split(' ').first;
      final st = _startOfStr(s).split(':');
      final et = _endOfStr(s).split(':');
      if (date.isNotEmpty && st.isNotEmpty && et.isNotEmpty) {
        final base = DateTime.parse(date);
        final start = DateTime(base.year, base.month, base.day,
            int.tryParse(st[0]) ?? 0,
            (st.length > 1 ? int.tryParse(st[1]) : 0) ?? 0);
        final end = DateTime(base.year, base.month, base.day,
            int.tryParse(et[0]) ?? 0,
            (st.length > 1 ? int.tryParse(et[1]) : 0) ?? 0);
        final now = DateTime.now();
        if (now.isBefore(start)) {
          return _StatusChip('Sắp tới', cs.primaryContainer,
              cs.onPrimaryContainer);
        }
        if (now.isAfter(end)) {
          return _StatusChip('Đã qua', cs.surfaceVariant,
              cs.onSurfaceVariant);
        }
        return _StatusChip('Đang diễn ra', cs.tertiaryContainer,
            cs.onTertiaryContainer);
      }
    } catch (_) {}
    return _StatusChip(
        'Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
  }

  static String _hhmm(String raw) {
    if (raw.isEmpty) return '';
    final s = raw.trim();
    if (s.contains('T')) {
      try {
        final dt = DateTime.parse(s);
        return DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }
    final parts = s.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return s;
  }
}

/* ----------------------------- Boxes trạng thái ---------------------------- */

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          )
        ]),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyBox({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available,
              size: 56, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'Không có buổi học nào sắp tới để xin nghỉ.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

extension _EmptyStr on String {
  String ifEmpty(String alt) => isEmpty ? alt : this;
}
