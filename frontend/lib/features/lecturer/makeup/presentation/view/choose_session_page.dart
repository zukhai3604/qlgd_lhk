// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';

import 'package:qlgd_lhk/features/lecturer/makeup/model/api/makeup_api.dart';

/// Trang chọn các đơn nghỉ đã được duyệt để đăng ký dạy bù.
/// UI: KHÔNG có nút to “Đăng ký…”, chạm cả card để đi tiếp.
class ChooseApprovedLeavePage extends StatefulWidget {
  const ChooseApprovedLeavePage({super.key});

  @override
  State<ChooseApprovedLeavePage> createState() =>
      _ChooseApprovedLeavePageState();
}

class _ChooseApprovedLeavePageState extends State<ChooseApprovedLeavePage> {
  final _makeupApi = LecturerMakeupApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _leaves = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Lấy danh sách đơn nghỉ đã duyệt sử dụng API makeup
      final raw = await _makeupApi.approvedLeaves();
      final list = raw.map((e) => Map<String, dynamic>.from(e)).toList();

      // Chuẩn hoá ngày để sắp xếp
      for (final e in list) {
        final schedule = e['schedule'] as Map<String, dynamic>? ?? {};
        final rawDate = schedule['date']?.toString();
        e['__date__'] = (rawDate != null && rawDate.length >= 10)
            ? rawDate.substring(0, 10)
            : '';
      }

      if (list.length > 1) {
        list.sort((a, b) {
          final da = DateTime.tryParse(a['__date__'] ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['__date__'] ?? '') ?? DateTime(1970);
          if (da != db) return da.compareTo(db);

          // Nếu cùng ngày, sắp xếp theo thời gian
          final scheduleA =
              (a['schedule'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};
          final scheduleB =
              (b['schedule'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};
          final timeA = _extractStartTime(scheduleA);
          final timeB = _extractStartTime(scheduleB);
          return timeA.compareTo(timeB);
        });
      }

      // 👉 Gộp các buổi liền kề giống "bảng buổi" ở lịch sử xin nghỉ
      final grouped = _groupConsecutiveLeaveRequests(list);

      if (!mounted) return;
      setState(() => _leaves = grouped);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không tải được buổi nghỉ đã duyệt: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Điều hướng thẳng sang form dạy bù, truyền buổi gốc (schedule) + leave_request_id qua extra
  void _goToMakeupForm(Map<String, dynamic> leaveRequest) {
    // Nếu là grouped, lấy schedule từ group (đã được merge)
    final sessionData = leaveRequest['schedule'] as Map<String, dynamic>?;
    if (sessionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy dữ liệu buổi học gốc.')),
      );
      return;
    }

    // Nếu có grouped leave request IDs, lấy ID đầu tiên (hoặc có thể để user chọn)
    final leaveRequestId = leaveRequest['id'] as int?;
    if (leaveRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy ID đơn nghỉ.')),
      );
      return;
    }

    // Tạo data object kết hợp schedule và leave_request_id
    final combinedData = Map<String, dynamic>.from(sessionData);
    combinedData['leave_request_id'] = leaveRequestId;

    // Nếu có grouped IDs, cũng truyền vào để form có thể biết
    final groupedIds = leaveRequest['_grouped_leave_request_ids'] as List?;
    if (groupedIds != null && groupedIds.isNotEmpty) {
      combinedData['_grouped_leave_request_ids'] = groupedIds;
    }

    context.push('/makeup/form', extra: combinedData);
  }

