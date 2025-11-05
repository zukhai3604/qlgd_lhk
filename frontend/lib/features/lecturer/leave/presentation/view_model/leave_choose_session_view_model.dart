import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/repositories/leave_choose_session_repository.dart';

/// State cho LeaveChooseSessionViewModel
class LeaveChooseSessionState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> allSessions;
  final List<Map<String, dynamic>> filteredSessions;
  final List<String> dateOptions;
  final String? selectedDate;

  const LeaveChooseSessionState({
    this.isLoading = false,
    this.error,
    this.allSessions = const [],
    this.filteredSessions = const [],
    this.dateOptions = const [],
    this.selectedDate,
  });

  LeaveChooseSessionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? allSessions,
    List<Map<String, dynamic>>? filteredSessions,
    List<String>? dateOptions,
    String? selectedDate,
  }) {
    return LeaveChooseSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      allSessions: allSessions ?? this.allSessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      dateOptions: dateOptions ?? this.dateOptions,
      selectedDate: selectedDate ?? this.selectedDate,
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
      success: (sessions) {
        // Tập ngày cho dropdown
        final opts = <String>{};
        for (final s in sessions) {
          final d = _dateIsoOf(s);
          if (d.isNotEmpty) opts.add(d);
        }
        final sorted = opts.toList()..sort();

        final selectedDate = sorted.isNotEmpty ? sorted.first : null;

        state = state.copyWith(
          isLoading: false,
          allSessions: sessions,
          dateOptions: sorted,
          selectedDate: selectedDate,
        );

        _filterByDate(selectedDate);
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

  /// Chọn ngày và filter sessions
  void selectDate(String? date) {
    state = state.copyWith(selectedDate: date);
    _filterByDate(date);
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

