import 'dart:async';
import 'dart:math';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/core/services/database_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:drift/drift.dart';

class RetryService {
  static RetryService? _instance;
  static RetryService get instance => _instance ??= RetryService._();
  
  RetryService._() {
    _initRetryProcessor();
  }

  final AppDatabase _db = DatabaseService.instance.database;
  Timer? _retryProcessorTimer;
  final StreamController<RetryEvent> _retryEventController = StreamController.broadcast();

  Stream<RetryEvent> get retryEventStream => _retryEventController.stream;

  void _initRetryProcessor() {
    // Process retries every minute
    _retryProcessorTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        await _processScheduledRetries();
      } catch (e) {
        logger.e('Error processing scheduled retries: $e');
      }
    });
  }

  // Get default retry configuration
  Future<RetryConfiguration?> getDefaultRetryConfiguration() async {
    final query = _db.select(_db.retryConfigurations)
      ..where((config) => config.isDefault.equals(true));
    final result = await query.getSingleOrNull();
    if (result != null) {
      final retryConfiguration = RetryConfiguration(
        id: result.id,
        name: result.name,
        maxRetries: result.maxRetries,
        initialDelayMinutes: result.initialDelayMinutes,
        maxDelayMinutes: result.maxDelayMinutes,
        backoffStrategy: result.backoffStrategy,
        retryOnNetworkError: result.retryOnNetworkError,
        retryOnServerError: result.retryOnServerError,
        retryOnTimeout: result.retryOnTimeout,
        isDefault: result.isDefault,
        updatedAt: result.updatedAt,
        createdAt: result.createdAt
      );
      return retryConfiguration;
    } else {
      return null;
    }
  }

  // Get all retry configurations
  Future<List<RetryConfiguration>> getAllRetryConfigurations() async {
    final query = _db.select(_db.retryConfigurations)
      ..orderBy([(config) => OrderingTerm.desc(config.isDefault)]);
    final results = await query.get();
    return results.map((row) {
    final retryConfiguration = RetryConfiguration(
        id: row.id,
        name: row.name,
        maxRetries: row.maxRetries,
        initialDelayMinutes: row.initialDelayMinutes,
        maxDelayMinutes: row.maxDelayMinutes,
        backoffStrategy: row.backoffStrategy,
        retryOnNetworkError: row.retryOnNetworkError,
        retryOnServerError: row.retryOnServerError,
        retryOnTimeout: row.retryOnTimeout,
        isDefault: row.isDefault,
        updatedAt: row.updatedAt,
        createdAt: row.createdAt
      );
      return retryConfiguration;
    }).toList();
  }

  // Create or update retry configuration
  Future<int> saveRetryConfiguration(RetryConfiguration config) async {
    return await _db.transaction(() async {
      if (config.isDefault) {
        // Ensure only one default configuration exists
        await (_db.update(_db.retryConfigurations)
          ..where((c) => c.isDefault.equals(true)))
          .write(const RetryConfigurationsCompanion(isDefault: Value(false)));
      }

      if (config.id != null) {
        // Update existing
        await (_db.update(_db.retryConfigurations)
          ..where((c) => c.id.equals(config.id!)))
          .write(config.toCompanion());
        return config.id!;
      } else {
        // Insert new
        return await _db.into(_db.retryConfigurations).insert(config.toCompanion());
      }
    });
  }


  // Get retryable messages for a campaign
  Future<List<MessageLogModel>> getRetryableMessagesForCampaign(int campaignId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => 
        m.campaignId.equals(campaignId) &
        (m.status.equals('failed') | m.status.equals('failed_max_retries')) &
        m.retryCount.isSmallerThan(m.maxRetries)
      )
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    final results = await query.get();
    return results.map((row) => MessageLogModel.fromDriftRow(row)).toList();
  }

  // Get recent retry logs for a campaign
  Future<List<RetryLogModel>> getRecentRetryLogsForCampaign(int campaignId, {int limit = 50}) async {
    final query = _db.select(_db.retryLogs).join([
      innerJoin(_db.messageLogs, _db.messageLogs.id.equalsExp(_db.retryLogs.messageLogId))
    ])
      ..where(_db.messageLogs.campaignId.equals(campaignId))
      ..orderBy([OrderingTerm.desc(_db.retryLogs.attemptedAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map((row) => RetryLogModel.fromDriftRow(row.readTable(_db.retryLogs))).toList();
  }

  // Get campaign ID for a message log
  Future<int?> getCampaignIdForMessage(int messageLogId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => m.id.equals(messageLogId));
    final result = await query.getSingleOrNull();
    return result?.campaignId;
  }

  // Schedule a message for retry
  Future<void> scheduleRetry(int messageLogId, {
    String? reason,
    RetryConfiguration? customConfig,
    bool isManualTrigger = false,
  }) async {
    final messageLog = await _getMessageLogById(messageLogId);
    if (messageLog == null) {
      throw Exception('Message log not found: $messageLogId');
    }

    final config = customConfig ?? await getDefaultRetryConfiguration();
    if (config == null) {
      throw Exception('No retry configuration available');
    }

    // Check if we've exceeded max retries
    if (messageLog.retryCount >= config.maxRetries) {
      logger.i('Max retries exceeded for message $messageLogId');
      await _updateMessageStatus(messageLogId, 'failed_max_retries');
      return;
    }

    // Calculate next retry time
    final nextRetryAt = _calculateNextRetryTime(
      messageLog.retryCount,
      config,
    );

    // Update message log with retry information
    await (_db.update(_db.messageLogs)
      ..where((m) => m.id.equals(messageLogId)))
      .write(MessageLogsCompanion(
        nextRetryAt: Value(nextRetryAt),
        retryReason: Value(reason),
        lastRetryAt: Value(DateTime.now()),
      ));

    // Log the retry scheduling
    await _db.into(_db.retryLogs).insert(RetryLogsCompanion.insert(
      messageLogId: messageLogId,
      retryAttempt: messageLog.retryCount + 1,
      status: 'scheduled',
      errorMessage: Value(reason),
      delayMinutes: Value(nextRetryAt.difference(DateTime.now()).inMinutes),
      triggerType: Value(isManualTrigger ? 'manual' : 'automatic'),
    ));

    final campaignId = await getCampaignIdForMessage(messageLogId);

    _retryEventController.add(RetryEvent(
      messageLogId: messageLogId,
      campaignId: campaignId,
      type: RetryEventType.scheduled,
      retryAttempt: messageLog.retryCount + 1,
      nextRetryAt: nextRetryAt,
      reason: reason,
    ));

    logger.i('Scheduled retry for message $messageLogId at $nextRetryAt');
  }

  // Process all scheduled retries that are due
  Future<void> _processScheduledRetries() async {
    final now = DateTime.now();
    final query = _db.select(_db.messageLogs)
      ..where((m) => 
        m.nextRetryAt.isSmallerOrEqualValue(now) &
        m.status.equals('failed') &
        m.retryCount.isSmallerThan(m.maxRetries)
      );

    final dueMessages = await query.get();
    
    for (final message in dueMessages) {
      try {
        await _executeRetry(message.id);
      } catch (e) {
        logger.e('Error executing retry for message ${message.id}: $e');
      }
    }
  }

  // Execute a retry for a specific message
  Future<void> _executeRetry(int messageLogId) async {
    final messageLog = await _getMessageLogById(messageLogId);
    if (messageLog == null) return;

    // Increment retry count
    await (_db.update(_db.messageLogs)
      ..where((m) => m.id.equals(messageLogId)))
      .write(MessageLogsCompanion(
        retryCount: Value(messageLog.retryCount + 1),
        status: const Value('retrying'),
        nextRetryAt: const Value.absent(),
      ));

    // Log the retry attempt
    final retryLogId = await _db.into(_db.retryLogs).insert(RetryLogsCompanion.insert(
      messageLogId: messageLogId,
      retryAttempt: messageLog.retryCount + 1,
      status: 'attempting',
    ));

    final campaignId = await getCampaignIdForMessage(messageLogId);

    _retryEventController.add(RetryEvent(
      messageLogId: messageLogId,
      campaignId: campaignId,
      type: RetryEventType.attempting,
      retryAttempt: messageLog.retryCount + 1,
    ));

    try {
      // Here you would integrate with your actual sending logic
      // For now, we'll simulate the retry attempt
      final success = await _attemptMessageSend(messageLog);
      
      if (success) {
        await _handleRetrySuccess(messageLogId, retryLogId);
      } else {
        await _handleRetryFailure(messageLogId, retryLogId, 'Retry attempt failed');
      }
    } catch (e) {
      await _handleRetryFailure(messageLogId, retryLogId, e.toString());
    }
  }

  // Simulate message sending (replace with actual implementation)
  Future<bool> _attemptMessageSend(MessageLog messageLog) async {
    // This is where you'd integrate with your actual email/WhatsApp sending logic
    // For simulation, we'll randomly succeed or fail
    await Future.delayed(const Duration(seconds: 2));
    return Random().nextBool();
  }

  // Handle successful retry
  Future<void> _handleRetrySuccess(int messageLogId, int retryLogId) async {
    await _db.transaction(() async {
      // Update message log
      await (_db.update(_db.messageLogs)
        ..where((m) => m.id.equals(messageLogId)))
        .write(MessageLogsCompanion(
          status: const Value('sent'),
          sentAt: Value(DateTime.now()),
        ));

      // Update retry log
      await (_db.update(_db.retryLogs)
        ..where((r) => r.id.equals(retryLogId)))
        .write(const RetryLogsCompanion(
          status: Value('success'),
        ));
    });

    final campaignId = await getCampaignIdForMessage(messageLogId);

    _retryEventController.add(RetryEvent(
      messageLogId: messageLogId,
      campaignId: campaignId,
      type: RetryEventType.success,
    ));

    logger.i('Retry successful for message $messageLogId');
  }

  // Handle failed retry
  Future<void> _handleRetryFailure(int messageLogId, int retryLogId, String error) async {
    final messageLog = await _getMessageLogById(messageLogId);
    if (messageLog == null) return;

    await _db.transaction(() async {
      // Update retry log
      await (_db.update(_db.retryLogs)
        ..where((r) => r.id.equals(retryLogId)))
        .write(RetryLogsCompanion(
          status: const Value('failed'),
          errorMessage: Value(error),
        ));

      // Check if we should schedule another retry
      final config = await getDefaultRetryConfiguration();
      if (config != null && messageLog.retryCount < config.maxRetries) {
        // Schedule next retry
        await scheduleRetry(messageLogId, reason: error);
      } else {
        // Mark as permanently failed
        await (_db.update(_db.messageLogs)
          ..where((m) => m.id.equals(messageLogId)))
          .write(const MessageLogsCompanion(
            status: Value('failed_max_retries'),
          ));
      }
    });

    final campaignId = await getCampaignIdForMessage(messageLogId);

    _retryEventController.add(RetryEvent(
      messageLogId: messageLogId,
      campaignId: campaignId,
      type: RetryEventType.failed,
      error: error,
    ));

    logger.i('Retry failed for message $messageLogId: $error');
  }

  // Manual retry trigger
  Future<void> triggerManualRetry(int messageLogId, {String? reason}) async {
    await scheduleRetry(
      messageLogId,
      reason: reason ?? 'Manual retry triggered',
      isManualTrigger: true,
    );
  }

  // Bulk retry for campaign
  Future<void> retryFailedMessagesForCampaign(int campaignId, {String? reason}) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => 
        m.campaignId.equals(campaignId) &
        (m.status.equals('failed') | m.status.equals('failed_max_retries'))
      );

    final failedMessages = await query.get();
    
    for (final message in failedMessages) {
      try {
        // Reset retry count for manual bulk retry
        await (_db.update(_db.messageLogs)
          ..where((m) => m.id.equals(message.id)))
          .write(const MessageLogsCompanion(
            retryCount: Value(0),
            status: Value('failed'),
          ));

        await triggerManualRetry(
          message.id,
          reason: reason ?? 'Bulk campaign retry',
        );
      } catch (e) {
        logger.e('Error scheduling retry for message ${message.id}: $e');
      }
    }
  }

  // Get retry statistics for a campaign
  Future<RetryStatistics> getRetryStatistics(int campaignId) async {
    final messageQuery = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId));
    final messages = await messageQuery.get();

    // Get retry logs for this campaign
    final retryLogQuery = _db.select(_db.retryLogs).join([
      innerJoin(_db.messageLogs, _db.messageLogs.id.equalsExp(_db.retryLogs.messageLogId))
    ])..where(_db.messageLogs.campaignId.equals(campaignId));
    
    final retryLogResults = await retryLogQuery.get();
    final retryLogs = retryLogResults.map((row) => row.readTable(_db.retryLogs)).toList();

    return RetryStatistics(
      totalMessages: messages.length,
      messagesWithRetries: messages.where((m) => m.retryCount > 0).length,
      totalRetryAttempts: retryLogs.length,
      successfulRetries: retryLogs.where((r) => r.status == 'success').length,
      failedRetries: retryLogs.where((r) => r.status == 'failed').length,
      pendingRetries: messages.where((m) => m.nextRetryAt != null && m.nextRetryAt!.isAfter(DateTime.now())).length,
    );
  }

  // Get retry logs for a specific message
  Future<List<RetryLogModel>> getRetryLogsForMessage(int messageLogId) async {
    final query = _db.select(_db.retryLogs)
      ..where((r) => r.messageLogId.equals(messageLogId))
      ..orderBy([(r) => OrderingTerm.desc(r.attemptedAt)]);
    
    final results = await query.get();
    return results.map((row) => RetryLogModel.fromDriftRow(row)).toList();
  }

  // Helper methods
  Future<MessageLog?> _getMessageLogById(int id) async {
    final query = _db.select(_db.messageLogs)..where((m) => m.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<void> _updateMessageStatus(int messageLogId, String status) async {
    await (_db.update(_db.messageLogs)
      ..where((m) => m.id.equals(messageLogId)))
      .write(MessageLogsCompanion(status: Value(status)));
  }

  DateTime _calculateNextRetryTime(int retryCount, RetryConfiguration config) {
    int delayMinutes;
    
    switch (config.backoffStrategy) {
      case 'linear':
        delayMinutes = config.initialDelayMinutes * (retryCount + 1);
        break;
      case 'exponential':
        delayMinutes = (config.initialDelayMinutes * pow(2, retryCount)).toInt();
        break;
      case 'fixed':
      default:
        delayMinutes = config.initialDelayMinutes;
        break;
    }

    // Cap at max delay
    delayMinutes = min(delayMinutes, config.maxDelayMinutes);
    
    return DateTime.now().add(Duration(minutes: delayMinutes));
  }

  void dispose() {
    _retryProcessorTimer?.cancel();
    _retryEventController.close();
  }
}

// Data models for retry functionality
class RetryConfiguration {
  final int? id;
  final String name;
  final int maxRetries;
  final int initialDelayMinutes;
  final int maxDelayMinutes;
  final String backoffStrategy;
  final bool retryOnNetworkError;
  final bool retryOnServerError;
  final bool retryOnTimeout;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RetryConfiguration({
    this.id,
    required this.name,
    required this.maxRetries,
    required this.initialDelayMinutes,
    required this.maxDelayMinutes,
    required this.backoffStrategy,
    required this.retryOnNetworkError,
    required this.retryOnServerError,
    required this.retryOnTimeout,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RetryConfiguration.fromDriftRow(RetryConfiguration row) {
    return RetryConfiguration(
      id: row.id,
      name: row.name,
      maxRetries: row.maxRetries,
      initialDelayMinutes: row.initialDelayMinutes,
      maxDelayMinutes: row.maxDelayMinutes,
      backoffStrategy: row.backoffStrategy,
      retryOnNetworkError: row.retryOnNetworkError,
      retryOnServerError: row.retryOnServerError,
      retryOnTimeout: row.retryOnTimeout,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  RetryConfigurationsCompanion toCompanion() {
    return RetryConfigurationsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(name),
      maxRetries: Value(maxRetries),
      initialDelayMinutes: Value(initialDelayMinutes),
      maxDelayMinutes: Value(maxDelayMinutes),
      backoffStrategy: Value(backoffStrategy),
      retryOnNetworkError: Value(retryOnNetworkError),
      retryOnServerError: Value(retryOnServerError),
      retryOnTimeout: Value(retryOnTimeout),
      isDefault: Value(isDefault),
      updatedAt: Value(DateTime.now()),
    );
  }
}

class RetryEvent {
  final int messageLogId;
  final int? campaignId;
  final RetryEventType type;
  final int? retryAttempt;
  final DateTime? nextRetryAt;
  final String? reason;
  final String? error;

  const RetryEvent({
    required this.messageLogId,
    this.campaignId,
    required this.type,
    this.retryAttempt,
    this.nextRetryAt,
    this.reason,
    this.error,
  });
}

enum RetryEventType {
  scheduled,
  attempting,
  success,
  failed,
}

class RetryStatistics {
  final int totalMessages;
  final int messagesWithRetries;
  final int totalRetryAttempts;
  final int successfulRetries;
  final int failedRetries;
  final int pendingRetries;

  const RetryStatistics({
    required this.totalMessages,
    required this.messagesWithRetries,
    required this.totalRetryAttempts,
    required this.successfulRetries,
    required this.failedRetries,
    required this.pendingRetries,
  });

  double get retrySuccessRate => 
    totalRetryAttempts > 0 ? successfulRetries / totalRetryAttempts : 0.0;
}

// Updated RetryLogModel with proper Drift integration
class RetryLogModel {
  final int id;
  final int messageLogId;
  final int retryAttempt;
  final String status;
  final String? errorMessage;
  final String? errorType;
  final DateTime attemptedAt;
  final int? delayMinutes;
  final String triggerType;

  const RetryLogModel({
    required this.id,
    required this.messageLogId,
    required this.retryAttempt,
    required this.status,
    this.errorMessage,
    this.errorType,
    required this.attemptedAt,
    this.delayMinutes,
    required this.triggerType,
  });

  factory RetryLogModel.fromDriftRow(RetryLog row) {
    return RetryLogModel(
      id: row.id,
      messageLogId: row.messageLogId,
      retryAttempt: row.retryAttempt,
      status: row.status,
      errorMessage: row.errorMessage,
      errorType: row.errorType,
      attemptedAt: row.attemptedAt,
      delayMinutes: row.delayMinutes,
      triggerType: row.triggerType,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isScheduled => status == 'scheduled';
  bool get isAttempting => status == 'attempting';
  bool get isManualTrigger => triggerType == 'manual';
  int get attemptNumber => retryAttempt;
  String? get reason => errorMessage;
}