import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analytics/logic/analytics_providers.dart';
import '../presentation/widgets/activity_feed_widget.dart';
import '../presentation/widgets/chart_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';

// Dashboard metrics provider
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
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
});

// Recent activity provider for dashboard
final dashboardActivityProvider = FutureProvider<List<ActivityItem>>((ref) async {
  // This would typically fetch from multiple sources
  // For now, creating mock data based on existing providers
  
  return [
    ActivityItem(
      title: 'New client added',
      subtitle: 'John Doe from Acme Corp',
      timeAgo: '2 minutes ago',
      icon: FluentIcons.add_friend,
      iconColor: Colors.green,
    ),
    ActivityItem(
      title: 'Campaign completed',
      subtitle: 'Holiday Promotion - 95% success rate',
      timeAgo: '1 hour ago',
      icon: FluentIcons.completed_solid,
      iconColor: Colors.blue,
    ),
    ActivityItem(
      title: 'Template created',
      subtitle: 'Welcome Email Template',
      timeAgo: '3 hours ago',
      icon: FluentIcons.page_add,
      iconColor: Colors.purple,
    ),
    ActivityItem(
      title: 'Data imported',
      subtitle: '150 new clients from CSV',
      timeAgo: '1 day ago',
      icon: FluentIcons.import,
      iconColor: Colors.orange,
    ),
    ActivityItem(
      title: 'Campaign started',
      subtitle: 'Product Launch Announcement',
      timeAgo: '2 days ago',
      icon: FluentIcons.send,
      iconColor: Colors.teal,
    ),
  ];
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