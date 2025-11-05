import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/leave/model/repositories/leave_repository.dart';
import 'package:qlgd_lhk/features/lecturer/leave/utils/leave_data_helpers.dart';

/// State cho LeaveViewModel
class LeaveState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? room;
  final String? subject;

  const LeaveState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.room,
    this.subject,
  });

  LeaveState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    String? room,
    String? subject,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      room: room ?? this.room,
      subject: subject ?? this.subject,
    );
  }
}

/// ViewModel cho LeavePage
class LeaveViewModel extends StateNotifier<LeaveState> {
  final LeaveRepository _repository;
  final Map<String, dynamic> _session;

  LeaveViewModel(this._repository, this._session) : super(const LeaveState()) {
    _loadSessionDetail();
  }

  /// Load chi tiết session nếu thiếu thông tin
  Future<void> _loadSessionDetail() async {
    final roomInline = LeaveDataExtractor.extractRoom(_session);
    final subjectInline = LeaveDataExtractor.extractSubject(_session);

    // Nếu đã có đủ thông tin thì không cần fetch
    if (roomInline.isNotEmpty &&
        subjectInline.isNotEmpty &&
        subjectInline != 'Môn học') {
      state = state.copyWith(
        room: roomInline,
        subject: subjectInline,
      );
      return;
    }

    final sessionId = int.tryParse('${_session['id']}');
    if (sessionId == null || sessionId <= 0) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.getSessionDetail(sessionId);
    result.when(
      success: (detail) {
        final room = roomInline.isNotEmpty ? roomInline : LeaveDataExtractor.extractRoom(detail);
        final subject = (subjectInline.isNotEmpty && subjectInline != 'Môn học')
            ? subjectInline
            : LeaveDataExtractor.extractSubject(detail);

        state = state.copyWith(
          isLoading: false,
          room: room.isNotEmpty ? room : null,
          subject: (subject.isNotEmpty && subject != 'Môn học') ? subject : null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );
  }

  /// Submit leave request
  Future<bool> submitLeaveRequest(String reason) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    // Kiểm tra xem session này có phải là session đã được gộp không
    final groupedIds = _session['_grouped_session_ids'];
    List<int> scheduleIds;

    if (groupedIds is List) {
      scheduleIds = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    } else {
      final id = int.tryParse('${_session['id']}') ?? 0;
      scheduleIds = id > 0 ? [id] : [];
    }

    if (scheduleIds.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Không tìm thấy buổi học hợp lệ',
      );
      return false;
    }

    final result = scheduleIds.length == 1
        ? await _repository.createLeaveRequest(
            scheduleId: scheduleIds.first,
            reason: reason,
          )
        : await _repository.createMultipleLeaveRequests(
            scheduleIds: scheduleIds,
            reason: reason,
          );

    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false);
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          isSubmitting: false,
          error: error.toString(),
        );
        return false;
      },
    );
  }

}

/// Provider cho LeaveViewModel
final leaveViewModelProvider = StateNotifierProvider.family<LeaveViewModel, LeaveState, Map<String, dynamic>>(
  (ref, session) {
    final repository = LeaveRepositoryImpl();
    return LeaveViewModel(repository, session);
  },
);

