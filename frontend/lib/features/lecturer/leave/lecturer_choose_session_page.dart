// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../schedule/service.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'leave_api.dart';

/// Chip trạng thái dùng chung
class _StatusChip {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusChip(this.label, this.bg, this.fg);
}

class LecturerChooseSessionPage extends StatefulWidget {
  const LecturerChooseSessionPage({super.key});

  @override
  State<LecturerChooseSessionPage> createState() =>
      _LecturerChooseSessionPageState();
}

class _LecturerChooseSessionPageState extends State<LecturerChooseSessionPage> {
  final _scheduleSvc = LecturerScheduleService();
  final _leaveApi = LecturerLeaveApi();

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> sessions = [];
  String? selectedDate; // yyyy-MM-dd
  List<String> dateOptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Lấy các buổi sắp tới (30 ngày), chỉ giữ những buổi chưa bắt đầu
      final all = await _scheduleSvc.listUpcomingSessions(
        from: DateTime.now(),
        to: DateTime.now().add(const Duration(days: 30)),
      );

      // Removed excessive debug logging for performance

      DateTime? _startOf(Map<String, dynamic> s) {
        final date = _dateIsoOf(s);
        final st = _startOfStr(s);
        if (date.isEmpty || st.isEmpty) return null;

        final parts = st.split(':');
        final hh = (parts.isNotEmpty ? parts[0] : '00').padLeft(2, '0');
        final mm = (parts.length > 1 ? parts[1] : '00').padLeft(2, '0');

        try {
          return DateTime.parse('${date}T$hh:$mm:00');
        } catch (_) {
          return null;
        }
      }

      final now = DateTime.now();
      var upcoming = all
          .where((raw) {
        final s = Map<String, dynamic>.from(raw as Map);
        final isPlanned =
        (s['status']?.toString().toUpperCase() == 'PLANNED');
        final start = _startOf(s);
        return isPlanned && start != null && now.isBefore(start);
      })
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Loại các buổi đã có đơn xin nghỉ PENDING/APPROVED
      final pending = await _leaveApi.list(status: 'PENDING');
      final approved = await _leaveApi.list(status: 'APPROVED');
      final excluded = <int>{}
        ..addAll(pending.map((e) => int.tryParse('${e['schedule_id']}') ?? -1))
        ..addAll(approved.map((e) => int.tryParse('${e['schedule_id']}') ?? -1));
      
      upcoming = upcoming
          .where((s) => !excluded.contains(int.tryParse('${s['id']}') ?? -1))
          .toList();

      // >>> ENRICH: lấy room cho những item chưa có phòng
      await _enrichMissingRooms(upcoming);

      // Tập ngày cho dropdown
      final opts = <String>{};
      for (final s in upcoming) {
        final d = _dateIsoOf(s);
        if (d.isNotEmpty) opts.add(d);
      }
      final sorted = opts.toList()..sort();

