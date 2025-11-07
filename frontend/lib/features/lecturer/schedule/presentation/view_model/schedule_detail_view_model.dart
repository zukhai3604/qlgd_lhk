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
    this.status = 'PLANNED',
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
        // Giữ nguyên status từ backend (uppercase) để hiển thị đúng
        final rawStatus = (detail['status'] ?? 'PLANNED').toString().toUpperCase();
        final status = rawStatus; // Giữ nguyên để helper methods hoạt động đúng

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
    // Log trạng thái hiện tại trước khi gọi API
    print('DEBUG endLesson: Current status: ${state.status}');
    print('DEBUG endLesson: Has attendance: ${state.hasAttendance}');
    print('DEBUG endLesson: Confirmed: $confirmed');
    
    // Reload attendance status trước khi check
    await checkAttendance();
    
    // Log sau khi check attendance
    print('DEBUG endLesson: After checkAttendance - Has attendance: ${state.hasAttendance}');
    
    // Kiểm tra status trước khi gọi API
    final currentStatus = state.status.toUpperCase();
    if (currentStatus != 'PLANNED' && currentStatus != 'TEACHING') {
      print('DEBUG endLesson: Invalid status: $currentStatus');
      state = state.copyWith(
        error: 'Không thể kết thúc buổi học. Trạng thái hiện tại: ${_getStatusLabel(currentStatus)}',
      );
      return false;
    }
    
    // Nếu chưa confirm và không có attendance, cần confirm
    if (!confirmed && state.hasAttendance == false) {
      print('DEBUG endLesson: Need confirmation (no attendance)');
      return false; // Return false để trigger confirmation dialog
    }

    print('DEBUG endLesson: Calling API...');
    final result = await _repository.endLesson(sessionId);
    return result.when(
      success: (data) {
        // Giữ nguyên status từ backend (uppercase)
        final newStatus = (data['status'] ?? 'DONE').toString().toUpperCase();
        print('DEBUG endLesson: Success - New status: $newStatus');

        state = state.copyWith(status: newStatus, clearError: true);
        loadData(); // Reload để cập nhật UI
        return true;
      },
      failure: (error) {
        // Giữ nguyên error message từ repository
        final errorMessage = error.toString().replaceFirst('Exception: ', '');
        print('DEBUG endLesson: Failure - Error: $errorMessage');
        state = state.copyWith(error: errorMessage);
        return false;
      },
    );
  }
  
  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return 'Đã lên kế hoạch';
      case 'TEACHING':
        return 'Đang dạy';
      case 'DONE':
        return 'Đã hoàn thành';
      case 'CANCELED':
        return 'Đã hủy';
      case 'MAKEUP_PLANNED':
        return 'Dạy bù đã lên kế hoạch';
      case 'MAKEUP_DONE':
        return 'Dạy bù đã hoàn thành';
      default:
        return status;
    }
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

  Future<bool> deleteMaterial(int materialId) async {
    final result = await _repository.deleteMaterial(sessionId, materialId);
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

  Future<bool> submitReport({String? noteOverride}) async {
    // Nếu status đã là DONE hoặc CANCELED, không cho phép thay đổi status nữa
    final currentStatus = state.status.toUpperCase();
    final isFinalized = currentStatus == 'DONE' || currentStatus == 'CANCELED';
    
    // Ưu tiên dùng noteOverride nếu có (từ TextField controller), nếu không thì dùng state.note
    final noteToSend = noteOverride ?? state.note;
    
    print('DEBUG submitReport: noteOverride=$noteOverride, state.note=${state.note}, noteToSend=$noteToSend');
    
    final result = await _repository.submitReport(
      sessionId: sessionId,
      status: isFinalized ? null : state.status.toLowerCase(), // Gửi lowercase cho API
      // Luôn gửi note (kể cả rỗng) để backend có thể cập nhật/xóa
      note: noteToSend.trim(),
    );

    return result.when(
      success: (_) {
        // Reload data sau khi lưu thành công để hiển thị note mới từ backend
        // Delay một chút để đảm bảo backend đã commit transaction
        Future.delayed(const Duration(milliseconds: 100), () {
          loadData();
        });
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  void updateStatus(String status) {
    // Normalize thành uppercase để consistency
    state = state.copyWith(status: status.toUpperCase());
  }

  void updateNote(String note) {
    state = state.copyWith(note: note);
  }

  /// Kết thúc buổi học cho một sessionId cụ thể (dùng cho grouped sessions)
  Future<bool> endLessonForSession(int targetSessionId, {bool confirmed = false}) async {
    print('DEBUG endLessonForSession: Target sessionId: $targetSessionId');
    
    // Kiểm tra status của session đó
    final detailResult = await _repository.getDetail(targetSessionId);
    String? currentStatus;
    detailResult.when(
      success: (detail) {
        currentStatus = (detail['status'] ?? 'PLANNED').toString().toUpperCase();
      },
      failure: (_) {
        // Nếu không load được, vẫn thử kết thúc
      },
    );
    
    if (currentStatus != null && currentStatus != 'PLANNED' && currentStatus != 'TEACHING') {
      print('DEBUG endLessonForSession: Invalid status for session $targetSessionId: $currentStatus');
      return false;
    }
    
    // Kiểm tra attendance cho session đó
    final attendanceResult = await _repository.hasAttendance(targetSessionId);
    bool? hasAtt;
    attendanceResult.when(
      success: (hasAttendance) {
        hasAtt = hasAttendance;
      },
      failure: (_) {
        hasAtt = false;
      },
    );
    
    // Nếu chưa confirm và không có attendance, cần confirm
    if (!confirmed && hasAtt == false) {
      print('DEBUG endLessonForSession: Need confirmation for session $targetSessionId (no attendance)');
      return false;
    }

    print('DEBUG endLessonForSession: Calling API for session $targetSessionId');
    final result = await _repository.endLesson(targetSessionId);
    return result.when(
      success: (_) {
        print('DEBUG endLessonForSession: Success for session $targetSessionId');
        return true;
      },
      failure: (error) {
        print('DEBUG endLessonForSession: Failure for session $targetSessionId - $error');
        return false;
      },
    );
  }

  /// Lưu note cho một sessionId cụ thể (dùng cho grouped sessions)
  Future<bool> submitReportForSession(int targetSessionId, String note) async {
    print('DEBUG submitReportForSession: Target sessionId: $targetSessionId, note: $note');
    
    final result = await _repository.submitReport(
      sessionId: targetSessionId,
      status: null, // Không thay đổi status khi lưu note
      note: note.trim(),
    );

    return result.when(
      success: (_) {
        print('DEBUG submitReportForSession: Success for session $targetSessionId');
        return true;
      },
      failure: (error) {
        print('DEBUG submitReportForSession: Failure for session $targetSessionId - $error');
        return false;
      },
    );
  }
}

/// Provider cho ScheduleDetailViewModel
final scheduleDetailViewModelProvider =
    StateNotifierProvider.family<ScheduleDetailViewModel, ScheduleDetailState, int>(
  (ref, sessionId) {
    return ScheduleDetailViewModel(ScheduleDetailRepositoryImpl(), sessionId);
  },
);

