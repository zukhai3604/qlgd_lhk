import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/features/lecturer/home/model/repositories/home_repository.dart';

/// State cho HomeViewModel
class HomeState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> todaySchedule;
  final Map<String, dynamic> stats;
  final bool showAllSessions;
  final String selectedSemester;

  const HomeState({
    this.isLoading = false,
    this.error,
    this.todaySchedule = const [],
    this.stats = const {},
    this.showAllSessions = false,
    this.selectedSemester = 'Học kỳ I 2025',
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? todaySchedule,
    Map<String, dynamic>? stats,
    bool? showAllSessions,
    String? selectedSemester,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      todaySchedule: todaySchedule ?? this.todaySchedule,
      stats: stats ?? this.stats,
      showAllSessions: showAllSessions ?? this.showAllSessions,
      selectedSemester: selectedSemester ?? this.selectedSemester,
    );
  }
}

/// ViewModel cho HomePage
class HomeViewModel extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeViewModel(this._repository) : super(const HomeState()) {
    // Delay nhẹ để đảm bảo app đã render và network sẵn sàng
    Future.microtask(() => loadData());
  }

  /// Load dữ liệu ban đầu
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final today = DateTime.now();
      final iso = DateFormat('yyyy-MM-dd').format(today);

      // Load schedule và stats song song với timeout
      final scheduleResult = await _repository.getTodaySchedule(iso)
          .timeout(const Duration(seconds: 15));
      final statsResult = await _repository.getStats()
          .timeout(const Duration(seconds: 15));

      scheduleResult.when(
        success: (scheduleData) {
          statsResult.when(
            success: (statsData) {
              final schedule = scheduleData['schedule'] as List<Map<String, dynamic>>;
              final groupedSchedule = _groupConsecutiveSessions(schedule);
              
              // Lấy semester name từ stats nếu có
              final semesterName = statsData['semester']?['name']?.toString() ?? 'Học kỳ I 2025';

              state = state.copyWith(
                isLoading: false,
                todaySchedule: groupedSchedule,
                stats: statsData,
                selectedSemester: semesterName,
              );
            },
            failure: (error) {
              // Nếu stats fail nhưng schedule OK, vẫn hiển thị schedule
              final schedule = scheduleData['schedule'] as List<Map<String, dynamic>>;
              final groupedSchedule = _groupConsecutiveSessions(schedule);
              
              state = state.copyWith(
                isLoading: false,
                todaySchedule: groupedSchedule,
                stats: {}, // Empty stats nếu fail
                // Không set error để không làm gián đoạn UI
              );
            },
          );
        },
        failure: (error) {
          // Nếu schedule fail, vẫn thử load stats
          statsResult.when(
            success: (statsData) {
              final semesterName = statsData['semester']?['name']?.toString() ?? 'Học kỳ I 2025';
              state = state.copyWith(
                isLoading: false,
                todaySchedule: [],
                stats: statsData,
                selectedSemester: semesterName,
                error: 'Không tải được lịch hôm nay: $error',
              );
            },
            failure: (statsError) {
              state = state.copyWith(
                isLoading: false,
                error: 'Không tải được dữ liệu: $error',
              );
            },
          );
        },
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Kết nối timeout. Vui lòng thử lại.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không tải được dữ liệu: $e',
      );
    }
  }

  /// Refresh dữ liệu
  Future<void> refresh() async {
    await loadData();
  }

  /// Toggle hiển thị tất cả sessions
  void toggleShowAllSessions() {
    state = state.copyWith(showAllSessions: !state.showAllSessions);
  }

  /// Thay đổi học kỳ
  void changeSemester(String semester) {
    state = state.copyWith(selectedSemester: semester);
    // TODO: Reload data khi đổi học kỳ
  }

  /// Gộp các tiết liền kề nhau của cùng môn học
  List<Map<String, dynamic>> _groupConsecutiveSessions(
      List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return [];

    final sorted = List<Map<String, dynamic>>.from(sessions);
    sorted.sort((a, b) {
      final startA = (a['start_time'] ?? '').toString();
      final startB = (b['start_time'] ?? '').toString();
      if (startA.isEmpty && startB.isEmpty) return 0;
      if (startA.isEmpty) return 1;
      if (startB.isEmpty) return -1;
      return _parseTimeToMinutes(startA)
          .compareTo(_parseTimeToMinutes(startB));
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = (current['subject'] ?? 'Môn học').toString();
      final className = (current['class_name'] ?? 'Lớp').toString();

      final r = current['room'];
      final room = (r is Map
              ? (r['name']?.toString() ?? r['code']?.toString() ?? '-')
              : r?.toString() ?? '-')
          .trim();

      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];
      final currentShift = _getShiftFromSession(current);

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject = (next['subject'] ?? 'Môn học').toString();
        final nextClassName = (next['class_name'] ?? 'Lớp').toString();

        final nextR = next['room'];
        final nextRoom = (nextR is Map
                ? (nextR['name']?.toString() ?? nextR['code']?.toString() ?? '-')
                : nextR?.toString() ?? '-')
            .trim();

        if (subject != nextSubject ||
            className != nextClassName ||
            room != nextRoom) {
          break;
        }

        final nextShift = _getShiftFromSession(next);
        if (currentShift != nextShift) break;

        final lastEndStr = (group.last['end_time'] ?? '--:--').toString();
        final nextStartStr = (next['start_time'] ?? '--:--').toString();

        final lastEnd = _parseTimeToMinutes(lastEndStr);
        final nextStart = _parseTimeToMinutes(nextStartStr);

        if (lastEnd == 0 || nextStart == 0) break;

        final gap = nextStart - lastEnd;
        if (gap <= 60 && gap >= 0) {
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
        result.add(group.first);
      } else {
        final first = group.first;
        final last = group.last;

        final merged = Map<String, dynamic>.from(first);
        
        // ✅ Lấy thời gian từ timeslot nếu không có trực tiếp
        String startTime = (first['start_time'] ?? '').toString();
        String endTime = (last['end_time'] ?? '').toString();
        
        // Fallback: Lấy từ timeslot nếu chưa có
        if ((startTime.isEmpty || startTime == '--:--') && first['timeslot'] is Map) {
          final timeslot = first['timeslot'] as Map;
          startTime = (timeslot['start_time'] ?? '').toString();
        }
        if ((endTime.isEmpty || endTime == '--:--') && last['timeslot'] is Map) {
          final timeslot = last['timeslot'] as Map;
          endTime = (timeslot['end_time'] ?? '').toString();
        }
        
        if (startTime.isEmpty) startTime = '--:--';
        if (endTime.isEmpty) endTime = '--:--';

        merged['start_time'] = startTime;
        merged['end_time'] = endTime;

        final sessionIds = group
            .map((s) => int.tryParse('${s['id']}'))
            .whereType<int>()
            .toList();
        merged['_grouped_session_ids'] = sessionIds;

        result.add(merged);
      }
    }

    return result;
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return 0;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }

  String? _getShiftFromSession(Map<String, dynamic> session) {
    if (session['timeslot'] is Map) {
      final period =
          _getPeriodFromTimeslot((session['timeslot'] as Map).cast<String, dynamic>());
      if (period != null) {
        if (period >= 1 && period <= 6) return 'morning';
        if (period >= 7 && period <= 12) return 'afternoon';
        if (period >= 13 && period <= 15) return 'evening';
      }
    }

    final startTime = (session['start_time'] ?? '--:--').toString();
    if (startTime.isEmpty || startTime == '--:--') return null;

    final minutes = _parseTimeToMinutes(startTime);
    if (minutes >= 420 && minutes < 720) return 'morning';
    if (minutes >= 720 && minutes < 1080) return 'afternoon';
    if (minutes >= 1080) return 'evening';

    return null;
  }

  int? _getPeriodFromTimeslot(Map<String, dynamic> timeslot) {
    final periodStr = timeslot['period']?.toString();
    if (periodStr == null) return null;
    return int.tryParse(periodStr);
  }
}

/// Provider cho HomeViewModel
final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  // ✅ Keep alive để tránh dispose khi navigate (tối ưu performance)
  ref.keepAlive();
  
  final repository = HomeRepositoryImpl();
  return HomeViewModel(repository);
});

