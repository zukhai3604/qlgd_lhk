import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/api/leave_api.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';

typedef LeaveChooseSessionResult<T> = Result<T, Exception>;

/// Result bao gồm cả sessions và weeks
class LeaveChooseSessionData {
  final List<Map<String, dynamic>> sessions;
  final List<String> weekOptions;
  final List<String> allDates; // Tất cả các ngày từ sessions trước khi filter

  LeaveChooseSessionData({
    required this.sessions,
    required this.weekOptions,
    required this.allDates,
  });
}

/// Repository cho leave choose session
abstract class LeaveChooseSessionRepository {
  Future<LeaveChooseSessionResult<LeaveChooseSessionData>> getAvailableSessions();
}

/// Implementation của LeaveChooseSessionRepository
class LeaveChooseSessionRepositoryImpl implements LeaveChooseSessionRepository {
  final LecturerLeaveApi _leaveApi;
  final ScheduleApi _scheduleApi;

  LeaveChooseSessionRepositoryImpl({
    LecturerLeaveApi? leaveApi,
    ScheduleApi? scheduleApi,
  })  : _leaveApi = leaveApi ?? LecturerLeaveApi(),
        _scheduleApi = scheduleApi ?? ScheduleApi();

  @override
  Future<LeaveChooseSessionResult<LeaveChooseSessionData>> getAvailableSessions() async {
    try {
      // Lấy tất cả sessions trong semester hiện tại bằng cách sử dụng API /api/lecturer/schedule
      // API này trả về filters.weeks với danh sách đầy đủ các tuần trong semester
      final scheduleData = await _scheduleApi.getSchedule();
      
      // Extract weeks từ filters để lấy danh sách đầy đủ các tuần
      final filters = scheduleData['filters'] as Map<String, dynamic>?;
      final weeksRaw = filters?['weeks'] as List? ?? [];
      
      print('DEBUG Repository: Total weeks from API: ${weeksRaw.length}');
      
      // Format weeks thành danh sách string giống như _calculateWeekOptions
      // Và filter bỏ những tuần đã qua
      // Đánh số lại để khớp với schedule: nếu tuần đầu tiên đã qua và bị filter,
      // thì tuần tiếp theo sẽ được đánh số là tuần 2
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // Normalize về 00:00:00
      
      final weekOptions = <String>[];
      int weekNumber = 1; // Bắt đầu từ tuần 1
      bool firstWeekSkipped = false; // Track xem tuần đầu tiên có bị filter không
      
      for (final weekData in weeksRaw) {
        final weekMap = weekData as Map<String, dynamic>;
        final start = weekMap['start']?.toString();
        final end = weekMap['end']?.toString();
        final label = weekMap['label']?.toString();
        
        if (start != null && end != null) {
          try {
            // Parse dates và format lại
            final startDate = DateTime.parse(start);
            final endDate = DateTime.parse(end);
            
            // Chỉ thêm tuần nếu tuần chưa kết thúc (endDate >= today)
            final weekEndNormalized = DateTime(endDate.year, endDate.month, endDate.day);
            if (weekEndNormalized.isBefore(today)) {
              // Nếu đây là tuần đầu tiên và bị filter, đánh số từ tuần 2
              if (!firstWeekSkipped) {
                weekNumber = 2;
                firstWeekSkipped = true;
              }
              print('DEBUG Repository: Skipping past week: $start - $end');
              continue; // Bỏ qua tuần đã qua
            }
            
            final startStr = '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
            final endStr = '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
            weekOptions.add('Tuần $weekNumber: $startStr - $endStr');
            weekNumber++;
            firstWeekSkipped = true; // Đánh dấu đã có tuần được thêm vào
          } catch (_) {
            // Nếu parse lỗi, dùng label nếu có (nhưng vẫn cần check date)
            if (label != null && label.isNotEmpty) {
              // Thử parse từ label hoặc bỏ qua nếu không parse được
              weekOptions.add('Tuần $weekNumber: $label');
              weekNumber++;
              firstWeekSkipped = true;
            }
          }
        } else if (label != null && label.isNotEmpty) {
          // Nếu không có start/end, vẫn thêm nhưng có thể không chính xác
          weekOptions.add('Tuần $weekNumber: $label');
          weekNumber++;
          firstWeekSkipped = true;
        }
      }
      
      print('DEBUG Repository: Formatted week options (after filtering past weeks): ${weekOptions.length}');
      
      // Fetch sessions của từng tuần để lấy đủ sessions
      // Chỉ fetch các tuần chưa qua (logic filter đã được xử lý ở trên)
      List<Map<String, dynamic>> all = [];
      
      print('DEBUG Repository: Starting to fetch sessions from ${weeksRaw.length} weeks');
      
      for (final weekData in weeksRaw) {
        final weekMap = weekData as Map<String, dynamic>;
        final start = weekMap['start']?.toString();
        final end = weekMap['end']?.toString();
        
        // Chỉ fetch tuần nếu tuần chưa kết thúc (giống logic filter ở trên)
        if (start != null && end != null) {
          try {
            final endDate = DateTime.parse(end);
            final weekEndNormalized = DateTime(endDate.year, endDate.month, endDate.day);
            if (weekEndNormalized.isBefore(today)) {
              print('DEBUG Repository: Skipping past week when fetching sessions: $start - $end');
              continue; // Bỏ qua tuần đã qua
            }
          } catch (_) {
            // Nếu parse lỗi, vẫn tiếp tục fetch
          }
        }
        
        final weekValue = (weekData as Map<String, dynamic>)['value']?.toString();
        if (weekValue == null || weekValue.isEmpty) {
          print('DEBUG Repository: Skipping week with null/empty value');
          continue;
        }
        
        try {
          print('DEBUG Repository: Fetching week $weekValue...');
          final weekScheduleData = await _scheduleApi.getSchedule(weekValue: weekValue);
          
          print('DEBUG Repository: Week $weekValue response keys: ${weekScheduleData.keys}');
          
          // Extract items từ response - kiểm tra nhiều format khác nhau
          dynamic weekDataList;
          
          // Thử format 1: data.items
          if (weekScheduleData['data'] is Map && weekScheduleData['data']?['items'] is List) {
            weekDataList = weekScheduleData['data']['items'];
            print('DEBUG Repository: Week $weekValue: Found data.items format');
          }
          // Thử format 2: data là List trực tiếp
          else if (weekScheduleData['data'] is List) {
            weekDataList = weekScheduleData['data'];
            print('DEBUG Repository: Week $weekValue: Found data as List format');
          }
          // Thử format 3: items trực tiếp
          else if (weekScheduleData['items'] is List) {
            weekDataList = weekScheduleData['items'];
            print('DEBUG Repository: Week $weekValue: Found items format');
          }
          // Thử format 4: root là List
          else if (weekScheduleData is List) {
            weekDataList = weekScheduleData;
            print('DEBUG Repository: Week $weekValue: Found root as List format');
          }
          // Thử format 5: data là Map với session_date
          else if (weekScheduleData['data'] is Map && weekScheduleData['data']?['session_date'] != null) {
            weekDataList = [weekScheduleData['data']];
            print('DEBUG Repository: Week $weekValue: Found single item format');
          }
          else {
            weekDataList = [];
            print('DEBUG Repository: Week $weekValue: Unknown format, response structure: ${weekScheduleData.runtimeType}');
            if (weekScheduleData is Map) {
              print('DEBUG Repository: Week $weekValue: Map keys: ${(weekScheduleData as Map).keys.toList()}');
            }
          }
          
          if (weekDataList is List && weekDataList.isNotEmpty) {
            final weekSessions = weekDataList
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            all.addAll(weekSessions);
            print('DEBUG Repository: Week $weekValue: ${weekSessions.length} sessions (total: ${all.length})');
            
            // Debug: In ra một session mẫu để kiểm tra format
            if (weekSessions.isNotEmpty) {
              final sample = weekSessions.first;
              print('DEBUG Repository: Week $weekValue: Sample session keys: ${sample.keys.toList()}');
              print('DEBUG Repository: Week $weekValue: Sample session_date: ${sample['session_date']}, date: ${sample['date']}');
            }
          } else {
            print('DEBUG Repository: Week $weekValue: No sessions found or invalid format (weekDataList type: ${weekDataList.runtimeType}, isEmpty: ${weekDataList is List ? weekDataList.isEmpty : 'N/A'})');
          }
        } catch (e, stackTrace) {
          print('DEBUG Repository: Error fetching week $weekValue: $e');
          print('DEBUG Repository: Stack trace: $stackTrace');
          // Bỏ qua nếu fetch lỗi, tiếp tục với tuần tiếp theo
        }
      }
      
      print('DEBUG Repository: Total sessions from all weeks: ${all.length}');
      
      // Normalize data để có format giống listUpcomingSessions
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

      final normalized = all.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e);
        
        // Extract assignment nếu có
        final assignment = m['assignment'] is Map ? Map<String, dynamic>.from(m['assignment']) : null;
        
        // Extract subject từ nhiều nguồn: assignment.subject hoặc subject trực tiếp
        Map<String, dynamic>? subj;
        if (assignment != null && assignment['subject'] is Map) {
          subj = Map<String, dynamic>.from(assignment['subject']);
        } else if (m['subject'] is Map) {
          subj = Map<String, dynamic>.from(m['subject']);
        }
        
        // Extract class_unit từ nhiều nguồn: assignment.classUnit hoặc class_unit trực tiếp
        Map<String, dynamic>? cu;
        if (assignment != null && assignment['classUnit'] is Map) {
          cu = Map<String, dynamic>.from(assignment['classUnit']);
        } else if (assignment != null && assignment['class_unit'] is Map) {
          cu = Map<String, dynamic>.from(assignment['class_unit']);
        } else if (m['class_unit'] is Map) {
          cu = Map<String, dynamic>.from(m['class_unit']);
        } else if (m['classUnit'] is Map) {
          cu = Map<String, dynamic>.from(m['classUnit']);
        }
        
        final timeslot = m['timeslot'] is Map ? Map<String, dynamic>.from(m['timeslot']) : null;
        final room = m['room'] is Map ? Map<String, dynamic>.from(m['room']) : null;

        final date = onlyDate(m['date'] ?? m['session_date'] ?? m['sessionDate']);
        final start = hhmm(m['start_time'] ?? timeslot?['start_time']);
        final end = hhmm(m['end_time'] ?? timeslot?['end_time']);

        // Extract subject name/code với nhiều fallback
        String subjectName = '';
        if (subj != null) {
          subjectName = subj['name']?.toString() ?? 
                       subj['title']?.toString() ?? 
                       subj['code']?.toString() ?? 
                       '';
        }
        if (subjectName.isEmpty) {
          subjectName = m['subject']?.toString() ?? '';
        }
        
        // Extract class name/code với nhiều fallback
        String className = '';
        if (cu != null) {
          className = cu['name']?.toString() ?? 
                     cu['code']?.toString() ?? 
                     cu['title']?.toString() ?? 
                     '';
        }
        if (className.isEmpty) {
          className = m['class_name']?.toString() ?? 
                     m['className']?.toString() ?? 
                     '';
        }

        return <String, dynamic>{
          'id': m['id'],
          'date': date,
          'session_date': date,
          'subject': subjectName,
          'class_name': className,
          'room': roomLabel(m['room']),
          'start_time': start,
          'end_time': end,
          'status': m['status'] ?? 'PLANNED',
          'note': m['note'],
          'timeslot': timeslot != null ? Map<String, dynamic>.from(timeslot) : null,
          'subject_nested': subj,
          'class_unit': cu,
          'classUnit': cu,
          'room_nested': room,
          // Giữ lại assignment để UI có thể extract từ assignment.subject nếu cần
          'assignment': assignment,
        };
      }).toList();
      
      print('DEBUG Repository: Normalized sessions: ${normalized.length}');

      // Tính toán tất cả các ngày từ normalized sessions (trước khi filter)
      // để đảm bảo dropdown ngày luôn có dữ liệu
      // Nhưng filter bỏ những ngày đã qua
      final allDatesSet = <String>{};
      for (final s in normalized) {
        final date = _dateIsoOf(s);
        if (date.isNotEmpty) {
          try {
            final dateObj = DateTime.parse(date);
            final dateNormalized = DateTime(dateObj.year, dateObj.month, dateObj.day);
            // Chỉ thêm ngày nếu chưa qua (dateNormalized >= today)
            if (!dateNormalized.isBefore(today)) {
              allDatesSet.add(date);
            }
          } catch (_) {
            // Nếu parse lỗi, vẫn thêm vào để không mất dữ liệu
            allDatesSet.add(date);
          }
        }
      }
      final allDates = allDatesSet.toList()..sort();
      print('DEBUG Repository: All dates from normalized sessions (after filtering past dates): ${allDates.length}');

      // Sử dụng now và today đã tạo ở trên
      
      DateTime? _startOf(Map<String, dynamic> s) {
        final date = _dateIsoOf(s);
        final st = _startOfStr(s);
        if (date.isEmpty || st.isEmpty) return null;

        final parts = st.split(':');
        final hh = (parts.isNotEmpty ? parts[0] : '00').padLeft(2, '0');
        final mm = (parts.length > 1 ? parts[1] : '00').padLeft(2, '0');

        try {
          return DateTime.parse('${date}T$hh:$mm:00');
        } catch (_) {
          return null;
        }
      }

      var upcoming = normalized
          .where((raw) {
            final s = Map<String, dynamic>.from(raw as Map);
            final isPlanned = (s['status']?.toString().toUpperCase() == 'PLANNED');
            final start = _startOf(s);
            final isUpcoming = start != null && now.isBefore(start);
            
            if (!isPlanned) {
              print('DEBUG Repository: Session ${s['id']} filtered out: status=${s['status']}');
            }
            if (start == null) {
              print('DEBUG Repository: Session ${s['id']} filtered out: cannot parse start time');
            }
            if (start != null && !now.isBefore(start)) {
              print('DEBUG Repository: Session ${s['id']} filtered out: already passed (start=$start, now=$now)');
            }
            
            return isPlanned && isUpcoming;
          })
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      
      print('DEBUG Repository: Upcoming sessions after filter: ${upcoming.length}');
      
      // Loại các buổi đã có đơn xin nghỉ PENDING/APPROVED
      final pending = await _leaveApi.list(status: 'PENDING');
      final approved = await _leaveApi.list(status: 'APPROVED');
      print('DEBUG Repository: Pending leave requests: ${pending.length}');
      print('DEBUG Repository: Approved leave requests: ${approved.length}');
      
      final excluded = <int>{}
        ..addAll(pending.map((e) => int.tryParse('${e['schedule_id']}') ?? -1))
        ..addAll(approved.map((e) => int.tryParse('${e['schedule_id']}') ?? -1));
      
      print('DEBUG Repository: Excluded schedule IDs: $excluded');
      
      final beforeExclude = upcoming.length;
      upcoming = upcoming
          .where((s) {
            final id = int.tryParse('${s['id']}') ?? -1;
            final isExcluded = excluded.contains(id);
            if (isExcluded) {
              print('DEBUG Repository: Session ${s['id']} excluded: already has leave request');
            }
            return !isExcluded;
          })
          .toList();
      
      print('DEBUG Repository: Sessions after exclude: ${upcoming.length} (removed ${beforeExclude - upcoming.length})');

      // Tính toán lại allDates từ upcoming sessions (sau khi filter)
      // để chỉ hiển thị các ngày có sessions có thể xin nghỉ
      final availableDatesSet = <String>{};
      for (final s in upcoming) {
        final date = _dateIsoOf(s);
        if (date.isNotEmpty) {
          try {
            final dateObj = DateTime.parse(date);
            final dateNormalized = DateTime(dateObj.year, dateObj.month, dateObj.day);
            // Chỉ thêm ngày nếu chưa qua (dateNormalized >= today)
            if (!dateNormalized.isBefore(today)) {
              availableDatesSet.add(date);
            }
          } catch (_) {
            // Nếu parse lỗi, vẫn thêm vào để không mất dữ liệu
            availableDatesSet.add(date);
          }
        }
      }
      final availableDates = availableDatesSet.toList()..sort();
      print('DEBUG Repository: Available dates from upcoming sessions: ${availableDates.length}');

      // Enrich rooms cho những item chưa có phòng
      await _enrichMissingRooms(upcoming);

      return LeaveChooseSessionResult.success(LeaveChooseSessionData(
        sessions: upcoming,
        weekOptions: weekOptions,
        allDates: availableDates, // Sử dụng availableDates thay vì allDates
      ));
    } catch (e) {
      return LeaveChooseSessionResult.failure(Exception('Không tải được danh sách buổi dạy: $e'));
    }
  }

  Future<void> _enrichMissingRooms(List<Map<String, dynamic>> list) async {
    final needIds = <int>[];
    for (final s in list) {
      if (_roomOf(s).isEmpty) {
        final id = int.tryParse('${s['id']}');
        if (id != null && id > 0) needIds.add(id);
      }
    }
    if (needIds.isEmpty) return;

    for (final id in needIds) {
      try {
        final detail = await _scheduleApi.getDetail(id);
        final idx = list.indexWhere((e) => int.tryParse('${e['id']}') == id);
        if (idx != -1) {
          final merged = {...list[idx], ...Map<String, dynamic>.from(detail)};
          list[idx] = merged;
        }
      } catch (_) {
        // bỏ qua nếu fetch lỗi
      }
    }
  }

  String _dateIsoOf(Map<String, dynamic> s) {
    final raw = (s['date'] ?? s['session_date'] ?? '').toString();
    if (raw.isEmpty) return '';
    return raw.split(' ').first;
  }

  String _startOfStr(Map<String, dynamic> s) {
    final raw = (s['start_time'] ?? s['timeslot']?['start_time'] ?? '').toString();
    if (raw.isEmpty) return '';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _roomOf(Map<String, dynamic> s) {
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = r['code']?.toString() ?? r['name']?.toString() ?? '';
      if (code.isNotEmpty) return code.trim();
    }
    if (s['room'] is String) return (s['room'] as String).trim();
    return '';
  }
}

