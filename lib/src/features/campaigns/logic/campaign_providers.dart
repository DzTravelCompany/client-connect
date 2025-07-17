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

// Campaign control provider for starting/stopping campaigns
final campaignControlProvider = Provider<CampaignController>((ref) {
  return CampaignController();
});

// Enhanced campaign metrics provider with real-time updates
final campaignMetricsProvider = StreamProvider.family<CampaignMetrics, int>((ref, campaignId) {
  final dao = ref.watch(campaignDaoProvider);
  return Stream.periodic(const Duration(seconds: 2), (_) async {
    final statistics = await dao.getCampaignStatistics(campaignId);
    final campaign = await dao.getCampaignById(campaignId);
    return CampaignMetrics(
      campaignId: campaignId,
      statistics: statistics,
      campaign: campaign,
      lastUpdated: DateTime.now(),
    );
  }).asyncMap((future) => future);
});

// Campaign filter state provider
final campaignFilterStateProvider = StateNotifierProvider<CampaignFilterNotifier, CampaignFilterState>((ref) {
  return CampaignFilterNotifier();
});

// Campaign detail panel provider
final campaignDetailPanelProvider = StateNotifierProvider<CampaignDetailPanelNotifier, CampaignDetailPanelState>((ref) {
  return CampaignDetailPanelNotifier();
});

// Real-time campaign status updates
final campaignStatusStreamProvider = StreamProvider.family<CampaignModel?, int>((ref, campaignId) {
  final dao = ref.watch(campaignDaoProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => dao.getCampaignById(campaignId))
      .asyncMap((future) => future);
});

// Real-time campaign monitoring provider
final campaignMonitoringProvider = StreamProvider.family<CampaignMonitoringData, int>((ref, campaignId) {
  return Stream.periodic(const Duration(seconds: 1), (_) async {
    final dao = ref.read(campaignDaoProvider);
    final campaign = await dao.getCampaignById(campaignId);
    final statistics = await dao.getCampaignStatistics(campaignId);
    final messageLogs = await dao.watchMessageLogs(campaignId).first;
    
    return CampaignMonitoringData(
      campaign: campaign,
      statistics: statistics,
      messageLogs: messageLogs,
      lastUpdated: DateTime.now(),
      healthScore: _calculateHealthScore(statistics, messageLogs),
    );
  }).asyncMap((future) => future);
});

// Campaign health monitoring provider
final campaignHealthProvider = StreamProvider<List<CampaignHealthIndicator>>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (_) async {
    final dao = ref.read(campaignDaoProvider);
    final campaigns = await dao.watchAllCampaigns().first;
    
    List<CampaignHealthIndicator> healthIndicators = [];
    
    for (final campaign in campaigns.where((c) => c.isInProgress)) {
      final statistics = await dao.getCampaignStatistics(campaign.id);
      final messageLogs = await dao.watchMessageLogs(campaign.id).first;
      
      healthIndicators.add(CampaignHealthIndicator(
        campaignId: campaign.id,
        campaignName: campaign.name,
        healthScore: _calculateHealthScore(statistics, messageLogs),
        status: campaign.status,
        issues: _detectIssues(statistics, messageLogs),
        lastUpdated: DateTime.now(),
      ));
    }
    
    return healthIndicators;
  }).asyncMap((future) => future);
});

// Campaign analytics provider
final campaignAnalyticsProvider = FutureProvider.family<CampaignAnalytics, CampaignAnalyticsRequest>((ref, request) async {
  final dao = ref.read(campaignDaoProvider);
  
  // Get campaigns in date range
  final campaigns = await dao.watchAllCampaigns().first;
  final filteredCampaigns = campaigns.where((campaign) {
    return campaign.createdAt.isAfter(request.startDate) && 
           campaign.createdAt.isBefore(request.endDate);
  }).toList();
  
  // Calculate analytics
  final successRates = <DateTime, double>{};
  final deliveryTimes = <DateTime, Duration>{};
  final templatePerformance = <int, TemplatePerformanceMetrics>{};
  
  for (final campaign in filteredCampaigns) {
    final statistics = await dao.getCampaignStatistics(campaign.id);
    final date = DateTime(campaign.createdAt.year, campaign.createdAt.month, campaign.createdAt.day);
    
    // Success rate trends
    successRates[date] = statistics.successRate;
    
    // Delivery time analysis
    if (campaign.completedAt != null) {
      deliveryTimes[date] = campaign.completedAt!.difference(campaign.createdAt);
    }
    
    // Template performance
    if (!templatePerformance.containsKey(campaign.templateId)) {
      templatePerformance[campaign.templateId] = TemplatePerformanceMetrics(
        templateId: campaign.templateId,
        totalCampaigns: 0,
        totalMessages: 0,
        successfulMessages: 0,
        averageSuccessRate: 0.0,
      );
    }
    
    final metrics = templatePerformance[campaign.templateId]!;
    templatePerformance[campaign.templateId] = metrics.copyWith(
      totalCampaigns: metrics.totalCampaigns + 1,
      totalMessages: metrics.totalMessages + statistics.totalMessages,
      successfulMessages: metrics.successfulMessages + statistics.sentMessages,
    );
  }
  
  // Calculate average success rates for templates
  templatePerformance.forEach((templateId, metrics) {
    templatePerformance[templateId] = metrics.copyWith(
      averageSuccessRate: metrics.totalMessages > 0 
          ? metrics.successfulMessages / metrics.totalMessages 
          : 0.0,
    );
  });
  
  return CampaignAnalytics(
    successRateTrends: successRates,
    deliveryTimeAnalysis: deliveryTimes,
    templatePerformance: templatePerformance.values.toList(),
    totalCampaigns: filteredCampaigns.length,
    averageSuccessRate: filteredCampaigns.isNotEmpty 
        ? successRates.values.reduce((a, b) => a + b) / successRates.length 
        : 0.0,
  );
});

