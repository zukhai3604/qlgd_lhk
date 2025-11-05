import 'package:intl/intl.dart';

/// Helper classes để extract và format dữ liệu makeup request
/// Tập trung hóa logic để tránh duplicate giữa View và ViewModel

class MakeupDataExtractor {
  /// Extract subject name với nhiều fallback
  static String extractSubject(Map<String, dynamic> item) {
    // Ưu tiên dùng normalized data nếu có
    String subject = item['_normalized_subject']?.toString()?.trim() ?? '';
    if (subject.isNotEmpty && subject != 'Môn học' && subject != 'null') {
      return subject;
    }

    // Fallback 1: Từ subject object
    if (item['subject'] != null) {
      if (item['subject'] is Map) {
        subject = (item['subject'] as Map)['name']?.toString()?.trim() ?? '';
      } else {
        final subjStr = item['subject'].toString().trim();
        if (subjStr.isNotEmpty && subjStr != 'Môn học' && subjStr != 'null') {
          subject = subjStr;
        }
      }
    }

    // Fallback 2: Từ subject_name
    if (subject.isEmpty || subject == 'Môn học' || subject == 'null') {
      final subjName = item['subject_name']?.toString()?.trim() ?? '';
      if (subjName.isNotEmpty && subjName != 'Môn học' && subjName != 'null') {
        subject = subjName;
      }
    }

    // Fallback 3: Từ nested leave.schedule.assignment.subject
    if (subject.isEmpty || subject == 'Môn học' || subject == 'null') {
      try {
        final leave = item['leave'];
        if (leave is Map) {
          final schedule = leave['schedule'];
          if (schedule is Map) {
            final assignment = schedule['assignment'];
            if (assignment is Map) {
              final subjectObj = assignment['subject'];
              if (subjectObj is Map) {
                final subjName = subjectObj['name']?.toString()?.trim() ?? '';
                if (subjName.isNotEmpty &&
                    subjName != 'Môn học' &&
                    subjName != 'null') {
                  subject = subjName;
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return subject.isEmpty || subject == 'null' ? 'Môn học' : subject;
  }

  /// Extract class name với nhiều fallback
  static String extractClassName(Map<String, dynamic> item) {
    // Ưu tiên dùng normalized data nếu có
    String className = item['_normalized_class_name']?.toString()?.trim() ?? '';
    if (className.isNotEmpty && className != 'null') {
      return className == 'null' ? '' : className;
    }

    // Fallback 1: Từ class_name hoặc class_code
    final classNm = item['class_name']?.toString()?.trim() ?? '';
    final classCd = item['class_code']?.toString()?.trim() ?? '';
    className = classNm.isNotEmpty ? classNm : (classCd.isNotEmpty ? classCd : '');

    // Fallback 2: Từ class object
    if (className.isEmpty && item['class'] is Map) {
      className = (item['class'] as Map)['name']?.toString()?.trim() ?? '';
    }

    // Fallback 3: Từ nested leave.schedule.assignment.classUnit
    if (className.isEmpty) {
      try {
        final leave = item['leave'];
        if (leave is Map) {
          final schedule = leave['schedule'];
          if (schedule is Map) {
            final assignment = schedule['assignment'];
            if (assignment is Map) {
              final classUnit = assignment['classUnit'];
              if (classUnit is Map) {
                className = classUnit['name']?.toString()?.trim() ?? '';
              }
            }
          }
        }
      } catch (_) {}
    }

    return className == 'null' ? '' : className;
  }

  /// Extract room name với nhiều fallback
  static String extractRoom(Map<String, dynamic> item) {
    // Ưu tiên dùng normalized data nếu có
    String room = item['_normalized_room']?.toString()?.trim() ?? '';
    if (room.isNotEmpty && room != 'null') {
      return room == 'null' ? '' : room;
    }

    // Fallback 1: Từ room object
    if (item['room'] is Map) {
      final r = item['room'] as Map;
      room = r['name']?.toString()?.trim() ??
          r['code']?.toString()?.trim() ??
          '';
    }

    // Fallback 2: Từ room_name
    if (room.isEmpty || room == 'null') {
      room = item['room_name']?.toString()?.trim() ?? '';
    }

    // Fallback 3: Từ room string
    if (room.isEmpty || room == 'null') {
      final roomStr = item['room']?.toString()?.trim() ?? '';
      if (roomStr.isNotEmpty && roomStr != 'null') {
        room = roomStr;
      }
    }

    return room == 'null' ? '' : room;
  }

  /// Extract start time và end time
  static ({String startTime, String endTime}) extractTime(Map<String, dynamic> item) {
    String startTime = item['_normalized_start_time']?.toString()?.trim() ?? '';
    String endTime = item['_normalized_end_time']?.toString()?.trim() ?? '';

    // Fallback: Từ timeslot object
    if ((startTime.isEmpty || startTime == '--:--' || startTime == 'null') ||
        (endTime.isEmpty || endTime == '--:--' || endTime == 'null')) {
      if (item['timeslot'] is Map) {
        final ts = item['timeslot'] as Map;
        if (startTime.isEmpty || startTime == '--:--' || startTime == 'null') {
          startTime = ts['start_time']?.toString()?.trim() ?? '';
        }
        if (endTime.isEmpty || endTime == '--:--' || endTime == 'null') {
          endTime = ts['end_time']?.toString()?.trim() ?? '';
        }
      }
    }

    // Fallback: Từ start_time và end_time trực tiếp
    if (startTime.isEmpty || startTime == '--:--' || startTime == 'null') {
      startTime = item['start_time']?.toString()?.trim() ?? '';
    }
    if (endTime.isEmpty || endTime == '--:--' || endTime == 'null') {
      endTime = item['end_time']?.toString()?.trim() ?? '';
    }

    return (
      startTime: startTime == 'null' ? '' : startTime,
      endTime: endTime == 'null' ? '' : endTime,
    );
  }

  /// Extract original time từ leave request
  static ({String startTime, String endTime}) extractOriginalTime(
    Map<String, dynamic> item,
    List<Map<String, dynamic>>? originalItems,
  ) {
    String originalStartTime = '';
    String originalEndTime = '';

    final groupedIds = item['_grouped_makeup_request_ids'];
    
    // Nếu là grouped makeup requests, thu thập từ tất cả leave requests
    if (groupedIds is List && groupedIds.length > 1 && originalItems != null) {
      final leaveRequestsWithTime = <Map<String, dynamic>>[];
      final processedLeaveRequestIds = <int>{};
      
      final groupedIdsInt = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .toList();
      
      for (final req in originalItems) {
        final reqId = req['id'];
        final reqIdInt = reqId != null ? int.tryParse('$reqId') : null;
        
        if (reqIdInt != null && groupedIdsInt.contains(reqIdInt)) {
          if (req['leave'] is Map) {
            final leave = req['leave'] as Map;
            final leaveRequestId = leave['id'];
            final leaveRequestIdInt = leaveRequestId != null ? int.tryParse('$leaveRequestId') : null;
            
            if (leaveRequestIdInt != null && !processedLeaveRequestIds.contains(leaveRequestIdInt)) {
              String? reqStartTime;
              String? reqEndTime;

              // Ưu tiên lấy từ schedule.timeslot
              if (leave['schedule'] is Map) {
                final schedule = leave['schedule'] as Map;
                if (schedule['timeslot'] is Map) {
                  final timeslot = schedule['timeslot'] as Map;
                  reqStartTime = timeslot['start_time']?.toString()?.trim();
                  reqEndTime = timeslot['end_time']?.toString()?.trim();
                }
              }

              // Fallback về original_time
              if (reqStartTime == null || reqStartTime.isEmpty || reqEndTime == null || reqEndTime.isEmpty) {
                if (leave['original_time'] is Map) {
                  final origTime = leave['original_time'] as Map;
                  if (reqStartTime == null || reqStartTime.isEmpty) {
                    reqStartTime = origTime['start_time']?.toString()?.trim();
                  }
                  if (reqEndTime == null || reqEndTime.isEmpty) {
                    reqEndTime = origTime['end_time']?.toString()?.trim();
                  }
                }
              }

              if (reqStartTime != null && reqStartTime.isNotEmpty && reqEndTime != null && reqEndTime.isNotEmpty) {
                leaveRequestsWithTime.add({
                  'start_time': reqStartTime,
                  'end_time': reqEndTime,
                });
                processedLeaveRequestIds.add(leaveRequestIdInt);
              }
            }
          }
        }
      }
      
      // Sắp xếp theo thời gian bắt đầu
      leaveRequestsWithTime.sort((a, b) {
        final startA = TimeParser.parseToMinutes(a['start_time'] as String);
        final startB = TimeParser.parseToMinutes(b['start_time'] as String);
        if (startA == null || startB == null) return 0;
        return startA.compareTo(startB);
      });
      
      // Lấy start_time từ leave request đầu tiên và end_time từ leave request cuối cùng
      if (leaveRequestsWithTime.isNotEmpty) {
        originalStartTime = leaveRequestsWithTime.first['start_time'] as String? ?? '';
        originalEndTime = leaveRequestsWithTime.last['end_time'] as String? ?? '';
      }
    } else {
      // Không grouped: Lấy từ original_start_time và original_end_time
      originalStartTime = item['original_start_time']?.toString()?.trim() ?? '';
      originalEndTime = item['original_end_time']?.toString()?.trim() ?? '';

      if (originalStartTime.isEmpty || originalEndTime.isEmpty) {
        if (item['leave'] is Map) {
          final leave = item['leave'] as Map;
          if (leave['schedule'] is Map) {
            final schedule = leave['schedule'] as Map;
            if (schedule['timeslot'] is Map) {
              final timeslot = schedule['timeslot'] as Map;
              if (originalStartTime.isEmpty) {
                originalStartTime = timeslot['start_time']?.toString()?.trim() ?? '';
              }
              if (originalEndTime.isEmpty) {
                originalEndTime = timeslot['end_time']?.toString()?.trim() ?? '';
              }
            }
          }
          if (originalStartTime.isEmpty || originalEndTime.isEmpty) {
            if (leave['original_time'] is Map) {
              final origTime = leave['original_time'] as Map;
              if (originalStartTime.isEmpty) {
                originalStartTime = origTime['start_time']?.toString()?.trim() ?? '';
              }
              if (originalEndTime.isEmpty) {
                originalEndTime = origTime['end_time']?.toString()?.trim() ?? '';
              }
            }
          }
        }
      }
    }

    return (
      startTime: originalStartTime,
      endTime: originalEndTime,
    );
  }

  /// Extract original date
  static String extractOriginalDate(Map<String, dynamic> item) {
    if (item['original_date'] != null) {
      return item['original_date']?.toString() ?? '';
    }
    if (item['leave'] is Map) {
      final leave = item['leave'] as Map;
      if (leave['original_date'] != null) {
        return leave['original_date']?.toString() ?? '';
      }
    }
    return '';
  }

  /// Extract leave reason
  static String extractLeaveReason(Map<String, dynamic> item) {
    String leaveReason = item['leave_reason']?.toString() ?? '';
    if (leaveReason.isEmpty && item['leave'] is Map) {
      final leave = item['leave'] as Map;
      leaveReason = leave['reason']?.toString() ?? '';
    }
    return leaveReason;
  }
}

class TimeParser {
  /// Parse thời gian HH:mm thành số phút (ví dụ: "15:40" -> 940)
  static int? parseToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  /// Format thời gian thành HH:mm
  static String formatHHMM(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }
}

class DateFormatter {
  /// Format date từ ISO string sang dd/MM/yyyy
  static String formatDDMMYYYY(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final raw = iso.length >= 10 ? iso.substring(0, 10) : iso;
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return iso;
    }
  }
}

