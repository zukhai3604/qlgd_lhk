import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/repositories/makeup_repository.dart';

/// State cho MakeupViewModel
class MakeupState {
  final bool isLoadingRooms;
  final bool isSubmitting;
  final String? error;
  final List<Map<String, dynamic>> rooms;
  final DateTime? selectedDate;
  final Set<int> selectedPeriods;
  final int? selectedRoomId;
  final Map<int, int>? timeslotIdMap;

  const MakeupState({
    this.isLoadingRooms = false,
    this.isSubmitting = false,
    this.error,
    this.rooms = const [],
    this.selectedDate,
    this.selectedPeriods = const {},
    this.selectedRoomId,
    this.timeslotIdMap,
  });

  MakeupState copyWith({
    bool? isLoadingRooms,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? rooms,
    DateTime? selectedDate,
    Set<int>? selectedPeriods,
    int? selectedRoomId,
    Map<int, int>? timeslotIdMap,
  }) {
    return MakeupState(
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      rooms: rooms ?? this.rooms,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPeriods: selectedPeriods ?? this.selectedPeriods,
      selectedRoomId: selectedRoomId ?? this.selectedRoomId,
      timeslotIdMap: timeslotIdMap ?? this.timeslotIdMap,
    );
  }
}

/// ViewModel cho MakeupPage
class MakeupViewModel extends StateNotifier<MakeupState> {
  final MakeupRepository _repository;
  final Map<String, dynamic>? _contextData;

  MakeupViewModel(this._repository, this._contextData) : super(const MakeupState()) {
    _initialize();
  }

  void _initialize() {
    _loadRooms();
    
    // Initialize từ contextData nếu có
    if (_contextData != null) {
      final d = _contextData!;
      final roomId = d['room_id'] ?? d['room']?['id'];
      if (roomId != null) {
        state = state.copyWith(selectedRoomId: int.tryParse(roomId.toString()));
      }

      // Extract timeslot để map với tiết số
      final timeslot = d['timeslot'] as Map?;
      if (timeslot != null && timeslot['code'] != null) {
        final code = timeslot['code'].toString();
        final match = RegExp(r'CA(\d+)$').firstMatch(code);
        if (match != null) {
          final period = int.tryParse(match.group(1) ?? '');
          if (period != null && period >= 1 && period <= 15) {
            state = state.copyWith(selectedPeriods: {period});
          }
        }
      }
    }
  }

  /// Load danh sách phòng học
  Future<void> _loadRooms() async {
    state = state.copyWith(isLoadingRooms: true, clearError: true);

    final result = await _repository.getRooms();
    result.when(
      success: (rooms) {
        // Validate và reset selectedRoomId nếu không tồn tại trong danh sách
        int? validatedRoomId = state.selectedRoomId;
        if (validatedRoomId != null) {
          final exists = rooms.any((room) => (room['id'] as int?) == validatedRoomId);
          if (!exists) {
            validatedRoomId = null;
          }
        }

        state = state.copyWith(
          isLoadingRooms: false,
          rooms: rooms,
          selectedRoomId: validatedRoomId,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingRooms: false,
          error: error.toString(),
          selectedRoomId: null, // Reset để tránh dropdown assertion
        );
      },
    );
  }

  /// Set ngày đã chọn và load timeslot map
  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, clearError: true);

    if (state.selectedPeriods.isNotEmpty) {
      await _loadTimeslotIdMap();
    }
  }

  /// Set periods đã chọn và load timeslot map
  Future<void> selectPeriods(Set<int> periods) async {
    state = state.copyWith(selectedPeriods: periods);

    if (state.selectedDate != null && periods.isNotEmpty) {
      await _loadTimeslotIdMap();
    }
  }

  /// Load timeslot ID map từ API
  Future<void> _loadTimeslotIdMap() async {
    if (state.selectedDate == null || state.selectedPeriods.isEmpty) return;

    final result = await _repository.getTimeslotIdMap(
      selectedDate: state.selectedDate!,
      periods: state.selectedPeriods.toList(),
    );

    result.when(
      success: (map) {
        state = state.copyWith(timeslotIdMap: map);
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  /// Set phòng đã chọn
  void selectRoom(int? roomId) {
    state = state.copyWith(selectedRoomId: roomId);
  }

  /// Submit makeup request
  Future<bool> submitMakeupRequest({
    required List<int> leaveRequestIds,
    required String note,
  }) async {
    if (state.selectedDate == null || state.selectedPeriods.isEmpty) {
      state = state.copyWith(error: 'Vui lòng chọn ngày và khung giờ');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    // Build payloads
    final payloads = <Map<String, dynamic>>[];
    final sortedPeriods = state.selectedPeriods.toList()..sort();

    // Đảm bảo periods là consecutive
    if (!_isConsecutive(sortedPeriods)) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Chỉ được chọn các tiết liền kề nhau',
      );
      return false;
    }

    // Map mỗi period với một leave_request_id
    if (sortedPeriods.length != leaveRequestIds.length) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Số lượng tiết không khớp với số đơn nghỉ',
      );
      return false;
    }

    final dateStr = _formatDate(state.selectedDate!);
    final timeslotIdMap = state.timeslotIdMap ?? {};

    for (int i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i];
      final leaveRequestId = leaveRequestIds[i];
      final timeslotId = timeslotIdMap[period];

      if (timeslotId == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Không tìm thấy timeslot cho tiết $period',
        );
        return false;
      }

      payloads.add({
        'leave_request_id': leaveRequestId,
        'makeup_date': dateStr,
        'timeslot_id': timeslotId,
        'room_id': state.selectedRoomId,
        'note': note,
      });
    }

    final result = payloads.length == 1
        ? await _repository.createMakeupRequest(payloads.first)
        : await _repository.createMultipleMakeupRequests(payloads);

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

  /// Kiểm tra periods có consecutive không
  bool _isConsecutive(List<int> periods) {
    if (periods.length <= 1) return true;
    for (int i = 1; i < periods.length; i++) {
      if (periods[i] - periods[i - 1] != 1) return false;
    }
    return true;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Provider cho MakeupViewModel
final makeupViewModelProvider =
    StateNotifierProvider.family<MakeupViewModel, MakeupState, Map<String, dynamic>?>(
  (ref, contextData) {
    final repository = MakeupRepositoryImpl();
    return MakeupViewModel(repository, contextData);
  },
);

