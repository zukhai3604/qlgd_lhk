// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'makeup_history_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MakeupHistoryState {
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get allItems => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get filteredItems =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get originalItems =>
      throw _privateConstructorUsedError; // Lưu items gốc (chưa gộp)
  String? get selectedStatus => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MakeupHistoryStateCopyWith<MakeupHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MakeupHistoryStateCopyWith<$Res> {
  factory $MakeupHistoryStateCopyWith(
          MakeupHistoryState value, $Res Function(MakeupHistoryState) then) =
      _$MakeupHistoryStateCopyWithImpl<$Res, MakeupHistoryState>;
  @useResult
  $Res call(
      {bool isLoading,
      String? error,
      List<Map<String, dynamic>> allItems,
      List<Map<String, dynamic>> filteredItems,
      List<Map<String, dynamic>> originalItems,
      String? selectedStatus});
}

/// @nodoc
class _$MakeupHistoryStateCopyWithImpl<$Res, $Val extends MakeupHistoryState>
    implements $MakeupHistoryStateCopyWith<$Res> {
  _$MakeupHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? error = freezed,
    Object? allItems = null,
    Object? filteredItems = null,
    Object? originalItems = null,
    Object? selectedStatus = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      allItems: null == allItems
          ? _value.allItems
          : allItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      filteredItems: null == filteredItems
          ? _value.filteredItems
          : filteredItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      originalItems: null == originalItems
          ? _value.originalItems
          : originalItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      selectedStatus: freezed == selectedStatus
          ? _value.selectedStatus
          : selectedStatus // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MakeupHistoryStateImplCopyWith<$Res>
    implements $MakeupHistoryStateCopyWith<$Res> {
  factory _$$MakeupHistoryStateImplCopyWith(_$MakeupHistoryStateImpl value,
          $Res Function(_$MakeupHistoryStateImpl) then) =
      __$$MakeupHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      String? error,
      List<Map<String, dynamic>> allItems,
      List<Map<String, dynamic>> filteredItems,
      List<Map<String, dynamic>> originalItems,
      String? selectedStatus});
}

/// @nodoc
class __$$MakeupHistoryStateImplCopyWithImpl<$Res>
    extends _$MakeupHistoryStateCopyWithImpl<$Res, _$MakeupHistoryStateImpl>
    implements _$$MakeupHistoryStateImplCopyWith<$Res> {
  __$$MakeupHistoryStateImplCopyWithImpl(_$MakeupHistoryStateImpl _value,
      $Res Function(_$MakeupHistoryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? error = freezed,
    Object? allItems = null,
    Object? filteredItems = null,
    Object? originalItems = null,
    Object? selectedStatus = freezed,
  }) {
    return _then(_$MakeupHistoryStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      allItems: null == allItems
          ? _value._allItems
          : allItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      filteredItems: null == filteredItems
          ? _value._filteredItems
          : filteredItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      originalItems: null == originalItems
          ? _value._originalItems
          : originalItems // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      selectedStatus: freezed == selectedStatus
          ? _value.selectedStatus
          : selectedStatus // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MakeupHistoryStateImpl implements _MakeupHistoryState {
  const _$MakeupHistoryStateImpl(
      {this.isLoading = true,
      this.error,
      final List<Map<String, dynamic>> allItems = const [],
      final List<Map<String, dynamic>> filteredItems = const [],
      final List<Map<String, dynamic>> originalItems = const [],
      this.selectedStatus})
      : _allItems = allItems,
        _filteredItems = filteredItems,
        _originalItems = originalItems;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  final List<Map<String, dynamic>> _allItems;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get allItems {
    if (_allItems is EqualUnmodifiableListView) return _allItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allItems);
  }

  final List<Map<String, dynamic>> _filteredItems;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get filteredItems {
    if (_filteredItems is EqualUnmodifiableListView) return _filteredItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredItems);
  }

  final List<Map<String, dynamic>> _originalItems;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get originalItems {
    if (_originalItems is EqualUnmodifiableListView) return _originalItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_originalItems);
  }

// Lưu items gốc (chưa gộp)
  @override
  final String? selectedStatus;

  @override
  String toString() {
    return 'MakeupHistoryState(isLoading: $isLoading, error: $error, allItems: $allItems, filteredItems: $filteredItems, originalItems: $originalItems, selectedStatus: $selectedStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MakeupHistoryStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality().equals(other._allItems, _allItems) &&
            const DeepCollectionEquality()
                .equals(other._filteredItems, _filteredItems) &&
            const DeepCollectionEquality()
                .equals(other._originalItems, _originalItems) &&
            (identical(other.selectedStatus, selectedStatus) ||
                other.selectedStatus == selectedStatus));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      error,
      const DeepCollectionEquality().hash(_allItems),
      const DeepCollectionEquality().hash(_filteredItems),
      const DeepCollectionEquality().hash(_originalItems),
      selectedStatus);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MakeupHistoryStateImplCopyWith<_$MakeupHistoryStateImpl> get copyWith =>
      __$$MakeupHistoryStateImplCopyWithImpl<_$MakeupHistoryStateImpl>(
          this, _$identity);
}

abstract class _MakeupHistoryState implements MakeupHistoryState {
  const factory _MakeupHistoryState(
      {final bool isLoading,
      final String? error,
      final List<Map<String, dynamic>> allItems,
      final List<Map<String, dynamic>> filteredItems,
      final List<Map<String, dynamic>> originalItems,
      final String? selectedStatus}) = _$MakeupHistoryStateImpl;

  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  List<Map<String, dynamic>> get allItems;
  @override
  List<Map<String, dynamic>> get filteredItems;
  @override
  List<Map<String, dynamic>> get originalItems;
  @override // Lưu items gốc (chưa gộp)
  String? get selectedStatus;
  @override
  @JsonKey(ignore: true)
  _$$MakeupHistoryStateImplCopyWith<_$MakeupHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
