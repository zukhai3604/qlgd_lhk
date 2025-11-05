import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class LecturerLeaveApi {
  LecturerLeaveApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio; 

  Future<List<Map<String, dynamic>>> list({String? status, int page = 1}) async {
    final res = await _dio.get(
      '/api/lecturer/leave-requests',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
      },
    );
    final data = res.data;
    final List raw = data is Map ? (data['data'] ?? const []) : (data as List? ?? const []);
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/lecturer/leave-requests', data: data);
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  Future<void> cancel(int leaveRequestId) async {
    await _dio.delete('/api/lecturer/leave-requests/$leaveRequestId');
  }
}

