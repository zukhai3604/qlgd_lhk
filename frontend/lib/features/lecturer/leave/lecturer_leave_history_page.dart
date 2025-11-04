// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../schedule/service.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import '../leave/leave_api.dart';

class LecturerLeaveHistoryPage extends StatefulWidget {
  const LecturerLeaveHistoryPage({super.key});

  @override
  State<LecturerLeaveHistoryPage> createState() => _LecturerLeaveHistoryPageState();
}

class _LecturerLeaveHistoryPageState extends State<LecturerLeaveHistoryPage> {
  final _leaveApi = LecturerLeaveApi();
  final _scheduleSvc = LecturerScheduleService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _allItems = const []; // Lưu tất cả items để filter client-side
  String? _selectedStatus; // null = tất cả, 'PENDING', 'APPROVED', 'REJECTED', 'CANCELED'

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final leaves = await _leaveApi.list(); // [{id, schedule_id, status, reason, note, ...}]
      final results = <Map<String, dynamic>>[];

      for (final lr in leaves) {
        final scheduleId = lr['schedule_id'];
        if (scheduleId == null) continue;

        Map<String, dynamic> sd = {};
        try {
          final raw = await _scheduleSvc.getDetail(int.parse(scheduleId.toString()));
          sd = Map<String, dynamic>.from(raw);
        } catch (_) {
          // vẫn hiển thị phần đã có
        }

        // Gom dữ liệu hiển thị
        final subject = _subjectOf(sd, lr);
        final className = _classOf(sd, lr);
        final dateIso = _dateIsoOf(sd, lr);
        final start = _hhmm(_startOf(sd, lr));
        final end = _hhmm(_endOf(sd, lr));
        final room = _roomOf(sd, lr);

        results.add({
          'leave_request_id': lr['id'],
          'status': (lr['status'] ?? 'UNKNOWN').toString(),
          'reason': (lr['reason'] ?? '').toString(),
          'note': (lr['note'] ?? '').toString(),
          'schedule_id': scheduleId,
          'subject': subject,
          'class_name': className,
          'date': dateIso,
          'start_time': start,
          'end_time': end,
          'room': room,
        });
      }

      // Gộp các đơn liền kề nhau của cùng môn học
      final grouped = _groupConsecutiveLeaveRequests(results);

      // Lưu tất cả items để filter client-side
      _allItems = grouped;

