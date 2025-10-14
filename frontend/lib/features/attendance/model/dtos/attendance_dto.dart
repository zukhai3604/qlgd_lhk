import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_dto.freezed.dart';
part 'attendance_dto.g.dart';

@freezed
class AttendanceDto with _$AttendanceDto {
  const factory AttendanceDto({
    required String id,
    required String studentId,
    required String scheduleId,
    required bool isPresent,
  }) = _AttendanceDto;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDtoFromJson(json);
}
