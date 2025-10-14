import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// A class to represent a result that can be either a success or a failure.
@freezed
abstract class Result<T, E> with _$Result<T, E> {
  /// Represents a successful result.
  const factory Result.success(T data) = Success<T, E>;

  /// Represents a failed result.
  const factory Result.failure(E error) = Failure<T, E>;
}
