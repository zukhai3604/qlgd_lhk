import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/repositories/schedule_detail_repository.dart';

/// State cho ScheduleDetailViewModel
class ScheduleDetailState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? detail;
  final List<Map<String, dynamic>> materials;
  final String status;
  final String note;
  final bool? hasAttendance; // null = chưa check, true/false = đã check

  const ScheduleDetailState({
    this.isLoading = false,
    this.error,
    this.detail,
    this.materials = const [],
    this.status = 'done',
    this.note = '',
    this.hasAttendance,
  });

  ScheduleDetailState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? detail,
    List<Map<String, dynamic>>? materials,
    String? status,
    String? note,
    bool? hasAttendance,
  }) {
    return ScheduleDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      detail: detail ?? this.detail,
      materials: materials ?? this.materials,
      status: status ?? this.status,
      note: note ?? this.note,
      hasAttendance: hasAttendance ?? this.hasAttendance,
    );
  }
}

/// ViewModel cho ScheduleDetailPage
class ScheduleDetailViewModel extends StateNotifier<ScheduleDetailState> {
  final ScheduleDetailRepository _repository;
  final int sessionId;

  ScheduleDetailViewModel(this._repository, this.sessionId)
      : super(const ScheduleDetailState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final detailResult = await _repository.getDetail(sessionId);
    final materialsResult = await _repository.getMaterials(sessionId);

    detailResult.when(
      success: (detail) {
        final rawStatus = (detail['status'] ?? '').toString().toLowerCase();
        final status = switch (rawStatus) {
          'done' => 'done',
          'teaching' => 'teaching',
          'canceled' || 'cancelled' => 'canceled',
          _ => 'done',
        };

        final note = (detail['note'] ?? '').toString();

        state = state.copyWith(
          isLoading: false,
          detail: detail,
          status: status,
          note: note,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );

    materialsResult.when(
      success: (materials) {
        state = state.copyWith(materials: materials);
      },
      failure: (_) {
        // Không update error nếu materials fail, chỉ log
      },
    );

    // Check attendance khi load data
    await checkAttendance();
  }

  Future<void> checkAttendance() async {
    final result = await _repository.hasAttendance(sessionId);
    result.when(
      success: (hasAtt) {
        state = state.copyWith(hasAttendance: hasAtt);
      },
      failure: (_) {
        // Không update error nếu check attendance fail
      },
    );
  }

  Future<bool> endLesson({bool confirmed = false}) async {
    // Nếu chưa confirm và không có attendance, cần confirm
    if (!confirmed && state.hasAttendance == false) {
      return false; // Return false để trigger confirmation dialog
    }

    final result = await _repository.endLesson(sessionId);
    return result.when(
      success: (data) {
        final newStatus = (data['status'] ?? '').toString().toLowerCase();
        final status = switch (newStatus) {
          'done' => 'done',
          'canceled' || 'cancelled' => 'canceled',
          _ => 'done',
        };

        state = state.copyWith(status: status);
        loadData(); // Reload để cập nhật UI
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<bool> addMaterial(String title) async {
    if (title.trim().isEmpty) return false;

    final result = await _repository.addMaterial(sessionId, title.trim());
    return result.when(
      success: (_) {
        loadData(); // Reload để cập nhật materials
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  Future<bool> uploadMaterial(String title, String filePath) async {
    if (title.trim().isEmpty) return false;

    final result = await _repository.uploadMaterial(sessionId, title.trim(), filePath);
    return result.when(
      success: (_) {
        loadData(); // Reload để cập nhật materials
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  Future<bool> submitReport() async {
    // Nếu status đã là DONE hoặc CANCELED, không cho phép thay đổi status nữa
    final currentStatus = state.status.toLowerCase();
    final isFinalized = currentStatus == 'done' || currentStatus == 'canceled';
    
    final result = await _repository.submitReport(
      sessionId: sessionId,
      status: isFinalized ? null : state.status, // Không gửi status nếu đã kết thúc
      note: state.note.trim().isNotEmpty ? state.note.trim() : null,
    );

    return result.when(
      success: (_) => true,
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  void updateNote(String note) {
    state = state.copyWith(note: note);
  }
}

/// Provider cho ScheduleDetailViewModel
final scheduleDetailViewModelProvider =
    StateNotifierProvider.family<ScheduleDetailViewModel, ScheduleDetailState, int>(
  (ref, sessionId) {
    return ScheduleDetailViewModel(ScheduleDetailRepositoryImpl(), sessionId);
  },
);

