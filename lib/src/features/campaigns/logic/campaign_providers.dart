import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/campaign_dao.dart';
import '../../../core/services/sending_engine.dart';

// Campaign DAO provider
final campaignDaoProvider = Provider<CampaignDao>((ref) => CampaignDao());

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

// Campaign progress provider
final campaignProgressProvider = StreamProvider<CampaignProgress>((ref) {
  return SendingEngine.instance.progressStream;
});

// Campaign creation provider
final campaignCreationProvider = StateNotifierProvider<CampaignCreationNotifier, CampaignCreationState>((ref) {
  return CampaignCreationNotifier(ref.watch(campaignDaoProvider));
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