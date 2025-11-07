import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';

typedef ScheduleDetailResult<T> = Result<T, Exception>;

/// Repository cho schedule detail
abstract class ScheduleDetailRepository {
  Future<ScheduleDetailResult<Map<String, dynamic>>> getDetail(int id);
  Future<ScheduleDetailResult<List<Map<String, dynamic>>>> getMaterials(int id);
  Future<ScheduleDetailResult<void>> addMaterial(int sessionId, String title);
  Future<ScheduleDetailResult<void>> uploadMaterial(int sessionId, String title, String filePath);
  Future<ScheduleDetailResult<void>> deleteMaterial(int sessionId, int materialId);
  Future<ScheduleDetailResult<void>> submitReport({
    required int sessionId,
    String? status,
    String? note,
    String? content,
    String? issues,
    String? nextPlan,
  });
  Future<ScheduleDetailResult<bool>> hasAttendance(int sessionId);
  Future<ScheduleDetailResult<Map<String, dynamic>>> endLesson(int sessionId);
}

class ScheduleDetailRepositoryImpl implements ScheduleDetailRepository {
  final ScheduleApi _api;

  ScheduleDetailRepositoryImpl({ScheduleApi? api}) : _api = api ?? ScheduleApi();

  @override
  Future<ScheduleDetailResult<Map<String, dynamic>>> getDetail(int id) async {
    try {
      final detail = await _api.getDetail(id);
      return ScheduleDetailResult.success(detail);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không tải được chi tiết buổi học: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<List<Map<String, dynamic>>>> getMaterials(int id) async {
    try {
      final materials = await _api.listMaterials(id);
      return ScheduleDetailResult.success(materials);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không tải được tài liệu: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<void>> addMaterial(int sessionId, String title) async {
    try {
      await _api.addMaterial(sessionId, title);
      return const ScheduleDetailResult.success(null);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không thể thêm tài liệu: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<void>> uploadMaterial(int sessionId, String title, String filePath) async {
    try {
      await _api.uploadMaterial(sessionId, title, filePath);
      return const ScheduleDetailResult.success(null);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không thể upload tài liệu: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<void>> deleteMaterial(int sessionId, int materialId) async {
    try {
      await _api.deleteMaterial(sessionId, materialId);
      return const ScheduleDetailResult.success(null);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không thể xóa tài liệu: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<void>> submitReport({
    required int sessionId,
    String? status,
    String? note,
    String? content,
    String? issues,
    String? nextPlan,
  }) async {
    try {
      final response = await _api.submitReport(
        sessionId: sessionId,
        status: status,
        note: note,
        content: content,
        issues: issues,
        nextPlan: nextPlan,
      );
      print('DEBUG Repository submitReport: API call successful');
      return const ScheduleDetailResult.success(null);
    } catch (e) {
      print('DEBUG Repository submitReport: Exception - $e');
      return ScheduleDetailResult.failure(
        Exception('Không thể lưu báo cáo: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<bool>> hasAttendance(int sessionId) async {
    try {
      final hasAtt = await _api.hasAttendance(sessionId);
      return ScheduleDetailResult.success(hasAtt);
    } catch (e) {
      return ScheduleDetailResult.failure(
        Exception('Không thể kiểm tra điểm danh: $e'),
      );
    }
  }

  @override
  Future<ScheduleDetailResult<Map<String, dynamic>>> endLesson(int sessionId) async {
    try {
      print('DEBUG Repository endLesson: Calling API for session $sessionId');
      final result = await _api.endLesson(sessionId);
      print('DEBUG Repository endLesson: API call successful, result: $result');
      return ScheduleDetailResult.success(result);
    } catch (e) {
      // Giữ nguyên error message từ API layer
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('DEBUG Repository endLesson: Exception caught - $e');
      print('DEBUG Repository endLesson: Error message: $errorMessage');
      return ScheduleDetailResult.failure(
        Exception(errorMessage),
      );
    }
  }
}

