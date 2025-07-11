import 'package:client_connect/src/core/services/retry_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart' hide RetryLogModel;
import 'package:drift/drift.dart';
import '../../../../constants.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';

class CampaignDao {
  final AppDatabase _db = DatabaseService.instance.database;

  // Watch all campaigns
  Stream<List<CampaignModel>> watchAllCampaigns() {
    return _db.select(_db.campaigns).watch().map(
      (rows) => rows.map((row) => _campaignFromRow(row)).toList(),
    );
  }

  // Get campaign by ID with client IDs
  Future<CampaignModel?> getCampaignById(int id) async {
    final query = _db.select(_db.campaigns)..where((c) => c.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    // Get associated client IDs from message logs
    final messageQuery = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(id));
    final messages = await messageQuery.get();
    final clientIds = messages.map((m) => m.clientId).toSet().toList();

    return _campaignFromRow(row, clientIds);
  }

  // Insert new campaign and create message logs with retry configuration
  Future<int> createCampaign({
    required String name,
    required int templateId,
    required List<int> clientIds,
    required String messageType,
    DateTime? scheduledAt,
  }) async {
    return await _db.transaction(() async {
      // Determine initial status
      final initialStatus = scheduledAt != null && scheduledAt.isAfter(DateTime.now())
          ? 'scheduled'
          : 'pending';

      // Insert campaign
      final campaignId = await _db.into(_db.campaigns).insert(CampaignsCompanion.insert(
        name: name,
        templateId: templateId,
        status: initialStatus,
        scheduledAt: Value(scheduledAt),
      ));

      // Get default retry configuration
      final retryConfig = await RetryService.instance.getDefaultRetryConfiguration();
      final maxRetries = retryConfig?.maxRetries ?? 3;

      // Create message logs for each client with retry configuration
      for (final clientId in clientIds) {
        await _db.into(_db.messageLogs).insert(MessageLogsCompanion.insert(
          campaignId: campaignId,
          clientId: clientId,
          type: messageType,
          status: 'pending',
          maxRetries: Value(maxRetries),
        ));
      }

      return campaignId;
    });
  }

  // Update campaign status
  Future<bool> updateCampaignStatus(int id, String status, {DateTime? completedAt}) async {
    final query = _db.update(_db.campaigns)..where((c) => c.id.equals(id));
    final updatedRows = await query.write(CampaignsCompanion(
      status: Value(status),
      completedAt: Value(completedAt),
    ));
    return updatedRows > 0;
  }

  // Get campaigns that need recovery (in_progress or with pending messages)
  Future<List<CampaignModel>> getCampaignsNeedingRecovery() async {
    final campaignsQuery = _db.select(_db.campaigns)
      ..where((c) => c.status.equals('in_progress') | c.status.equals('pending'));
    
    final campaigns = await campaignsQuery.get();
    List<CampaignModel> needingRecovery = [];

    for (final campaign in campaigns) {
      // Check if campaign has pending messages or messages that can be retried
      final pendingMessagesQuery = _db.select(_db.messageLogs)
        ..where((m) => 
          m.campaignId.equals(campaign.id) & 
          (m.status.equals('pending') | 
           m.status.equals('failed') | 
           m.status.equals('retrying'))
        );
      
      final pendingMessages = await pendingMessagesQuery.get();
      if (pendingMessages.isNotEmpty) {
        final clientIds = pendingMessages.map((m) => m.clientId).toList();
        needingRecovery.add(_campaignFromRow(campaign, clientIds));
      }
    }

    return needingRecovery;
  }

  // Get due scheduled campaigns
  Future<List<CampaignModel>> getDueScheduledCampaigns() async {
    final now = DateTime.now();
    final query = _db.select(_db.campaigns)
      ..where((c) => c.status.equals('scheduled') & c.scheduledAt.isSmallerOrEqualValue(now));
    
    final rows = await query.get();
    return rows.map((row) => _campaignFromRow(row)).toList();
  }

  // Get message logs for a campaign with retry information
  Stream<List<MessageLogModel>> watchMessageLogs(int campaignId) {
    final query = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);
    
