import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/analytics/data/analytics_service.dart';
import 'event_bus.dart';
import 'realtime_sync_service.dart';

/// Service for real-time dashboard updates
class RealtimeDashboardService {
  static final RealtimeDashboardService _instance = RealtimeDashboardService._internal();
  factory RealtimeDashboardService() => _instance;
  RealtimeDashboardService._internal();

  final RealtimeSyncService _syncService = RealtimeSyncService();
  final StreamController<DashboardUpdate> _updateController = StreamController.broadcast();

  /// Stream of dashboard updates
  Stream<DashboardUpdate> get updateStream => _updateController.stream;

  /// Initialize the dashboard service
  void initialize() {
    // Listen to all events and determine what dashboard updates are needed
    _syncService.allEvents.listen((event) {
      _handleEvent(event);
    });
  }

  /// Handle events and emit dashboard updates
  void _handleEvent(AppEvent event) {
    switch (event.runtimeType) {
      case ClientEvent _:
        _updateController.add(DashboardUpdate(
          type: DashboardUpdateType.clientMetrics,
          timestamp: event.timestamp,
          source: event.source,
        ));
        break;
      case CampaignEvent _:
        _updateController.add(DashboardUpdate(
          type: DashboardUpdateType.campaignMetrics,
          timestamp: event.timestamp,
          source: event.source,
        ));
        break;
      case TemplateEvent _:
        _updateController.add(DashboardUpdate(
          type: DashboardUpdateType.templateMetrics,
          timestamp: event.timestamp,
          source: event.source,
        ));
        break;
      case AnalyticsEvent _:
        _updateController.add(DashboardUpdate(
          type: DashboardUpdateType.analytics,
          timestamp: event.timestamp,
          source: event.source,
        ));
        break;
    }
  }

  /// Get real-time metrics stream
  Stream<DashboardMetrics> getMetricsStream() {
    return Stream.periodic(const Duration(seconds: 5), (_) => null)
        .startWith(null)
        .mergeWith([
          updateStream
              .debounceTime(const Duration(seconds: 2))
              .map((_) => null)
        ])
        .asyncMap((_) => _fetchMetrics())
        .distinct();
  }

