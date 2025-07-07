import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:drift/drift.dart';
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

  // Insert new campaign and create message logs
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
        status: initialStatus, // Use determined status
        scheduledAt: Value(scheduledAt),
      ));

      // Create message logs for each client
      for (final clientId in clientIds) {
        await _db.into(_db.messageLogs).insert(MessageLogsCompanion.insert(
          campaignId: campaignId,
          clientId: clientId,
          type: messageType,
          status: 'pending',
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
      // Check if campaign has pending messages
      final pendingMessagesQuery = _db.select(_db.messageLogs)
        ..where((m) => m.campaignId.equals(campaign.id) & m.status.equals('pending'));
      
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
    // For scheduled campaigns, we don't need to fetch clientIds immediately,
    // as startCampaign will fetch the full details including pending messages.
    return rows.map((row) => _campaignFromRow(row)).toList();
  }

  // Get message logs for a campaign
  Stream<List<MessageLogModel>> watchMessageLogs(int campaignId) {
    final query = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);
    
    return query.watch().map(
      (rows) => rows.map((row) => _messageLogFromRow(row)).toList(),
    );
  }

  // Update message log status
  Future<bool> updateMessageStatus(int messageId, String status, {String? errorMessage}) async {
    final query = _db.update(_db.messageLogs)..where((m) => m.id.equals(messageId));
    final updatedRows = await query.write(MessageLogsCompanion(
      status: Value(status),
      errorMessage: Value(errorMessage),
      sentAt: Value(status == 'sent' ? DateTime.now() : null),
    ));
    return updatedRows > 0;
  }

  // Get pending messages for a campaign
  Future<List<MessageLogModel>> getPendingMessages(int campaignId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId) & m.status.equals('pending'));
    
    final rows = await query.get();
    return rows.map((row) => _messageLogFromRow(row)).toList();
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
    );
  }
}