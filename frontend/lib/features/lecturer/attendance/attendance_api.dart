import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class LecturerAttendanceApi {
  final Dio _dio = ApiClient().dio;

  /// Lấy danh sách điểm danh cho một buổi học
  /// Trả về danh sách đầy đủ sinh viên trong lớp, kể cả chưa điểm danh
  Future<List<Map<String, dynamic>>> getAttendance(int sessionId) async {
    try {
      final res = await _dio.get(
        '/api/lecturer/sessions/$sessionId/attendance',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (res.statusCode == null || res.statusCode! >= 400) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          message: 'Lỗi khi tải danh sách sinh viên: ${res.statusCode}',
        );
      }
      
      final data = res.data is Map ? res.data['data'] : res.data;
      final List list = data is List ? data : [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      // Log chi tiết lỗi để debug
      print('Attendance API Error: ${e.type}');
      print('Message: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');
      rethrow;
    } catch (e) {
      print('Unexpected error in getAttendance: $e');
      rethrow;
    }
  }

  /// Lưu điểm danh cho một buổi học
  /// records: [{student_id: int, status: 'PRESENT'|'ABSENT'|'LATE'|'EXCUSED', note: String?}]
  Future<List<Map<String, dynamic>>> saveAttendance(
    int sessionId,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final res = await _dio.post(
        '/api/lecturer/sessions/$sessionId/attendance',
        data: {'records': records},
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final data = res.data is Map ? res.data['data'] : res.data;
      final List list = data is List ? data : [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      print('Save Attendance API Error: ${e.type}');
      print('Message: ${e.message}');
      rethrow;
    }
  }
}

