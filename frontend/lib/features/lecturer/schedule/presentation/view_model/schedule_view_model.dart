import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleViewModelProvider = StateNotifierProvider<ScheduleViewModel, AsyncValue<void>>((ref) {
  return ScheduleViewModel(ref);
});

class ScheduleViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ScheduleViewModel(this._ref) : super(const AsyncData(null));

  // Add methods to fetch and update schedule data here
}
