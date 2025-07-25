import 'package:client_connect/src/core/error/app_error.dart';

/// A Result type for handling success and failure states
sealed class Result<T> {
  const Result();

  /// Create a successful result
  const factory Result.success(T data) = Success<T>;

  /// Create a failure result
  const factory Result.failure(AppError error) = Failure<T>;

  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get the data if successful, null otherwise
  T? get data => switch (this) {
    Success<T> success => success.data,
    Failure<T> _ => null,
  };

  /// Get the error if failure, null otherwise
  AppError? get error => switch (this) {
    Success<T> _ => null,
    Failure<T> failure => failure.error,
  };

  /// Transform the result if successful
  Result<U> map<U>(U Function(T) transform) => switch (this) {
    Success<T> success => Result.success(transform(success.data)),
    Failure<T> failure => Result.failure(failure.error),
  };

  /// Handle both success and failure cases
  U fold<U>(
    U Function(T) onSuccess,
    U Function(AppError) onFailure,
  ) => switch (this) {
    Success<T> success => onSuccess(success.data),
    Failure<T> failure => onFailure(failure.error),
  };
}

/// Successful result
final class Success<T> extends Result<T> {
  @override
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure result
final class Failure<T> extends Result<T> {
  @override
  final AppError error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;
}
