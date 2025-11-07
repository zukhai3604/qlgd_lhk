import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_entry.freezed.dart';

@freezed
class ScheduleEntry with _$ScheduleEntry {
  const factory ScheduleEntry({
    required String id,
    required String courseName,
    required String room,
    required DateTime startTime,
    required DateTime endTime,
    required String lecturerName,
  }) = _ScheduleEntry;
}
