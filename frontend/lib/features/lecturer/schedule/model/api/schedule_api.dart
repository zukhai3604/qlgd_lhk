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
        'subject':
            m['subject']?.toString() ?? subj?['name'] ?? subj?['code'] ?? '',
        'class_name':
            m['class_name']?.toString() ?? cu?['name'] ?? cu?['code'] ?? '',
        'room': room,
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'PLANNED',
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
        'subject': subj?['name'] ?? subj?['code'] ?? m['subject']?.toString() ?? '',
        'class_name': cu?['name'] ?? cu?['code'] ?? '',
        'room': roomLabel(m['room']),
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'CANCELED',
        'note': m['note'],
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
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
    if (content != null && content.trim().isNotEmpty) {
      body['content'] = content.trim();
    }
    if (issues != null && issues.trim().isNotEmpty) {
      body['issues'] = issues.trim();
    }
    if (nextPlan != null && nextPlan.trim().isNotEmpty) {
      body['next_plan'] = nextPlan.trim();
    }
    await _dio.post('/api/lecturer/schedule/$sessionId/report', data: body);
  }

  // ===== Check attendance =====
  Future<bool> hasAttendance(int sessionId) async {
    try {
      final res = await _dio.get('/api/lecturer/sessions/$sessionId/attendance');
      final data = res.data is Map ? res.data['data'] : res.data;
      final List records = data is List ? data : [];
      return records.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ===== End lesson =====
  Future<Map<String, dynamic>> endLesson(int sessionId) async {
    final res = await _dio.post('/api/lecturer/sessions/$sessionId/end');
    final data = res.data is Map ? res.data['data'] : res.data;
    return Map<String, dynamic>.from(data);
  }

  // ===== Stats =====
  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/api/lecturer/stats');
    return Map<String, dynamic>.from(res.data);
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
        'session_date': date,
        // Normalized (flat) fields
        'subject': subj?['name'] ?? subj?['code'] ?? m['subject']?.toString() ?? '',
        'class_name': cu?['name'] ?? cu?['code'] ?? '',
        'room': roomLabel(m['room']),
        'start_time': start,
        'end_time': end,
        'status': m['status'] ?? 'PLANNED',
        'note': m['note'],
        // Giữ lại nested structure gốc để logic extract có thể dùng
        'timeslot': timeslot != null ? Map<String, dynamic>.from(timeslot) : null,
        'subject_nested': subj, // Giữ lại subject Map gốc
        'class_unit': cu, // Giữ lại class_unit Map gốc (camelCase)
        'classUnit': cu, // Cũng giữ camelCase variant
        'room_nested': room, // Giữ lại room Map gốc
      };
    }).toList();
  }
}

