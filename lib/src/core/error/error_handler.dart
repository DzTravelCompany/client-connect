import 'package:fluent_ui/fluent_ui.dart';
import 'package:logging/logging.dart';
import 'app_error.dart';

/// Centralized error handling service
class AppErrorHandler {
  static final Logger _logger = Logger('AppErrorHandler');

  /// Handle errors with appropriate user feedback and logging
  static void handleError(
    Object error,
    StackTrace stackTrace, {
    required BuildContext context,
    String? userMessage,
    bool showToUser = true,
    bool logError = true,
  }) {
    // Log the error
    if (logError) {
      _logError(error, stackTrace);
    }

    // Show user-friendly message if requested
    if (showToUser && context.mounted) {
      _showErrorToUser(context, error, userMessage);
    }
  }

  /// Handle async errors in a safe way
  static Future<T?> handleAsyncError<T>(
    Future<T> Function() operation, {
    required BuildContext context,
    String? userMessage,
    bool showToUser = true,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context,
        userMessage: userMessage,
        showToUser: showToUser,
      );
      return fallbackValue;
    }
  }

  /// Log error with appropriate level based on error type
  static void _logError(Object error, StackTrace stackTrace) {
    if (error is AppError) {
      switch (error.runtimeType) {
        case NetworkError _:
          _logger.warning('Network Error: ${error.message}', error, stackTrace);
          break;
        case DatabaseError _:
          _logger.severe('Database Error: ${error.message}', error, stackTrace);
          break;
        case ValidationError _:
          _logger.info('Validation Error: ${error.message}', error, stackTrace);
          break;
        case BusinessLogicError _:
          _logger.warning('Business Logic Error: ${error.message}', error, stackTrace);
          break;
        case AuthError _:
          _logger.warning('Auth Error: ${error.message}', error, stackTrace);
          break;
        default:
          _logger.severe('Unknown App Error: ${error.message}', error, stackTrace);
      }
    } else {
      _logger.severe('Unhandled Error: $error', error, stackTrace);
    }
  }

  /// Show error to user with appropriate styling
  static void _showErrorToUser(BuildContext context, Object error, String? userMessage) {
    String displayMessage;
    InfoBarSeverity severity;

    if (error is AppError) {
      displayMessage = userMessage ?? _getDefaultUserMessage(error);
      severity = _getSeverityForError(error);
    } else {
      displayMessage = userMessage ?? 'An unexpected error occurred. Please try again.';
      severity = InfoBarSeverity.error;
    }

    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(_getTitleForSeverity(severity)),
        content: Text(displayMessage),
        severity: severity,
        onClose: close,
      ),
    );
  }

  /// Get default user-friendly message for error types
  static String _getDefaultUserMessage(AppError error) {
    switch (error.runtimeType) {
      case NetworkError _:
        return 'Network connection problem. Please check your internet connection and try again.';
      case DatabaseError _:
        return 'Data storage error. Please try again or contact support if the problem persists.';
      case ValidationError _:
        return error.message; // Validation messages are already user-friendly
      case BusinessLogicError _:
        return error.message; // Business logic messages are usually user-friendly
      case AuthError _:
        return 'Authentication error. Please check your credentials and try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get severity level for different error types
  static InfoBarSeverity _getSeverityForError(AppError error) {
    switch (error.runtimeType) {
      case NetworkError _:
        return InfoBarSeverity.warning;
      case DatabaseError _:
        return InfoBarSeverity.error;
      case ValidationError _:
        return InfoBarSeverity.info;
      case BusinessLogicError _:
        return InfoBarSeverity.warning;
      case AuthError _:
        return InfoBarSeverity.error;
      default:
        return InfoBarSeverity.error;
    }
  }

  /// Get title for different severity levels
  static String _getTitleForSeverity(InfoBarSeverity severity) {
    switch (severity) {
      case InfoBarSeverity.info:
        return 'Information';
      case InfoBarSeverity.warning:
        return 'Warning';
      case InfoBarSeverity.error:
        return 'Error';
      case InfoBarSeverity.success:
        return 'Success';
    }
  }
}

/// Extension to make error handling more convenient
extension ErrorHandlingExtension on BuildContext {
  void handleError(
    Object error,
    StackTrace stackTrace, {
    String? userMessage,
    bool showToUser = true,
  }) {
    AppErrorHandler.handleError(
      error,
      stackTrace,
      context: this,
      userMessage: userMessage,
      showToUser: showToUser,
    );
  }

  Future<T?> handleAsyncError<T>(
    Future<T> Function() operation, {
    String? userMessage,
    bool showToUser = true,
    T? fallbackValue,
  }) {
    return AppErrorHandler.handleAsyncError(
      operation,
      context: this,
      userMessage: userMessage,
      showToUser: showToUser,
      fallbackValue: fallbackValue,
    );
  }
}