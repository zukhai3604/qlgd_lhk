import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class LecturerScheduleService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getWeek({String? date}) async {
    final res = await _dio.get(
      '/api/lecturer/schedule/week',
      queryParameters: { if (date != null) 'date': date },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getDetail(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id');
    final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listMaterials(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id/materials');
    final List list = (res.data is Map ? res.data['data'] ?? [] : res.data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> submitReport(
      int id, {
        required String content,
        String? issues,
        String? nextPlan,
      }) async {
    await _dio.post('/api/lecturer/schedule/$id/report', data: {
      'content': content,
      if (issues != null) 'issues': issues,
      if (nextPlan != null) 'next_plan': nextPlan,
    });
  }
}
