import 'dart:isolate';
import 'dart:async';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/core/services/isolate_sending_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaign_dao.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:client_connect/src/core/services/retry_service.dart';


class SendingEngine {
  static SendingEngine? _instance;
  static SendingEngine get instance => _instance ??= SendingEngine.internal();
  SendingEngine.internal() {
    _initScheduledCampaignsChecker();
  }

  final Map<int, SendingIsolateController> _activeIsolates = {};
  final StreamController<CampaignProgress> _progressController = StreamController.broadcast();
  Timer? _scheduledCampaignsTimer;

  Stream<CampaignProgress> get progressStream => _progressController.stream;

  void _initScheduledCampaignsChecker() {
    // Check for scheduled campaigns every minute
    _scheduledCampaignsTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      try {
        final campaignDao = CampaignDao();
        final dueCampaigns = await campaignDao.getDueScheduledCampaigns();
        for (final campaign in dueCampaigns) {
          if (!_activeIsolates.containsKey(campaign.id)) {
            logger.i('Starting scheduled campaign ${campaign.id}: ${campaign.name}');
            await startCampaign(campaign.id);
          }
        }
      } catch (e) {
        logger.e('Error checking for scheduled campaigns: $e');
      }
    });
  }

  // Start sending a campaign
  Future<void> startCampaign(int campaignId) async {
    if (_activeIsolates.containsKey(campaignId)) {
      throw Exception('Campaign $campaignId is already running');
    }

    try {
      // Update campaign status to in_progress
      logger.i('Starting campaign $campaignId');
      final campaignDao = CampaignDao();
      await campaignDao.updateCampaignStatus(campaignId, 'in_progress');
      logger.i('Campaign $campaignId started successfully');
      // Create isolate controller
      final controller = SendingIsolateController(campaignId);
      _activeIsolates[campaignId] = controller;

      // Start the isolate
      await controller.start();

      // Listen to progress updates
      controller.progressStream.listen(
        (progress) {
          _progressController.add(progress);
          
          // Check if campaign is complete
          if (progress.isComplete) {
            handleCampaignComplete(campaignId, progress);
          }
        },
        onError: (error) {
          handleCampaignError(campaignId, error);
        },
      );

    } catch (e) {
      // Update campaign status to failed
      final campaignDao = CampaignDao();
      await campaignDao.updateCampaignStatus(campaignId, 'failed');
      rethrow;
    }
  }

  // Resume interrupted campaigns on app startup
  Future<void> resumeInterruptedCampaigns() async {
    final campaignDao = CampaignDao();
    final interruptedCampaigns = await campaignDao.getCampaignsNeedingRecovery();

    for (final campaign in interruptedCampaigns) {
      try {
        debugPrint('Resuming interrupted campaign: ${campaign.name}');
        await startCampaign(campaign.id);
      } catch (e) {
        debugPrint('Failed to resume campaign ${campaign.id}: $e');
      }
    }
  }

  // Stop a campaign
  Future<void> stopCampaign(int campaignId) async {
    final controller = _activeIsolates[campaignId];
    if (controller != null) {
      await controller.stop();
      _activeIsolates.remove(campaignId);
    }
  }

  void handleCampaignComplete(int campaignId, CampaignProgress progress) async {
    final campaignDao = CampaignDao();
    await campaignDao.updateCampaignStatus(
      campaignId, 
      'completed', 
      completedAt: DateTime.now(),
    );
    
    _activeIsolates.remove(campaignId);
    debugPrint('Campaign $campaignId completed successfully');
  }

  void handleCampaignError(int campaignId, dynamic error) async {
    final campaignDao = CampaignDao();
    await campaignDao.updateCampaignStatus(campaignId, 'failed');
    
    // Schedule retries for failed messages
    try {
      await RetryService.instance.retryFailedMessagesForCampaign(
        campaignId,
        reason: 'Campaign failed: $error',
      );
    } catch (e) {
      logger.e('Failed to schedule retries for campaign $campaignId: $e');
    }
    
    _activeIsolates.remove(campaignId);
    debugPrint('Campaign $campaignId failed: $error');
  }

  // Handle individual message failure with retry logic
  Future<void> handleMessageFailure(int messageId, String error) async {
    try {
      final campaignDao = CampaignDao();
      await campaignDao.updateMessageStatus(
        messageId,
        'failed',
        errorMessage: error,
        shouldScheduleRetry: true,
      );
    } catch (e) {
      logger.e('Error handling message failure for $messageId: $e');
    }
  }

  void dispose() {
    _scheduledCampaignsTimer?.cancel();
    _progressController.close();
    for (final controller in _activeIsolates.values) {
      controller.stop();
    }
    _activeIsolates.clear();
  }
}

// Isolate controller for managing individual campaign sending
class SendingIsolateController {
  final int campaignId;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  final StreamController<CampaignProgress> _progressController = StreamController();
  Stream<CampaignProgress> get progressStream => _progressController.stream;

  SendingIsolateController(this.campaignId);

  Future<void> start() async {
    _receivePort = ReceivePort();
    
    // Spawn the isolate
    _isolate = await Isolate.spawn(
      _sendingIsolateEntryPoint,
      SendingIsolateData(
        campaignId: campaignId,
        sendPort: _receivePort!.sendPort,
        rootIsolateToken: RootIsolateToken.instance!,
      ),
    );

    // Listen to messages from isolate
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is CampaignProgress) {
        _progressController.add(message);
      } else if (message is SendingError) {
        _progressController.addError(message.error);
      }
    });
  }

  Future<void> stop() async {
    _sendPort?.send('STOP');
    _isolate?.kill();
    _receivePort?.close();
    _progressController.close();
  }
}

// Data class for isolate communication
class SendingIsolateData {
  final int campaignId;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  SendingIsolateData({
    required this.campaignId,
    required this.sendPort,
    required this.rootIsolateToken,
  });
}

// Progress tracking class
class CampaignProgress {
  final int campaignId;
  final int processed;
  final int total;
  final int successful;
  final int failed;
  final String? currentStatus;

  CampaignProgress({
    required this.campaignId,
    required this.processed,
    required this.total,
    required this.successful,
    required this.failed,
    this.currentStatus,
  });

  bool get isComplete => processed >= total;
  double get progressPercentage => total > 0 ? (processed / total) : 0.0;
}

// Error class for isolate communication
class SendingError {
  final String error;
  SendingError(this.error);
}

// ISOLATE ENTRY POINT - This runs in the background isolate
void _sendingIsolateEntryPoint(SendingIsolateData data) async {
  final receivePort = ReceivePort();

  try {

    // CRITICAL: Initialize BackgroundIsolateBinaryMessenger first
    BackgroundIsolateBinaryMessenger.ensureInitialized(data.rootIsolateToken);
    // Send the receive port back to main isolate
    data.sendPort.send(receivePort.sendPort);
    // Initialize database connection in isolate
    final sendingService = IsolateSendingService();
    await sendingService.initialize();

    // Process the campaign
    await sendingService.processCampaign(
      data.campaignId,
      (progress) => data.sendPort.send(progress),
    );

  } catch (e) {
    logger.e('Isolate error: $e', error: e);
    data.sendPort.send(SendingError('Isolate initialization failed: $e'));
  }

  // Listen for stop commands
  receivePort.listen((message) {
    if (message == 'STOP') {
      receivePort.close();
      Isolate.exit();
    }
  });
}