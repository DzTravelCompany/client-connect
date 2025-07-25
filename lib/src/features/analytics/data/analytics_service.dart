import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import 'analytics_models.dart';



class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  final AppDatabase _db = DatabaseService.instance.database;

  // Get comprehensive analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary(AnalyticsDateRange dateRange) async {
    final campaignAnalytics = await getCampaignAnalytics(dateRange);
    final clientGrowth = await getClientGrowthData(dateRange);
    final campaignPerformance = await getCampaignPerformanceData(dateRange);
    final messageTypeDistribution = await getMessageTypeDistribution(dateRange);
    final topTemplates = await getTopPerformingTemplates(dateRange);

    return AnalyticsSummary(
      campaignAnalytics: campaignAnalytics,
      clientGrowth: clientGrowth,
      campaignPerformance: campaignPerformance,
      messageTypeDistribution: messageTypeDistribution,
      topTemplates: topTemplates,
      dateRange: dateRange,
    );
  }

  // Campaign Analytics
  Future<CampaignAnalytics> getCampaignAnalytics(AnalyticsDateRange dateRange) async {
    // Get campaign counts
    final campaignQuery = _db.select(_db.campaigns)
      ..where((c) => c.createdAt.isBetweenValues(dateRange.startDate, dateRange.endDate));
    
    final campaigns = await campaignQuery.get();
    
    final totalCampaigns = campaigns.length;
    final completedCampaigns = campaigns.where((c) => c.status == 'completed').length;
    final activeCampaigns = campaigns.where((c) => c.status == 'in_progress').length;
    final failedCampaigns = campaigns.where((c) => c.status == 'failed').length;
    
    final successRate = totalCampaigns > 0 
        ? (completedCampaigns / totalCampaigns) * 100 
        : 0.0;

    // Get message statistics
    final messageQuery = _db.select(_db.messageLogs)
      ..where((m) => m.createdAt.isBetweenValues(dateRange.startDate, dateRange.endDate));
    
    final messages = await messageQuery.get();
    
    final totalMessagesSent = messages.length;
    final totalMessagesDelivered = messages.where((m) => m.status == 'sent').length;
    final totalMessagesFailed = messages.where((m) => m.status == 'failed').length;
    
    final deliveryRate = totalMessagesSent > 0 
        ? (totalMessagesDelivered / totalMessagesSent) * 100 
        : 0.0;

    return CampaignAnalytics(
      totalCampaigns: totalCampaigns,
      completedCampaigns: completedCampaigns,
      activeCampaigns: activeCampaigns,
      failedCampaigns: failedCampaigns,
      successRate: successRate,
      totalMessagesSent: totalMessagesSent,
      totalMessagesDelivered: totalMessagesDelivered,
      totalMessagesFailed: totalMessagesFailed,
      deliveryRate: deliveryRate,
    );
  }

  // Client Growth Data
  Future<List<ClientGrowthData>> getClientGrowthData(AnalyticsDateRange dateRange) async {
    final List<ClientGrowthData> growthData = [];
    
    // Generate daily data points
    DateTime currentDate = dateRange.startDate;
    while (currentDate.isBefore(dateRange.endDate) || currentDate.isAtSameMomentAs(dateRange.endDate)) {
      final endOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);
      
      // Get total clients up to this date
      final totalClientsQuery = _db.select(_db.clients)
        ..where((c) => c.createdAt.isSmallerOrEqualValue(endOfDay));
      final totalClients = await totalClientsQuery.get();
      
      // Get new clients on this specific day
      final startOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final newClientsQuery = _db.select(_db.clients)
        ..where((c) => c.createdAt.isBetweenValues(startOfDay, endOfDay));
      final newClients = await newClientsQuery.get();
      
      growthData.add(ClientGrowthData(
        date: currentDate,
        totalClients: totalClients.length,
        newClients: newClients.length,
      ));
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return growthData;
  }

  // Campaign Performance Data
  Future<List<CampaignPerformanceData>> getCampaignPerformanceData(AnalyticsDateRange dateRange) async {
    final List<CampaignPerformanceData> performanceData = [];
    
    // Generate daily data points
    DateTime currentDate = dateRange.startDate;
    while (currentDate.isBefore(dateRange.endDate) || currentDate.isAtSameMomentAs(dateRange.endDate)) {
      final startOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final endOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);
      
      // Get campaigns launched on this day
      final campaignsQuery = _db.select(_db.campaigns)
        ..where((c) => c.createdAt.isBetweenValues(startOfDay, endOfDay));
      final campaigns = await campaignsQuery.get();
      
      // Get messages sent on this day
      final messagesQuery = _db.select(_db.messageLogs)
        ..where((m) => m.createdAt.isBetweenValues(startOfDay, endOfDay));
      final messages = await messagesQuery.get();
      
      final messagesDelivered = messages.where((m) => m.status == 'sent').length;
      final messagesFailed = messages.where((m) => m.status == 'failed').length;
      final totalMessages = messages.length;
      
      final successRate = totalMessages > 0 
          ? (messagesDelivered / totalMessages) * 100 
          : 0.0;
      
      performanceData.add(CampaignPerformanceData(
        date: currentDate,
        campaignsLaunched: campaigns.length,
        messagesDelivered: messagesDelivered,
        messagesFailed: messagesFailed,
        successRate: successRate,
      ));
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return performanceData;
  }

  // Message Type Distribution
  Future<List<MessageTypeDistribution>> getMessageTypeDistribution(AnalyticsDateRange dateRange) async {
    final messageQuery = _db.select(_db.messageLogs)
      ..where((m) => m.createdAt.isBetweenValues(dateRange.startDate, dateRange.endDate));
    
    final messages = await messageQuery.get();
    final totalMessages = messages.length;
    
    if (totalMessages == 0) {
      return [];
    }
    
    final Map<String, int> typeCounts = {};
    for (final message in messages) {
      typeCounts[message.type] = (typeCounts[message.type] ?? 0) + 1;
    }
    
    return typeCounts.entries.map((entry) {
      return MessageTypeDistribution(
        type: entry.key,
        count: entry.value,
        percentage: (entry.value / totalMessages) * 100,
      );
    }).toList();
  }

  // Top Performing Templates
  Future<List<TopPerformingTemplate>> getTopPerformingTemplates(AnalyticsDateRange dateRange) async {
    // Get campaigns within date range
    final campaignQuery = _db.select(_db.campaigns)
      ..where((c) => c.createdAt.isBetweenValues(dateRange.startDate, dateRange.endDate));
    
    final campaigns = await campaignQuery.get();
    
    if (campaigns.isEmpty) {
      return [];
    }
    
    final Map<int, List<Campaign>> templateUsage = {};
    for (final campaign in campaigns) {
      templateUsage.putIfAbsent(campaign.templateId, () => []).add(campaign);
    }
    
    final List<TopPerformingTemplate> topTemplates = [];
    
    for (final entry in templateUsage.entries) {
      final templateId = entry.key;
      final templateCampaigns = entry.value;
      
      // Get template name
      final templateQuery = _db.select(_db.templates)
        ..where((t) => t.id.equals(templateId));
      final template = await templateQuery.getSingleOrNull();
      
      if (template == null) continue;
      
      // Calculate success metrics
      int totalMessages = 0;
      int successfulMessages = 0;
      
      for (final campaign in templateCampaigns) {
        final messageQuery = _db.select(_db.messageLogs)
          ..where((m) => m.campaignId.equals(campaign.id));
        final messages = await messageQuery.get();
        
        totalMessages += messages.length;
        successfulMessages += messages.where((m) => m.status == 'sent').length;
      }
      
      final successRate = totalMessages > 0 
          ? (successfulMessages / totalMessages) * 100 
          : 0.0;
      
      topTemplates.add(TopPerformingTemplate(
        templateId: templateId,
        templateName: template.name,
        usageCount: templateCampaigns.length,
        successRate: successRate,
        totalMessages: totalMessages,
      ));
    }
    
    // Sort by usage count and success rate
    topTemplates.sort((a, b) {
      final usageComparison = b.usageCount.compareTo(a.usageCount);
      if (usageComparison != 0) return usageComparison;
      return b.successRate.compareTo(a.successRate);
    });
    
    return topTemplates.take(10).toList();
  }

  // Get client count over time for dashboard widget
  Future<int> getTotalClientsCount() async {
    final query = _db.select(_db.clients);
    final clients = await query.get();
    return clients.length;
  }

  // Get active campaigns count
  Future<int> getActiveCampaignsCount() async {
    final query = _db.select(_db.campaigns)
      ..where((c) => c.status.equals('in_progress') | c.status.equals('pending'));
    final campaigns = await query.get();
    return campaigns.length;
  }

  // Get total templates count
  Future<int> getTotalTemplatesCount() async {
    final query = _db.select(_db.templates);
    final templates = await query.get();
    return templates.length;
  }

  // Get recent activity (last 7 days)
  Future<Map<String, dynamic>> getRecentActivity() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // New clients in last 7 days
    final newClientsQuery = _db.select(_db.clients)
      ..where((c) => c.createdAt.isBiggerOrEqualValue(sevenDaysAgo));
    final newClients = await newClientsQuery.get();
    
    // New campaigns in last 7 days
    final newCampaignsQuery = _db.select(_db.campaigns)
      ..where((c) => c.createdAt.isBiggerOrEqualValue(sevenDaysAgo));
    final newCampaigns = await newCampaignsQuery.get();
    
    // Messages sent in last 7 days
    final messagesQuery = _db.select(_db.messageLogs)
      ..where((m) => m.createdAt.isBiggerOrEqualValue(sevenDaysAgo) & m.status.equals('sent'));
    final messagesSent = await messagesQuery.get();
    
    return {
      'newClients': newClients.length,
      'newCampaigns': newCampaigns.length,
      'messagesSent': messagesSent.length,
    };
  }
}
