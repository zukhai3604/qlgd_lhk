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
    try {
      print('DEBUG LeaveApi: cancel called for ID: $leaveRequestId');
      print('DEBUG LeaveApi: Making DELETE request to /api/lecturer/leave-requests/$leaveRequestId');
      
      // ✅ Thêm validateStatus để chấp nhận 204 No Content (giống makeup_api.dart)
      final response = await _dio.delete(
        '/api/lecturer/leave-requests/$leaveRequestId',
        options: Options(
          validateStatus: (status) {
            // ✅ Chấp nhận cả 204 (No Content) và 200-299
            return status != null && status >= 200 && status < 300;
          },
        ),
      );
      
      print('DEBUG LeaveApi: cancel successful for ID: $leaveRequestId, statusCode: ${response.statusCode}');
      print('DEBUG LeaveApi: Response data: ${response.data}');
      
      // ✅ Response 204 (No Content) là thành công
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('DEBUG LeaveApi: Cancel successful (status ${response.statusCode})');
        return;
      }
    } on DioException catch (e) {
      print('DEBUG LeaveApi: DioException in cancel for ID $leaveRequestId');
      print('DEBUG LeaveApi: Exception type: ${e.type}');
      print('DEBUG LeaveApi: Response status: ${e.response?.statusCode}');
      print('DEBUG LeaveApi: Response data: ${e.response?.data}');
      print('DEBUG LeaveApi: Error message: ${e.message}');
      
      // ✅ Extract error message từ response
      String errorMessage = 'Không thể hủy đơn';
      
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
          print('DEBUG LeaveApi: Extracted error message from response: $errorMessage');
        } else if (e.response!.statusCode == 422) {
          errorMessage = 'Chỉ hủy được đơn khi còn trạng thái PENDING';
        } else if (e.response!.statusCode == 403) {
          errorMessage = 'Không có quyền hủy đơn này';
        } else if (e.response!.statusCode == 404) {
          errorMessage = 'Không tìm thấy đơn để hủy';
        } else if (e.response!.statusCode != null) {
          errorMessage = 'Lỗi: ${e.response!.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Hết thời gian chờ. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      }
      
      print('DEBUG LeaveApi: Throwing exception with message: $errorMessage');
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('DEBUG LeaveApi: Generic exception in cancel for ID $leaveRequestId: $e');
      print('DEBUG LeaveApi: StackTrace: $stackTrace');
      rethrow;
    }
  }
}

