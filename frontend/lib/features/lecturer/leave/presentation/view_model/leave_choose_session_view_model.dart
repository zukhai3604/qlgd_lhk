import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/repositories/leave_choose_session_repository.dart';

/// State cho LeaveChooseSessionViewModel
class LeaveChooseSessionState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> allSessions;
  final List<Map<String, dynamic>> filteredSessions;
  final List<String> dateOptions; // Tất cả các ngày
  final List<String> filteredDateOptions; // Các ngày trong tuần đã chọn
  final String? selectedDate;
  final List<String> weekOptions; // Danh sách các tuần (format: "Tuần X: DD/MM - DD/MM")
  final String? selectedWeek; // Tuần đã chọn

  const LeaveChooseSessionState({
    this.isLoading = false,
    this.error,
    this.allSessions = const [],
    this.filteredSessions = const [],
    this.dateOptions = const [],
    this.filteredDateOptions = const [],
    this.selectedDate,
    this.weekOptions = const [],
    this.selectedWeek,
  });

  LeaveChooseSessionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? allSessions,
    List<Map<String, dynamic>>? filteredSessions,
    List<String>? dateOptions,
    List<String>? filteredDateOptions,
    String? selectedDate,
    List<String>? weekOptions,
    String? selectedWeek,
  }) {
    return LeaveChooseSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      allSessions: allSessions ?? this.allSessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      dateOptions: dateOptions ?? this.dateOptions,
      filteredDateOptions: filteredDateOptions ?? this.filteredDateOptions,
      selectedDate: selectedDate ?? this.selectedDate,
      weekOptions: weekOptions ?? this.weekOptions,
      selectedWeek: selectedWeek ?? this.selectedWeek,
    );
  }
}

/// ViewModel cho LeaveChooseSessionPage
class LeaveChooseSessionViewModel extends StateNotifier<LeaveChooseSessionState> {
  final LeaveChooseSessionRepository _repository;

  LeaveChooseSessionViewModel(this._repository) : super(const LeaveChooseSessionState()) {
    loadData();
  }

  /// Load dữ liệu ban đầu
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAvailableSessions();
    result.when(
      success: (data) {
        // Extract sessions và weekOptions từ LeaveChooseSessionData
        final sessions = data.sessions;
        final weekOptions = data.weekOptions;
        final allDatesFromRepo = data.allDates; // Tất cả các ngày từ sessions trước khi filter
        
        // Debug: Kiểm tra số lượng sessions
        print('DEBUG: Total sessions loaded: ${sessions.length}');
        print('DEBUG: Week options from API: ${weekOptions.length}');
        print('DEBUG: All dates from repository: ${allDatesFromRepo.length}');
        
        // Sử dụng allDates từ repository thay vì tính từ sessions đã filter
        // Điều này đảm bảo dropdown ngày luôn có dữ liệu, kể cả khi không còn sessions nào
        final sorted = allDatesFromRepo;
        
        print('DEBUG: Unique dates: ${sorted.length}');
        if (sorted.isNotEmpty) {
          print('DEBUG: First date: ${sorted.first}, Last date: ${sorted.last}');
        }

        if (weekOptions.isNotEmpty) {
          print('DEBUG: First week: ${weekOptions.first}');
          print('DEBUG: Last week: ${weekOptions.last}');
        }
        
        final selectedWeek = weekOptions.isNotEmpty ? weekOptions.first : null;

        // Tính toán filteredDateOptions dựa trên tuần đã chọn
        List<String> filteredDateOptions = sorted;
        if (selectedWeek != null) {
          final weekDates = _parseWeekDates(selectedWeek);
          if (weekDates != null) {
            filteredDateOptions = _getDatesInWeekFromList(
              weekDates['start']!,
              weekDates['end']!,
              sorted,
            );
          }
        }

        // Chọn ngày đầu tiên trong filteredDateOptions (không phải sorted)
        final selectedDate = filteredDateOptions.isNotEmpty ? filteredDateOptions.first : null;

        state = state.copyWith(
          isLoading: false,
          allSessions: sessions,
          dateOptions: sorted,
          selectedDate: selectedDate,
          weekOptions: weekOptions,
          selectedWeek: selectedWeek,
          filteredDateOptions: filteredDateOptions,
        );

        // Áp dụng filter sau khi set state
        _applyFilters();
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );
  }

