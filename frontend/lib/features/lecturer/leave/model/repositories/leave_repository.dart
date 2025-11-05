import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/api/leave_api.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';

typedef LeaveResult<T> = Result<T, Exception>;

/// Repository cho leave operations
abstract class LeaveRepository {
  Future<LeaveResult<void>> createLeaveRequest({
    required int scheduleId,
    required String reason,
  });
  
  Future<LeaveResult<void>> createMultipleLeaveRequests({
    required List<int> scheduleIds,
    required String reason,
  });
  
  Future<LeaveResult<Map<String, dynamic>>> getSessionDetail(int sessionId);
}

/// Implementation của LeaveRepository
class LeaveRepositoryImpl implements LeaveRepository {
  final LecturerLeaveApi _api;
  final ScheduleApi _scheduleApi;

  LeaveRepositoryImpl({
    LecturerLeaveApi? api,
    ScheduleApi? scheduleApi,
  })  : _api = api ?? LecturerLeaveApi(),
        _scheduleApi = scheduleApi ?? ScheduleApi();

  @override
  Future<LeaveResult<void>> createLeaveRequest({
    required int scheduleId,
    required String reason,
  }) async {
    try {
      await _api.create({
        'schedule_id': scheduleId,
        'reason': reason,
      });
      return LeaveResult.success(null);
    } catch (e) {
      return LeaveResult.failure(Exception('Không thể tạo đơn xin nghỉ: $e'));
    }
  }

  @override
  Future<LeaveResult<void>> createMultipleLeaveRequests({
    required List<int> scheduleIds,
    required String reason,
  }) async {
    try {
      int successCount = 0;
      String? lastError;
      
      for (final scheduleId in scheduleIds) {
        try {
          await _api.create({
            'schedule_id': scheduleId,
            'reason': reason,
          });
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }
      
      if (successCount == scheduleIds.length) {
        return LeaveResult.success(null);
      } else if (successCount > 0) {
        return LeaveResult.failure(
          Exception('Đã gửi $successCount/${scheduleIds.length} đơn. Lỗi: ${lastError ?? "Không xác định"}'),
        );
      } else {
        return LeaveResult.failure(
          Exception('Gửi đơn thất bại: ${lastError ?? "Không xác định"}'),
        );
      }
    } catch (e) {
      return LeaveResult.failure(Exception('Không thể tạo đơn xin nghỉ: $e'));
    }
  }

  @override
  Future<LeaveResult<Map<String, dynamic>>> getSessionDetail(int sessionId) async {
    try {
      final detail = await _scheduleApi.getDetail(sessionId);
      return LeaveResult.success(detail);
    } catch (e) {
      return LeaveResult.failure(Exception('Không thể tải thông tin buổi học: $e'));
    }
  }
}

