/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Database-related errors
class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Validation errors
class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError({
    required super.message,
    this.fieldErrors = const {},
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Business logic errors
class BusinessLogicError extends AppError {
  const BusinessLogicError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication/Authorization errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
