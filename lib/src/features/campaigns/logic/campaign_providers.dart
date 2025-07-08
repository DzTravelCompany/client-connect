import 'package:client_connect/src/core/services/retry_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart' hide RetryLogModel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/campaign_dao.dart';
import '../../../core/services/sending_engine.dart';

// Campaign DAO provider
final campaignDaoProvider = Provider<CampaignDao>((ref) => CampaignDao());

// Retry service provider
final retryServiceProvider = Provider<RetryService>((ref) => RetryService.instance);

// All campaigns stream provider
final allCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.watchAllCampaigns();
});

// Campaign by ID provider
final campaignByIdProvider = FutureProvider.family<CampaignModel?, int>((ref, id) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.getCampaignById(id);
});

// Message logs for campaign provider
final campaignMessageLogsProvider = StreamProvider.family<List<MessageLogModel>, int>((ref, campaignId) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.watchMessageLogs(campaignId);
});

// Campaign statistics provider
final campaignStatisticsProvider = FutureProvider.family<CampaignStatistics, int>((ref, campaignId) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.getCampaignStatistics(campaignId);
});

// Retry logs provider
final retryLogsProvider = FutureProvider.family<List<RetryLogModel>, int>((ref, messageLogId) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.getRetryLogs(messageLogId);
});

// Retryable messages provider
final retryableMessagesProvider = FutureProvider.family<List<MessageLogModel>, int>((ref, campaignId) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.getRetryableMessages(campaignId);
});

// Retry configurations provider
final retryConfigurationsProvider = FutureProvider<List<RetryConfiguration>>((ref) {
  final retryService = ref.watch(retryServiceProvider);
  return retryService.getAllRetryConfigurations();
});

// Default retry configuration provider
final defaultRetryConfigurationProvider = FutureProvider<RetryConfiguration?>((ref) {
  final retryService = ref.watch(retryServiceProvider);
  return retryService.getDefaultRetryConfiguration();
});

// Retry events stream provider
final retryEventsProvider = StreamProvider<RetryEvent>((ref) {
  final retryService = ref.watch(retryServiceProvider);
  return retryService.retryEventStream;
});

// Campaign progress provider
final campaignProgressProvider = StreamProvider<CampaignProgress>((ref) {
  return SendingEngine.instance.progressStream;
});

// Campaign creation provider
final campaignCreationProvider = StateNotifierProvider<CampaignCreationNotifier, CampaignCreationState>((ref) {
  return CampaignCreationNotifier(ref.watch(campaignDaoProvider));
});

// Retry management provider
final retryManagementProvider = StateNotifierProvider<RetryManagementNotifier, RetryManagementState>((ref) {
  return RetryManagementNotifier(ref.watch(retryServiceProvider));
});

// Campaign creation state
class CampaignCreationState {
  final bool isLoading;
  final String? error;
  final bool isCreated;

  const CampaignCreationState({
    this.isLoading = false,
    this.error,
    this.isCreated = false,
  });

  CampaignCreationState copyWith({
    bool? isLoading,
    String? error,
    bool? isCreated,
  }) {
    return CampaignCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCreated: isCreated ?? this.isCreated,
    );
  }
}

// Campaign creation notifier
class CampaignCreationNotifier extends StateNotifier<CampaignCreationState> {
  final CampaignDao _dao;

  CampaignCreationNotifier(this._dao) : super(const CampaignCreationState());

  Future<int?> createCampaign({
    required String name,
    required int templateId,
    required List<int> clientIds,
    required String messageType,
    DateTime? scheduledAt,
    bool startImmediately = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Create campaign in database
      final campaignId = await _dao.createCampaign(
        name: name,
        templateId: templateId,
        clientIds: clientIds,
        messageType: messageType,
        scheduledAt: scheduledAt,
      );

      // Start sending immediately if requested and not scheduled
      if (startImmediately && scheduledAt == null) {
        await SendingEngine.instance.startCampaign(campaignId);
      }

      state = state.copyWith(isLoading: false, isCreated: true);
      return campaignId;
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void resetState() {
    state = const CampaignCreationState();
  }
}

// Retry management state
class RetryManagementState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const RetryManagementState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  RetryManagementState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return RetryManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// Retry management notifier
class RetryManagementNotifier extends StateNotifier<RetryManagementState> {
  final RetryService _retryService;

  RetryManagementNotifier(this._retryService) : super(const RetryManagementState());

  Future<void> retryMessage(int messageLogId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _retryService.triggerManualRetry(messageLogId, reason: reason);
      state = state.copyWith(
        isLoading: false, 
        successMessage: 'Retry scheduled successfully',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> retryCampaign(int campaignId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _retryService.retryFailedMessagesForCampaign(campaignId, reason: reason);
      state = state.copyWith(
        isLoading: false, 
        successMessage: 'Campaign retry scheduled successfully',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveRetryConfiguration(RetryConfiguration config) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _retryService.saveRetryConfiguration(config);
      state = state.copyWith(
        isLoading: false, 
        successMessage: 'Retry configuration saved successfully',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Campaign control provider for starting/stopping campaigns
final campaignControlProvider = Provider<CampaignController>((ref) {
  return CampaignController();
});

class CampaignController {
  Future<void> startCampaign(int campaignId) async {
    await SendingEngine.instance.startCampaign(campaignId);
  }

  Future<void> stopCampaign(int campaignId) async {
    await SendingEngine.instance.stopCampaign(campaignId);
  }

  Future<void> resumeInterruptedCampaigns() async {
    await SendingEngine.instance.resumeInterruptedCampaigns();
  }
}