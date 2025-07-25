class CampaignAnalytics {
  final int totalCampaigns;
  final int completedCampaigns;
  final int activeCampaigns;
  final int failedCampaigns;
  final double successRate;
  final int totalMessagesSent;
  final int totalMessagesDelivered;
  final int totalMessagesFailed;
  final double deliveryRate;

  const CampaignAnalytics({
    required this.totalCampaigns,
    required this.completedCampaigns,
    required this.activeCampaigns,
    required this.failedCampaigns,
    required this.successRate,
    required this.totalMessagesSent,
    required this.totalMessagesDelivered,
    required this.totalMessagesFailed,
    required this.deliveryRate,
  });
}

class ClientGrowthData {
  final DateTime date;
  final int totalClients;
  final int newClients;

  const ClientGrowthData({
    required this.date,
    required this.totalClients,
    required this.newClients,
  });
}

class CampaignPerformanceData {
  final DateTime date;
  final int campaignsLaunched;
  final int messagesDelivered;
  final int messagesFailed;
  final double successRate;

  const CampaignPerformanceData({
    required this.date,
    required this.campaignsLaunched,
    required this.messagesDelivered,
    required this.messagesFailed,
    required this.successRate,
  });
}

class MessageTypeDistribution {
  final String type;
  final int count;
  final double percentage;

  const MessageTypeDistribution({
    required this.type,
    required this.count,
    required this.percentage,
  });
}

class TopPerformingTemplate {
  final int templateId;
  final String templateName;
  final int usageCount;
  final double successRate;
  final int totalMessages;

  const TopPerformingTemplate({
    required this.templateId,
    required this.templateName,
    required this.usageCount,
    required this.successRate,
    required this.totalMessages,
  });
}

class AnalyticsDateRange {
  final DateTime startDate;
  final DateTime endDate;

  const AnalyticsDateRange({
    required this.startDate,
    required this.endDate,
  });

  static AnalyticsDateRange last7Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  static AnalyticsDateRange last30Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }

  static AnalyticsDateRange last90Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now,
    );
  }

  static AnalyticsDateRange thisMonth() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  static AnalyticsDateRange thisYear() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: DateTime(now.year, 1, 1),
      endDate: now,
    );
  }
}

class AnalyticsSummary {
  final CampaignAnalytics campaignAnalytics;
  final List<ClientGrowthData> clientGrowth;
  final List<CampaignPerformanceData> campaignPerformance;
  final List<MessageTypeDistribution> messageTypeDistribution;
  final List<TopPerformingTemplate> topTemplates;
  final AnalyticsDateRange dateRange;

  const AnalyticsSummary({
    required this.campaignAnalytics,
    required this.clientGrowth,
    required this.campaignPerformance,
    required this.messageTypeDistribution,
    required this.topTemplates,
    required this.dateRange,
  });
}
