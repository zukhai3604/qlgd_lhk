// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleDtoImpl _$$ScheduleDtoImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleDtoImpl(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      room: json['room'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      lecturerName: json['lecturerName'] as String,
    );

Map<String, dynamic> _$$ScheduleDtoImplToJson(_$ScheduleDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseName': instance.courseName,
      'room': instance.room,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'lecturerName': instance.lecturerName,
    };
