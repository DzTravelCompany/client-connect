import 'package:client_connect/src/features/analytics/presentation/widgets/compaign_performance_chart.dart';
import 'package:client_connect/src/features/analytics/presentation/widgets/top_template_list.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/analytics_providers.dart';
import '../data/analytics_models.dart';
import 'widgets/stats_card.dart';
import 'widgets/client_growth_chart.dart';
import 'widgets/message_type_pie_chart.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final analyticsSummaryAsync = ref.watch(analyticsSummaryProvider);
    final totalClientsAsync = ref.watch(totalClientsProvider);
    final activeCampaignsAsync = ref.watch(activeCampaignsProvider);
    final totalTemplatesAsync = ref.watch(totalTemplatesProvider);
    final recentActivityAsync = ref.watch(recentActivityProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Analytics Dashboard'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () {
                ref.invalidate(analyticsSummaryProvider);
                ref.invalidate(totalClientsProvider);
                ref.invalidate(activeCampaignsProvider);
                ref.invalidate(totalTemplatesProvider);
                ref.invalidate(recentActivityProvider);
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            _buildDateRangeSelector(),
            
            const SizedBox(height: 24),
            
            // Overview Stats Cards
            Row(
              children: [
                Expanded(
                  child: totalClientsAsync.when(
                    data: (count) => StatsCard(
                      title: 'Total Clients',
                      value: count.toString(),
                      icon: FluentIcons.people,
                      color: Colors.blue,
                    ),
                    loading: () => StatsCard(
                      title: 'Total Clients',
                      value: '...',
                      icon: FluentIcons.people,
                      color: Colors.blue,
                    ),
                    error: (_, __) => StatsCard(
                      title: 'Total Clients',
                      value: 'Error',
                      icon: FluentIcons.people,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: activeCampaignsAsync.when(
                    data: (count) => StatsCard(
                      title: 'Active Campaigns',
                      value: count.toString(),
                      icon: FluentIcons.send,
                      color: Colors.green,
                    ),
                    loading: () => StatsCard(
                      title: 'Active Campaigns',
                      value: '...',
                      icon: FluentIcons.send,
                      color: Colors.green,
                    ),
                    error: (_, __) => StatsCard(
                      title: 'Active Campaigns',
                      value: 'Error',
                      icon: FluentIcons.send,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: totalTemplatesAsync.when(
                    data: (count) => StatsCard(
                      title: 'Templates',
                      value: count.toString(),
                      icon: FluentIcons.mail,
                      color: Colors.orange,
                    ),
                    loading: () => StatsCard(
                      title: 'Templates',
                      value: '...',
                      icon: FluentIcons.mail,
                      color: Colors.orange,
                    ),
                    error: (_, __) => StatsCard(
                      title: 'Templates',
                      value: 'Error',
                      icon: FluentIcons.mail,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: recentActivityAsync.when(
                    data: (activity) => StatsCard(
                      title: 'Messages Sent (7d)',
                      value: activity['messagesSent'].toString(),
                      icon: FluentIcons.mail,
                      color: Colors.purple,
                      subtitle: '${activity['newClients']} new clients',
                    ),
                    loading: () => StatsCard(
                      title: 'Messages Sent (7d)',
                      value: '...',
                      icon: FluentIcons.mail,
                      color: Colors.purple,
                    ),
                    error: (_, __) => StatsCard(
                      title: 'Messages Sent (7d)',
                      value: 'Error',
                      icon: FluentIcons.mail,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Main Analytics Content
            analyticsSummaryAsync.when(
              data: (summary) => _buildAnalyticsContent(summary),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProgressRing(),
                    SizedBox(height: 16),
                    Text('Loading analytics data...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading analytics: $error'),
                    const SizedBox(height: 16),
                    Button(
                      onPressed: () => ref.invalidate(analyticsSummaryProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final currentRange = ref.watch(analyticsDateRangeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(FluentIcons.calendar, size: 20),
            const SizedBox(width: 12),
            const Text('Date Range:'),
            const SizedBox(width: 16),
            ComboBox<String>(
              value: _getDateRangeKey(currentRange),
              items: const [
                ComboBoxItem(value: 'last7days', child: Text('Last 7 Days')),
                ComboBoxItem(value: 'last30days', child: Text('Last 30 Days')),
                ComboBoxItem(value: 'last90days', child: Text('Last 90 Days')),
                ComboBoxItem(value: 'thismonth', child: Text('This Month')),
                ComboBoxItem(value: 'thisyear', child: Text('This Year')),
              ],
              onChanged: (value) {
                if (value != null) {
                  AnalyticsDateRange newRange;
                  switch (value) {
                    case 'last7days':
                      newRange = AnalyticsDateRange.last7Days();
                      break;
                    case 'last30days':
                      newRange = AnalyticsDateRange.last30Days();
                      break;
                    case 'last90days':
                      newRange = AnalyticsDateRange.last90Days();
                      break;
                    case 'thismonth':
                      newRange = AnalyticsDateRange.thisMonth();
                      break;
                    case 'thisyear':
                      newRange = AnalyticsDateRange.thisYear();
                      break;
                    default:
                      newRange = AnalyticsDateRange.last30Days();
                  }
                  ref.read(analyticsDateRangeProvider.notifier).state = newRange;
                }
              },
            ),
            const Spacer(),
            Text(
              '${_formatDate(currentRange.startDate)} - ${_formatDate(currentRange.endDate)}',
              style: TextStyle(
                color: Colors.grey[100],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(AnalyticsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campaign Analytics Overview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Performance Overview',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Total Campaigns',
                        summary.campaignAnalytics.totalCampaigns.toString(),
                        FluentIcons.send,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Success Rate',
                        '${summary.campaignAnalytics.successRate.toStringAsFixed(1)}%',
                        FluentIcons.completed,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Messages Sent',
                        summary.campaignAnalytics.totalMessagesSent.toString(),
                        FluentIcons.mail,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Delivery Rate',
                        '${summary.campaignAnalytics.deliveryRate.toStringAsFixed(1)}%',
                        FluentIcons.check_mark,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Growth Chart
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Growth',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: ClientGrowthChart(data: summary.clientGrowth),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Message Type Distribution
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message Types',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: MessageTypePieChart(data: summary.messageTypeDistribution),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Campaign Performance Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Campaign Performance',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: CampaignPerformanceChart(data: summary.campaignPerformance),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Top Performing Templates
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Performing Templates',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 16),
                TopTemplatesList(templates: summary.topTemplates),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[100],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getDateRangeKey(AnalyticsDateRange range) {
    final last7Days = AnalyticsDateRange.last7Days();
    final last30Days = AnalyticsDateRange.last30Days();
    final last90Days = AnalyticsDateRange.last90Days();
    final thisMonth = AnalyticsDateRange.thisMonth();
    
    if (_isSameRange(range, last7Days)) return 'last7days';
    if (_isSameRange(range, last30Days)) return 'last30days';
    if (_isSameRange(range, last90Days)) return 'last90days';
    if (_isSameRange(range, thisMonth)) return 'thismonth';
    return 'last30days';
  }

  bool _isSameRange(AnalyticsDateRange a, AnalyticsDateRange b) {
    return a.startDate.day == b.startDate.day &&
           a.startDate.month == b.startDate.month &&
           a.startDate.year == b.startDate.year;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}