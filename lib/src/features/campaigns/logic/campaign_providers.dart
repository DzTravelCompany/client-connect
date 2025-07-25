import 'package:client_connect/src/core/realtime/event_bus.dart';
import 'package:client_connect/src/core/realtime/realtime_sync_service.dart';
import 'package:client_connect/src/core/services/retry_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart' hide RetryLogModel;
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants.dart';
import '../data/campaign_dao.dart';
import '../../../core/services/sending_engine.dart';
import 'package:rxdart/rxdart.dart';

// Campaign DAO provider
final campaignDaoProvider = Provider<CampaignDao>((ref) => CampaignDao());

// Retry service provider
final retryServiceProvider = Provider<RetryService>((ref) => RetryService.instance);

// Event-driven campaign list with proper event integration
final allCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  final dao = ref.watch(campaignDaoProvider);
  final syncService = RealtimeSyncService();
  
  // Watch database changes and emit events
  return dao.watchAllCampaigns().map((campaigns) {
    // Emit event for other components
    syncService.emitEvent(DatabaseEvent(
      tableName: 'campaigns',
      type: DatabaseEventType.update,
      timestamp: DateTime.now(),
      source: 'CampaignProvider',
      metadata: {'count': campaigns.length},
    ));
    return campaigns;
  });
});

// Campaign by ID provider
final campaignByIdProvider = StreamProvider.family<CampaignModel?, int>((ref, id) {
  final dao = ref.watch(campaignDaoProvider);
  return dao.watchCampaignById(id);
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
  return CampaignCreationNotifier(ref.watch(campaignDaoProvider), ref);
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

// Event-driven campaign health provider
final campaignHealthProvider = StreamProvider<List<CampaignHealthIndicator>>((ref) {
  final syncService = RealtimeSyncService();
  
  // Initial load
  final initialStream = Stream.fromFuture(_fetchHealthIndicators(ref));
  
  // Event-driven updates
  final eventStream = syncService.on<CampaignEvent>()
      .debounceTime(const Duration(milliseconds: 500))
      .asyncMap((_) => _fetchHealthIndicators(ref));
  
  return Rx.merge([initialStream, eventStream]).distinct();
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
        lastAttemptTime: retryLogs.first.attemptedAt,
        estimatedNextRetry: log.nextRetryAt,
      ));
    }
    
    return enhancedLogs;
  }).asyncMap((future) => future);
});

// Campaign actions provider
final campaignActionsProvider = StateNotifierProvider<CampaignActionsNotifier, CampaignActionsState>((ref) {
  return CampaignActionsNotifier(
    ref.watch(campaignDaoProvider),
    ref.watch(campaignControlProvider),
    ref.watch(retryServiceProvider),
  );
});

// Bulk campaign operations provider
final bulkCampaignOperationsProvider = StateNotifierProvider<BulkCampaignOperationsNotifier, BulkCampaignOperationsState>((ref) {
  return BulkCampaignOperationsNotifier(
    ref.watch(campaignDaoProvider),
    ref.watch(campaignControlProvider),
  );
});

// Campaign scheduling provider
final campaignSchedulingProvider = StateNotifierProvider<CampaignSchedulingNotifier, CampaignSchedulingState>((ref) {
  return CampaignSchedulingNotifier(ref.watch(campaignDaoProvider));
});

// Campaign duplication provider
final campaignDuplicationProvider = StateNotifierProvider<CampaignDuplicationNotifier, CampaignDuplicationState>((ref) {
  return CampaignDuplicationNotifier(
    ref.watch(campaignDaoProvider),
    templateByIdProvider,
  );
});

// Campaign export provider
final campaignExportProvider = StateNotifierProvider<CampaignExportNotifier, CampaignExportState>((ref) {
  return CampaignExportNotifier(ref.watch(campaignDaoProvider));
});

