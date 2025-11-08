import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class ScheduleApi {
  final Dio _dio;

  ScheduleApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  // ===== Week =====
  Future<Map<String, dynamic>> getWeek({String? date}) async {
    final res = await _dio.get(
      '/api/lecturer/schedule/week',
      queryParameters: {if (date != null) 'date': date},
    );

    final raw = res.data;
    List list;
    if (raw is Map && raw['data'] is List) {
      list = List.from(raw['data'] as List);
    } else if (raw is List) {
      list = List.from(raw);
    } else if (raw is Map) {
      // single object ? wrap
      list = [raw];
    } else {
      throw Exception('Unexpected response type for week schedule');
    }

    String? onlyDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      return s.contains(' ') ? s.split(' ').first : s;
    }

    String? hhmm(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    String roomLabel(dynamic value) {
      if (value is Map) {
        final code = value['code']?.toString();
        final name = value['name']?.toString();
        if (code != null && code.isNotEmpty) return code;
        return name ?? '';
      }
      return value?.toString() ?? '';
    }

    // Normalize to flat shape expected by UI
    final normalized = list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final asg = m['assignment'] is Map ? Map.of(m['assignment']) : null;
      final subj = asg?['subject'] is Map
          ? Map.of(asg!['subject'])
          : (m['subject'] is Map ? Map.of(m['subject']) : null);
      final cu = asg?['classUnit'] is Map
          ? Map.of(asg!['classUnit'])
          : (m['classUnit'] is Map ? Map.of(m['classUnit']) : null);
      final ts = m['timeslot'] is Map ? Map.of(m['timeslot']) : null;

      final date = onlyDate(m['date'] ?? m['session_date'] ?? m['sessionDate']);
      final start = hhmm(m['start_time'] ?? ts?['start_time']);
      final end = hhmm(m['end_time'] ?? ts?['end_time']);
      final room = roomLabel(m['room']);

      return <String, dynamic>{
        'id': m['id'],
        'date': date,
        'session_date': m['session_date'] ?? date, // Giữ lại session_date gốc
        'subject':
            m['subject']?.toString() ?? subj?['name'] ?? subj?['code'] ?? '',
        // ✅ Ưu tiên code trước name để hiển thị mã lớp
        'class_name':
            m['class_name']?.toString() ?? cu?['code'] ?? cu?['class_code'] ?? cu?['name'] ?? '',
        'class_code': cu?['code'] ?? cu?['class_code'] ?? '', // ✅ Thêm class_code riêng
        'room': room,
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'PLANNED',
        // ✅ Giữ lại nested structure để extract có thể dùng
        'assignment': asg,
      };
    }).toList();

    return {'data': normalized};
  }

  // ===== Schedule list with filters =====
  Future<Map<String, dynamic>> getSchedule({
    String? semesterId,
    String? weekValue,
  }) async {
    final params = <String, dynamic>{};
    if (semesterId != null && semesterId.isNotEmpty) {
      params['semester_id'] = semesterId;
    }
    if (weekValue != null && weekValue.isNotEmpty) {
      params['week'] = weekValue;
    }

    final res = await _dio.get(
      '/api/lecturer/schedule',
      queryParameters: params,
    );
    return Map<String, dynamic>.from(res.data);
  }

  // ===== Detail =====
  Future<Map<String, dynamic>> getDetail(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id');
    final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    return Map<String, dynamic>.from(data);
  }

  // ===== List canceled sessions (for makeup) =====
  Future<List<Map<String, dynamic>>> listCanceledSessions({
    String? from,
    String? to,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/lecturer/sessions',
      queryParameters: {
        'status': 'CANCELED',
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        'page': page,
      },
    );

    final src = res.data;
    final List raw = src is Map ? (src['data'] ?? const []) : (src as List? ?? const []);

    String? onlyDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.contains(' ') ? s.split(' ').first : s;
    }

    String? hhmm(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    String roomLabel(dynamic value) {
      if (value is Map) {
        final code = value['code']?.toString();
        final name = value['name']?.toString();
        if (code != null && code.isNotEmpty) return code;
        return name ?? '';
      }
      return value?.toString() ?? '';
    }

    return raw.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final subj = m['subject'] is Map ? Map<String, dynamic>.from(m['subject']) : null;
      final cu = m['class_unit'] is Map ? Map<String, dynamic>.from(m['class_unit']) : null;
      final timeslot = m['timeslot'] is Map ? Map<String, dynamic>.from(m['timeslot']) : null;

      final date = onlyDate(m['date'] ?? m['session_date']);
      final start = hhmm(m['start_time'] ?? timeslot?['start_time']);
      final end = hhmm(m['end_time'] ?? timeslot?['end_time']);

      return <String, dynamic>{
        'id': m['id'],
        'date': date,
        'session_date': m['session_date'] ?? date, // Giữ lại session_date gốc
        'subject': subj?['name'] ?? subj?['code'] ?? m['subject']?.toString() ?? '',
        // ✅ Ưu tiên code trước name để hiển thị mã lớp
        'class_name': cu?['code'] ?? cu?['class_code'] ?? cu?['name'] ?? '',
        'class_code': cu?['code'] ?? cu?['class_code'] ?? '', // ✅ Thêm class_code riêng
        'room': roomLabel(m['room']),
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'CANCELED',
        'note': m['note'],
        // ✅ Giữ lại nested structure để extract có thể dùng
        'class_unit': cu,
        'timeslot': timeslot,
      };
    }).toList();
  }

  // ===== Materials =====
  Future<List<Map<String, dynamic>>> listMaterials(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id/materials');
    final List list =
        (res.data is Map ? res.data['data'] ?? [] : res.data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addMaterial(int sessionId, String title) async {
    await _dio.post('/api/lecturer/schedule/$sessionId/materials', data: {
      'title': title,
    });
  }

  /// Upload material với file
  Future<void> uploadMaterial(int sessionId, String title, String filePath) async {
    final formData = FormData.fromMap({
      'title': title,
      'file': await MultipartFile.fromFile(filePath),
    });
    await _dio.post('/api/lecturer/schedule/$sessionId/materials', data: formData);
  }

  /// Xóa material
  Future<void> deleteMaterial(int sessionId, int materialId) async {
    await _dio.delete('/api/lecturer/schedule/$sessionId/materials/$materialId');
  }

  // ===== Report =====
  Future<void> submitReport({
    required int sessionId,
    String? status,
    String? note,
    String? content,
    String? issues,
    String? nextPlan,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    // Luôn gửi note nếu được truyền vào (kể cả rỗng) để backend có thể cập nhật/xóa
    if (note != null) {
      body['note'] = note.trim();
      print('DEBUG API submitReport: Sending note="${note.trim()}"');
    } else {
      print('DEBUG API submitReport: note is null, not sending');
    }
    if (content != null && content.trim().isNotEmpty) {
      body['content'] = content.trim();
    }
    if (issues != null && issues.trim().isNotEmpty) {
      body['issues'] = issues.trim();
    }
    if (nextPlan != null && nextPlan.trim().isNotEmpty) {
      body['next_plan'] = nextPlan.trim();
    }
    print('DEBUG API submitReport: Request body=$body');
    try {
      final response = await _dio.post('/api/lecturer/schedule/$sessionId/report', data: body);
      print('DEBUG API submitReport: Response status=${response.statusCode}');
      print('DEBUG API submitReport: Response headers=${response.headers}');
      print('DEBUG API submitReport: Response data type=${response.data.runtimeType}');
      print('DEBUG API submitReport: Response data=$response.data');
      print('DEBUG API submitReport: Response data.toString()=${response.data.toString()}');
      
      // Kiểm tra xem response.data có null hoặc empty không
      if (response.data == null) {
        print('DEBUG API submitReport: WARNING - response.data is NULL');
      } else if (response.data is Map && (response.data as Map).isEmpty) {
        print('DEBUG API submitReport: WARNING - response.data is empty Map');
      } else if (response.data is String && (response.data as String).isEmpty) {
        print('DEBUG API submitReport: WARNING - response.data is empty String');
      }
      
      return;
    } on DioException catch (e) {
      print('DEBUG API submitReport: DioException - ${e.response?.statusCode}');
      print('DEBUG API submitReport: Response data=${e.response?.data}');
      rethrow;
    }
  }

  // ===== Check attendance =====
  Future<bool> hasAttendance(int sessionId) async {
    try {
      final res = await _dio.get('/api/lecturer/sessions/$sessionId/attendance');
      final data = res.data is Map ? res.data['data'] : res.data;
      final List records = data is List ? data : [];
      
      // Kiểm tra xem có records nào đã được điểm danh (có id và status)
      // Backend trả về tất cả students, kể cả chưa điểm danh (id: null, status: null)
      // Chỉ coi là đã điểm danh nếu có ít nhất 1 record có id và status không null
      final hasMarkedAttendance = records.any((record) {
        if (record is Map) {
          final id = record['id'];
          final status = record['status'];
          // Có id và status không null nghĩa là đã được điểm danh
          return id != null && status != null;
        }
        return false;
      });
      
      print('DEBUG hasAttendance: Total records: ${records.length}');
      print('DEBUG hasAttendance: Has marked attendance: $hasMarkedAttendance');
      
      return hasMarkedAttendance;
    } catch (e) {
      print('DEBUG hasAttendance: Error - $e');
      return false;
    }
  }

  // ===== End lesson =====
  Future<Map<String, dynamic>> endLesson(int sessionId) async {
    try {
      print('DEBUG endLesson API: Calling POST /api/lecturer/sessions/$sessionId/end');
      final res = await _dio.post('/api/lecturer/sessions/$sessionId/end');
      print('DEBUG endLesson API: Response status: ${res.statusCode}');
      print('DEBUG endLesson API: Response data: ${res.data}');
      
      final data = res.data is Map ? res.data['data'] : res.data;
      print('DEBUG endLesson API: Parsed data: $data');
      
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      // Parse error message từ backend với logging chi tiết
      String errorMessage = 'Không thể kết thúc buổi học';
      
      print('DEBUG endLesson API: DioException caught');
      print('DEBUG endLesson API: Exception type: ${e.type}');
      
      if (e.response != null) {
        // Log status code và response data để debug
        print('DEBUG endLesson API: Status code: ${e.response?.statusCode}');
        print('DEBUG endLesson API: Response data: ${e.response?.data}');
        
        if (e.response?.data is Map) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
          print('DEBUG endLesson API: Parsed error message: $errorMessage');
        } else if (e.response?.data is String) {
          errorMessage = e.response!.data as String;
          print('DEBUG endLesson API: String error message: $errorMessage');
        }
      } else {
        // Network error hoặc timeout
        print('DEBUG endLesson API: Network error - ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Kết nối timeout. Vui lòng thử lại.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      // Catch các exception khác
      print('DEBUG endLesson API: Generic exception - $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // ===== Stats =====
  Future<Map<String, dynamic>> getStats() async {
    int attempt = 0;
    const maxRetries = 3;
    Duration delay = const Duration(milliseconds: 500);
    
    while (attempt < maxRetries) {
      try {
        final res = await _dio.get(
          '/api/lecturer/stats',
          options: Options(
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
          ),
        );
        return Map<String, dynamic>.from(res.data);
      } on DioException catch (e) {
        // Chỉ retry cho connection errors
        if ((e.type == DioExceptionType.connectionError ||
             e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.receiveTimeout) &&
            attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(delay);
          delay = Duration(milliseconds: delay.inMilliseconds * 2);
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Không thể kết nối đến server sau $maxRetries lần thử');
  }

  // ===== Upcoming sessions for leave =====
  Future<List<Map<String, dynamic>>> listUpcomingSessions({
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) async {
    // Build query parameters
    final queryParams = <String, dynamic>{
      'status': 'PLANNED',
      'page': page,
      'per_page': 1000, // Lấy nhiều items để bao phủ toàn bộ semester
    };
    
    // Chỉ thêm from/to nếu được cung cấp
    if (from != null) {
      queryParams['from'] = from.toIso8601String().substring(0, 10);
    }
    if (to != null) {
      queryParams['to'] = to.toIso8601String().substring(0, 10);
    }

    String? onlyDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.contains(' ') ? s.split(' ').first : s;
    }

    String? hhmm(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    String roomLabel(dynamic value) {
      if (value is Map) {
        final code = value['code']?.toString();
        final name = value['name']?.toString();
        if (code != null && code.isNotEmpty) return code;
        return name ?? '';
      }
      return value?.toString() ?? '';
    }

    // Fetch với per_page lớn để lấy nhiều items trong 1 request
    final res = await _dio.get(
      '/api/lecturer/sessions',
      queryParameters: queryParams,
    );

    final src = res.data;
    final List raw = src is Map ? (src['data'] ?? const []) : (src as List? ?? const []);

    return raw.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final subj = m['subject'] is Map ? Map<String, dynamic>.from(m['subject']) : null;
      final cu = m['class_unit'] is Map ? Map<String, dynamic>.from(m['class_unit']) : null;
      final timeslot = m['timeslot'] is Map ? Map<String, dynamic>.from(m['timeslot']) : null;
      final room = m['room'] is Map ? Map<String, dynamic>.from(m['room']) : null;

      final date = onlyDate(m['date'] ?? m['session_date']);
      final start = hhmm(m['start_time'] ?? timeslot?['start_time']);
      final end = hhmm(m['end_time'] ?? timeslot?['end_time']);

      // Giữ lại structure gốc để logic extract hoạt động đúng
      return <String, dynamic>{
        'id': m['id'],
        'date': date,
        'session_date': m['session_date'] ?? date, // Giữ lại session_date gốc
        // Normalized (flat) fields
        'subject': subj?['name'] ?? subj?['code'] ?? m['subject']?.toString() ?? '',
        // ✅ Ưu tiên code trước name để hiển thị mã lớp
        'class_name': cu?['code'] ?? cu?['class_code'] ?? cu?['name'] ?? '',
        'class_code': cu?['code'] ?? cu?['class_code'] ?? '', // ✅ Thêm class_code riêng
        'room': roomLabel(m['room']),
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'PLANNED',
        'note': m['note'],
        // Giữ lại nested structure gốc để logic extract có thể dùng
        'timeslot': timeslot != null ? Map<String, dynamic>.from(timeslot) : null,
        'subject_nested': subj, // Giữ lại subject Map gốc
        'class_unit': cu, // Giữ lại class_unit Map gốc (snake_case)
        'classUnit': cu, // Cũng giữ camelCase variant
        'assignment': m['assignment'] is Map ? Map<String, dynamic>.from(m['assignment']) : null, // ✅ Giữ lại assignment
        'room_nested': room, // Giữ lại room Map gốc
      };
    }).toList();
  }
}