  /// Gộp các đơn nghỉ liền kề nhau của cùng môn học thành 1 buổi
  /// Tiêu chí giống bên lịch sử:
  /// - Cùng subject + class + room + date
  /// - Cùng ca (morning/afternoon/evening)
  /// - end_time buổi trước cách start_time buổi sau ≤ 10 phút
  List<Map<String, dynamic>> _groupConsecutiveLeaveRequests(
      List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return [];

    // Sắp xếp theo ngày và thời gian bắt đầu (theo thời gian thực tế)
    final sorted = List<Map<String, dynamic>>.from(requests);
    sorted.sort((a, b) {
      final dateA = (a['__date__'] ?? '').toString();
      final dateB = (b['__date__'] ?? '').toString();
      if (dateA != dateB) return dateA.compareTo(dateB);

      final scheduleA =
          (a['schedule'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final scheduleB =
          (b['schedule'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final startA = _extractStartTime(scheduleA);
      final startB = _extractStartTime(scheduleB);

      if (startA.isEmpty && startB.isEmpty) return 0;
      if (startA.isEmpty) return 1;
      if (startB.isEmpty) return -1;

      final minutesA = _parseTimeToMinutes(startA);
      final minutesB = _parseTimeToMinutes(startB);
      if (minutesA == null && minutesB == null) return 0;
      if (minutesA == null) return 1;
      if (minutesB == null) return -1;
      return minutesA.compareTo(minutesB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final schedule =
          (current['schedule'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final subject = _getSubjectName(schedule);
      final className = _classNameOf(schedule);
      final room = _roomOf(schedule);
      final date = (current['__date__'] ?? '').toString();

      // Tìm các đơn liền kề có cùng subject, class, room, date
      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];
      final groupLeaveIds = <int>[];

      // Lấy leave request ID của current
      final currentId = current['id'];
      if (currentId != null) {
        groupLeaveIds.add(int.tryParse('$currentId') ?? -1);
      }

      // Xác định ca của request hiện tại
      final currentSchedule =
          (current['schedule'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final currentShift = _getShiftFromSchedule(currentSchedule);

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSchedule =
            (next['schedule'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
        final nextSubject = _getSubjectName(nextSchedule);
        final nextClassName = _classNameOf(nextSchedule);
        final nextRoom = _roomOf(nextSchedule);
        final nextDate = (next['__date__'] ?? '').toString();

        // Kiểm tra cùng môn, lớp, phòng, ngày (không còn check cohort)
        if (subject != nextSubject ||
            className != nextClassName ||
            room != nextRoom ||
            date != nextDate) {
          break;
        }

        // Kiểm tra cùng ca
        final nextShift = _getShiftFromSchedule(nextSchedule);
        if (currentShift != nextShift) {
          break; // Khác ca, không gộp
        }

        // Kiểm tra liền kề (end_time đơn trước gần start_time đơn sau <= 10 phút)
        final lastSchedule =
            (group.last['schedule'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
        final lastEnd = _parseTimeToMinutes(_extractEndTime(lastSchedule));
        final nextStart =
            _parseTimeToMinutes(_extractStartTime(nextSchedule));

        if (lastEnd == null || nextStart == null) break;

        final gap = nextStart - lastEnd;
        if (gap <= 10 && gap >= 0) {
          group.add(next);
          groupIndices.add(j);

          final nextId = next['id'];
          if (nextId != null) {
            final id = int.tryParse('$nextId');
            if (id != null && id > 0) groupLeaveIds.add(id);
          }
        } else {
          break;
        }
      }

      for (final idx in groupIndices) {
        processed.add(idx);
      }

      if (group.length == 1) {
        result.add(current);
      } else {
        // Gộp thành 1 buổi: lấy start từ đơn đầu, end từ đơn cuối
        final first = group.first;
        final last = group.last;
        final firstSchedule =
            (first['schedule'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
        final lastSchedule =
            (last['schedule'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};

        final merged = Map<String, dynamic>.from(current);

        final mergedSchedule = Map<String, dynamic>.from(firstSchedule);
        final startTime = _extractStartTime(firstSchedule);
        final endTime = _extractEndTime(lastSchedule);

        // Cập nhật timeslot với thời gian mới
        if (mergedSchedule['timeslot'] is Map) {
          final ts =
              Map<String, dynamic>.from(mergedSchedule['timeslot'] as Map);
          if (startTime.isNotEmpty) {
            ts['start_time'] =
                startTime.split(':').length == 2 ? '$startTime:00' : startTime;
          }
          if (endTime.isNotEmpty) {
            ts['end_time'] =
                endTime.split(':').length == 2 ? '$endTime:00' : endTime;
          }
          mergedSchedule['timeslot'] = ts;
        } else {
          mergedSchedule['timeslot'] = {
            'start_time': startTime.isNotEmpty
                ? (startTime.split(':').length == 2
                    ? '$startTime:00'
                    : startTime)
                : null,
            'end_time': endTime.isNotEmpty
                ? (endTime.split(':').length == 2 ? '$endTime:00' : endTime)
                : null,
          };
        }

        mergedSchedule['start_time'] = startTime.split(':').length == 2
            ? '$startTime:00'
            : startTime;
        mergedSchedule['end_time'] = endTime.split(':').length == 2
            ? '$endTime:00'
            : endTime;

        merged['schedule'] = mergedSchedule;

        // Lưu list ID đơn nghỉ đã gộp (giống bên lịch sử để dùng sau)
        merged['_grouped_leave_request_ids'] = groupLeaveIds;
        merged['id'] = current['id']; // giữ ID đầu tiên làm đại diện

        result.add(merged);
      }
    }

    return result;
  }

  /// Xác định period từ timeslot code (nếu có)
  /// Ví dụ: "T2_CA14" -> 14
  int? _getPeriodFromTimeslot(Map<String, dynamic>? timeslot) {
    if (timeslot == null) return null;
    final code = timeslot['code']?.toString() ?? '';
    final match = RegExp(r'CA(\d+)$').firstMatch(code);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Xác định ca từ schedule hoặc thời gian
  /// Trả về: 'morning' (ca sáng), 'afternoon' (ca chiều), 'evening' (ca tối), hoặc null
  String? _getShiftFromSchedule(Map<String, dynamic> schedule) {
    // Ưu tiên lấy từ period nếu có timeslot
    if (schedule['timeslot'] is Map) {
      final period = _getPeriodFromTimeslot(
          (schedule['timeslot'] as Map).cast<String, dynamic>());
      if (period != null) {
        if (period >= 1 && period <= 6) return 'morning';
        if (period >= 7 && period <= 12) return 'afternoon';
        if (period >= 13 && period <= 15) return 'evening';
      }
    }

    // Fallback: xác định từ thời gian bắt đầu
    final startTime = _extractStartTime(schedule);
    if (startTime.isEmpty || startTime == '--:--') return null;

    final minutes = _parseTimeToMinutes(startTime);
    if (minutes == null) return null;

    if (minutes >= 420 && minutes < 720) return 'morning';
    if (minutes >= 720 && minutes < 1080) return 'afternoon';
    if (minutes >= 1080) return 'evening';

    return null;
  }

  String _extractStartTime(Map<String, dynamic> schedule) {
    final timeslot = schedule['timeslot'] as Map?;
    if (timeslot != null) {
      final st = timeslot['start_time']?.toString();
      if (st != null && st.isNotEmpty) return _hhmm(st);
    }
    final st = schedule['start_time']?.toString();
    return st != null ? _hhmm(st) : '';
  }

  String _extractEndTime(Map<String, dynamic> schedule) {
    final timeslot = schedule['timeslot'] as Map?;
    if (timeslot != null) {
      final et = timeslot['end_time']?.toString();
      if (et != null && et.isNotEmpty) return _hhmm(et);
    }
    final et = schedule['end_time']?.toString();
    return et != null ? _hhmm(et) : '';
  }

  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _getSubjectName(Map<String, dynamic> schedule) {
    final subject = schedule['subject'] as Map?;
    if (subject != null) {
      return _pickObj(subject, ['name', 'code']).ifEmpty('Môn học');
    }
    final assignment = schedule['assignment'] as Map?;
    if (assignment != null) {
      final subj = assignment['subject'] as Map?;
      if (subj != null) {
        return _pickObj(subj, ['name', 'code']).ifEmpty('Môn học');
      }
    }
    return 'Môn học';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TluAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/makeup/history'),
                            icon: const Icon(Icons.history),
                            label: const Text('Lịch sử dạy bù'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_leaves.isEmpty)
                        _EmptyBox(onReload: _load)
                      else
                        ..._leaves.map((leave) {
                          final schedule = (leave['schedule'] as Map?)
                                  ?.cast<String, dynamic>() ??
                              const <String, dynamic>{};
                          return _LeaveItemTile(
                            data: schedule,
                            onTap: () => _goToMakeupForm(
                              leave,
                            ), // 👉 chạm card để đi tiếp
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

/* ======================= ITEM (KHÔNG NÚT TO) ======================= */

class _LeaveItemTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _LeaveItemTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Subject
    final subject = _pickObj(data['subject'] as Map?, ['name', 'code'])
        .ifEmpty(_pickObj(data['assignment']?['subject'] as Map?, ['name', 'code']))
        .ifEmpty('Môn học');

    final className = _classNameOf(data);
    final cohort = _cohortOf(data);
    final room = _roomOf(data);

    final dateStr =
        data['session_date']?.toString() ?? data['date']?.toString();
    final dateLabel = _dateVN(dateStr);

    final timeRange = _timeRangeOf(data);
    final hasTime =
        timeRange.isNotEmpty && timeRange != '--:-- - --:--';

    // Kiểm tra xem schedule có bị hủy không
    // CHỈ kiểm tra schedule.status === 'CANCELED'
    // Không kiểm tra thời gian vì buổi nghỉ đã được duyệt vẫn có thể đã qua thời gian
    // nhưng vẫn là buổi nghỉ đã được duyệt, không phải bị hủy
    final scheduleStatus = (data['status'] ?? '').toString().toUpperCase();
    final isCanceled = scheduleStatus == 'CANCELED';

    // Xác định màu và text dựa trên trạng thái
    // Nếu schedule.status === 'CANCELED' → màu vàng, "Buổi học bị hủy"
    // Nếu không (đơn nghỉ đã được duyệt) → màu xanh, "Buổi nghỉ đã duyệt"
    final borderColor = isCanceled ? Colors.orange.shade300 : Colors.green.shade300;
    final statusColor = isCanceled ? Colors.orange.shade600 : Colors.green.shade700;
    final statusText = isCanceled ? 'Buổi học bị hủy' : 'Buổi nghỉ đã duyệt';
    final statusIcon = isCanceled ? Icons.cancel : Icons.check_circle;

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
              // BÊN TRÁI
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (dateLabel.isNotEmpty)
                      Text(
                        'Ngày: $dateLabel',
                        style: tt.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (room.isNotEmpty && room != '-')
                      Text(
                        'Phòng học: $room',
                        style: tt.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (className.isNotEmpty || cohort.isNotEmpty)
                      Text(
                        'Lớp: ${className.isNotEmpty ? className : ''}'
                        '${cohort.isNotEmpty ? (className.isNotEmpty ? ' - $cohort' : cohort) : ''}',
                        style: tt.bodyMedium?.copyWith(
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
                          style: tt.bodySmall?.copyWith(
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
                    if (hasTime)
                      Text(
                        timeRange,
                        style: tt.headlineSmall?.copyWith(
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
                      'Bấm để đăng ký dạy bù',
                      style: tt.bodySmall?.copyWith(
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
}

/* ======================= HỘP TRẠNG THÁI & HELPERS ======================= */

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ]),
        ),
      );
}

class _EmptyBox extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyBox({required this.onReload});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_available,
                  size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Không có đơn nghỉ nào đã được duyệt\nđể bạn đăng ký dạy bù.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
}

/* -------------------------- Helper functions -------------------------- */

String _pick(Map s, List<String> keys, {String def = ''}) {
  for (final k in keys) {
    final v = s[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
  }
  return def;
}

String _pickObj(Map? obj, List<String> keys, {String def = ''}) {
  if (obj == null) return def;
  for (final k in keys) {
    final v = obj[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
  }
  return def;
}

extension _StringExt on String {
  String ifEmpty(String alt) => isEmpty ? alt : this;
}

String _classNameOf(Map<String, dynamic> s) {
  // Ưu tiên code thay vì name
  final a = s['assignment'] as Map?;
  if (a != null) {
    var v = _pickObj(a['classUnit'] as Map?, ['code', 'name']); // code trước
    if (v.isNotEmpty) return v;
    v = _pickObj(a['class_unit'] as Map?, ['code', 'name']); // code trước
    if (v.isNotEmpty) return v;
  }

  // Fallback từ flat fields - ưu tiên code
  return _pick(s, ['class_code', 'class_name', 'class', 'group_name']);
}

String _cohortOf(Map<String, dynamic> s) {
  var c = _pick(s, ['cohort', 'k', 'course', 'batch']);
  if (c.isNotEmpty && !c.toUpperCase().startsWith('K')) c = 'K$c';
  return c;
}

String _roomOf(Map<String, dynamic> s) {
  if (s['room'] is Map) {
    final r = s['room'] as Map;
    final code =
        _pickObj(r, ['code', 'name', 'room_code', 'title', 'label']);
    if (code.isNotEmpty) return code;
  }
  if (s['room'] is String && (s['room'] as String).trim().isNotEmpty) {
    return (s['room'] as String).trim();
  }
  if (s['assignment'] is Map && (s['assignment'] as Map)['room'] is Map) {
    final r = (s['assignment'] as Map)['room'] as Map;
    final code =
        _pickObj(r, ['code', 'name', 'room_code', 'title', 'label']);
    if (code.isNotEmpty) return code;
  }
  final rooms = s['rooms'] ?? s['classrooms'] ?? s['room_list'];
  if (rooms is List && rooms.isNotEmpty) {
    final first = rooms.first;
    if (first is String && first.trim().isNotEmpty) return first.trim();
    if (first is Map) {
      final code =
          _pickObj(first, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
  }
  final building =
      _pick(s, ['building', 'building.name', 'block', 'block.name']);
  final num =
      _pick(s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
  if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
  if (num.isNotEmpty) return num;
  return _pick(s, ['room_code', 'roomName']);
}

String _hhmm(String? raw) {
  if (raw == null || raw.isEmpty) return '--:--';
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

String _timeRangeOf(Map<String, dynamic> s) {
  // Ưu tiên từ timeslot object
  final timeslot = s['timeslot'] as Map?;
  if (timeslot != null) {
    final st = timeslot['start_time']?.toString();
    final et = timeslot['end_time']?.toString();
    if (st != null && et != null) {
      return '${_hhmm(st)} - ${_hhmm(et)}';
    }
  }

  // Fallback từ các field khác
  final times = s['times'] ?? s['timespan'];
  if (times != null && times.toString().trim().isNotEmpty) {
    final str = times.toString();
    final parts = str.split('-').map((e) => e.trim()).toList();
    if (parts.length == 2) {
      return '${_hhmm(parts[0])} - ${_hhmm(parts[1])}';
    }
    return str;
  }

  final st = _pick(s, [
    'start_time',
    'startTime',
    'timeslot.start_time',
    'timeslot.start',
    'period.start',
    'slot.start'
  ]);
  final et = _pick(s, [
    'end_time',
    'endTime',
    'timeslot.end_time',
    'timeslot.end',
    'period.end',
    'slot.end'
  ]);
  return '${_hhmm(st)} - ${_hhmm(et)}';
}

String _dateVN(String? isoOrDate) {
  if (isoOrDate == null || isoOrDate.isEmpty) return '';
  final raw =
      isoOrDate.length >= 10 ? isoOrDate.substring(0, 10) : isoOrDate;
  try {
    final dt = DateTime.parse(raw);
    return DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(dt);
  } catch (_) {
    return isoOrDate;
  }
}
