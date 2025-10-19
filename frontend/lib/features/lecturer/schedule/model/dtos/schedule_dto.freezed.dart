// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduleDto _$ScheduleDtoFromJson(Map<String, dynamic> json) {
  return _ScheduleDto.fromJson(json);
}

/// @nodoc
mixin _$ScheduleDto {
  String get id => throw _privateConstructorUsedError;
  String get courseName => throw _privateConstructorUsedError;
  String get room => throw _privateConstructorUsedError;
  String get startTime =>
      throw _privateConstructorUsedError; // Representing DateTime as String in DTO
  String get endTime => throw _privateConstructorUsedError;
  String get lecturerName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScheduleDtoCopyWith<ScheduleDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleDtoCopyWith<$Res> {
  factory $ScheduleDtoCopyWith(
          ScheduleDto value, $Res Function(ScheduleDto) then) =
      _$ScheduleDtoCopyWithImpl<$Res, ScheduleDto>;
  @useResult
  $Res call(
      {String id,
      String courseName,
      String room,
      String startTime,
      String endTime,
      String lecturerName});
}

/// @nodoc
class _$ScheduleDtoCopyWithImpl<$Res, $Val extends ScheduleDto>
    implements $ScheduleDtoCopyWith<$Res> {
  _$ScheduleDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseName = null,
    Object? room = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? lecturerName = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      lecturerName: null == lecturerName
          ? _value.lecturerName
          : lecturerName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleDtoImplCopyWith<$Res>
    implements $ScheduleDtoCopyWith<$Res> {
  factory _$$ScheduleDtoImplCopyWith(
          _$ScheduleDtoImpl value, $Res Function(_$ScheduleDtoImpl) then) =
      __$$ScheduleDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String courseName,
      String room,
      String startTime,
      String endTime,
      String lecturerName});
}

/// @nodoc
class __$$ScheduleDtoImplCopyWithImpl<$Res>
    extends _$ScheduleDtoCopyWithImpl<$Res, _$ScheduleDtoImpl>
    implements _$$ScheduleDtoImplCopyWith<$Res> {
  __$$ScheduleDtoImplCopyWithImpl(
      _$ScheduleDtoImpl _value, $Res Function(_$ScheduleDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseName = null,
    Object? room = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? lecturerName = null,
  }) {
    return _then(_$ScheduleDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      courseName: null == courseName
          ? _value.courseName
          : courseName // ignore: cast_nullable_to_non_nullable
              as String,
      room: null == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      lecturerName: null == lecturerName
          ? _value.lecturerName
          : lecturerName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduleDtoImpl implements _ScheduleDto {
  const _$ScheduleDtoImpl(
      {required this.id,
      required this.courseName,
      required this.room,
      required this.startTime,
      required this.endTime,
      required this.lecturerName});

  factory _$ScheduleDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String courseName;
  @override
  final String room;
  @override
  final String startTime;
// Representing DateTime as String in DTO
  @override
  final String endTime;
  @override
  final String lecturerName;

  @override
  String toString() {
    return 'ScheduleDto(id: $id, courseName: $courseName, room: $room, startTime: $startTime, endTime: $endTime, lecturerName: $lecturerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.lecturerName, lecturerName) ||
                other.lecturerName == lecturerName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, courseName, room, startTime, endTime, lecturerName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleDtoImplCopyWith<_$ScheduleDtoImpl> get copyWith =>
      __$$ScheduleDtoImplCopyWithImpl<_$ScheduleDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleDtoImplToJson(
      this,
    );
  }
}

abstract class _ScheduleDto implements ScheduleDto {
  const factory _ScheduleDto(
      {required final String id,
      required final String courseName,
      required final String room,
      required final String startTime,
      required final String endTime,
      required final String lecturerName}) = _$ScheduleDtoImpl;

  factory _ScheduleDto.fromJson(Map<String, dynamic> json) =
      _$ScheduleDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get courseName;
  @override
  String get room;
  @override
  String get startTime;
  @override // Representing DateTime as String in DTO
  String get endTime;
  @override
  String get lecturerName;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleDtoImplCopyWith<_$ScheduleDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
