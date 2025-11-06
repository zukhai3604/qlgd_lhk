import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/repositories/leave_history_repository.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

/// State cho LeaveHistoryViewModel
class LeaveHistoryState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> allItems;
  final List<Map<String, dynamic>> filteredItems;
  final String? selectedStatus; // null = tất cả, 'PENDING', 'APPROVED', 'REJECTED', 'CANCELED'

  const LeaveHistoryState({
    this.isLoading = false,
    this.error,
    this.allItems = const [],
    this.filteredItems = const [],
    this.selectedStatus,
  });

  LeaveHistoryState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? allItems,
    List<Map<String, dynamic>>? filteredItems,
    String? selectedStatus,
  }) {
    return LeaveHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

/// ViewModel cho LeaveHistoryPage
class LeaveHistoryViewModel extends StateNotifier<LeaveHistoryState> {
  final LeaveHistoryRepository _repository;

  LeaveHistoryViewModel(this._repository) : super(const LeaveHistoryState()) {
    loadData();
  }

  /// Load dữ liệu ban đầu
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getLeaveRequests();
    result.when(
      success: (requests) {
        // Lọc bỏ các đơn đã hủy
        final filtered = requests.where((req) {
          final status = (req['status'] ?? '').toString().toUpperCase();
          return status != 'CANCELED';
        }).toList();
        
        // Gộp các đơn liền kề nhau của cùng môn học
        final grouped = _groupConsecutiveLeaveRequests(filtered);
        state = state.copyWith(
          isLoading: false,
          allItems: grouped,
        );
        _applyFilter();
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

  /// Filter theo trạng thái
  void filterByStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilter();
  }

  /// Áp dụng filter
  void _applyFilter() {
    if (state.selectedStatus == null) {
      state = state.copyWith(filteredItems: state.allItems);
    } else {
      final filtered = state.allItems
          .where((item) => (item['status']?.toString().toUpperCase() ?? '') == state.selectedStatus)
          .toList();
      state = state.copyWith(filteredItems: filtered);
    }
  }

  /// Cancel leave request
  Future<bool> cancelLeaveRequest(int leaveRequestId) async {
    final result = await _repository.cancelLeaveRequest(leaveRequestId);
    return result.when(
      success: (_) {
        loadData(); // Reload sau khi hủy thành công
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  /// Cancel multiple leave requests
  Future<bool> cancelMultipleLeaveRequests(List<int> leaveRequestIds) async {
    final result = await _repository.cancelMultipleLeaveRequests(leaveRequestIds);
    return result.when(
      success: (_) {
        loadData(); // Reload sau khi hủy thành công
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  /// Gộp các đơn xin nghỉ liền kề nhau của cùng môn học thành 1 đơn
  List<Map<String, dynamic>> _groupConsecutiveLeaveRequests(
      List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return [];

    // Sắp xếp theo ngày và thời gian bắt đầu
    final sorted = List<Map<String, dynamic>>.from(requests);
    sorted.sort((a, b) {
      final dateA = (a['date'] ?? '').toString();
      final dateB = (b['date'] ?? '').toString();
      if (dateA != dateB) return dateA.compareTo(dateB);

      final startA = (a['start_time'] ?? '--:--').toString();
      final startB = (b['start_time'] ?? '--:--').toString();
      if (startA == '--:--' && startB == '--:--') return 0;
      if (startA == '--:--') return 1;
      if (startB == '--:--') return -1;

      final minutesA = TimeParser.parseToMinutes(startA);
      final minutesB = TimeParser.parseToMinutes(startB);
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
      final subject = (current['subject'] ?? 'Môn học').toString();
      final className = (current['class_name'] ?? 'Lớp').toString();
      final status = (current['status'] ?? 'UNKNOWN').toString();

      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];
      final currentShift = _getShiftFromRequest(current);

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject = (next['subject'] ?? 'Môn học').toString();
        final nextClassName = (next['class_name'] ?? 'Lớp').toString();
        final nextStatus = (next['status'] ?? 'UNKNOWN').toString();

        // Kiểm tra cùng môn, lớp, status
        if (subject != nextSubject || className != nextClassName || status != nextStatus) {
          break;
        }

        // Kiểm tra cùng ngày
        final dateA = (current['date'] ?? '').toString();
        final dateB = (next['date'] ?? '').toString();
        if (dateA != dateB) break;

        // Kiểm tra cùng ca
        final nextShift = _getShiftFromRequest(next);
        if (currentShift != nextShift) break;

        // Kiểm tra liền kề (gap <= 10 phút)
        final lastEndStr = (group.last['end_time'] ?? '--:--').toString();
        final nextStartStr = (next['start_time'] ?? '--:--').toString();

        final lastEnd = TimeParser.parseToMinutes(lastEndStr);
        final nextStart = TimeParser.parseToMinutes(nextStartStr);

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
        final startTime = (first['start_time'] ?? '--:--').toString();
        final endTime = (last['end_time'] ?? '--:--').toString();

        merged['start_time'] = startTime;
        merged['end_time'] = endTime;

        final leaveRequestIds = group
            .map((r) => int.tryParse('${r['leave_request_id']}'))
            .whereType<int>()
            .toList();
        merged['_grouped_leave_request_ids'] = leaveRequestIds;

        result.add(merged);
      }
    }

    return result;
  }

  int? _getPeriodFromTimeslot(Map<String, dynamic> timeslot) {
    final periodStr = timeslot['period']?.toString();
    if (periodStr == null) return null;
    return int.tryParse(periodStr);
  }

  String? _getShiftFromRequest(Map<String, dynamic> request) {
    // Ưu tiên lấy từ period nếu có timeslot trong schedule
    if (request['schedule'] is Map) {
      final schedule = request['schedule'] as Map;
      if (schedule['timeslot'] is Map) {
        final period = _getPeriodFromTimeslot(
            (schedule['timeslot'] as Map).cast<String, dynamic>());
        if (period != null) {
          if (period >= 1 && period <= 6) return 'morning';
          if (period >= 7 && period <= 12) return 'afternoon';
          if (period >= 13 && period <= 15) return 'evening';
        }
      }
    }

    // Fallback: xác định từ thời gian bắt đầu
    final startTime = (request['start_time'] ?? '--:--').toString();
    if (startTime.isEmpty || startTime == '--:--') return null;

    final minutes = TimeParser.parseToMinutes(startTime);
    if (minutes == null) return null;

    if (minutes >= 420 && minutes < 720) return 'morning';
    if (minutes >= 720 && minutes < 1080) return 'afternoon';
    if (minutes >= 1080) return 'evening';

    return null;
  }
}

/// Provider cho LeaveHistoryViewModel
final leaveHistoryViewModelProvider =
    StateNotifierProvider<LeaveHistoryViewModel, LeaveHistoryState>((ref) {
  final repository = LeaveHistoryRepositoryImpl();
  return LeaveHistoryViewModel(repository);
});