  /// Refresh dữ liệu
  Future<void> refresh() async {
    await loadData();
  }

  /// Chọn tuần và filter sessions
  void selectWeek(String? week) {
    // Tính toán filteredDateOptions trước
    List<String> filteredDateOptions;
    String? newSelectedDate;
    
    if (week != null) {
      final weekDates = _parseWeekDates(week);
      if (weekDates != null) {
        filteredDateOptions = _getDatesInWeek(weekDates['start']!, weekDates['end']!);
        // Chọn ngày đầu tiên trong tuần mới nếu có
        newSelectedDate = filteredDateOptions.isNotEmpty ? filteredDateOptions.first : null;
      } else {
        filteredDateOptions = [];
        newSelectedDate = null;
      }
    } else {
      // Nếu chọn "Tất cả các tuần", hiển thị tất cả các ngày
      filteredDateOptions = state.dateOptions;
      // Giữ nguyên selectedDate nếu nó vẫn còn trong danh sách, nếu không thì chọn ngày đầu tiên
      newSelectedDate = state.selectedDate != null && filteredDateOptions.contains(state.selectedDate)
          ? state.selectedDate
          : (filteredDateOptions.isNotEmpty ? filteredDateOptions.first : null);
    }
    
    state = state.copyWith(
      selectedWeek: week,
      selectedDate: newSelectedDate,
      filteredDateOptions: filteredDateOptions,
    );
    
    _applyFilters();
  }

  /// Chọn ngày và filter sessions
  void selectDate(String? date) {
    state = state.copyWith(selectedDate: date);
    _applyFilters();
  }

  /// Lấy danh sách các ngày trong tuần từ danh sách ngày có sẵn
  List<String> _getDatesInWeekFromList(
    DateTime startDate,
    DateTime endDate,
    List<String> availableDates,
  ) {
    final dates = <String>[];
    final formatter = DateFormat('yyyy-MM-dd');
    
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (!currentDate.isAfter(end)) {
      final dateStr = formatter.format(currentDate);
      // Chỉ thêm ngày nếu có trong availableDates
      if (availableDates.contains(dateStr)) {
        dates.add(dateStr);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dates;
  }

  /// Lấy danh sách các ngày trong tuần (dùng state.dateOptions)
  List<String> _getDatesInWeek(DateTime startDate, DateTime endDate) {
    return _getDatesInWeekFromList(startDate, endDate, state.dateOptions);
  }

  /// Áp dụng filter dựa trên tuần và ngày đã chọn
  void _applyFilters() {
    // Nếu có chọn ngày, filter theo ngày
    if (state.selectedDate != null) {
      _filterByDate(state.selectedDate);
    } else if (state.selectedWeek != null) {
      // Nếu không có ngày nhưng có tuần, filter theo tuần
      _filterByWeek(state.selectedWeek);
    } else {
      // Nếu không có cả tuần và ngày, hiển thị tất cả
      final grouped = _groupConsecutiveSessions(state.allSessions);
      state = state.copyWith(filteredSessions: grouped);
    }
  }

  /// Filter sessions theo tuần đã chọn
  void _filterByWeek(String? week) {
    if (week == null) {
      state = state.copyWith(filteredSessions: []);
      return;
    }

    // Parse tuần từ format "Tuần X: DD/MM/YYYY - DD/MM/YYYY"
    final weekDates = _parseWeekDates(week);
    if (weekDates == null) {
      state = state.copyWith(filteredSessions: []);
      return;
    }

    final filtered = state.allSessions.where((s) {
      final sessionDate = _dateIsoOf(s);
      if (sessionDate.isEmpty) return false;
      
      try {
        final date = DateTime.parse(sessionDate);
        final startDate = weekDates['start']!;
        final endDate = weekDates['end']!;
        
        // So sánh chỉ phần ngày (không có giờ)
        final sessionDay = DateTime(date.year, date.month, date.day);
        final startDay = DateTime(startDate.year, startDate.month, startDate.day);
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);
        
        // Kiểm tra xem ngày có nằm trong khoảng tuần không (bao gồm cả start và end)
        return (sessionDay.isAtSameMomentAs(startDay) || sessionDay.isAfter(startDay)) &&
               (sessionDay.isAtSameMomentAs(endDay) || sessionDay.isBefore(endDay));
      } catch (_) {
        return false;
      }
    }).toList();

    final grouped = _groupConsecutiveSessions(filtered);
    state = state.copyWith(filteredSessions: grouped);
  }

  /// Parse tuần từ string format "Tuần X: DD/MM/YYYY - DD/MM/YYYY"
  Map<String, DateTime>? _parseWeekDates(String weekStr) {
    try {
      // Format: "Tuần X: DD/MM/YYYY - DD/MM/YYYY"
      final parts = weekStr.split(':');
      if (parts.length < 2) return null;
      
      final dateRange = parts[1].trim();
      final dates = dateRange.split(' - ');
      if (dates.length < 2) return null;
      
      final startStr = dates[0].trim();
      final endStr = dates[1].trim();
      
      // Parse DD/MM/YYYY
      final startParts = startStr.split('/');
      final endParts = endStr.split('/');
      
      if (startParts.length < 3 || endParts.length < 3) return null;
      
      final startDate = DateTime(
        int.parse(startParts[2]),
        int.parse(startParts[1]),
        int.parse(startParts[0]),
      );
      
      final endDate = DateTime(
        int.parse(endParts[2]),
        int.parse(endParts[1]),
        int.parse(endParts[0]),
      );
      
      return {'start': startDate, 'end': endDate};
    } catch (_) {
      return null;
    }
  }

  /// Tính toán các tuần từ danh sách sessions
  List<String> _calculateWeekOptions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return [];
    
    // Dùng Set để loại bỏ duplicate dates
    final dateSet = <DateTime>{};
    
    for (final s in sessions) {
      final dateStr = _dateIsoOf(s);
      if (dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          // Normalize về 00:00:00 để so sánh chính xác
          final normalizedDate = DateTime(date.year, date.month, date.day);
          dateSet.add(normalizedDate);
        } catch (_) {
          // Bỏ qua nếu parse lỗi
        }
      }
    }
    