  /// Fetch current metrics
  Future<DashboardMetrics> _fetchMetrics() async {
    final analyticsService = AnalyticsService.instance;
    
    final totalClients = await analyticsService.getTotalClientsCount();
    final activeCampaigns = await analyticsService.getActiveCampaignsCount();
    final totalTemplates = await analyticsService.getTotalTemplatesCount();
    final recentActivity = await analyticsService.getRecentActivity();

    return DashboardMetrics(
      totalClients: totalClients,
      activeCampaigns: activeCampaigns,
      totalTemplates: totalTemplates,
      newClientsThisWeek: recentActivity['newClients'] ?? 0,
      messagesSentThisWeek: recentActivity['messagesSent'] ?? 0,
      campaignsThisWeek: recentActivity['newCampaigns'] ?? 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get real-time activity feed
  Stream<List<ActivityItem>> getActivityFeedStream() {
    return _syncService.allEvents
        .map((event) => _eventToActivityItem(event))
        .where((item) => item != null)
        .cast<ActivityItem>()
        .scan<List<ActivityItem>>((accumulated, item, index) {
          final newList = [item, ...accumulated];
          return newList.take(50).toList(); // Keep last 50 items
        }, <ActivityItem>[]);
  }

  /// Convert event to activity item
  ActivityItem? _eventToActivityItem(AppEvent event) {
    switch (event.runtimeType) {
      case ClientEvent _:
        final clientEvent = event as ClientEvent;
        return ActivityItem(
          title: _getClientEventTitle(clientEvent.type),
          subtitle: clientEvent.metadata?['client_name'] ?? 'Unknown client',
          timestamp: event.timestamp,
          type: ActivityType.client,
          metadata: event.metadata,
          icon: FluentIcons.contact, // Example icon for client events
          iconColor: Colors.blue, // Example color for client events
        );
      case CampaignEvent _:
        final campaignEvent = event as CampaignEvent;
        return ActivityItem(
          title: _getCampaignEventTitle(campaignEvent.type),
          subtitle: campaignEvent.metadata?['campaign_name'] ?? 'Campaign ${campaignEvent.campaignId}',
          timestamp: event.timestamp,
          type: ActivityType.campaign,
          metadata: event.metadata,
          icon: FluentIcons.campaign_template, // Example icon for campaign events
          iconColor: Colors.green, // Example color for campaign events
        );
      case TemplateEvent _:
        final templateEvent = event as TemplateEvent;
        return ActivityItem(
          title: _getTemplateEventTitle(templateEvent.type),
          subtitle: templateEvent.metadata?['template_name'] ?? 'Template ${templateEvent.templateId}',
          timestamp: event.timestamp,
          type: ActivityType.template,
          metadata: event.metadata,
          icon: FluentIcons.page, // Example icon for template events
          iconColor: Colors.orange, // Example color for template events
        );
      default:
        return null;
    }
  }

  String _getClientEventTitle(ClientEventType type) {
    switch (type) {
      case ClientEventType.created:
        return 'New client added';
      case ClientEventType.updated:
        return 'Client updated';
      case ClientEventType.deleted:
        return 'Client deleted';
      case ClientEventType.bulkUpdated:
        return 'Clients bulk updated';
      case ClientEventType.bulkDeleted:
        return 'Clients bulk deleted';
    }
  }

  String _getCampaignEventTitle(CampaignEventType type) {
    switch (type) {
      case CampaignEventType.created:
        return 'Campaign created';
      case CampaignEventType.started:
        return 'Campaign started';
      case CampaignEventType.completed:
        return 'Campaign completed';
      case CampaignEventType.failed:
        return 'Campaign failed';
      case CampaignEventType.paused:
        return 'Campaign paused';
      case CampaignEventType.cancelled:
        return 'Campaign cancelled';
      default:
        return 'Campaign updated';
    }
  }

  String _getTemplateEventTitle(TemplateEventType type) {
    switch (type) {
      case TemplateEventType.created:
        return 'Template created';
      case TemplateEventType.updated:
        return 'Template updated';
      case TemplateEventType.deleted:
        return 'Template deleted';
      case TemplateEventType.duplicated:
        return 'Template duplicated';
      case TemplateEventType.bulkDeleted:
        return 'Templates bulk deleted';
    }
  }

  /// Dispose the service
  void dispose() {
    _updateController.close();
  }
}

/// Dashboard update model
class DashboardUpdate {
  final DashboardUpdateType type;
  final DateTime timestamp;
  final String source;

  const DashboardUpdate({
    required this.type,
    required this.timestamp,
    required this.source,
  });
}

enum DashboardUpdateType {
  clientMetrics,
  campaignMetrics,
  templateMetrics,
  analytics,
  activity,
}

/// Dashboard metrics model
class DashboardMetrics {
  final int totalClients;
  final int activeCampaigns;
  final int totalTemplates;
  final int newClientsThisWeek;
  final int messagesSentThisWeek;
  final int campaignsThisWeek;
  final DateTime lastUpdated;

  const DashboardMetrics({
    required this.totalClients,
    required this.activeCampaigns,
    required this.totalTemplates,
    required this.newClientsThisWeek,
    required this.messagesSentThisWeek,
    required this.campaignsThisWeek,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardMetrics &&
          runtimeType == other.runtimeType &&
          totalClients == other.totalClients &&
          activeCampaigns == other.activeCampaigns &&
          totalTemplates == other.totalTemplates &&
          newClientsThisWeek == other.newClientsThisWeek &&
          messagesSentThisWeek == other.messagesSentThisWeek &&
          campaignsThisWeek == other.campaignsThisWeek;

  @override
  int get hashCode =>
      totalClients.hashCode ^
      activeCampaigns.hashCode ^
      totalTemplates.hashCode ^
      newClientsThisWeek.hashCode ^
      messagesSentThisWeek.hashCode ^
      campaignsThisWeek.hashCode;
}

/// Activity item model
class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final Map<String, dynamic>? metadata;
  final IconData icon; // Added
  final Color iconColor;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.metadata,
    required this.icon, // Added
    required this.iconColor,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

enum ActivityType {
  client,
  campaign,
  template,
  system,
}

/// Provider for real-time dashboard service
final realtimeDashboardServiceProvider = Provider<RealtimeDashboardService>((ref) {
  return RealtimeDashboardService();
});

/// Provider for real-time dashboard metrics
final realtimeDashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) {
  final service = ref.watch(realtimeDashboardServiceProvider);
  return service.getMetricsStream();
});

/// Provider for real-time activity feed
final realtimeActivityFeedProvider = StreamProvider<List<ActivityItem>>((ref) {
  final service = ref.watch(realtimeDashboardServiceProvider);
  return service.getActivityFeedStream();
});