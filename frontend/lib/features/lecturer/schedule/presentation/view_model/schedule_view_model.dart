import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleViewModelProvider =
    StateNotifierProvider<ScheduleViewModel, AsyncValue<void>>(
        (ref) => ScheduleViewModel());

class ScheduleViewModel extends StateNotifier<AsyncValue<void>> {
  ScheduleViewModel() : super(const AsyncData(null));

  // Add methods to fetch and update schedule data here.
}
