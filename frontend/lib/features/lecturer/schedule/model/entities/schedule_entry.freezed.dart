// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScheduleEntry {
  String get id => throw _privateConstructorUsedError;
  String get courseName => throw _privateConstructorUsedError;
  String get room => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime get endTime => throw _privateConstructorUsedError;
  String get lecturerName => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScheduleEntryCopyWith<ScheduleEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleEntryCopyWith<$Res> {
  factory $ScheduleEntryCopyWith(
          ScheduleEntry value, $Res Function(ScheduleEntry) then) =
      _$ScheduleEntryCopyWithImpl<$Res, ScheduleEntry>;
  @useResult
  $Res call(
      {String id,
      String courseName,
      String room,
      DateTime startTime,
      DateTime endTime,
      String lecturerName});
}

/// @nodoc
class _$ScheduleEntryCopyWithImpl<$Res, $Val extends ScheduleEntry>
    implements $ScheduleEntryCopyWith<$Res> {
  _$ScheduleEntryCopyWithImpl(this._value, this._then);

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
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lecturerName: null == lecturerName
          ? _value.lecturerName
          : lecturerName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleEntryImplCopyWith<$Res>
    implements $ScheduleEntryCopyWith<$Res> {
  factory _$$ScheduleEntryImplCopyWith(
          _$ScheduleEntryImpl value, $Res Function(_$ScheduleEntryImpl) then) =
      __$$ScheduleEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String courseName,
      String room,
      DateTime startTime,
      DateTime endTime,
      String lecturerName});
}

/// @nodoc
class __$$ScheduleEntryImplCopyWithImpl<$Res>
    extends _$ScheduleEntryCopyWithImpl<$Res, _$ScheduleEntryImpl>
    implements _$$ScheduleEntryImplCopyWith<$Res> {
  __$$ScheduleEntryImplCopyWithImpl(
      _$ScheduleEntryImpl _value, $Res Function(_$ScheduleEntryImpl) _then)
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
    return _then(_$ScheduleEntryImpl(
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
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lecturerName: null == lecturerName
          ? _value.lecturerName
          : lecturerName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ScheduleEntryImpl implements _ScheduleEntry {
  const _$ScheduleEntryImpl(
      {required this.id,
      required this.courseName,
      required this.room,
      required this.startTime,
      required this.endTime,
      required this.lecturerName});

  @override
  final String id;
  @override
  final String courseName;
  @override
  final String room;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final String lecturerName;

  @override
  String toString() {
    return 'ScheduleEntry(id: $id, courseName: $courseName, room: $room, startTime: $startTime, endTime: $endTime, lecturerName: $lecturerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleEntryImpl &&
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

  @override
  int get hashCode => Object.hash(
      runtimeType, id, courseName, room, startTime, endTime, lecturerName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleEntryImplCopyWith<_$ScheduleEntryImpl> get copyWith =>
      __$$ScheduleEntryImplCopyWithImpl<_$ScheduleEntryImpl>(this, _$identity);
}

abstract class _ScheduleEntry implements ScheduleEntry {
  const factory _ScheduleEntry(
      {required final String id,
      required final String courseName,
      required final String room,
      required final DateTime startTime,
      required final DateTime endTime,
      required final String lecturerName}) = _$ScheduleEntryImpl;

  @override
  String get id;
  @override
  String get courseName;
  @override
  String get room;
  @override
  DateTime get startTime;
  @override
  DateTime get endTime;
  @override
  String get lecturerName;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleEntryImplCopyWith<_$ScheduleEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
