import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class LecturerService {
  final Dio _dio = ApiClient().dio;

  // 1) Hồ sơ
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/api/lecturer/profile');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return Map<String, dynamic>.from(data);
  }

  // 2) Lịch tuần
  Future<Map<String, dynamic>> getWeekSchedule({String? date}) async {
    final res = await _dio.get('/api/lecturer/schedule/week', queryParameters: {
      if (date != null) 'date': date,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // 3) Chi tiết buổi
  Future<Map<String, dynamic>> getScheduleDetail(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return Map<String, dynamic>.from(data);
  }

  // 4) Nộp báo cáo
  Future<void> submitReport(int scheduleId, {
    required String content,
    String? issues,
    String? nextPlan,
  }) async {
    await _dio.post('/api/lecturer/schedule/$scheduleId/report', data: {
      'content': content,
      if (issues != null) 'issues': issues,
      if (nextPlan != null) 'next_plan': nextPlan,
    });
  }

  // 5) Upload tài liệu
  Future<Map<String, dynamic>> uploadMaterial(int scheduleId, {
    required String title,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/api/lecturer/schedule/$scheduleId/materials', data: form);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return Map<String, dynamic>.from(data);
  }

  // 6) Danh sách tài liệu
  Future<List<Map<String, dynamic>>> listMaterials(int scheduleId) async {
    final res = await _dio.get('/api/lecturer/schedule/$scheduleId/materials');
    final List list = (res.data is Map ? res.data['data'] ?? [] : res.data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 7) Điểm danh bulk (tuỳ cần)
  Future<void> saveAttendanceBulk({
    required int scheduleId,
    required List<Map<String, dynamic>> items, // [{student_id: 1, status: 'PRESENT', note: '...'}, ...]
  }) async {
    await _dio.post('/api/lecturer/attendance/records/bulk', data: {
      'schedule_id': scheduleId,
      'items': items,
    });
  }
}