    if (dateSet.isEmpty) return [];
    
    // Chuyển Set thành List và sắp xếp
    final dates = dateSet.toList()..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    
    // Tính tuần đầu tiên (Thứ 2 của tuần chứa ngày đầu tiên)
    final firstWeekday = firstDate.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = firstWeekday == 7 ? 6 : firstWeekday - 1;
    final firstMonday = DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day,
    ).subtract(Duration(days: daysFromMonday));
    
    // Tính tuần cuối cùng (Chủ nhật của tuần chứa ngày cuối cùng)
    final lastWeekday = lastDate.weekday;
    final daysToSunday = lastWeekday == 7 ? 0 : 7 - lastWeekday;
    final lastSunday = DateTime(
      lastDate.year,
      lastDate.month,
      lastDate.day,
    ).add(Duration(days: daysToSunday));
    
    // Tạo danh sách tất cả các tuần từ tuần đầu đến tuần cuối
    final weeks = <String, Map<String, DateTime>>{};
    var currentMonday = DateTime(firstMonday.year, firstMonday.month, firstMonday.day);
    final endSunday = DateTime(lastSunday.year, lastSunday.month, lastSunday.day);
    
    // Tạo Set dates để so sánh nhanh hơn
    final datesSet = dates.toSet();
    
    while (!currentMonday.isAfter(endSunday)) {
      final currentSunday = DateTime(
        currentMonday.year,
        currentMonday.month,
        currentMonday.day,
      ).add(const Duration(days: 6));
      
      final weekKey = '${currentMonday.year}-${currentMonday.month}-${currentMonday.day}';
      
      // Kiểm tra xem có session nào trong tuần này không
      // So sánh chính xác bằng cách normalize dates và so sánh year/month/day
      final hasSessionInWeek = datesSet.any((date) {
        final dateYear = date.year;
        final dateMonth = date.month;
        final dateDay = date.day;
        
        final mondayYear = currentMonday.year;
        final mondayMonth = currentMonday.month;
        final mondayDay = currentMonday.day;
        
        final sundayYear = currentSunday.year;
        final sundayMonth = currentSunday.month;
        final sundayDay = currentSunday.day;
        
        // So sánh dates bằng cách so sánh year, month, day
        final dateCompare = dateYear * 10000 + dateMonth * 100 + dateDay;
        final mondayCompare = mondayYear * 10000 + mondayMonth * 100 + mondayDay;
        final sundayCompare = sundayYear * 10000 + sundayMonth * 100 + sundayDay;
        
        return dateCompare >= mondayCompare && dateCompare <= sundayCompare;
      });
      
      if (hasSessionInWeek && !weeks.containsKey(weekKey)) {
        weeks[weekKey] = {
          'start': DateTime(currentMonday.year, currentMonday.month, currentMonday.day),
          'end': DateTime(currentSunday.year, currentSunday.month, currentSunday.day),
        };
      }
      
      currentMonday = currentMonday.add(const Duration(days: 7));
    }
    
    // Sắp xếp các tuần theo thứ tự thời gian
    final sortedWeeks = weeks.values.toList()
      ..sort((a, b) => a['start']!.compareTo(b['start']!));
    
    // Format thành danh sách string
    final weekOptions = <String>[];
    int weekNumber = 1;
    
    for (final week in sortedWeeks) {
      final start = week['start']!;
      final end = week['end']!;
      
      final startStr = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
      final endStr = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
      
      weekOptions.add('Tuần $weekNumber: $startStr - $endStr');
      weekNumber++;
    }
    
    return weekOptions;
  }

  /// Filter sessions theo ngày đã chọn và group
  void _filterByDate(String? date) {
    if (date == null) {
      state = state.copyWith(filteredSessions: []);
      return;
    }

    final filtered = state.allSessions
        .where((s) => _dateIsoOf(s).startsWith(date))
        .toList();

    final grouped = _groupConsecutiveSessions(filtered);
    state = state.copyWith(filteredSessions: grouped);
  }

  /// Gộp các tiết liền kề nhau của cùng môn học thành 1 buổi
  List<Map<String, dynamic>> _groupConsecutiveSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return [];

    final sorted = List<Map<String, dynamic>>.from(sessions);
    sorted.sort((a, b) {
      final dateA = _dateIsoOf(a);
      final dateB = _dateIsoOf(b);
      if (dateA != dateB) return dateA.compareTo(dateB);

      final startA = _startOfStr(a);
      final startB = _startOfStr(b);
      if (startA.isEmpty && startB.isEmpty) return 0;
      if (startA.isEmpty) return 1;
      if (startB.isEmpty) return -1;

      final minutesA = _parseTimeToMinutes(startA);
      final minutesB = _parseTimeToMinutes(startB);
      if (minutesA == null && minutesB == null) return 0;
      if (minutesA == null) return 1;
      if (minutesB == null) return -1;
      return minutesA.compareTo(minutesB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = _subjectOf(current);
      final className = _classNameForGrouping(current);
      final cohort = _cohortForGrouping(current);
      final room = _roomOf(current);
      final date = _dateIsoOf(current);

      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];

      final currentSchedule = (current['schedule'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final currentShift = _getShiftFromSchedule(currentSchedule);

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject = _subjectOf(next);
        final nextClassName = _classNameForGrouping(next);
        final nextCohort = _cohortForGrouping(next);
        final nextRoom = _roomOf(next);
        final nextDate = _dateIsoOf(next);

        final cohortMatch = cohort.isEmpty && nextCohort.isEmpty || cohort == nextCohort;

        if (subject != nextSubject ||
            className != nextClassName ||
            !cohortMatch ||
            room != nextRoom ||
            date != nextDate) {
          break;
        }

        final nextSchedule = (next['schedule'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final nextShift = _getShiftFromSchedule(nextSchedule);
        if (currentShift != nextShift) break;

        final lastEndStr = _endOfStr(group.last);
        final nextStartStr = _startOfStr(next);
        final lastEnd = _parseTimeToMinutes(lastEndStr);
        final nextStart = _parseTimeToMinutes(nextStartStr);

        if (lastEnd == null || nextStart == null) break;

        final gap = nextStart - lastEnd;
        if (gap <= 10 && gap >= 0) {
          group.add(next);
          groupIndices.add(j);
        } else {
          break;
        }
      }

      for (final idx in groupIndices) {
        processed.add(idx);
      }

      if (group.length == 1) {
        result.add(current);
      } else {
        final first = group.first;
        final last = group.last;

        final merged = Map<String, dynamic>.from(first);
        final startTimeMerged = _startOfStr(first);
        final endTimeMerged = _endOfStr(last);

        if (merged['timeslot'] is Map) {
          final ts = Map<String, dynamic>.from(merged['timeslot'] as Map);
          if (startTimeMerged.isNotEmpty) {
            ts['start_time'] = startTimeMerged.split(':').length == 2 ? '$startTimeMerged:00' : startTimeMerged;
          }
          if (endTimeMerged.isNotEmpty) {
            ts['end_time'] = endTimeMerged.split(':').length == 2 ? '$endTimeMerged:00' : endTimeMerged;
          }
          merged['timeslot'] = ts;
        } else {
          merged['timeslot'] = {
            'start_time': startTimeMerged.isNotEmpty
                ? (startTimeMerged.split(':').length == 2 ? '$startTimeMerged:00' : startTimeMerged)
                : null,
            'end_time': endTimeMerged.isNotEmpty
                ? (endTimeMerged.split(':').length == 2 ? '$endTimeMerged:00' : endTimeMerged)
                : null,
          };
        }

        merged['start_time'] = startTimeMerged.split(':').length == 2 ? '$startTimeMerged:00' : startTimeMerged;
        merged['end_time'] = endTimeMerged.split(':').length == 2 ? '$endTimeMerged:00' : endTimeMerged;

        final sessionIds = group.map((s) => int.tryParse('${s['id']}')).whereType<int>().toList();
        merged['_grouped_session_ids'] = sessionIds;

        result.add(merged);
      }
    }

    return result;
  }

  // Helper methods
  String _pickStr(Map data, List<String> paths) {
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

  String _dateIsoOf(Map<String, dynamic> s) {
    final raw = _pickStr(s, ['session_date', 'date', 'timeslot.date', 'period.date', 'start_at']);
    if (raw.isEmpty) return '';
    final only = raw.split(' ').first;
    try {
      final dt = DateTime.parse(only);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return only;
    }
  }

  String _startOfStr(Map<String, dynamic> s) {
    final raw = _pickStr(s, ['timeslot.start_time', 'timeslot.start', 'start_time', 'startTime', 'slot.start']);
    return _hhmm(raw);
  }

  String _endOfStr(Map<String, dynamic> s) {
    final raw = _pickStr(s, ['timeslot.end_time', 'timeslot.end', 'end_time', 'endTime', 'slot.end']);
    return _hhmm(raw);
  }

  String _hhmm(String raw) {
    if (raw.isEmpty) return '';
    final s = raw.trim();
    if (s.contains('T')) {
      try {
        final dt = DateTime.parse(s);
        return DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }
    final parts = s.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return s;
  }

  String _roomOf(Map<String, dynamic> s) {
    if (s['room_nested'] is Map) {
      final r = s['room_nested'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    if (s['room'] is Map) {
      final r = s['room'] as Map;
      final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
      if (code.isNotEmpty) return code;
    }
    if (s['room'] is String && (s['room'] as String).trim().isNotEmpty) {
      return (s['room'] as String).trim();
    }
    if (s['assignment'] is Map) {
      final a = s['assignment'] as Map;
      if (a['room'] is Map) {
        final r = a['room'] as Map;
        final code = _pickStr(r, ['code', 'name', 'room_code', 'title', 'label']);
        if (code.isNotEmpty) return code;
      }
    }
    dynamic rooms = s['rooms'] ?? s['classrooms'] ?? s['room_list'];
    if (rooms is List && rooms.isNotEmpty) {
      final first = rooms.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final fromList = _pickStr(first, ['code', 'name', 'room_code', 'title', 'label']);
        if (fromList.isNotEmpty) return fromList;
      }
    }
    final building = _pickStr(s, ['building', 'building.name', 'block', 'block.name']);
    final num = _pickStr(s, ['room_number', 'roomNo', 'room_no', 'code', 'room_code']);
    if (building.isNotEmpty && num.isNotEmpty) return '$building-$num';
    if (num.isNotEmpty) return num;
    return '';
  }

  String _subjectOf(Map<String, dynamic> s) {
    final result = _pickStr(s, [
      'assignment.subject.name',
      'assignment.subject.title',
      'subject.name',
      'subject.title',
      'subject_nested.name',
      'subject_nested.code',
      'subject_name',
      'subject',
      'course_name',
      'title',
    ]);
    if (result.isEmpty && s['subject'] is Map) {
      final subjMap = s['subject'] as Map;
      final name = _pickStr(subjMap, ['name', 'title', 'code']);
      if (name.isNotEmpty) return name;
    }
    if (result.isEmpty && s['subject_nested'] is Map) {
      final subjMap = s['subject_nested'] as Map;
      final name = _pickStr(subjMap, ['name', 'title', 'code']);
      if (name.isNotEmpty) return name;
    }
    return result.isEmpty ? 'Môn học' : result;
  }

  String _classNameForGrouping(Map<String, dynamic> s) {
    final result = _pickStr(s, [
      'assignment.class_unit.name',
      'assignment.class_unit.code',
      'assignment.classUnit.name',
      'assignment.classUnit.code',
      'class_unit.name',
      'class_unit.code',
      'classUnit.name',
      'classUnit.code',
      'class_name',
      'class',
      'class_code',
      'group_name',
    ]);

    if (result.isEmpty) {
      final cu = s['classUnit'] ?? s['class_unit'];
      if (cu is Map) {
        final name = _pickStr(cu, ['name', 'code']);
        if (name.isNotEmpty) return name;
      }
      if (s['assignment'] is Map) {
        final asg = s['assignment'] as Map;
        final cuInAsg = asg['classUnit'] ?? asg['class_unit'];
        if (cuInAsg is Map) {
          final name = _pickStr(cuInAsg, ['name', 'code']);
          if (name.isNotEmpty) return name;
        }
      }
    }

    return result;
  }

  String _cohortForGrouping(Map<String, dynamic> s) {
    var cohort = _pickStr(s, ['cohort', 'k', 'course', 'batch']);
    if (cohort.isNotEmpty && !cohort.toUpperCase().startsWith('K')) {
      cohort = 'K$cohort';
    }
    return cohort;
  }

  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  int? _getPeriodFromTimeslot(Map<String, dynamic>? timeslot) {
    if (timeslot == null) return null;
    final code = timeslot['code']?.toString() ?? '';
    final match = RegExp(r'CA(\d+)$').firstMatch(code);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  String? _getShiftFromSchedule(Map<String, dynamic> schedule) {
    if (schedule['timeslot'] is Map) {
      final period = _getPeriodFromTimeslot((schedule['timeslot'] as Map).cast<String, dynamic>());
      if (period != null) {
        if (period >= 1 && period <= 6) return 'morning';
        if (period >= 7 && period <= 12) return 'afternoon';
        if (period >= 13 && period <= 15) return 'evening';
      }
    }

    final startTime = _startOfStr(schedule);
    if (startTime.isEmpty || startTime == '--:--') return null;

    final minutes = _parseTimeToMinutes(startTime);
    if (minutes == null) return null;

    if (minutes >= 420 && minutes < 720) return 'morning';
    if (minutes >= 720 && minutes < 1080) return 'afternoon';
    if (minutes >= 1080) return 'evening';

    return null;
  }
}

/// Provider cho LeaveChooseSessionViewModel
final leaveChooseSessionViewModelProvider =
    StateNotifierProvider<LeaveChooseSessionViewModel, LeaveChooseSessionState>((ref) {
  final repository = LeaveChooseSessionRepositoryImpl();
  return LeaveChooseSessionViewModel(repository);
});

