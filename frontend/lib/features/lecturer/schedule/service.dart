import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class LecturerScheduleService {
  final Dio _dio = ApiClient().dio;

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
      // single object → wrap
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

  // ===== Detail =====
  Future<Map<String, dynamic>> getDetail(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id');
    final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
    return Map<String, dynamic>.from(data);
  }

  // ===== Materials =====
  Future<List<Map<String, dynamic>>> listMaterials(int id) async {
    final res = await _dio.get('/api/lecturer/schedule/$id/materials');
    final List list =
        (res.data is Map ? res.data['data'] ?? [] : res.data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // UI mới đang gọi getMaterials -> alias về listMaterials
  Future<List<Map<String, dynamic>>> getMaterials(int sessionId) =>
      listMaterials(sessionId);

  // Thêm nội dung/tài liệu (UI mới dùng)
  Future<void> addMaterial(int sessionId, String title) async {
    await _dio.post('/api/lecturer/schedule/$sessionId/materials', data: {
      'title': title,
      // Nếu BE của bạn bắt buộc file_url thì thêm ở đây:
      // 'file_url': 'https://example.com',
    });
  }

  // ===== Report =====
  // UI mới gọi kiểu đặt tên:
  // submitReport(sessionId: 1, status: 'done', note: '...', content: '...')
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

  // Giữ tương thích với code cũ của bạn:
  // submitReport(id, content: '...', issues: '...', nextPlan: '...')
  @Deprecated('Dùng submitReport({...}) với tham số đặt tên')
  Future<void> submitReportLegacy(
    int id, {
    required String content,
    String? issues,
    String? nextPlan,
  }) async {
    await submitReport(
      sessionId: id,
      content: content,
      issues: issues,
      nextPlan: nextPlan,
    );
  }
}
