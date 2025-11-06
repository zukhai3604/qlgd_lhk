import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/api/leave_api.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';

typedef LeaveChooseSessionResult<T> = Result<T, Exception>;

/// Repository cho leave choose session
abstract class LeaveChooseSessionRepository {
  Future<LeaveChooseSessionResult<List<Map<String, dynamic>>>> getAvailableSessions();
}

/// Implementation của LeaveChooseSessionRepository
class LeaveChooseSessionRepositoryImpl implements LeaveChooseSessionRepository {
  final LecturerLeaveApi _leaveApi;
  final ScheduleApi _scheduleApi;

  LeaveChooseSessionRepositoryImpl({
    LecturerLeaveApi? leaveApi,
    ScheduleApi? scheduleApi,
  })  : _leaveApi = leaveApi ?? LecturerLeaveApi(),
        _scheduleApi = scheduleApi ?? ScheduleApi();

  @override
  Future<LeaveChooseSessionResult<List<Map<String, dynamic>>>> getAvailableSessions() async {
    try {
      // Lấy các buổi sắp tới (30 ngày)
      final all = await _scheduleApi.listUpcomingSessions(
        from: DateTime.now(),
        to: DateTime.now().add(const Duration(days: 30)),
      );

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
            final isPlanned = (s['status']?.toString().toUpperCase() == 'PLANNED');
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

      // Enrich rooms cho những item chưa có phòng
      await _enrichMissingRooms(upcoming);

      return LeaveChooseSessionResult.success(upcoming);
    } catch (e) {
      return LeaveChooseSessionResult.failure(Exception('Không tải được danh sách buổi dạy: $e'));
    }
  }

  Future<void> _enrichMissingRooms(List<Map<String, dynamic>> list) async {
    final needIds = <int>[];
    for (final s in list) {
      if (_roomOf(s).isEmpty) {
        final id = int.tryParse('${s['id']}');
        if (id != null && id > 0) needIds.add(id);
      }
    }
    if (needIds.isEmpty) return;

    for (final id in needIds) {
      try {
        final detail = await _scheduleApi.getDetail(id);
        final idx = list.indexWhere((e) => int.tryParse('${e['id']}') == id);
        if (idx != -1) {
          final merged = {...list[idx], ...Map<String, dynamic>.from(detail)};
          list[idx] = merged;
        }
      } catch (_) {
        // bỏ qua nếu fetch lỗi
      }
    }
  }

  String _dateIsoOf(Map<String, dynamic> s) {
    final raw = (s['date'] ?? s['session_date'] ?? '').toString();
    if (raw.isEmpty) return '';
    return raw.split(' ').first;
  }

  String _startOfStr(Map<String, dynamic> s) {
    final raw = (s['start_time'] ?? s['timeslot']?['start_time'] ?? '').toString();
    if (raw.isEmpty) return '';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _roomOf(Map<String, dynamic> s) {
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = r['code']?.toString() ?? r['name']?.toString() ?? '';
      if (code.isNotEmpty) return code.trim();
    }
    if (s['room'] is String) return (s['room'] as String).trim();
    return '';
  }
}

