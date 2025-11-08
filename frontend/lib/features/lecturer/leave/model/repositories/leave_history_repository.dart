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

        // ✅ Lấy class_code riêng từ schedule detail
        String? classCode;
        if (sd['class_code'] != null) {
          classCode = sd['class_code'].toString();
        } else if (sd['class_unit'] is Map) {
          final cu = sd['class_unit'] as Map;
          classCode = (cu['code'] ?? cu['class_code'])?.toString();
        } else if (sd['classUnit'] is Map) {
          final cu = sd['classUnit'] as Map;
          classCode = (cu['code'] ?? cu['class_code'])?.toString();
        } else if (sd['assignment'] is Map) {
          final assignment = sd['assignment'] as Map;
          final cu = assignment['class_unit'] ?? assignment['classUnit'];
          if (cu is Map) {
            classCode = (cu['code'] ?? cu['class_code'])?.toString();
          }
        }

        results.add({
          'leave_request_id': lr['id'],
          'status': (lr['status'] ?? 'UNKNOWN').toString(),
          'reason': (lr['reason'] ?? '').toString(),
          'note': (lr['note'] ?? '').toString(),
          'schedule_id': scheduleId,
          'subject': subject,
          'class_name': classCode ?? className, // ✅ Ưu tiên class_code nếu có
          'class_code': classCode, // ✅ Thêm class_code riêng
          'date': dateIso,
          'start_time': timeRange.startTime,
          'end_time': timeRange.endTime,
          'room': room,
          // ✅ Giữ lại nested structure để view có thể extract
          'assignment': sd['assignment'],
          'class_unit': sd['class_unit'] ?? sd['classUnit'],
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
      print('DEBUG LeaveHistoryRepository: cancelLeaveRequest called for ID: $leaveRequestId');
      await _api.cancel(leaveRequestId);
      print('DEBUG LeaveHistoryRepository: cancelLeaveRequest successful for ID: $leaveRequestId');
      return LeaveHistoryResult.success(null);
    } catch (e, stackTrace) {
      print('DEBUG LeaveHistoryRepository: cancelLeaveRequest failed for ID $leaveRequestId: $e');
      print('DEBUG LeaveHistoryRepository: StackTrace: $stackTrace');
      // ✅ Giữ nguyên error message từ API (đã được extract)
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      return LeaveHistoryResult.failure(Exception(errorMsg));
    }
  }

  @override
  Future<LeaveHistoryResult<void>> cancelMultipleLeaveRequests(List<int> leaveRequestIds) async {
    try {
      print('DEBUG LeaveHistoryRepository: cancelMultipleLeaveRequests called with IDs: $leaveRequestIds');
      int successCount = 0;
      String? lastError;

      for (final leaveRequestId in leaveRequestIds) {
        try {
          print('DEBUG LeaveHistoryRepository: Canceling leave request ID: $leaveRequestId');
          await _api.cancel(leaveRequestId);
          print('DEBUG LeaveHistoryRepository: Successfully canceled leave request ID: $leaveRequestId');
          successCount++;
        } catch (e, stackTrace) {
          // ✅ Extract error message từ exception
          print('DEBUG LeaveHistoryRepository: Error canceling leave request ID $leaveRequestId: $e');
          print('DEBUG LeaveHistoryRepository: StackTrace: $stackTrace');
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          lastError = errorMsg;
        }
      }

      print('DEBUG LeaveHistoryRepository: cancelMultipleLeaveRequests result: successCount=$successCount/${leaveRequestIds.length}, lastError=$lastError');

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
    } catch (e, stackTrace) {
      // ✅ Giữ nguyên error message từ API
      print('DEBUG LeaveHistoryRepository: cancelMultipleLeaveRequests outer catch: $e');
      print('DEBUG LeaveHistoryRepository: StackTrace: $stackTrace');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      return LeaveHistoryResult.failure(Exception(errorMsg));
    }
  }

}

