import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_service.dart';
import '../data/analytics_models.dart';
import '../../../core/realtime/reactive_providers.dart';
import '../../../core/realtime/event_bus.dart';

// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService.instance);

// Date range provider for analytics
final analyticsDateRangeProvider = StateProvider<AnalyticsDateRange>((ref) {
  return AnalyticsDateRange.last30Days();
});

// Real-time analytics summary provider
final analyticsSummaryProvider = ReactiveProvider<AnalyticsSummary>(
  (ref) async {
    final service = ref.watch(analyticsServiceProvider);
    final dateRange = ref.watch(analyticsDateRangeProvider);
    return service.getAnalyticsSummary(dateRange);
  },
  [ClientEvent, CampaignEvent, AnalyticsEvent],
  debounceTime: const Duration(seconds: 2),
).createProvider();

// Real-time dashboard stats providers
final totalClientsProvider = ReactiveProvider<int>(
  (ref) async {
    final service = ref.watch(analyticsServiceProvider);
    return service.getTotalClientsCount();
  },
  [ClientEvent],
).createProvider();

final activeCampaignsProvider = ReactiveProvider<int>(
  (ref) async {
    final service = ref.watch(analyticsServiceProvider);
    return service.getActiveCampaignsCount();
  },
  [CampaignEvent],
).createProvider();

final totalTemplatesProvider = FutureProvider<int>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return service.getTotalTemplatesCount();
});

final recentActivityProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return service.getRecentActivity();
});

// Individual analytics components
final campaignAnalyticsProvider = FutureProvider<CampaignAnalytics>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  return service.getCampaignAnalytics(dateRange);
});

final clientGrowthProvider = FutureProvider<List<ClientGrowthData>>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  return service.getClientGrowthData(dateRange);
});

final campaignPerformanceProvider = FutureProvider<List<CampaignPerformanceData>>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  return service.getCampaignPerformanceData(dateRange);
});

final messageTypeDistributionProvider = FutureProvider<List<MessageTypeDistribution>>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  return service.getMessageTypeDistribution(dateRange);
});

final topTemplatesProvider = FutureProvider<List<TopPerformingTemplate>>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  return service.getTopPerformingTemplates(dateRange);
});