    return query.watch().map(
      (rows) => rows.map((row) => _messageLogFromRow(row)).toList(),
    );
  }

  // Get retry logs for a message
  Future<List<RetryLogModel>> getRetryLogs(int messageLogId) async {
    final query = _db.select(_db.retryLogs)
      ..where((r) => r.messageLogId.equals(messageLogId))
      ..orderBy([(r) => OrderingTerm.desc(r.attemptedAt)]);
    
    final rows = await query.get();
    return rows.map((row) => _retryLogFromRow(row)).toList();
  }

  // Get failed messages that can be retried
  Future<List<MessageLogModel>> getRetryableMessages(int campaignId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => 
        m.campaignId.equals(campaignId) &
        (m.status.equals('failed') | m.status.equals('failed_max_retries')) &
        m.retryCount.isSmallerThan(m.maxRetries)
      );
    
    final rows = await query.get();
    return rows.map((row) => _messageLogFromRow(row)).toList();
  }

  // Update message log status with retry handling
  Future<bool> updateMessageStatus(int messageId, String status, {
    String? errorMessage,
    bool shouldScheduleRetry = false,
  }) async {
    return await _db.transaction(() async {
      final updatedRows = await (_db.update(_db.messageLogs)
        ..where((m) => m.id.equals(messageId)))
        .write(MessageLogsCompanion(
          status: Value(status),
          errorMessage: Value(errorMessage),
          sentAt: Value(status == 'sent' ? DateTime.now() : null),
        ));

      // Schedule retry if needed and message failed
      if (shouldScheduleRetry && status == 'failed' && errorMessage != null) {
        try {
          await RetryService.instance.scheduleRetry(
            messageId,
            reason: errorMessage,
          );
        } catch (e) {
          // Log error but don't fail the transaction
          logger.e('Failed to schedule retry for message $messageId: $e');
        }
      }

      return updatedRows > 0;
    });
  }

  // Get pending messages for a campaign (including retry-eligible messages)
  Future<List<MessageLogModel>> getPendingMessages(int campaignId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => 
        m.campaignId.equals(campaignId) & 
        (m.status.equals('pending') | 
         m.status.equals('retrying') |
         (m.status.equals('failed') & m.retryCount.isSmallerThan(m.maxRetries)))
      );
    
    final rows = await query.get();
    return rows.map((row) => _messageLogFromRow(row)).toList();
  }

  // Get campaign statistics including retry information
  Future<CampaignStatistics> getCampaignStatistics(int campaignId) async {
    final messageQuery = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId));
    final messages = await messageQuery.get();

    final retryStats = await RetryService.instance.getRetryStatistics(campaignId);

    return CampaignStatistics(
      totalMessages: messages.length,
      sentMessages: messages.where((m) => m.status == 'sent').length,
      failedMessages: messages.where((m) => m.status == 'failed' || m.status == 'failed_max_retries').length,
      pendingMessages: messages.where((m) => m.status == 'pending' || m.status == 'retrying').length,
      retryStatistics: retryStats,
    );
  }

  // Helper methods
  CampaignModel _campaignFromRow(Campaign row, [List<int>? clientIds]) {
    return CampaignModel(
      id: row.id,
      name: row.name,
      templateId: row.templateId,
      status: row.status,
      scheduledAt: row.scheduledAt,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
      clientIds: clientIds ?? [],
    );
  }

  MessageLogModel _messageLogFromRow(MessageLog row) {
    return MessageLogModel(
      id: row.id,
      campaignId: row.campaignId,
      clientId: row.clientId,
      type: row.type,
      status: row.status,
      errorMessage: row.errorMessage,
      sentAt: row.sentAt,
      createdAt: row.createdAt,
      retryCount: row.retryCount,
      maxRetries: row.maxRetries,
      nextRetryAt: row.nextRetryAt,
      lastRetryAt: row.lastRetryAt,
      retryReason: row.retryReason,
    );
  }

  RetryLogModel _retryLogFromRow(RetryLog row) {
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
}

// New statistics model
class CampaignStatistics {
  final int totalMessages;
  final int sentMessages;
  final int failedMessages;
  final int pendingMessages;
  final RetryStatistics retryStatistics;

  const CampaignStatistics({
    required this.totalMessages,
    required this.sentMessages,
    required this.failedMessages,
    required this.pendingMessages,
    required this.retryStatistics,
  });

  double get successRate => totalMessages > 0 ? sentMessages / totalMessages : 0.0;
  double get failureRate => totalMessages > 0 ? failedMessages / totalMessages : 0.0;
}