import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_dto.freezed.dart';
part 'schedule_dto.g.dart';

@freezed
class ScheduleDto with _$ScheduleDto {
  const factory ScheduleDto({
    required String id,
    required String courseName,
    required String room,
    required String startTime, // Representing DateTime as String in DTO
    required String endTime,
    required String lecturerName,
  }) = _ScheduleDto;

  factory ScheduleDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleDtoFromJson(json);
}
