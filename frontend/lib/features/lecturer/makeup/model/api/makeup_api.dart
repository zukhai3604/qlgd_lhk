import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class LecturerMakeupApi {
  final Dio _dio;

  LecturerMakeupApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  // ALWAYS return a mutable list
  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return []; // <<== not const
  }

  Future<List<Map<String, dynamic>>> list({String? status}) async {
    try {
      final res = await _dio.get(
        '/api/lecturer/makeup-requests',
        queryParameters: {if (status != null && status.isNotEmpty) 'status': status},
      );
      print('MakeupApi: Response status: ${res.statusCode}');
      print('MakeupApi: Response data type: ${res.data.runtimeType}');
      if (res.data is Map && (res.data as Map).containsKey('data')) {
        print('MakeupApi: Data array length: ${((res.data as Map)['data'] as List?)?.length ?? 0}');
        if (((res.data as Map)['data'] as List?)?.isNotEmpty == true) {
          print('MakeupApi: First item keys: ${((res.data as Map)['data'] as List).first.keys.toList()}');
        }
      }
      return _asList(res.data);
    } catch (e, stackTrace) {
      print('MakeupApi: Error in list(): $e');
      print('MakeupApi: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/lecturer/makeup-requests', data: payload);
    // Handle response format: could be {data: {...}} or direct {...}
    if (res.data is Map) {
      final data = Map<String, dynamic>.from(res.data);
      if (data.containsKey('data')) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> cancel(int id) async {
    try {
      print('DEBUG MakeupApi: cancel called for ID: $id');
      print('DEBUG MakeupApi: Making DELETE request to /api/lecturer/makeup-requests/$id');
      
      final response = await _dio.delete(
        '/api/lecturer/makeup-requests/$id',
        options: Options(
          validateStatus: (status) {
            // ✅ Chấp nhận cả 204 (No Content) và 200-299
            return status != null && status >= 200 && status < 300;
          },
        ),
      );
      
      print('DEBUG MakeupApi: cancel successful for ID: $id, statusCode: ${response.statusCode}');
      print('DEBUG MakeupApi: Response data: ${response.data}');
      
      // ✅ Response 204 (No Content) là thành công
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('DEBUG MakeupApi: Cancel successful (status ${response.statusCode})');
        return;
      }
    } on DioException catch (e) {
      print('DEBUG MakeupApi: DioException in cancel for ID $id');
      print('DEBUG MakeupApi: Exception type: ${e.type}');
      print('DEBUG MakeupApi: Response status: ${e.response?.statusCode}');
      print('DEBUG MakeupApi: Response data: ${e.response?.data}');
      print('DEBUG MakeupApi: Error message: ${e.message}');
      
      // ✅ Extract error message từ response
      String errorMessage = 'Không thể hủy đơn';
      
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
          print('DEBUG MakeupApi: Extracted error message from response: $errorMessage');
        } else if (e.response!.statusCode == 422) {
          errorMessage = 'Chỉ hủy được đề xuất còn PENDING';
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
      
      print('DEBUG MakeupApi: Throwing exception with message: $errorMessage');
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('DEBUG MakeupApi: Generic exception in cancel for ID $id: $e');
      print('DEBUG MakeupApi: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detail(int id) async {
    final res = await _dio.get('/api/lecturer/makeup-requests/$id');
    // Handle response format
    if (res.data is Map) {
      final data = Map<String, dynamic>.from(res.data);
      if (data.containsKey('data')) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Lấy danh sách đơn nghỉ đã được duyệt (APPROVED) để đăng ký dạy bù
  Future<List<Map<String, dynamic>>> approvedLeaves({int page = 1}) async {
    try {
      // Gọi API lấy danh sách leave requests với schedule relationship
      final r = await _dio.get(
        '/api/lecturer/leave-requests',
        queryParameters: {
          'status': 'APPROVED',
          'page': page,
        },
      );
      
      final list = _asList(r.data);
      
      // Lọc status APPROVED ở phía client để đảm bảo
      final approvedList = list.where((item) {
        final status = item['status']?.toString().toUpperCase();
        return status == 'APPROVED';
      }).toList();
      
      // Nếu schedule không có trong response, cần fetch từ schedule_id
      // (Backend đã include schedule, nhưng để robust hơn vẫn check)
      final enrichedList = <Map<String, dynamic>>[];
      for (final item in approvedList) {
        final enriched = Map<String, dynamic>.from(item);
        
        // Nếu chưa có schedule nhưng có schedule_id, cần fetch
        if (enriched['schedule'] == null && enriched['schedule_id'] != null) {
          try {
            final scheduleId = enriched['schedule_id'];
            final scheduleRes = await _dio.get('/api/lecturer/schedule/$scheduleId');
            final scheduleData = scheduleRes.data is Map 
                ? (scheduleRes.data['data'] ?? scheduleRes.data) 
                : scheduleRes.data;
            if (scheduleData is Map) {
              enriched['schedule'] = Map<String, dynamic>.from(scheduleData);
            }
          } catch (_) {
            // Bỏ qua nếu không fetch được schedule
          }
        }
        
        enrichedList.add(enriched);
      }
      
      return enrichedList;
    } catch (e) {
      // Nếu endpoint chính không hoạt động, trả về empty list
      return [];
    }
  }

  /// Lấy danh sách phòng học
  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final res = await _dio.get('/api/rooms');
      final list = _asList(res.data);
      return list;
    } catch (e) {
      rethrow; // Re-throw để frontend có thể handle và hiển thị lỗi
    }
  }

  /// Lấy timeslot_id từ day_of_week và period
  /// dayOfWeek: 1=Sun, 2=Mon, 3=Tue, ..., 7=Sat (Laravel format)
  /// period: 1-15 (số tiết)
  Future<int?> getTimeslotIdByPeriod(int dayOfWeek, int period) async {
    try {
      final res = await _dio.get(
        '/api/timeslots/by-period',
        queryParameters: {
          'day_of_week': dayOfWeek,
          'period': period,
        },
      );
      
      if (res.data is Map && res.data['data'] is Map) {
        return res.data['data']['id'] as int?;
      }
      return null;
    } catch (e) {
      // Log lỗi để debug
      print('Error getting timeslot by period: day_of_week=$dayOfWeek, period=$period, error=$e');
      return null;
    }
  }
}

