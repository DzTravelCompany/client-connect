import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

enum WhatsAppErrorType {
  networkError,
  authenticationError,
  rateLimitError,
  mediaUploadError,
  messageFormatError,
  fileNotFoundError,
  fileSizeError,
  invalidPhoneError,
  apiQuotaError,
  serverError,
  unknownError,
}

enum WhatsAppErrorSeverity {
  low,      // Recoverable, retry possible
  medium,   // Requires user attention
  high,     // Critical, stops operation
  critical, // System-level error
}

class WhatsAppError {
  final WhatsAppErrorType type;
  final WhatsAppErrorSeverity severity;
  final String message;
  final String? details;
  final String? phoneNumber;
  final String? mediaPath;
  final DateTime timestamp;
  final String? apiResponse;
  final int? httpStatusCode;
  final bool isRetryable;

  WhatsAppError({
    required this.type,
    required this.severity,
    required this.message,
    this.details,
    this.phoneNumber,
    this.mediaPath,
    DateTime? timestamp,
    this.apiResponse,
    this.httpStatusCode,
    this.isRetryable = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'details': details,
      'phoneNumber': phoneNumber,
      'mediaPath': mediaPath,
      'timestamp': timestamp.toIso8601String(),
      'apiResponse': apiResponse,
      'httpStatusCode': httpStatusCode,
      'isRetryable': isRetryable,
    };
  }

  factory WhatsAppError.fromJson(Map<String, dynamic> json) {
    return WhatsAppError(
      type: WhatsAppErrorType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WhatsAppErrorType.unknownError,
      ),
      severity: WhatsAppErrorSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => WhatsAppErrorSeverity.medium,
      ),
      message: json['message'] ?? '',
      details: json['details'],
      phoneNumber: json['phoneNumber'],
      mediaPath: json['mediaPath'],
      timestamp: DateTime.parse(json['timestamp']),
      apiResponse: json['apiResponse'],
      httpStatusCode: json['httpStatusCode'],
      isRetryable: json['isRetryable'] ?? false,
    );
  }

  @override
  String toString() {
    return 'WhatsAppError(type: $type, severity: $severity, message: $message)';
  }
}

class WhatsAppErrorHandler {
  static const String _errorLogFileName = 'whatsapp_errors.json';
  static const int _maxErrorLogEntries = 1000;
  
  late File _errorLogFile;
  final List<WhatsAppError> _errorHistory = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(p.join(appDir.path, 'logs'));
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      _errorLogFile = File(p.join(logsDir.path, _errorLogFileName));
      await _loadErrorHistory();
      
