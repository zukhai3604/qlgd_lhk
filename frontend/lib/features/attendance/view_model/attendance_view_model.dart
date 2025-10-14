import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceViewModelProvider = StateNotifierProvider<AttendanceViewModel, AsyncValue<void>>((ref) {
  return AttendanceViewModel(ref);
});

class AttendanceViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AttendanceViewModel(this._ref) : super(const AsyncData(null));
  
  // Add methods to submit attendance data here
}