      sessions = upcoming;
      dateOptions = sorted;
      if (selectedDate == null || !dateOptions.contains(selectedDate)) {
        selectedDate = dateOptions.isNotEmpty ? dateOptions.first : null;
      }
    } catch (e) {
      error = 'Không tải được danh sách buổi dạy: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Gọi getDetail(id) cho những session chưa có "room" và merge vào list
  Future<void> _enrichMissingRooms(List<Map<String, dynamic>> list) async {
    // gom các id cần bổ sung
    final needIds = <int>[];
    for (final s in list) {
      if (_roomOf(s).isEmpty) {
        final id = int.tryParse('${s['id']}');
        if (id != null && id > 0) needIds.add(id);
      }
    }
    if (needIds.isEmpty) return;

    // fetch tuần tự để an toàn (có thể đổi sang Future.wait nếu BE chịu tải tốt)
    for (final id in needIds) {
      try {
        final detail = await _scheduleSvc.getDetail(id);
        if (detail is Map) {
          // tìm item tương ứng trong list và merge
          final idx = list.indexWhere(
                  (e) => int.tryParse('${e['id']}') == id);
          if (idx != -1) {
            final merged = {...list[idx], ...Map<String, dynamic>.from(detail)};
            list[idx] = merged;
          }
        }
      } catch (_) {
        // bỏ qua nếu fetch lỗi; UI vẫn hiển thị không có phòng
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const TluAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _ErrorBox(message: error!, onRetry: _load)
          : RefreshIndicator(
        onRefresh: _load,
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

            if (dateOptions.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: selectedDate,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: dateOptions
                      .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(_formatDateLabel(d)),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedDate = v),
                ),
              ),
            const SizedBox(height: 8),

            if (_visibleSessions().isEmpty)
              _EmptyBox(onReload: _load)
            else
              ..._visibleSessions().map(
                    (s) => SessionItemTile(
                  data: s,
                  onTap: () => context.push('/leave/form', extra: s),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _visibleSessions() {
    if (selectedDate == null) return [];
    final filtered = sessions
        .where((s) => _dateIsoOf(s).startsWith(selectedDate!))
        .toList();
    
    // Gộp các tiết liền kề nhau của cùng môn học
    final grouped = _groupConsecutiveSessions(filtered);
    
    return grouped;
  }

  /// Gộp các tiết liền kề nhau của cùng môn học thành 1 buổi
  List<Map<String, dynamic>> _groupConsecutiveSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return [];

    // Sắp xếp theo thời gian bắt đầu
    final sorted = List<Map<String, dynamic>>.from(sessions);
    sorted.sort((a, b) {
      final dateA = _dateIsoOf(a);
      final dateB = _dateIsoOf(b);
      if (dateA != dateB) return dateA.compareTo(dateB);
      
      final startA = _startOfStr(a);
      final startB = _startOfStr(b);
      if (startA.isEmpty && startB.isEmpty) return 0;
      if (startA.isEmpty) return 1;
      if (startB.isEmpty) return -1;
      return startA.compareTo(startB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = _subjectOf(current);
      final className = _classNameForGrouping(current);
      final cohort = _cohortForGrouping(current);
      final room = _roomOf(current);
      final date = _dateIsoOf(current);
      final startTime = _startOfStr(current);
      final endTime = _endOfStr(current);
      
      print('DEBUG Grouping: Processing session $i');
      print('  - ID: ${current['id']}');
      print('  - Subject: $subject');
      print('  - ClassName: $className');
      print('  - Cohort: $cohort');
      print('  - Room: $room');
      print('  - Date: $date');
      print('  - Time: $startTime - $endTime');
      
      // Tìm các tiết liền kề có cùng subject, class, room, date
      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];
      
      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;
        
        final next = sorted[j];
        final nextSubject = _subjectOf(next);
        final nextClassName = _classNameForGrouping(next);
        final nextCohort = _cohortForGrouping(next);
        final nextRoom = _roomOf(next);
        final nextDate = _dateIsoOf(next);
        final nextStartTime = _startOfStr(next);
        final nextEndTime = _endOfStr(next);
        
        print('DEBUG Grouping: Comparing with session $j');
        print('  - ID: ${next['id']}');
        print('  - Subject: $nextSubject (match: ${subject == nextSubject})');
        print('  - ClassName: $nextClassName (match: ${className == nextClassName})');
        print('  - Cohort: $nextCohort (current: $cohort, match: ${cohort.isEmpty && nextCohort.isEmpty || cohort == nextCohort})');
        print('  - Room: $nextRoom (match: ${room == nextRoom})');
        print('  - Date: $nextDate (match: ${date == nextDate})');
        print('  - Time: $nextStartTime - $nextEndTime');
        
        // Kiểm tra cùng môn, lớp, cohort, phòng, ngày
        // Nếu cohort rỗng, không so sánh cohort (cho phép gộp các lớp không có cohort info)
        final cohortMatch = cohort.isEmpty && nextCohort.isEmpty || cohort == nextCohort;
        
        final sameSubject = subject == nextSubject;
        final sameClass = className == nextClassName;
        final sameRoom = room == nextRoom;
        final sameDate = date == nextDate;
        
        print('  - Match checks: Subject=$sameSubject, Class=$sameClass, Cohort=$cohortMatch, Room=$sameRoom, Date=$sameDate');
        
        if (!sameSubject || !sameClass || !cohortMatch || !sameRoom || !sameDate) {
          print('  - NOT MATCHING: Stopping group');
          break;
        }
        
        // Kiểm tra liền kề (end_time của tiết trước gần start_time của tiết sau <= 10 phút)
        final lastEndStr = _endOfStr(group.last);
        final nextStartStr = _startOfStr(next);
        final lastEnd = _parseTimeToMinutes(lastEndStr);
        final nextStart = _parseTimeToMinutes(nextStartStr);
        
        print('  - Time gap check: Last end=$lastEndStr ($lastEnd), Next start=$nextStartStr ($nextStart)');
        
        if (lastEnd == null || nextStart == null) {
          print('  - Cannot parse time: Stopping');
          break;
        }
        
        // Nếu gap <= 10 phút, coi là liền kề
        final gap = nextStart - lastEnd;
        print('  - Gap: $gap minutes');
        
        if (gap <= 10 && gap >= 0) {
          print('  - MATCHING: Adding to group');
          group.add(next);
          groupIndices.add(j);
        } else {
          print('  - Gap too large ($gap): Stopping');
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
        final startTime = _startOfStr(first);
        
        // Lấy end_time từ tiết cuối
        final endTime = _endOfStr(last);
        
        // Cập nhật timeslot với thời gian mới
        if (merged['timeslot'] is Map) {
          final ts = Map<String, dynamic>.from(merged['timeslot'] as Map);
          if (startTime.isNotEmpty) {
            ts['start_time'] = startTime.split(':').length == 2 ? '$startTime:00' : startTime;
          }
          if (endTime.isNotEmpty) {
            ts['end_time'] = endTime.split(':').length == 2 ? '$endTime:00' : endTime;
          }
          merged['timeslot'] = ts;
        } else {
          merged['timeslot'] = {
            'start_time': startTime.isNotEmpty ? (startTime.split(':').length == 2 ? '$startTime:00' : startTime) : null,
            'end_time': endTime.isNotEmpty ? (endTime.split(':').length == 2 ? '$endTime:00' : endTime) : null,
          };
        }
        
        // Cập nhật start_time và end_time ở top level (để UI hiển thị đúng)
        merged['start_time'] = startTime.split(':').length == 2 ? '$startTime:00' : startTime;
        merged['end_time'] = endTime.split(':').length == 2 ? '$endTime:00' : endTime;
        
        // Lưu danh sách các session IDs gốc để có thể xử lý khi submit
        final sessionIds = group.map((s) => int.tryParse('${s['id']}')).whereType<int>().toList();
        merged['_grouped_session_ids'] = sessionIds;
        
        result.add(merged);
      }
    }

    return result;
  }

  /// Parse thời gian HH:mm thành số phút (ví dụ: "15:40" -> 940)
  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
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

  /* ----------------------------- Helpers dữ liệu ----------------------------- */

  String _pickStr(Map data, List<String> paths) {
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

  String _dateIsoOf(Map<String, dynamic> s) {
    final raw = _pickStr(s, [
      'session_date',
      'date',
      'timeslot.date',
      'period.date',
      'start_at',
    ]);
    if (raw.isEmpty) return '';
    final only = raw.split(' ').first;
    try {
      final dt = DateTime.parse(only);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return only;
    }
  }

  String _startOfStr(Map<String, dynamic> s) {
    // Ưu tiên timeslot, sau đó top level
    final raw = _pickStr(s, [
      'timeslot.start_time',
      'timeslot.start',
      'start_time',
      'startTime',
      'slot.start',
    ]);
    final result = _hhmm(raw);
    
    // Debug: nếu không tìm thấy, log để kiểm tra
    if (result.isEmpty && s.containsKey('timeslot')) {
      // Có timeslot nhưng không extract được, có thể structure khác
    }
    
    return result;
  }

  String _endOfStr(Map<String, dynamic> s) {
    // Ưu tiên timeslot, sau đó top level
    final raw = _pickStr(s, [
      'timeslot.end_time',
      'timeslot.end',
      'end_time',
      'endTime',
      'slot.end',
    ]);
    final result = _hhmm(raw);
    
    // Debug: nếu không tìm thấy, log để kiểm tra
    if (result.isEmpty && s.containsKey('timeslot')) {
      // Có timeslot nhưng không extract được, có thể structure khác
    }
    
    return result;
  }

  /// Lấy phòng: hỗ trợ room object/string, assignment.room, list rooms, building+code/room_number
  String _roomOf(Map<String, dynamic> s) {
    // Check nested room structure (from normalized API - kept original)
    if (s['room_nested'] is Map) {
      final r = s['room_nested'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    
    // Check normalized string value
    if (s['room'] is String && (s['room'] as String).trim().isNotEmpty) {
      return (s['room'] as String).trim();
    }
    
    if (s['assignment'] is Map) {
      final a = s['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }
    dynamic rooms = s['rooms'] ?? s['classrooms'] ?? s['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fromList =
        _pickStr(first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }
    final building = _pickStr(s, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
    if (num.isNotEmpty) return num;
    return '';
  }

  String _subjectOf(Map<String, dynamic> s) {
    // Ưu tiên nested structure, sau đó flat structure
    final result = _pickStr(s, [
      'assignment.subject.name',
      'assignment.subject.title',
      'subject.name',
      'subject.title',
      'subject_nested.name', // From normalized API (kept original structure)
      'subject_nested.code',
      'subject_name',
      'subject', // Top level subject (from normalized API response - string)
      'course_name',
      'title',
    ]);
    
    // Nếu subject là Map, extract name hoặc code
    if (result.isEmpty) {
      if (s['subject'] is Map) {
        final subjMap = s['subject'] as Map;
        final name = _pickStr(subjMap, ['name', 'title', 'code']);
        if (name.isNotEmpty) return name;
      }
      // Check subject_nested (kept from original API response)
      if (s['subject_nested'] is Map) {
        final subjMap = s['subject_nested'] as Map;
        final name = _pickStr(subjMap, ['name', 'title', 'code']);
        if (name.isNotEmpty) return name;
      }
    }
    
    return result.isEmpty ? 'Môn học' : result;
  }

  /// Lấy className để so sánh khi gộp (không bao gồm room)
  String _classNameForGrouping(Map<String, dynamic> s) {
    // Ưu tiên nested structure, sau đó flat structure
    final result = _pickStr(s, [
      'assignment.class_unit.name',
      'assignment.class_unit.code',
      'assignment.classUnit.name',
      'assignment.classUnit.code',
      'class_unit.name',
      'class_unit.code',
      'classUnit.name', // From normalized API (kept original structure)
      'classUnit.code',
      'class_name', // Top level class_name (from normalized API response - string)
      'class',
      'class_code',
      'group_name',
    ]);
    
    // Nếu classUnit là Map, extract name hoặc code
    if (result.isEmpty) {
      final cu = s['classUnit'] ?? s['class_unit'];
      if (cu is Map) {
        final name = _pickStr(cu, ['name', 'code']);
        if (name.isNotEmpty) return name;
      }
      
      // Check trong assignment
      if (s['assignment'] is Map) {
        final asg = s['assignment'] as Map;
        final cuInAsg = asg['classUnit'] ?? asg['class_unit'];
        if (cuInAsg is Map) {
          final name = _pickStr(cuInAsg, ['name', 'code']);
          if (name.isNotEmpty) return name;
        }
      }
    }
    
    return result;
  }

  /// Lấy cohort để so sánh khi gộp
  String _cohortForGrouping(Map<String, dynamic> s) {
    var cohort = _pickStr(s, ['cohort', 'k', 'course', 'batch']); // ví dụ: 68
    if (cohort.isNotEmpty && !cohort.toUpperCase().startsWith('K')) {
      cohort = 'K$cohort';
    }
    return cohort;
  }

  String _classLineOf(Map<String, dynamic> s) {
    final className = _classNameForGrouping(s);
    final cohort = _cohortForGrouping(s);
    final room = _roomOf(s);

    final leftParts = <String>[];
    if (className.isNotEmpty) leftParts.add('Lớp: $className');
    if (cohort.isNotEmpty) leftParts.add(cohort);

    final left = leftParts.join(' - ');
    final roomPart = room.isEmpty ? '' : ' • Phòng: $room';

    if (left.isEmpty && roomPart.isEmpty) return '';
    return left + roomPart;
  }

  String _timeRangeOf(Map<String, dynamic> s) {
    final st = _startOfStr(s);
    final et = _endOfStr(s);
    if (st.isEmpty && et.isEmpty) return '';
    if (st.isEmpty) return et;
    if (et.isEmpty) return st;
    return '$st - $et';
  }

  _StatusChip _statusOf(Map<String, dynamic> s, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final raw = s['status']?.toString().toUpperCase();

    if (raw == 'PLANNED') return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
    if (raw == 'ONGOING') return _StatusChip('Đang diễn ra', cs.tertiaryContainer, cs.onTertiaryContainer);
    if (raw == 'DONE' || raw == 'COMPLETED') {
      return _StatusChip('Đã qua', cs.surfaceVariant, cs.onSurfaceVariant);
    }
    if (raw == 'CANCELED') return _StatusChip('Huỷ', cs.errorContainer, cs.onErrorContainer);

    // Suy luận theo thời gian nếu không có status
    try {
      final d = _dateIsoOf(s);
      if (d.isNotEmpty) {
        final st = _startOfStr(s).split(':');
        final et = _endOfStr(s).split(':');
        final base = DateTime.parse(d);
        final start = DateTime(base.year, base.month, base.day,
            int.tryParse(st[0]) ?? 0, (st.length > 1 ? int.tryParse(st[1]) : 0) ?? 0);
        final end = DateTime(base.year, base.month, base.day,
            int.tryParse(et[0]) ?? 0, (st.length > 1 ? int.tryParse(et[1]) : 0) ?? 0);
        final now = DateTime.now();
        if (now.isBefore(start)) return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
        if (now.isAfter(end)) return _StatusChip('Đã qua', cs.surfaceVariant, cs.onSurfaceVariant);
        return _StatusChip('Đang diễn ra', cs.tertiaryContainer, cs.onTertiaryContainer);
      }
    } catch (_) {}
    return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
  }

  String _hhmm(String raw) {
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

    final subject = _subjectOf(data);
    final classLine = _classLineOf(data);
    final timeLine = _timeRangeOf(data);
    final stt = _statusOf(data, context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: cs.surfaceVariant.withOpacity(.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.primary.withOpacity(.45), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon tròn bên trái
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 12),

              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (classLine.isNotEmpty)
                      Text(
                        classLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (timeLine.isNotEmpty)
                      Text(
                        timeLine,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Chip trạng thái
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: stt.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stt.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: stt.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers static dùng lại
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
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    if (s['room'] is String && (s['room'] as String).trim().isNotEmpty) {
      return (s['room'] as String).trim();
    }
    if (s['assignment'] is Map) {
      final a = s['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }
    dynamic rooms = s['rooms'] ?? s['classrooms'] ?? s['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fromList =
        _pickStr(first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }
    final building = _pickStr(s, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
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
    if (cohort.isNotEmpty && !cohort.toUpperCase().startsWith('K')) {
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

  static _StatusChip _statusOf(Map<String, dynamic> s, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final raw = s['status']?.toString().toUpperCase();

    if (raw == 'PLANNED') return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
    if (raw == 'ONGOING') return _StatusChip('Đang diễn ra', cs.tertiaryContainer, cs.onTertiaryContainer);
    if (raw == 'DONE' || raw == 'COMPLETED') {
      return _StatusChip('Đã qua', cs.surfaceVariant, cs.onSurfaceVariant);
    }
    if (raw == 'CANCELED') return _StatusChip('Huỷ', cs.errorContainer, cs.onErrorContainer);

    try {
      final date = _pickStr(s, ['session_date', 'date']).split(' ').first;
      final st = _startOfStr(s).split(':');
      final et = _endOfStr(s).split(':');
      if (date.isNotEmpty && st.isNotEmpty && et.isNotEmpty) {
        final base = DateTime.parse(date);
        final start = DateTime(base.year, base.month, base.day,
            int.tryParse(st[0]) ?? 0, (st.length > 1 ? int.tryParse(st[1]) : 0) ?? 0);
        final end = DateTime(base.year, base.month, base.day,
            int.tryParse(et[0]) ?? 0, (st.length > 1 ? int.tryParse(et[1]) : 0) ?? 0);
        final now = DateTime.now();
        if (now.isBefore(start)) return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
        if (now.isAfter(end)) return _StatusChip('Đã qua', cs.surfaceVariant, cs.onSurfaceVariant);
        return _StatusChip('Đang diễn ra', cs.tertiaryContainer, cs.onTertiaryContainer);
      }
    } catch (_) {}
    return _StatusChip('Sắp tới', cs.primaryContainer, cs.onPrimaryContainer);
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
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
          const Icon(Icons.event_available, size: 56, color: Colors.grey),
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
