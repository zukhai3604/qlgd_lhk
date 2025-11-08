import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/repositories/schedule_repository.dart';

class WeeklyScheduleQuery {
  final String? semesterId;
  final String? weekValue;

  const WeeklyScheduleQuery({
    this.semesterId,
    this.weekValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyScheduleQuery &&
          runtimeType == other.runtimeType &&
          semesterId == other.semesterId &&
          weekValue == other.weekValue;

  @override
  int get hashCode => Object.hash(semesterId, weekValue);
}

/// State cho WeeklyScheduleViewModel
class WeeklyScheduleState {
  final bool isLoading;
  final String? error;
  final WeeklyScheduleResult? data;

  const WeeklyScheduleState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  WeeklyScheduleState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    WeeklyScheduleResult? data,
  }) {
    return WeeklyScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

/// ViewModel cho WeeklySchedulePage
class WeeklyScheduleViewModel extends StateNotifier<WeeklyScheduleState> {
  final ScheduleRepository _repository;
  WeeklyScheduleQuery _query = const WeeklyScheduleQuery();

  WeeklyScheduleViewModel(this._repository) : super(const WeeklyScheduleState()) {
    loadData();
  }

  WeeklyScheduleQuery get query => _query;

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getWeeklySchedule(
      semesterId: _query.semesterId,
      weekValue: _query.weekValue,
    );

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          data: data,
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

  Future<void> updateQuery({
    String? semesterId,
    String? weekValue,
  }) async {
    _query = WeeklyScheduleQuery(
      semesterId: semesterId ?? _query.semesterId,
      weekValue: weekValue ?? _query.weekValue,
    );
    await loadData();
  }

  Future<void> refresh() async {
    await loadData();
  }
}

/// Provider cho WeeklyScheduleViewModel
final weeklyScheduleViewModelProvider =
    StateNotifierProvider.autoDispose<WeeklyScheduleViewModel, WeeklyScheduleState>((ref) {
  // ✅ Keep alive để tránh dispose khi navigate (tối ưu performance)
  ref.keepAlive();
  
  return WeeklyScheduleViewModel(ScheduleRepositoryImpl());
});