// Enhanced message logs provider with real-time updates
final realTimeMessageLogsProvider = StreamProvider.family<List<EnhancedMessageLog>, int>((ref, campaignId) {
  final dao = ref.read(campaignDaoProvider);
  
  return Stream.periodic(const Duration(seconds: 2), (_) async {
    final messageLogs = await dao.watchMessageLogs(campaignId).first;
    
    List<EnhancedMessageLog> enhancedLogs = [];
    for (final log in messageLogs) {
      final retryLogs = await dao.getRetryLogs(log.id);
      
      enhancedLogs.add(EnhancedMessageLog(
        messageLog: log,
        retryLogs: retryLogs,
        deliveryAttempts: retryLogs.length + 1,
        lastAttemptTime: retryLogs.isNotEmpty 
            ? retryLogs.first.attemptedAt 
            : log.createdAt,
        estimatedNextRetry: log.nextRetryAt,
      ));
    }
    
    return enhancedLogs;
  }).asyncMap((future) => future);
});

// Helper functions
double _calculateHealthScore(CampaignStatistics statistics, List<MessageLogModel> logs) {
  if (statistics.totalMessages == 0) return 1.0;
  
  final successRate = statistics.successRate;
  final failureRate = statistics.failureRate;
  final retryRate = logs.where((log) => log.retryCount > 0).length / statistics.totalMessages;
  
  // Health score calculation (0.0 to 1.0)
  double healthScore = successRate * 0.6 + (1 - failureRate) * 0.3 + (1 - retryRate) * 0.1;
  
  return healthScore.clamp(0.0, 1.0);
}

List<String> _detectIssues(CampaignStatistics statistics, List<MessageLogModel> logs) {
  List<String> issues = [];
  
  if (statistics.failureRate > 0.1) {
    issues.add('High failure rate (${(statistics.failureRate * 100).toStringAsFixed(1)}%)');
  }
  
  final retryRate = logs.where((log) => log.retryCount > 0).length / statistics.totalMessages;
  if (retryRate > 0.2) {
    issues.add('High retry rate (${(retryRate * 100).toStringAsFixed(1)}%)');
  }
  
  final stuckMessages = logs.where((log) => 
    log.status == 'pending' && 
    DateTime.now().difference(log.createdAt).inMinutes > 30
  ).length;
  
  if (stuckMessages > 0) {
    issues.add('$stuckMessages messages stuck in pending state');
  }
  
  return issues;
}

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

// Campaign metrics model
class CampaignMetrics {
  final int campaignId;
  final CampaignStatistics statistics;
  final CampaignModel? campaign;
  final DateTime lastUpdated;

  const CampaignMetrics({
    required this.campaignId,
    required this.statistics,
    required this.campaign,
    required this.lastUpdated,
  });
}

// Campaign filter state
class CampaignFilterState {
  final String searchTerm;
  final List<String> statusFilters;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? templateType;
  final String? sortBy;
  final bool sortAscending;