Future<List<CampaignHealthIndicator>> _fetchHealthIndicators(Ref ref) async {
  // Implementation moved to separate function for reuse
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
}

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
  final Ref _ref;

  CampaignCreationNotifier(this._dao, this._ref) : super(const CampaignCreationState());

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

      // Invalidate all campaign-related providers
      _ref.invalidate(allCampaignsProvider);
      _ref.invalidate(campaignByIdProvider(campaignId));
      _ref.invalidate(campaignHealthProvider);
      
      // Also invalidate client campaigns for affected clients
      for (final clientId in clientIds) {
        _ref.invalidate(clientCampaignsProvider(clientId));
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

// Campaign Actions State and Notifier
class CampaignActionsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Map<int, bool> loadingStates;

  const CampaignActionsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.loadingStates = const {},
  });

  CampaignActionsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<int, bool>? loadingStates,
  }) {
    return CampaignActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }
}

class CampaignActionsNotifier extends StateNotifier<CampaignActionsState> {
  final CampaignDao _dao;
  final CampaignController _controller;
  final RetryService _retryService;

  CampaignActionsNotifier(this._dao, this._controller, this._retryService) 
      : super(const CampaignActionsState());

  Future<void> startCampaign(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      await _controller.startCampaign(campaignId);
      state = state.copyWith(
        successMessage: 'Campaign started successfully',
        error: null,
      );
    } catch (e) {
      logger.e('Error starting campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to start campaign: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  Future<void> pauseCampaign(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      await _controller.stopCampaign(campaignId);
      await _dao.updateCampaignStatus(campaignId, 'paused');
      state = state.copyWith(
        successMessage: 'Campaign paused successfully',
        error: null,
      );
    } catch (e) {
      logger.e('Error pausing campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to pause campaign: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  Future<void> resumeCampaign(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      await _dao.updateCampaignStatus(campaignId, 'pending');
      await _controller.startCampaign(campaignId);
      state = state.copyWith(
        successMessage: 'Campaign resumed successfully',
        error: null,
      );
    } catch (e) {
      logger.e('Error resuming campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to resume campaign: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  Future<void> cancelCampaign(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      await _controller.stopCampaign(campaignId);
      await _dao.updateCampaignStatus(campaignId, 'cancelled');
      state = state.copyWith(
        successMessage: 'Campaign cancelled successfully',
        error: null,
      );
    } catch (e) {
      logger.e('Error cancelling campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to cancel campaign: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  Future<void> deleteCampaign(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      // Stop campaign if running
      await _controller.stopCampaign(campaignId);
      
      // Delete from database (this would need to be implemented in DAO)
      // await _dao.deleteCampaign(campaignId);
      
      state = state.copyWith(
        successMessage: 'Campaign deleted successfully',
        error: null,
      );
    } catch (e) {
      logger.e('Error deleting campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to delete campaign: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  Future<void> retryFailedMessages(int campaignId) async {
    _setLoadingForCampaign(campaignId, true);
    
    try {
      await _retryService.retryFailedMessagesForCampaign(
        campaignId,
        reason: 'Manual retry triggered from campaign actions',
      );
      state = state.copyWith(
        successMessage: 'Failed messages scheduled for retry',
        error: null,
      );
    } catch (e) {
      logger.e('Error retrying failed messages for campaign $campaignId: $e');
      state = state.copyWith(
        error: 'Failed to retry messages: $e',
        successMessage: null,
      );
    } finally {
      _setLoadingForCampaign(campaignId, false);
    }
  }

  void _setLoadingForCampaign(int campaignId, bool loading) {
    final newLoadingStates = Map<int, bool>.from(state.loadingStates);
    if (loading) {
      newLoadingStates[campaignId] = true;
    } else {
      newLoadingStates.remove(campaignId);
    }
    
    state = state.copyWith(
      loadingStates: newLoadingStates,
      isLoading: newLoadingStates.isNotEmpty,
    );
  }

  bool isLoadingForCampaign(int campaignId) {
    return state.loadingStates[campaignId] ?? false;
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Bulk Campaign Operations State and Notifier
class BulkCampaignOperationsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<int> selectedCampaignIds;
  final Map<String, int> operationProgress;

  const BulkCampaignOperationsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.selectedCampaignIds = const [],
    this.operationProgress = const {},
  });

  BulkCampaignOperationsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<int>? selectedCampaignIds,
    Map<String, int>? operationProgress,
  }) {
    return BulkCampaignOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      selectedCampaignIds: selectedCampaignIds ?? this.selectedCampaignIds,
      operationProgress: operationProgress ?? this.operationProgress,
    );
  }
}

class BulkCampaignOperationsNotifier extends StateNotifier<BulkCampaignOperationsState> {
  final CampaignDao _dao;
  final CampaignController _controller;

