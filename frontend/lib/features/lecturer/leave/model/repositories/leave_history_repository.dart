import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/api/leave_api.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';
import 'package:qlgd_lhk/features/lecturer/leave/utils/leave_data_helpers.dart';

typedef LeaveHistoryResult<T> = Result<T, Exception>;

/// Repository cho leave history
abstract class LeaveHistoryRepository {
  Future<LeaveHistoryResult<List<Map<String, dynamic>>>> getLeaveRequests();
  Future<LeaveHistoryResult<void>> cancelLeaveRequest(int leaveRequestId);
  Future<LeaveHistoryResult<void>> cancelMultipleLeaveRequests(List<int> leaveRequestIds);
}

/// Implementation của LeaveHistoryRepository
class LeaveHistoryRepositoryImpl implements LeaveHistoryRepository {
  final LecturerLeaveApi _api;
  final ScheduleApi _scheduleApi;

  LeaveHistoryRepositoryImpl({
    LecturerLeaveApi? api,
    ScheduleApi? scheduleApi,
  })  : _api = api ?? LecturerLeaveApi(),
        _scheduleApi = scheduleApi ?? ScheduleApi();

  @override
  Future<LeaveHistoryResult<List<Map<String, dynamic>>>> getLeaveRequests() async {
    try {
      final leaves = await _api.list();
      final results = <Map<String, dynamic>>[];

      for (final lr in leaves) {
        final scheduleId = lr['schedule_id'];
        if (scheduleId == null) continue;

        Map<String, dynamic> sd = {};
        try {
          final raw = await _scheduleApi.getDetail(int.parse(scheduleId.toString()));
          sd = Map<String, dynamic>.from(raw);
        } catch (_) {
          // vẫn hiển thị phần đã có
        }

        // Gom dữ liệu hiển thị - sử dụng LeaveDataExtractor để đảm bảo tính nhất quán
        final subject = LeaveDataExtractor.extractSubject(sd);
        final className = LeaveDataExtractor.extractClassName(sd);
        final dateIso = LeaveDataExtractor.extractDate(sd);
        final timeRange = LeaveDataExtractor.extractTime(sd);
        final room = LeaveDataExtractor.extractRoom(sd);

        results.add({
          'leave_request_id': lr['id'],
          'status': (lr['status'] ?? 'UNKNOWN').toString(),
          'reason': (lr['reason'] ?? '').toString(),
          'note': (lr['note'] ?? '').toString(),
          'schedule_id': scheduleId,
          'subject': subject,
          'class_name': className,
          'date': dateIso,
          'start_time': timeRange.startTime,
          'end_time': timeRange.endTime,
          'room': room,
        });
      }

      return LeaveHistoryResult.success(results);
    } catch (e) {
      return LeaveHistoryResult.failure(Exception('Không tải được lịch sử xin nghỉ: $e'));
    }
  }

  @override
  Future<LeaveHistoryResult<void>> cancelLeaveRequest(int leaveRequestId) async {
    try {
      await _api.cancel(leaveRequestId);
      return LeaveHistoryResult.success(null);
    } catch (e) {
      return LeaveHistoryResult.failure(Exception('Không thể hủy đơn: $e'));
    }
  }

  @override
  Future<LeaveHistoryResult<void>> cancelMultipleLeaveRequests(List<int> leaveRequestIds) async {
    try {
      int successCount = 0;
      String? lastError;

      for (final leaveRequestId in leaveRequestIds) {
        try {
          await _api.cancel(leaveRequestId);
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (successCount == leaveRequestIds.length) {
        return LeaveHistoryResult.success(null);
      } else if (successCount > 0) {
        return LeaveHistoryResult.failure(
          Exception('Đã hủy $successCount/${leaveRequestIds.length} đơn. Lỗi: ${lastError ?? "Không xác định"}'),
        );
      } else {
        return LeaveHistoryResult.failure(
          Exception('Lỗi khi hủy: ${lastError ?? "Không xác định"}'),
        );
      }
    } catch (e) {
      return LeaveHistoryResult.failure(Exception('Không thể hủy đơn: $e'));
    }
  }

}

