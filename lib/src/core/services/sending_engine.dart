import 'dart:isolate';
import 'dart:async';
import 'package:client_connect/src/core/services/isolate_sending_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaign_dao.dart';
import 'package:flutter/foundation.dart';

class SendingEngine {
  static SendingEngine? _instance;
  static SendingEngine get instance => _instance ??= SendingEngine._();
  SendingEngine._();

  final Map<int, SendingIsolateController> _activeIsolates = {};
  final StreamController<CampaignProgress> _progressController = StreamController.broadcast();

  Stream<CampaignProgress> get progressStream => _progressController.stream;

  // Start sending a campaign
  Future<void> startCampaign(int campaignId) async {
    if (_activeIsolates.containsKey(campaignId)) {
      throw Exception('Campaign $campaignId is already running');
    }

    try {
      // Update campaign status to in_progress
      final campaignDao = CampaignDao();
      await campaignDao.updateCampaignStatus(campaignId, 'in_progress');

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
            _handleCampaignComplete(campaignId, progress);
          }
        },
        onError: (error) {
          _handleCampaignError(campaignId, error);
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

  void _handleCampaignComplete(int campaignId, CampaignProgress progress) async {
    final campaignDao = CampaignDao();
    await campaignDao.updateCampaignStatus(
      campaignId, 
      'completed', 
      completedAt: DateTime.now(),
    );
    
    _activeIsolates.remove(campaignId);
    debugPrint('Campaign $campaignId completed successfully');
  }

  void _handleCampaignError(int campaignId, dynamic error) async {
    final campaignDao = CampaignDao();
    await campaignDao.updateCampaignStatus(campaignId, 'failed');
    
    _activeIsolates.remove(campaignId);
    debugPrint('Campaign $campaignId failed: $error');
  }

  void dispose() {
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

  SendingIsolateData({
    required this.campaignId,
    required this.sendPort,
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
  data.sendPort.send(receivePort.sendPort);

  try {
    // Initialize database connection in isolate
    final sendingService = IsolateSendingService();
    await sendingService.initialize();

    // Process the campaign
    await sendingService.processCampaign(
      data.campaignId,
      (progress) => data.sendPort.send(progress),
    );

  } catch (e) {
    data.sendPort.send(SendingError(e.toString()));
  }

  // Listen for stop commands
  receivePort.listen((message) {
    if (message == 'STOP') {
      receivePort.close();
      Isolate.exit();
    }
  });
}