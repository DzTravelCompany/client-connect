import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../logic/campaign_providers.dart';
import '../../../templates/logic/template_providers.dart';

class CampaignAnalyticsPanel extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showTemplatePerformance;
  final bool showTrends;

  const CampaignAnalyticsPanel({
    super.key,
    this.startDate,
    this.endDate,
    this.showTemplatePerformance = true,
    this.showTrends = true,
  });

  @override
  ConsumerState<CampaignAnalyticsPanel> createState() => _CampaignAnalyticsPanelState();
}

class _CampaignAnalyticsPanelState extends ConsumerState<CampaignAnalyticsPanel> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _endDate = widget.endDate ?? DateTime.now();
    _startDate = widget.startDate ?? _endDate.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final analyticsRequest = CampaignAnalyticsRequest(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    final analyticsAsync = ref.watch(campaignAnalyticsProvider(analyticsRequest));
    final theme = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date range selector
          _buildHeader(theme),
          
          const SizedBox(height: 16),
          
          // Tab navigation
          _buildTabNavigation(theme),
          
          const SizedBox(height: 16),
          
          // Content based on selected tab
          Expanded(
            child: analyticsAsync.when(
              data: (analytics) => _buildTabContent(theme, analytics),
              loading: () => const Center(child: ProgressRing()),
              error: (error, stack) => _buildErrorState(theme, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FluentThemeData theme) {
    return Row(
      children: [
        Icon(FluentIcons.analytics_report, size: 20, color: theme.accentColor),
        const SizedBox(width: 8),
        Text(
          'Campaign Analytics',
          style: theme.typography.subtitle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _buildDateRangeSelector(theme),
      ],
    );
  }

  Widget _buildDateRangeSelector(FluentThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.calendar, size: 14, color: Colors.grey[100]),
          const SizedBox(width: 6),
          Text(
            '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(FluentIcons.edit, size: 12),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(FluentThemeData theme) {
    final tabs = [
      ('overview', 'Overview'),
      ('trends', 'Trends'),
      ('templates', 'Templates'),
      ('delivery', 'Delivery'),
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = _selectedTab == tab.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = tab.$1),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? theme.accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? theme.accentColor : Colors.grey[200],
              ),
            ),
            child: Text(
              tab.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabContent(FluentThemeData theme, CampaignAnalytics analytics) {
    switch (_selectedTab) {
      case 'overview':
        return _buildOverviewTab(theme, analytics);
      case 'trends':
        return _buildTrendsTab(theme, analytics);
      case 'templates':
        return _buildTemplatesTab(theme, analytics);
      case 'delivery':
        return _buildDeliveryTab(theme, analytics);
      default:
        return _buildOverviewTab(theme, analytics);
    }
  }

  Widget _buildOverviewTab(FluentThemeData theme, CampaignAnalytics analytics) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Total Campaigns',
                  '${analytics.totalCampaigns}',
                  FluentIcons.send,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Avg Success Rate',
                  '${(analytics.averageSuccessRate * 100).toStringAsFixed(1)}%',
                  FluentIcons.completed,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Success rate trend chart
          if (analytics.successRateTrends.isNotEmpty) ...[
            Text(
              'Success Rate Trend',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildSuccessRateChart(analytics.successRateTrends),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendsTab(FluentThemeData theme, CampaignAnalytics analytics) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trends',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 16),
          
          if (analytics.successRateTrends.isNotEmpty) ...[
            SizedBox(
              height: 250,
              child: _buildSuccessRateChart(analytics.successRateTrends),
            ),
            const SizedBox(height: 24),
          ],
          
          if (analytics.deliveryTimeAnalysis.isNotEmpty) ...[
            Text(
              'Delivery Time Analysis',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildDeliveryTimeChart(analytics.deliveryTimeAnalysis),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(FluentThemeData theme, CampaignAnalytics analytics) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template Performance',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 16),
          
          ...analytics.templatePerformance.map((template) {
            return _buildTemplatePerformanceCard(theme, template);
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(FluentThemeData theme, CampaignAnalytics analytics) {
    if (analytics.deliveryTimeAnalysis.isEmpty) {
      return const Center(
        child: Text('No delivery data available for the selected period'),
      );
    }

    final avgDeliveryTime = analytics.deliveryTimeAnalysis.values
        .map((duration) => duration.inMinutes)
        .reduce((a, b) => a + b) / analytics.deliveryTimeAnalysis.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Avg Delivery Time',
                  '${avgDeliveryTime.toStringAsFixed(0)} min',
                  FluentIcons.clock,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Campaigns Analyzed',
                  '${analytics.deliveryTimeAnalysis.length}',
                  FluentIcons.analytics_report,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Delivery Time Trends',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildDeliveryTimeChart(analytics.deliveryTimeAnalysis),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(FluentThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePerformanceCard(FluentThemeData theme, TemplatePerformanceMetrics template) {
    final templateAsync = ref.watch(templateByIdProvider(template.templateId));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: templateAsync.when(
        data: (templateModel) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    templateModel?.isEmail == true ? FluentIcons.mail : FluentIcons.chat,
                    size: 16,
                    color: Colors.grey[100],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      templateModel?.name ?? 'Unknown Template',
                      style: theme.typography.bodyStrong,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSuccessRateColor(template.averageSuccessRate).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(template.averageSuccessRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getSuccessRateColor(template.averageSuccessRate),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTemplateMetric('Campaigns', '${template.totalCampaigns}'),
                  ),
                  Expanded(
                    child: _buildTemplateMetric('Messages', '${template.totalMessages}'),
                  ),
                  Expanded(
                    child: _buildTemplateMetric('Successful', '${template.successfulMessages}'),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 60, child: ProgressRing()),
        error: (_, __) => Text('Template ID: ${template.templateId}'),
      ),
    );
  }

  Widget _buildTemplateMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[100],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessRateChart(Map<DateTime, double> data) {
    final spots = data.entries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value * 100,
      );
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildDeliveryTimeChart(Map<DateTime, Duration> data) {
    final spots = data.entries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value.inMinutes.toDouble(),
      );
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FluentThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Analytics Error',
            style: theme.typography.bodyStrong?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.typography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate > 0.8) return Colors.green;
    if (rate > 0.6) return Colors.orange;
    return Colors.red;
  }

  // TODO complete this function
  void _showDateRangePicker() {
    // Implementation for date range picker
    // This would typically show a dialog with date pickers
  }
}
