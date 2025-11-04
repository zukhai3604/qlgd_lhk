// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'leave_api.dart';
import '../schedule/service.dart'; // dùng để fallback lấy detail buổi học (room)
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';

class LecturerLeavePage extends StatefulWidget {
  const LecturerLeavePage({super.key, required this.session});
  final Map<String, dynamic> session;

  @override
  State<LecturerLeavePage> createState() => _LecturerLeavePageState();
}

class _LecturerLeavePageState extends State<LecturerLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _submitting = false;

  // Fallback: nếu không có room trong session -> gọi service lấy detail để rút room
  final _scheduleSvc = LecturerScheduleService();
  String _roomAsync = ''; // room lấy từ detail (nếu cần)
  bool _loadingRoom = false;

  @override
  void initState() {
    super.initState();
    // nếu room trống -> thử lấy từ detail
    _maybeFetchRoomFromDetail();
  }

  Future<void> _maybeFetchRoomFromDetail() async {
    final s = widget.session;
    final roomInline = _roomOf(s);
    if (roomInline.isNotEmpty) return; // đã có phòng rồi

    final sessionId = int.tryParse('${s['id']}');
    if (sessionId == null || sessionId <= 0) return;

    setState(() => _loadingRoom = true);
    try {
      final detail = await _scheduleSvc.getDetail(sessionId);
      final room = _roomOf((detail ?? {}) as Map<String, dynamic>);
      if (mounted && room.isNotEmpty) {
        setState(() => _roomAsync = room);
      }
    } catch (_) {
      // bỏ qua: không có phòng thì UI vẫn hiển thị không có "Phòng"
    } finally {
      if (mounted) setState(() => _loadingRoom = false);
    }
  }

  // ===== Helpers bóc tách dữ liệu từ session Map =====
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

  String _subjectOf(Map<String, dynamic> s) {
    final v = _pickStr(s, [
      'assignment.subject.name', 'assignment.subject.title',
      'subject.name', 'subject.title',
      'subject_name', 'subject',
      'course_name', 'title',
    ]);
    return v.isEmpty ? 'Môn học' : v;
  }

  String _classNameOf(Map<String, dynamic> s) {
    return _pickStr(s, [
      'assignment.class_unit.name', 'assignment.class_unit.code',
      'class_unit.name', 'class_unit.code',
      'class_name', 'class', 'class_code', 'group_name',
    ]);
  }

  String _cohortOf(Map<String, dynamic> s) {
    var c = _pickStr(s, ['cohort', 'k', 'course', 'batch']);
    if (c.isNotEmpty && !c.toUpperCase().startsWith('K')) c = 'K$c';
    return c;
  }

  /// Lấy "Phòng" robust theo bảng rooms (code/building) và các biến thể JSON
  String _roomOf(Map<String, dynamic> s) {
    // 1) Nếu có object room
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }

    // 2) Nếu room là chuỗi trực tiếp
    if (s['room'] is String && (s['room'] as String).trim().isNotEmpty) {
      return (s['room'] as String).trim();
    }

    // 3) Nếu room nằm trong assignment
    if (s['assignment'] is Map) {
      final a = s['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }

    // 4) Nếu trả dạng danh sách rooms/classrooms
    dynamic rooms = s['rooms'] ?? s['classrooms'] ?? s['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fromList = _pickStr(first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }

    // 5) Một số BE tách building + room_number
    final building = _pickStr(s, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
    if (num.isNotEmpty) return num;

    // 6) Không có
    return '';
  }

  String _dateIsoOf(Map<String, dynamic> s) {
    final raw = _pickStr(s, ['session_date', 'date', 'timeslot.date', 'period.date', 'start_at']);
    if (raw.isEmpty) return '';
    final only = raw.split(' ').first;
    try {
      final dt = DateTime.parse(only);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return only;
    }
  }

  String _hhmm(String raw) {
    if (raw.isEmpty) return '';
    final time = raw.contains(' ') ? raw.split(' ').last : raw;
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  String _startStrOf(Map<String, dynamic> s) {
    final raw = _pickStr(s, [
      'timeslot.start_time', 'timeslot.start',
      'start_time', 'startTime', 'slot.start',
    ]);
    return _hhmm(raw);
  }

  String _endStrOf(Map<String, dynamic> s) {
    final raw = _pickStr(s, [
      'timeslot.end_time', 'timeslot.end',
      'end_time', 'endTime', 'slot.end',
    ]);
    return _hhmm(raw);
  }

  String _dateVN(String yyyyMmDd) {
    if (yyyyMmDd.isEmpty) return '';
    try {
      final dt = DateTime.parse(yyyyMmDd);
      return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);
    } catch (_) {
      final p = yyyyMmDd.split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
      return yyyyMmDd;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final api = LecturerLeaveApi();
      final reason = _reasonController.text.trim();
      
      // Kiểm tra xem session này có phải là session đã được gộp không
      final groupedIds = widget.session['_grouped_session_ids'];
      List<int> scheduleIds;
      
      if (groupedIds is List) {
        // Lấy danh sách schedule_ids từ nhóm
        scheduleIds = groupedIds
            .map((e) => int.tryParse('$e'))
            .whereType<int>()
            .where((id) => id > 0)
            .toList();
      } else {
        // Chỉ có 1 session, lấy ID từ session hiện tại
        final id = int.tryParse('${widget.session['id']}') ?? 0;
        scheduleIds = id > 0 ? [id] : [];
      }
      
      if (scheduleIds.isEmpty) {
        throw Exception('Không tìm thấy buổi học hợp lệ');
      }

      // Submit đơn cho tất cả các schedule_id trong nhóm
      int successCount = 0;
      String? lastError;
      
      for (final scheduleId in scheduleIds) {
        try {
          await api.create({
            'schedule_id': scheduleId,
            'reason': reason,
          });
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (mounted) {
        if (successCount == scheduleIds.length) {
          // Không hiển thị SnackBar, chuyển thẳng đến history
          context.go('/leave/history');
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi $successCount/${scheduleIds.length} đơn. Lỗi: ${lastError ?? "Không xác định"}'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gửi đơn thất bại: ${lastError ?? "Không xác định"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi đơn thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;

    final subject   = _subjectOf(s);
    final className = _classNameOf(s);
    final cohort    = _cohortOf(s);

    // room inline (từ session) + room async (từ detail nếu cần)
    final roomInline = _roomOf(s);
    final room = roomInline.isNotEmpty ? roomInline : _roomAsync;

    final dateIso   = _dateIsoOf(s);
    final dateLabel = _dateVN(dateIso);
    final start     = _startStrOf(s);
    final end       = _endStrOf(s);

    final classLineParts = <String>[
      'Lớp: $className${cohort.isNotEmpty ? ' - $cohort' : ''}',
      if (room.isNotEmpty) 'Phòng: $room',
      if (_loadingRoom && roomInline.isEmpty) 'đang lấy phòng…',
    ];
    final classLine = classLineParts.join(' • ');

    return Scaffold(
      appBar: const TluAppBar(title: 'Đơn xin nghỉ'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card thông tin buổi học
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(classLine),
                    const SizedBox(height: 4),
                    Text('$dateLabel • $start - $end'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form lý do
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Lý do xin nghỉ',
                hintText: 'Nhập lý do (tối thiểu 10 ký tự)',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 10) return 'Lý do quá ngắn (tối thiểu 10 ký tự)';
                if (t.length > 500) return 'Lý do quá dài (tối đa 500 ký tự)';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              label: const Text('Gửi đơn'),
            ),
          ),
        ],
      ),
    );
  }
}
