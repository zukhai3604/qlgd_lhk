import 'package:intl/intl.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

/// Helper classes để extract và format dữ liệu leave request
/// Tái sử dụng TimeParser và DateFormatter từ makeup module

class LeaveDataExtractor {
  /// Extract subject name với nhiều fallback
  static String extractSubject(Map<String, dynamic> session) {
    String v = _pickStr(session, [
      'assignment.subject.name',
      'assignment.subject.title',
      'assignment.subject.code',
      'subject.name',
      'subject.title',
      'subject.code',
      'subject_name',
      'subject',
      'course_name',
      'course.code',
      'course.name',
      'title',
      'name',
    ]);

    // Nếu vẫn không có, thử kiểm tra trực tiếp assignment.subject
    if (v.isEmpty && session['assignment'] is Map) {
      final asg = session['assignment'] as Map;
      if (asg['subject'] is Map) {
        final subj = asg['subject'] as Map;
        v = _pickStr(subj, ['name', 'title', 'code']);
      }
    }

    // Nếu vẫn không có, thử kiểm tra subject trực tiếp
    if (v.isEmpty && session['subject'] is Map) {
      final subj = session['subject'] as Map;
      v = _pickStr(subj, ['name', 'title', 'code']);
    }

    return v.isEmpty ? 'Môn học' : v;
  }

  /// Extract class name với nhiều fallback - ưu tiên mã lớp (code) thay vì tên lớp
  static String extractClassName(Map<String, dynamic> session) {
    // ✅ Ưu tiên code trước, sau đó mới đến name
    return _pickStr(session, [
      'assignment.classUnit.code',  // camelCase - ưu tiên code
      'assignment.classUnit.class_code',  // camelCase
      'assignment.class_unit.code',  // snake_case - ưu tiên code
      'assignment.class_unit.class_code',  // snake_case
      'classUnit.code',  // camelCase - ưu tiên code
      'classUnit.class_code',  // camelCase
      'class_unit.code',  // snake_case - ưu tiên code
      'class_unit.class_code',  // snake_case
      'class_code',  // Trực tiếp
      'assignment.classUnit.name',  // camelCase - fallback name
      'assignment.class_unit.name',  // snake_case - fallback name
      'classUnit.name',  // camelCase - fallback name
      'class_unit.name',  // snake_case - fallback name
      'class_name',  // Fallback
      'class',  // Fallback
      'group_name',  // Fallback
    ]);
  }

  /// Extract room name với nhiều fallback
  static String extractRoom(Map<String, dynamic> session) {
    // 1) Nếu có object room
    if (session['room'] is Map) {
      final r = session['room'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }

    // 2) Nếu room là chuỗi trực tiếp
    if (session['room'] is String && (session['room'] as String).trim().isNotEmpty) {
      return (session['room'] as String).trim();
    }

    // 3) Nếu room nằm trong assignment
    if (session['assignment'] is Map) {
      final a = session['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }

    return '';
  }

  /// Extract time range từ session
  static ({String startTime, String endTime}) extractTime(Map<String, dynamic> session) {
    final startRaw = _pickStr(session, [
      'timeslot.start_time',
      'timeslot.start',
      'start_time',
      'startTime',
      'slot.start',
    ]);
    final endRaw = _pickStr(session, [
      'timeslot.end_time',
      'timeslot.end',
      'end_time',
      'endTime',
      'slot.end',
    ]);

    return (
      startTime: TimeParser.formatHHMM(startRaw),
      endTime: TimeParser.formatHHMM(endRaw),
    );
  }

  /// Extract date từ session
  static String extractDate(Map<String, dynamic> session) {
    final raw = _pickStr(session, [
      'session_date',
      'date',
      'timeslot.date',
      'period.date',
      'start_at',
    ]);
    if (raw.isEmpty) return '';
    final only = raw.split(' ').first;
    try {
      final dt = DateTime.parse(only);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return only;
    }
  }

  /// Extract cohort từ session
  static String extractCohort(Map<String, dynamic> session) {
    var c = _pickStr(session, ['cohort', 'k', 'course', 'batch']);
    if (c.isNotEmpty && !c.toUpperCase().startsWith('K')) c = 'K$c';
    return c;
  }

  /// Helper để pick string từ nested map với nhiều paths
  static String _pickStr(Map data, List<String> paths) {
    for (final p in paths) {
      dynamic cur = data;
      for (final seg in p.split('.')) {
        if (cur is Map && cur.containsKey(seg)) {
          cur = cur[seg];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && cur.toString().trim().isNotEmpty) {
        return cur.toString().trim();
      }
    }
    return '';
  }
}
