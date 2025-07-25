import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analytics/logic/analytics_providers.dart';
import '../presentation/widgets/chart_widget.dart';
import '../../../core/realtime/reactive_providers.dart';
import '../../../core/realtime/event_bus.dart';
import '../../../core/realtime/realtime_dashboard_service.dart';


// Real-time dashboard metrics provider
final dashboardMetricsProvider = ReactiveProvider<DashboardMetrics>(
  (ref) async {
    final totalClients = await ref.watch(totalClientsProvider.future);
    final activeCampaigns = await ref.watch(activeCampaignsProvider.future);
    final totalTemplates = await ref.watch(totalTemplatesProvider.future);
    final recentActivity = await ref.watch(recentActivityProvider.future);

    return DashboardMetrics(
      totalClients: totalClients,
      activeCampaigns: activeCampaigns,
      totalTemplates: totalTemplates,
      newClientsThisWeek: recentActivity['newClients'] ?? 0,
      messagesSentThisWeek: recentActivity['messagesSent'] ?? 0,
      campaignsThisWeek: recentActivity['newCampaigns'] ?? 0,
    );
  },
  [ClientEvent, CampaignEvent, TemplateEvent, AnalyticsEvent],
).createProvider();

// Real-time activity provider using the realtime dashboard service
final dashboardActivityProvider = StreamProvider<List<ActivityItem>>((ref) {
  final service = RealtimeDashboardService();
  return service.getActivityFeedStream();
});

// Chart data providers
final clientGrowthChartProvider = FutureProvider<List<ChartData>>((ref) async {
  final clientGrowthData = await ref.watch(clientGrowthProvider.future);
  
  return clientGrowthData.take(7).map((data) {
    return ChartData(
      label: '${data.date.day}/${data.date.month}',
      value: data.newClients.toDouble(),
    );
  }).toList();
});

final campaignPerformanceChartProvider = FutureProvider<List<ChartData>>((ref) async {
  final performanceData = await ref.watch(campaignPerformanceProvider.future);
  
  return performanceData.take(7).map((data) {
    return ChartData(
      label: '${data.date.day}/${data.date.month}',
      value: data.successRate,
    );
  }).toList();
});

// Dashboard layout provider
final dashboardLayoutProvider = StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>((ref) {
  return DashboardLayoutNotifier();
});

class DashboardMetrics {
  final int totalClients;
  final int activeCampaigns;
  final int totalTemplates;
  final int newClientsThisWeek;
  final int messagesSentThisWeek;
  final int campaignsThisWeek;

  DashboardMetrics({
    required this.totalClients,
    required this.activeCampaigns,
    required this.totalTemplates,
    required this.newClientsThisWeek,
    required this.messagesSentThisWeek,
    required this.campaignsThisWeek,
  });
}

class DashboardLayout {
  final List<String> widgetOrder;
  final Map<String, bool> widgetVisibility;

  DashboardLayout({
    required this.widgetOrder,
    required this.widgetVisibility,
  });

  DashboardLayout copyWith({
    List<String>? widgetOrder,
    Map<String, bool>? widgetVisibility,
  }) {
    return DashboardLayout(
      widgetOrder: widgetOrder ?? this.widgetOrder,
      widgetVisibility: widgetVisibility ?? this.widgetVisibility,
    );
  }
}

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  DashboardLayoutNotifier() : super(
    DashboardLayout(
      widgetOrder: [
        'metrics',
        'client_growth',
        'campaign_performance',
        'activity_feed',
        'quick_actions',
      ],
      widgetVisibility: {
        'metrics': true,
        'client_growth': true,
        'campaign_performance': true,
        'activity_feed': true,
        'quick_actions': true,
      },
    ),
  );

  void reorderWidgets(List<String> newOrder) {
    state = state.copyWith(widgetOrder: newOrder);
  }

  void toggleWidgetVisibility(String widgetId) {
    final newVisibility = Map<String, bool>.from(state.widgetVisibility);
    newVisibility[widgetId] = !(newVisibility[widgetId] ?? true);
    state = state.copyWith(widgetVisibility: newVisibility);
  }
}