  const CampaignFilterState({
    this.searchTerm = '',
    this.statusFilters = const [],
    this.startDate,
    this.endDate,
    this.templateType,
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  CampaignFilterState copyWith({
    String? searchTerm,
    List<String>? statusFilters,
    DateTime? startDate,
    DateTime? endDate,
    String? templateType,
    String? sortBy,
    bool? sortAscending,
  }) {
    return CampaignFilterState(
      searchTerm: searchTerm ?? this.searchTerm,
      statusFilters: statusFilters ?? this.statusFilters,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      templateType: templateType ?? this.templateType,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return searchTerm.isNotEmpty ||
           statusFilters.isNotEmpty ||
           startDate != null ||
           endDate != null ||
           templateType != null;
  }
}

// Campaign filter notifier
class CampaignFilterNotifier extends StateNotifier<CampaignFilterState> {
  CampaignFilterNotifier() : super(const CampaignFilterState());

  void updateSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void toggleStatusFilter(String status) {
    final currentFilters = List<String>.from(state.statusFilters);
    if (currentFilters.contains(status)) {
      currentFilters.remove(status);
    } else {
      currentFilters.add(status);
    }
    state = state.copyWith(statusFilters: currentFilters);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setTemplateType(String? type) {
    state = state.copyWith(templateType: type);
  }

  void setSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, sortAscending: ascending);
  }

  void clearFilters() {
    state = const CampaignFilterState();
  }
}

// Campaign detail panel state
class CampaignDetailPanelState {
  final int? selectedCampaignId;
  final bool isVisible;
  final String activeTab;

  const CampaignDetailPanelState({
    this.selectedCampaignId,
    this.isVisible = false,
    this.activeTab = 'overview',
  });

  CampaignDetailPanelState copyWith({
    int? selectedCampaignId,
    bool? isVisible,
    String? activeTab,
  }) {
    return CampaignDetailPanelState(
      selectedCampaignId: selectedCampaignId ?? this.selectedCampaignId,
      isVisible: isVisible ?? this.isVisible,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// Campaign detail panel notifier
class CampaignDetailPanelNotifier extends StateNotifier<CampaignDetailPanelState> {
  CampaignDetailPanelNotifier() : super(const CampaignDetailPanelState());

  void showCampaignDetails(int campaignId) {
    state = state.copyWith(
      selectedCampaignId: campaignId,
      isVisible: true,
      activeTab: 'overview',
    );
  }

  void hidePanel() {
    state = state.copyWith(isVisible: false);
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }
}

// New model classes for real-time monitoring
class CampaignMonitoringData {
  final CampaignModel? campaign;
  final CampaignStatistics statistics;
  final List<MessageLogModel> messageLogs;
  final DateTime lastUpdated;
  final double healthScore;

  const CampaignMonitoringData({
    required this.campaign,
    required this.statistics,
    required this.messageLogs,
    required this.lastUpdated,
    required this.healthScore,
  });
}

class CampaignHealthIndicator {
  final int campaignId;
  final String campaignName;
  final double healthScore;
  final String status;
  final List<String> issues;
  final DateTime lastUpdated;

  const CampaignHealthIndicator({
    required this.campaignId,
    required this.campaignName,
    required this.healthScore,
    required this.status,
    required this.issues,
    required this.lastUpdated,
  });

  bool get isHealthy => healthScore > 0.8 && issues.isEmpty;
  bool get hasWarnings => healthScore > 0.5 && healthScore <= 0.8;
  bool get isCritical => healthScore <= 0.5 || issues.isNotEmpty;
}

class CampaignAnalyticsRequest {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? statusFilters;
  final List<int>? templateIds;

  const CampaignAnalyticsRequest({
    required this.startDate,
    required this.endDate,
    this.statusFilters,
    this.templateIds,
  });
}

class CampaignAnalytics {
  final Map<DateTime, double> successRateTrends;
  final Map<DateTime, Duration> deliveryTimeAnalysis;
  final List<TemplatePerformanceMetrics> templatePerformance;
  final int totalCampaigns;
  final double averageSuccessRate;

  const CampaignAnalytics({
    required this.successRateTrends,
    required this.deliveryTimeAnalysis,
    required this.templatePerformance,
    required this.totalCampaigns,
    required this.averageSuccessRate,
  });
}

class TemplatePerformanceMetrics {
  final int templateId;
  final int totalCampaigns;
  final int totalMessages;
  final int successfulMessages;
  final double averageSuccessRate;

  const TemplatePerformanceMetrics({
    required this.templateId,
    required this.totalCampaigns,
    required this.totalMessages,
    required this.successfulMessages,
    required this.averageSuccessRate,
  });

  TemplatePerformanceMetrics copyWith({
    int? templateId,
    int? totalCampaigns,
    int? totalMessages,
    int? successfulMessages,
    double? averageSuccessRate,
  }) {
    return TemplatePerformanceMetrics(
      templateId: templateId ?? this.templateId,
      totalCampaigns: totalCampaigns ?? this.totalCampaigns,
      totalMessages: totalMessages ?? this.totalMessages,
      successfulMessages: successfulMessages ?? this.successfulMessages,
      averageSuccessRate: averageSuccessRate ?? this.averageSuccessRate,
    );
  }
}

class EnhancedMessageLog {
  final MessageLogModel messageLog;
  final List<RetryLogModel> retryLogs;
  final int deliveryAttempts;
  final DateTime lastAttemptTime;
  final DateTime? estimatedNextRetry;

  const EnhancedMessageLog({
    required this.messageLog,
    required this.retryLogs,
    required this.deliveryAttempts,
    required this.lastAttemptTime,
    this.estimatedNextRetry,
  });

  bool get hasRetries => retryLogs.isNotEmpty;
  bool get isRetryable => messageLog.retryCount < messageLog.maxRetries && messageLog.isFailed;
  Duration? get timeSinceLastAttempt => DateTime.now().difference(lastAttemptTime);
}