      _initialized = true;
      logger.i('WhatsApp error handler initialized');
    } catch (e) {
      logger.e('Failed to initialize error handler: $e');
      _initialized = true; // Continue without error logging
    }
  }

  Future<void> _loadErrorHistory() async {
    try {
      if (await _errorLogFile.exists()) {
        final jsonString = await _errorLogFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        _errorHistory.clear();
        for (final errorJson in jsonList) {
          try {
            _errorHistory.add(WhatsAppError.fromJson(errorJson));
          } catch (e) {
            logger.w('Failed to parse error log entry: $e');
          }
        }
        
        logger.i('Loaded ${_errorHistory.length} error log entries');
      }
    } catch (e) {
      logger.e('Failed to load error history: $e');
      _errorHistory.clear();
    }
  }

  Future<void> _saveErrorHistory() async {
    try {
      // Keep only the most recent entries
      if (_errorHistory.length > _maxErrorLogEntries) {
        _errorHistory.removeRange(0, _errorHistory.length - _maxErrorLogEntries);
      }
      
      final jsonList = _errorHistory.map((error) => error.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _errorLogFile.writeAsString(jsonString);
      
      logger.d('Saved ${_errorHistory.length} error log entries');
    } catch (e) {
      logger.e('Failed to save error history: $e');
    }
  }

  Future<WhatsAppError> handleError(
    Exception exception, {
    String? phoneNumber,
    String? mediaPath,
    String? context,
  }) async {
    if (!_initialized) await initialize();
    
    final error = _categorizeError(exception, phoneNumber, mediaPath, context);
    
    // Log the error
    _logError(error, context);
    
    // Save to error history
    _errorHistory.add(error);
    await _saveErrorHistory();
    
    return error;
  }

  WhatsAppError _categorizeError(
    Exception exception,
    String? phoneNumber,
    String? mediaPath,
    String? context,
  ) {
    if (exception is DioException) {
      return _handleDioError(exception, phoneNumber, mediaPath, context);
    } else if (exception is FileSystemException) {
      return _handleFileSystemError(exception, mediaPath, context);
    } else {
      return WhatsAppError(
        type: WhatsAppErrorType.unknownError,
        severity: WhatsAppErrorSeverity.medium,
        message: 'Unexpected error: ${exception.toString()}',
        details: context,
        phoneNumber: phoneNumber,
        mediaPath: mediaPath,
        isRetryable: false,
      );
    }
  }

  WhatsAppError _handleDioError(
    DioException dioError,
    String? phoneNumber,
    String? mediaPath,
    String? context,
  ) {
    final statusCode = dioError.response?.statusCode;
    final responseData = dioError.response?.data?.toString();
    
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return WhatsAppError(
          type: WhatsAppErrorType.networkError,
          severity: WhatsAppErrorSeverity.low,
          message: 'Network timeout occurred',
          details: 'Connection timed out while ${context ?? "communicating with WhatsApp API"}',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: true,
        );
        
      case DioExceptionType.connectionError:
        return WhatsAppError(
          type: WhatsAppErrorType.networkError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'Network connection failed',
          details: 'Unable to connect to WhatsApp API: ${dioError.message}',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          isRetryable: true,
        );
        
      case DioExceptionType.badResponse:
        return _handleHttpError(statusCode, responseData, phoneNumber, mediaPath, context);
        
      case DioExceptionType.cancel:
        return WhatsAppError(
          type: WhatsAppErrorType.unknownError,
          severity: WhatsAppErrorSeverity.low,
          message: 'Request was cancelled',
          details: context,
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          isRetryable: false,
        );
        
      default:
        return WhatsAppError(
          type: WhatsAppErrorType.networkError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'Network error: ${dioError.message}',
          details: context,
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: true,
        );
    }
  }

  WhatsAppError _handleHttpError(
    int? statusCode,
    String? responseData,
    String? phoneNumber,
    String? mediaPath,
    String? context,
  ) {
    switch (statusCode) {
      case 400:
        return WhatsAppError(
          type: WhatsAppErrorType.messageFormatError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'Invalid message format or parameters',
          details: 'WhatsApp API rejected the request due to invalid format',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: false,
        );
        
      case 401:
        return WhatsAppError(
          type: WhatsAppErrorType.authenticationError,
          severity: WhatsAppErrorSeverity.high,
          message: 'Authentication failed',
          details: 'Invalid API key or expired token',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: false,
        );
        
      case 403:
        return WhatsAppError(
          type: WhatsAppErrorType.authenticationError,
          severity: WhatsAppErrorSeverity.high,
          message: 'Access forbidden',
          details: 'Insufficient permissions or account restrictions',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: false,
        );
        
      case 404:
        return WhatsAppError(
          type: WhatsAppErrorType.invalidPhoneError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'Phone number not found or invalid',
          details: 'The specified phone number is not registered with WhatsApp',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: false,
        );
        
      case 413:
        return WhatsAppError(
          type: WhatsAppErrorType.fileSizeError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'File too large',
          details: 'Media file exceeds WhatsApp size limits',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: false,
        );
        
      case 429:
        return WhatsAppError(
          type: WhatsAppErrorType.rateLimitError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'Rate limit exceeded',
          details: 'Too many requests sent to WhatsApp API',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: true,
        );
        
      case 500:
      case 502:
      case 503:
      case 504:
        return WhatsAppError(
          type: WhatsAppErrorType.serverError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'WhatsApp server error',
          details: 'WhatsApp API is experiencing technical difficulties',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: true,
        );
        
      default:
        return WhatsAppError(
          type: WhatsAppErrorType.unknownError,
          severity: WhatsAppErrorSeverity.medium,
          message: 'HTTP error $statusCode',
          details: 'Unexpected HTTP response from WhatsApp API',
          phoneNumber: phoneNumber,
          mediaPath: mediaPath,
          apiResponse: responseData,
          httpStatusCode: statusCode,
          isRetryable: statusCode != null && statusCode >= 500,
        );
    }
  }

  WhatsAppError _handleFileSystemError(
    FileSystemException fileError,
    String? mediaPath,
    String? context,
  ) {
    if (fileError.osError?.errorCode == 2) { // File not found
      return WhatsAppError(
        type: WhatsAppErrorType.fileNotFoundError,
        severity: WhatsAppErrorSeverity.medium,
        message: 'Media file not found',
        details: 'The specified media file does not exist: ${fileError.path}',
        mediaPath: mediaPath ?? fileError.path,
        isRetryable: false,
      );
    } else {
      return WhatsAppError(
        type: WhatsAppErrorType.mediaUploadError,
        severity: WhatsAppErrorSeverity.medium,
        message: 'File system error',
        details: 'Unable to access media file: ${fileError.message}',
        mediaPath: mediaPath ?? fileError.path,
        isRetryable: false,
      );
    }
  }

  void _logError(WhatsAppError error, String? context) {
    final contextStr = context != null ? ' [$context]' : '';
    
    switch (error.severity) {
      case WhatsAppErrorSeverity.low:
        logger.w('WhatsApp ${error.type.name}$contextStr: ${error.message}');
        break;
      case WhatsAppErrorSeverity.medium:
        logger.e('WhatsApp ${error.type.name}$contextStr: ${error.message}');
        if (error.details != null) {
          logger.e('Details: ${error.details}');
        }
        break;
      case WhatsAppErrorSeverity.high:
      case WhatsAppErrorSeverity.critical:
        logger.e('CRITICAL WhatsApp ${error.type.name}$contextStr: ${error.message}');
        if (error.details != null) {
          logger.e('Details: ${error.details}');
        }
        if (error.apiResponse != null) {
          logger.e('API Response: ${error.apiResponse}');
        }
        break;
    }
  }

  String getUserFriendlyMessage(WhatsAppError error) {
    switch (error.type) {
      case WhatsAppErrorType.networkError:
        return 'Network connection issue. Please check your internet connection and try again.';
      case WhatsAppErrorType.authenticationError:
        return 'WhatsApp API authentication failed. Please check your API credentials in settings.';
      case WhatsAppErrorType.rateLimitError:
        return 'Sending too many messages too quickly. Please wait a moment and try again.';
      case WhatsAppErrorType.mediaUploadError:
        return 'Failed to upload media file. Please check the file and try again.';
      case WhatsAppErrorType.messageFormatError:
        return 'Message format is invalid. Please check your template content.';
      case WhatsAppErrorType.fileNotFoundError:
        return 'Media file not found. Please check the file path and ensure the file exists.';
      case WhatsAppErrorType.fileSizeError:
        return 'Media file is too large. Please use a smaller file.';
      case WhatsAppErrorType.invalidPhoneError:
        return 'Invalid phone number or number not registered with WhatsApp.';
      case WhatsAppErrorType.apiQuotaError:
        return 'WhatsApp API quota exceeded. Please check your account limits.';
      case WhatsAppErrorType.serverError:
        return 'WhatsApp server is experiencing issues. Please try again later.';
      case WhatsAppErrorType.unknownError:
        return 'An unexpected error occurred. Please try again or contact support.';
    }
  }

  List<WhatsAppError> getRecentErrors({int limit = 50}) {
    if (!_initialized) return [];
    
    final recentErrors = _errorHistory.reversed.take(limit).toList();
    return recentErrors;
  }

  Map<WhatsAppErrorType, int> getErrorStatistics({Duration? period}) {
    if (!_initialized) return {};
    
    final cutoffTime = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.fromMillisecondsSinceEpoch(0);
    
    final relevantErrors = _errorHistory
        .where((error) => error.timestamp.isAfter(cutoffTime))
        .toList();
    
    final stats = <WhatsAppErrorType, int>{};
    for (final error in relevantErrors) {
      stats[error.type] = (stats[error.type] ?? 0) + 1;
    }
    
    return stats;
  }

  Future<void> clearErrorHistory() async {
    if (!_initialized) await initialize();
    
    _errorHistory.clear();
    await _saveErrorHistory();
    logger.i('Cleared WhatsApp error history');
  }

  bool shouldRetryError(WhatsAppError error, int attemptCount) {
    if (!error.isRetryable || attemptCount >= 3) {
      return false;
    }
    
    switch (error.type) {
      case WhatsAppErrorType.networkError:
      case WhatsAppErrorType.serverError:
        return attemptCount < 3;
      case WhatsAppErrorType.rateLimitError:
        return attemptCount < 2;
      default:
        return false;
    }
  }

  Duration getRetryDelay(WhatsAppError error, int attemptCount) {
    switch (error.type) {
      case WhatsAppErrorType.rateLimitError:
        // Exponential backoff for rate limiting
        return Duration(seconds: (attemptCount * attemptCount * 5).clamp(5, 60));
      case WhatsAppErrorType.networkError:
        return Duration(seconds: (attemptCount * 2).clamp(1, 10));
      case WhatsAppErrorType.serverError:
        return Duration(seconds: (attemptCount * 3).clamp(3, 15));
      default:
        return Duration(seconds: attemptCount);
    }
  }
}