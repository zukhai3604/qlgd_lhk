import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_record.freezed.dart';

@freezed
class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required String id,
    required String studentId,
    required String scheduleId,
    required bool isPresent,
  }) = _AttendanceRecord;
}
