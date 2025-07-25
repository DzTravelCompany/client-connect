import 'dart:async';
import '../../../constants.dart';
import '../realtime/event_bus.dart';
import '../realtime/realtime_sync_service.dart';
import 'sending_engine.dart';

/// Enhanced sending engine with real-time event integration
class EnhancedSendingEngine extends SendingEngine {
  static EnhancedSendingEngine? _instance;
  static EnhancedSendingEngine get instance => _instance ??= EnhancedSendingEngine._();
  
  EnhancedSendingEngine._() : super.internal() {
    _initRealtimeIntegration();
  }

  final RealtimeSyncService _syncService = RealtimeSyncService();

  /// Initialize real-time integration
  void _initRealtimeIntegration() {
    // Listen to progress updates and emit events
    progressStream.listen((progress) {
      _syncService.emitEvent(CampaignEvent(
        campaignId: progress.campaignId,
        type: CampaignEventType.progressUpdated,
        timestamp: DateTime.now(),
        source: 'EnhancedSendingEngine',
        metadata: {'progress': progress},
      ));
    });
  }

  @override
  Future<void> startCampaign(int campaignId) async {
    try {
      // Emit campaign starting event
      _syncService.emitEvent(CampaignEvent(
        campaignId: campaignId,
        type: CampaignEventType.started,
        timestamp: DateTime.now(),
        source: 'EnhancedSendingEngine',
      ));

      await super.startCampaign(campaignId);
      
      logger.i('Enhanced campaign $campaignId started with real-time tracking');
    } catch (e) {
      // Emit campaign failed event
      _syncService.emitEvent(CampaignEvent(
        campaignId: campaignId,
        type: CampaignEventType.failed,
        timestamp: DateTime.now(),
        source: 'EnhancedSendingEngine',
        metadata: {'error': e.toString()},
      ));
      rethrow;
    }
  }

  @override
  Future<void> stopCampaign(int campaignId) async {
    await super.stopCampaign(campaignId);
    
    // Emit campaign stopped event
    _syncService.emitEvent(CampaignEvent(
      campaignId: campaignId,
      type: CampaignEventType.paused,
      timestamp: DateTime.now(),
      source: 'EnhancedSendingEngine',
    ));
  }

  @override
  void handleCampaignComplete(int campaignId, CampaignProgress progress) {
    super.handleCampaignComplete(campaignId, progress);
    
    // Emit campaign completed event
    _syncService.emitEvent(CampaignEvent(
      campaignId: campaignId,
      type: CampaignEventType.completed,
      timestamp: DateTime.now(),
      source: 'EnhancedSendingEngine',
      metadata: {
        'total_messages': progress.total,
        'successful_messages': progress.successful,
        'failed_messages': progress.failed,
      },
    ));
  }

  @override
  void handleCampaignError(int campaignId, dynamic error) {
    super.handleCampaignError(campaignId, error);
    
    // Emit campaign failed event
    _syncService.emitEvent(CampaignEvent(
      campaignId: campaignId,
      type: CampaignEventType.failed,
      timestamp: DateTime.now(),
      source: 'EnhancedSendingEngine',
      metadata: {'error': error.toString()},
    ));
  }

  @override
  Future<void> handleMessageFailure(int messageId, String error) async {
    await super.handleMessageFailure(messageId, error);
    
    // Emit message status changed event
    _syncService.emitEvent(CampaignEvent(
      campaignId: 0, // Would need to get campaign ID from message
      type: CampaignEventType.messageStatusChanged,
      timestamp: DateTime.now(),
      source: 'EnhancedSendingEngine',
      metadata: {
        'message_id': messageId,
        'status': 'failed',
        'error': error,
      },
    ));
  }

  /// Get real-time campaign status
  Stream<CampaignStatus> getCampaignStatusStream(int campaignId) {
    return _syncService.on<CampaignEvent>()
        .where((event) => event.campaignId == campaignId)
        .map((event) => CampaignStatus(
          campaignId: campaignId,
          status: _mapEventTypeToStatus(event.type),
          lastUpdated: event.timestamp,
          metadata: event.metadata,
        ));
  }

  /// Get real-time progress for all active campaigns
  Stream<Map<int, CampaignProgress>> getAllCampaignProgressStream() {
    final Map<int, CampaignProgress> progressMap = {};
    
    return progressStream.map((progress) {
      progressMap[progress.campaignId] = progress;
      return Map<int, CampaignProgress>.from(progressMap);
    });
  }

  String _mapEventTypeToStatus(CampaignEventType eventType) {
    switch (eventType) {
      case CampaignEventType.started:
        return 'in_progress';
      case CampaignEventType.paused:
        return 'paused';
      case CampaignEventType.completed:
        return 'completed';
      case CampaignEventType.failed:
        return 'failed';
      case CampaignEventType.cancelled:
        return 'cancelled';
      default:
        return 'unknown';
    }
  }
}

/// Campaign status model for real-time updates
class CampaignStatus {
  final int campaignId;
  final String status;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  const CampaignStatus({
    required this.campaignId,
    required this.status,
    required this.lastUpdated,
    this.metadata,
  });

  @override
  String toString() {
    return 'CampaignStatus(id: $campaignId, status: $status, updated: $lastUpdated)';
  }
}