  BulkCampaignOperationsNotifier(this._dao, this._controller) 
      : super(const BulkCampaignOperationsState());

  void selectCampaign(int campaignId) {
    final newSelection = List<int>.from(state.selectedCampaignIds);
    if (!newSelection.contains(campaignId)) {
      newSelection.add(campaignId);
      state = state.copyWith(selectedCampaignIds: newSelection);
    }
  }

  void deselectCampaign(int campaignId) {
    final newSelection = List<int>.from(state.selectedCampaignIds);
    newSelection.remove(campaignId);
    state = state.copyWith(selectedCampaignIds: newSelection);
  }

  void toggleCampaignSelection(int campaignId) {
    if (state.selectedCampaignIds.contains(campaignId)) {
      deselectCampaign(campaignId);
    } else {
      selectCampaign(campaignId);
    }
  }

  void selectAllCampaigns(List<int> campaignIds) {
    state = state.copyWith(selectedCampaignIds: campaignIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedCampaignIds: []);
  }

  Future<void> bulkStart() async {
    await _performBulkOperation('start', (campaignId) async {
      await _controller.startCampaign(campaignId);
    });
  }

  Future<void> bulkPause() async {
    await _performBulkOperation('pause', (campaignId) async {
      await _controller.stopCampaign(campaignId);
      await _dao.updateCampaignStatus(campaignId, 'paused');
    });
  }

  Future<void> bulkCancel() async {
    await _performBulkOperation('cancel', (campaignId) async {
      await _controller.stopCampaign(campaignId);
      await _dao.updateCampaignStatus(campaignId, 'cancelled');
    });
  }

  Future<void> bulkDelete() async {
    await _performBulkOperation('delete', (campaignId) async {
      await _controller.stopCampaign(campaignId);
      // await _dao.deleteCampaign(campaignId); // Would need implementation
    });
  }

  Future<void> _performBulkOperation(
    String operationType,
    Future<void> Function(int) operation,
  ) async {
    if (state.selectedCampaignIds.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
      operationProgress: {operationType: 0},
    );

    int completed = 0;
    int failed = 0;

    for (final campaignId in state.selectedCampaignIds) {
      try {
        await operation(campaignId);
        completed++;
      } catch (e) {
        failed++;
        logger.e('Error in bulk $operationType for campaign $campaignId: $e');
      }

      // Update progress
      final progress = completed + failed;
      state = state.copyWith(
        operationProgress: {operationType: progress},
      );
    }

    state = state.copyWith(
      isLoading: false,
      successMessage: failed == 0
          ? 'Bulk $operationType completed successfully ($completed campaigns)'
          : 'Bulk $operationType completed with $failed failures ($completed successful)',
      error: failed > 0 ? 'Some operations failed' : null,
      operationProgress: {},
    );

    // Clear selection after operation
    clearSelection();
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Campaign Scheduling State and Notifier
class CampaignSchedulingState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const CampaignSchedulingState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  CampaignSchedulingState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return CampaignSchedulingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class CampaignSchedulingNotifier extends StateNotifier<CampaignSchedulingState> {
  final CampaignDao _dao;

  CampaignSchedulingNotifier(this._dao) : super(const CampaignSchedulingState());

  Future<void> scheduleCampaign(int campaignId, DateTime scheduledTime) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      // Update campaign with new scheduled time
      await _dao.updateCampaignStatus(campaignId, 'scheduled');
      // This would need to be implemented in the DAO
      // await _dao.updateCampaignScheduledTime(campaignId, scheduledTime);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Campaign scheduled successfully',
      );
    } catch (e) {
      logger.e('Error scheduling campaign $campaignId: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to schedule campaign: $e',
      );
    }
  }