      // Filter theo trạng thái nếu có
      _applyFilter();
      _error = null;
    } catch (e) {
      _error = 'Không tải được lịch sử xin nghỉ: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Gộp các đơn xin nghỉ liền kề nhau của cùng môn học thành 1 đơn
  List<Map<String, dynamic>> _groupConsecutiveLeaveRequests(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return [];

    // Sắp xếp theo ngày và thời gian bắt đầu
    final sorted = List<Map<String, dynamic>>.from(requests);
    sorted.sort((a, b) {
      final dateA = (a['date'] ?? '').toString();
      final dateB = (b['date'] ?? '').toString();
      if (dateA != dateB) return dateA.compareTo(dateB);

      final startA = (a['start_time'] ?? '--:--').toString();
      final startB = (b['start_time'] ?? '--:--').toString();
      if (startA == '--:--' && startB == '--:--') return 0;
      if (startA == '--:--') return 1;
      if (startB == '--:--') return -1;
      return startA.compareTo(startB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = (current['subject'] ?? '').toString();
      final className = (current['class_name'] ?? '').toString();
      final room = (current['room'] ?? '').toString();
      final date = (current['date'] ?? '').toString();
      final status = (current['status'] ?? '').toString();

      // Tìm các đơn liền kề có cùng subject, class, room, date, status
      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject = (next['subject'] ?? '').toString();
        final nextClassName = (next['class_name'] ?? '').toString();
        final nextRoom = (next['room'] ?? '').toString();
        final nextDate = (next['date'] ?? '').toString();
        final nextStatus = (next['status'] ?? '').toString();

        // Kiểm tra cùng môn, lớp, phòng, ngày, status
        if (subject != nextSubject ||
            className != nextClassName ||
            room != nextRoom ||
            date != nextDate ||
            status != nextStatus) {
          break;
        }

        // Kiểm tra liền kề (end_time của đơn trước gần start_time của đơn sau <= 10 phút)
        final lastEnd = _parseTimeToMinutes((group.last['end_time'] ?? '--:--').toString());
        final nextStart = _parseTimeToMinutes((next['start_time'] ?? '--:--').toString());

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

      // Nếu chỉ có 1 đơn, giữ nguyên
      if (group.length == 1) {
        result.add(current);
      } else {
        // Gộp thành 1 đơn: lấy start_time từ đơn đầu, end_time từ đơn cuối
        final first = group.first;
        final last = group.last;

        final merged = Map<String, dynamic>.from(first);

        // Lấy start_time từ đơn đầu
        final startTime = (first['start_time'] ?? '--:--').toString();

        // Lấy end_time từ đơn cuối
        final endTime = (last['end_time'] ?? '--:--').toString();

        // Cập nhật thời gian
        merged['start_time'] = startTime;
        merged['end_time'] = endTime;

        // Lưu danh sách các leave_request_ids để có thể xử lý khi cần
        final leaveRequestIds = group
            .map((r) {
              final id = r['leave_request_id'];
              return id != null ? int.tryParse('$id') : null;
            })
            .whereType<int>()
            .toList();
        merged['_grouped_leave_request_ids'] = leaveRequestIds;

        // Lưu danh sách schedule_ids
        final scheduleIds = group
            .map((r) {
              final id = r['schedule_id'];
              return id != null ? int.tryParse('$id') : null;
            })
            .whereType<int>()
            .toList();
        merged['_grouped_schedule_ids'] = scheduleIds;

        result.add(merged);
      }
    }

    return result;
  }

  /// Parse thời gian HH:mm thành số phút (ví dụ: "15:40" -> 940)
  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  Future<void> _handleTap(Map<String, dynamic> item) async {
    final status = item['status']?.toString().toUpperCase();

    // Hiển thị chi tiết đơn xin nghỉ cho tất cả status
    if (!mounted) return;

    final statusInfo = _getStatus(status ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chi tiết đơn xin nghỉ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Chip(
                    label: Text(statusInfo.label),
                    backgroundColor: statusInfo.color.withOpacity(0.15),
                    side: BorderSide(color: statusInfo.color),
                    labelStyle: TextStyle(color: statusInfo.color, fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Thông tin buổi học:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if ((item['subject'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Môn: ${item['subject']}'),
                ),
              if ((item['class_name'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Lớp: ${item['class_name']}'),
                ),
              if ((item['date'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Ngày: ${_toDDMMYYYY(item['date']?.toString())}'),
                ),
              if ((item['start_time'] ?? '').toString().isNotEmpty &&
                  (item['end_time'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Giờ: ${item['start_time']} - ${item['end_time']}'),
                ),
              if ((item['room'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Phòng: ${item['room']}'),
                ),
              const SizedBox(height: 16),
              if ((item['reason'] ?? '').toString().isNotEmpty) ...[
                const Text('Lý do xin nghỉ:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  item['reason'].toString(),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              if (status == 'REJECTED' && (item['note'] ?? '').toString().isNotEmpty) ...[
                const Text('Lý do từ chối:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                const SizedBox(height: 8),
                Text(
                  item['note'].toString(),
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
                ),
              ],
              if (status == 'APPROVED') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn đã được duyệt. Bạn có thể đăng ký dạy bù tại trang "Đăng ký dạy bù".',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (status == 'PENDING')
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showCancelDialog(item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hủy đơn'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(Map<String, dynamic> item) async {
    if (!mounted) return;

    // Kiểm tra xem có phải đơn đã gộp không
    final groupedIds = item['_grouped_leave_request_ids'];
    final List<int> leaveRequestIds;

    if (groupedIds is List && groupedIds.isNotEmpty) {
      leaveRequestIds = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    } else {
      final id = item['leave_request_id'];
      leaveRequestIds =
          id != null && int.tryParse('$id') != null ? [int.parse('$id')] : [];
    }

    if (leaveRequestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đơn để hủy')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn xin nghỉ?'),
        content: Text(
          leaveRequestIds.length > 1
              ? 'Bạn có muốn hủy ${leaveRequestIds.length} đơn xin nghỉ liền kề này không?'
              : 'Đơn này đang chờ duyệt. Bạn có muốn hủy không?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        // Hủy tất cả các đơn trong nhóm
        int successCount = 0;
        String? lastError;

        for (final leaveRequestId in leaveRequestIds) {
          try {
            await _leaveApi.cancel(leaveRequestId);
            successCount++;
          } catch (e) {
            lastError = e.toString();
          }
        }

        if (!mounted) return;

        if (successCount == leaveRequestIds.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                leaveRequestIds.length > 1
                    ? 'Đã hủy ${leaveRequestIds.length} đơn xin nghỉ.'
                    : 'Đã hủy đơn xin nghỉ.',
              ),
            ),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã hủy $successCount/${leaveRequestIds.length} đơn. Lỗi: ${lastError ?? "Không xác định"}'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi hủy: ${lastError ?? "Không xác định"}')),
          );
        }

        _fetch();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi hủy: $e')),
        );
      }
    }
  }

  String _toDDMMYYYY(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso.split(' ').first);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TluAppBar(title: 'Lịch sử xin nghỉ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(message: _error!, onRetry: _fetch)
              : Column(
                  children: [
                    // Filter bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tất cả', null),
                            const SizedBox(width: 8),
                            _buildFilterChip('Chờ duyệt', 'PENDING'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Đã duyệt', 'APPROVED'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Từ chối', 'REJECTED'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Đã hủy', 'CANCELED'),
                          ],
                        ),
                      ),
                    ),
                    // List content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetch,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Danh sách các đơn xin nghỉ đã gửi. Nhấn vào đơn để xem chi tiết.',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            Expanded(
                              child: _items.isEmpty
                                  ? const _EmptyBox()
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      itemCount: _items.length,
                                      itemBuilder: (context, i) {
                                        final item = _items[i];
                                        final subject =
                                            (item['subject'] ?? 'Môn học').toString();
                                        final className =
                                            (item['class_name'] ?? '').toString();
                                        final date =
                                            _toDDMMYYYY(item['date']?.toString());
                                        final start =
                                            (item['start_time'] ?? '--:--').toString();
                                        final end =
                                            (item['end_time'] ?? '--:--').toString();
                                        final room =
                                            (item['room'] ?? '').toString();

                                        final pieces = <String>[];
                                        if (className.isNotEmpty) {
                                          pieces.add('Lớp: $className');
                                        }
                                        if (date.isNotEmpty) pieces.add(date);
                                        pieces.add('$start - $end');
                                        if (room.isNotEmpty) pieces.add('Phòng: $room');
                                        final dateLine = pieces.join(' · ');

                                        final status =
                                            _getStatus(item['status']?.toString() ?? '');

                                        return Card(
                                          elevation: 1,
                                          margin: const EdgeInsets.only(bottom: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: status.color.withOpacity(0.5),
                                            ),
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              subject,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            subtitle: Text(dateLine),
                                            trailing: Chip(
                                              label: Text(
                                                status.label,
                                                style:
                                                    const TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor:
                                                  status.color.withOpacity(0.15),
                                              side: BorderSide.none,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onTap: () => _handleTap(item),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ================== Robust extractors ==================

  /// Lấy chuỗi theo danh sách đường dẫn (hỗ trợ "a.b.c")
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

  String _subjectOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    return _pickStr(sd, [
      'assignment.subject.name',
      'assignment.subject.title',
      'assignment.subject.code',
      'subject.name',
      'subject.title',
      'subject.code',
      'subject',
    ]).ifEmpty(_pickStr(lr, ['subject'])).ifEmpty('Môn học');
  }

  /// Mở rộng alias để bắt đủ tên lớp/nhóm
  String _classOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    // từ detail (ưu tiên)
    final fromDetail = _pickStr(sd, [
      'assignment.class_unit.name',
      'assignment.class_unit.code',
      'assignment.classUnit.name',
      'assignment.classUnit.code',
      'class_unit.name',
      'class_unit.code',
      'class.name',
      'class.code',
      'group_name',
      'group.code',
      'group.name',
      'className',
      'class',
    ]);
    if (fromDetail.isNotEmpty) return fromDetail;

    // fallback từ leave request
    final fromLeave = _pickStr(lr, [
      'class_name',
      'class',
      'group_name',
      'group',
    ]);
    return fromLeave;
  }

  /// Lấy phòng (nhiều biến thể)
  String _roomOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    if (sd['room'] is Map) {
      final r = sd['room'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    if (sd['room'] is String && (sd['room'] as String).trim().isNotEmpty) {
      return (sd['room'] as String).trim();
    }
    if (sd['assignment'] is Map) {
      final a = sd['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }
    dynamic rooms = sd['rooms'] ?? sd['classrooms'] ?? sd['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fromList = _pickStr(first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }
    final building = _pickStr(sd, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(sd, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
    if (num.isNotEmpty) return num;

    final fromLr = _pickStr(lr, ['room', 'room_code', 'roomName']);
    if (fromLr.isNotEmpty) return fromLr;

    return '';
  }

  /// Chuẩn hóa ngày ISO (yyyy-MM-dd)
  String _dateIsoOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    final raw = _pickStr(sd, [
      'session_date',
      'date',
      'start_at',
      'startDate',
      'timeslot.date',
      'period.date',
    ]).ifEmpty(_pickStr(lr, ['date', 'session_date']));

    if (raw.isEmpty) return '';
    final only = raw.split(' ').first;
    try {
      final dt = DateTime.parse(only);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return only;
    }
  }

  String _startOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    return _pickStr(sd, [
      'start_time',
      'startTime',
      'timeslot.start_time',
      'timeslot.start',
      'period.start',
      'slot.start',
    ]).ifEmpty(_pickStr(lr, ['start_time', 'startTime']));
  }

  String _endOf(Map<String, dynamic> sd, Map<String, dynamic> lr) {
    return _pickStr(sd, [
      'end_time',
      'endTime',
      'timeslot.end_time',
      'timeslot.end',
      'period.end',
      'slot.end',
    ]).ifEmpty(_pickStr(lr, ['end_time', 'endTime']));
  }

  String _hhmm(String raw) {
    if (raw.isEmpty) return '--:--';
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

  // ================== UI helpers ==================

  _StatusInfo _getStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const _StatusInfo('Đã duyệt', Colors.green);
      case 'REJECTED':
        return const _StatusInfo('Từ chối', Colors.red);
      case 'PENDING':
        return const _StatusInfo('Chờ duyệt', Colors.orange);
      case 'CANCELED':
        return const _StatusInfo('Đã hủy', Colors.grey);
      default:
        return _StatusInfo(status, Colors.blueGrey);
    }
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _selectedStatus = selected ? status : null;
        _applyFilter();
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  void _applyFilter() {
    if (_allItems.isEmpty) {
      _items = _allItems;
      return;
    }

    setState(() {
      if (_selectedStatus == null) {
        _items = _allItems;
      } else {
        _items = _allItems.where((item) {
          final status =
              (item['status'] ?? 'PENDING').toString().toUpperCase();
          return status == _selectedStatus!.toUpperCase();
        }).toList();
      }
    });
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}

extension _EmptyStr on String {
  String ifEmpty(String alt) => isEmpty ? alt : this;
}

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
          const SizedBox(height: 8),
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
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Bạn chưa gửi đơn xin nghỉ nào.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