  Future<void> reschedule(int campaignId, DateTime newScheduledTime) async {
    await scheduleCampaign(campaignId, newScheduledTime);
  }

  Future<void> unschedule(int campaignId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _dao.updateCampaignStatus(campaignId, 'pending');
      // Remove scheduled time
      // await _dao.updateCampaignScheduledTime(campaignId, null);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Campaign unscheduled successfully',
      );
    } catch (e) {
      logger.e('Error unscheduling campaign $campaignId: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unschedule campaign: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Campaign Duplication State and Notifier
class CampaignDuplicationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final int? duplicatedCampaignId;

  const CampaignDuplicationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.duplicatedCampaignId,
  });

  CampaignDuplicationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    int? duplicatedCampaignId,
  }) {
    return CampaignDuplicationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      duplicatedCampaignId: duplicatedCampaignId ?? this.duplicatedCampaignId,
    );
  }
}

class CampaignDuplicationNotifier extends StateNotifier<CampaignDuplicationState> {
  final CampaignDao _dao;
  // ignore: unused_field TODO
  final FutureProviderFamily<TemplateModel?, int> _templateProvider;

  CampaignDuplicationNotifier(this._dao, this._templateProvider) 
      : super(const CampaignDuplicationState());

  Future<void> duplicateCampaign(
    int originalCampaignId, {
    String? newName,
    List<int>? newClientIds,
    DateTime? newScheduledAt,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final originalCampaign = await _dao.getCampaignById(originalCampaignId);
      if (originalCampaign == null) {
        throw Exception('Original campaign not found');
      }

      // Create new campaign with modified parameters
      final duplicatedCampaignId = await _dao.createCampaign(
        name: newName ?? '${originalCampaign.name} (Copy)',
        templateId: originalCampaign.templateId,
        clientIds: newClientIds ?? originalCampaign.clientIds,
        messageType: 'email', // This would need to be determined from template
        scheduledAt: newScheduledAt,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Campaign duplicated successfully',
        duplicatedCampaignId: duplicatedCampaignId,
      );
    } catch (e) {
      logger.e('Error duplicating campaign $originalCampaignId: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to duplicate campaign: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      error: null, 
      successMessage: null,
      duplicatedCampaignId: null,
    );
  }
}

// Campaign Export State and Notifier
class CampaignExportState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? exportFilePath;

  const CampaignExportState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.exportFilePath,
  });

  CampaignExportState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    String? exportFilePath,
  }) {
    return CampaignExportState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      exportFilePath: exportFilePath ?? this.exportFilePath,
    );
  }
}

class CampaignExportNotifier extends StateNotifier<CampaignExportState> {
  final CampaignDao _dao;

  CampaignExportNotifier(this._dao) : super(const CampaignExportState());

  Future<void> exportCampaignData(
    int campaignId, {
    required String format, // 'csv', 'json', 'pdf'
    bool includeMessageLogs = true,
    bool includeStatistics = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final campaign = await _dao.getCampaignById(campaignId);
      if (campaign == null) {
        throw Exception('Campaign not found');
      }

      // This would need to be implemented based on the export format
      final exportPath = await _performExport(
        campaign,
        format,
        includeMessageLogs,
        includeStatistics,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Campaign data exported successfully',
        exportFilePath: exportPath,
      );
    } catch (e) {
      logger.e('Error exporting campaign $campaignId: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export campaign data: $e',
      );
    }
  }

  Future<String> _performExport(
    CampaignModel campaign,
    String format,
    bool includeMessageLogs,
    bool includeStatistics,
  ) async {
    // This is a placeholder implementation
    // In a real implementation, you would:
    // 1. Gather all campaign data
    // 2. Format it according to the specified format
    // 3. Save to file
    // 4. Return the file path
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate export time
    return '/path/to/exported/campaign_${campaign.id}.$format';
  }

  void clearMessages() {
    state = state.copyWith(
      error: null, 
      successMessage: null,
      exportFilePath: null,
    );
  }
}