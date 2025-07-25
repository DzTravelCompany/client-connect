import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../logic/campaign_providers.dart';
import 'widgets/campaign_analytics_panel.dart';
import 'widgets/campaign_monitoring_widget.dart';

class CampaignAnalyticsDashboard extends ConsumerStatefulWidget {
  const CampaignAnalyticsDashboard({super.key});

  @override
  ConsumerState<CampaignAnalyticsDashboard> createState() => _CampaignAnalyticsDashboardState();
}

class _CampaignAnalyticsDashboardState extends ConsumerState<CampaignAnalyticsDashboard> {
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();
  String _selectedView = 'overview';

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Campaign Analytics Dashboard'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back'),
              onPressed: () => context.go('/campaigns'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () {
                ref.invalidate(allCampaignsProvider);
                ref.invalidate(campaignHealthProvider);
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: const Text('Export Report'),
              onPressed: _exportAnalyticsReport,
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with view selector and date range
            _buildDashboardHeader(theme),
            
            const SizedBox(height: 16),
            
            // Main content based on selected view
            Expanded(
              child: _buildDashboardContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(FluentThemeData theme) {
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
      child: Row(
        children: [
          // View selector
          Expanded(
            child: Row(
              children: [
                Icon(FluentIcons.analytics_report, size: 20, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Analytics Dashboard',
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
                _buildViewSelector(),
              ],
            ),
          ),
          
          // Date range selector
          _buildDateRangeSelector(theme),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final views = [
      ('overview', 'Overview'),
      ('realtime', 'Real-Time'),
      ('analytics', 'Analytics'),
      ('health', 'Health'),
    ];

    return Row(
      children: views.map((view) {
        final isSelected = _selectedView == view.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedView = view.$1),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? FluentTheme.of(context).accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected 
                    ? FluentTheme.of(context).accentColor 
                    : Colors.grey[200],
              ),
            ),
            child: Text(
              view.$2,
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

  Widget _buildDashboardContent(FluentThemeData theme) {
    switch (_selectedView) {
      case 'overview':
        return _buildOverviewContent(theme);
      case 'realtime':
        return _buildRealTimeContent(theme);
      case 'analytics':
        return _buildAnalyticsContent(theme);
      case 'health':
        return _buildHealthContent(theme);
      default:
        return _buildOverviewContent(theme);
    }
  }

  Widget _buildOverviewContent(FluentThemeData theme) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    final healthAsync = ref.watch(campaignHealthProvider);

    return Row(
      children: [
        // Left column - Key metrics
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Campaign summary cards
              campaignsAsync.when(
                data: (campaigns) => _buildCampaignSummaryCards(theme, campaigns),
                loading: () => const Center(child: ProgressRing()),
                error: (_, __) => const Text('Error loading campaigns'),
              ),
              
              const SizedBox(height: 16),
              
              // Health overview
              healthAsync.when(
                data: (health) => _buildHealthOverviewCard(theme, health),
                loading: () => const Center(child: ProgressRing()),
                error: (_, __) => const Text('Error loading health data'),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Right column - Analytics panel
        Expanded(
          flex: 2,
          child: CampaignAnalyticsPanel(
            startDate: _startDate,
            endDate: _endDate,
            showTemplatePerformance: true,
            showTrends: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeContent(FluentThemeData theme) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    
    return campaignsAsync.when(
      data: (campaigns) {
        final activeCampaigns = campaigns.where((c) => c.isInProgress).toList();
        
        if (activeCampaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.send, size: 64, color: Colors.grey[100]),
                const SizedBox(height: 16),
                Text(
                  'No Active Campaigns',
                  style: theme.typography.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a campaign to see real-time monitoring data',
                  style: theme.typography.caption?.copyWith(
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: activeCampaigns.length,
          itemBuilder: (context, index) {
            final campaign = activeCampaigns[index];
            return CampaignMonitoringWidget(
              campaignId: campaign.id,
              showDetailedMetrics: true,
              showHealthIndicator: true,
            );
          },
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildAnalyticsContent(FluentThemeData theme) {
    return CampaignAnalyticsPanel(
      startDate: _startDate,
      endDate: _endDate,
      showTemplatePerformance: true,
      showTrends: true,
    );
  }

  Widget _buildHealthContent(FluentThemeData theme) {
    final healthAsync = ref.watch(campaignHealthProvider);
    
    return healthAsync.when(
      data: (healthIndicators) {
        if (healthIndicators.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.health, size: 64, color: Colors.grey[100]),
                const SizedBox(height: 16),
                Text(
                  'No Health Data Available',
                  style: theme.typography.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Health monitoring data will appear when campaigns are active',
                  style: theme.typography.caption?.copyWith(
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: healthIndicators.length,
          itemBuilder: (context, index) {
            final indicator = healthIndicators[index];
            return _buildDetailedHealthCard(theme, indicator);
          },
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCampaignSummaryCards(FluentThemeData theme, List<CampaignModel> campaigns) {
    final totalCampaigns = campaigns.length;
    final activeCampaigns = campaigns.where((c) => c.isInProgress).length;
    final completedCampaigns = campaigns.where((c) => c.isCompleted).length;
    final failedCampaigns = campaigns.where((c) => c.isFailed).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                'Total Campaigns',
                '$totalCampaigns',
                FluentIcons.send,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme,
                'Active',
                '$activeCampaigns',
                FluentIcons.play,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                'Completed',
                '$completedCampaigns',
                FluentIcons.completed,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme,
                'Failed',
                '$failedCampaigns',
                FluentIcons.error,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(FluentThemeData theme, String title, String value, IconData icon, Color color) {
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

  Widget _buildHealthOverviewCard(FluentThemeData theme, List<CampaignHealthIndicator> healthIndicators) {
    if (healthIndicators.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]),
        ),
        child: const Center(
          child: Text('No health data available'),
        ),
      );
    }

    final avgHealthScore = healthIndicators
        .map((h) => h.healthScore)
        .reduce((a, b) => a + b) / healthIndicators.length;

    final criticalCount = healthIndicators.where((h) => h.isCritical).length;
    final warningCount = healthIndicators.where((h) => h.hasWarnings).length;
    final healthyCount = healthIndicators.where((h) => h.isHealthy).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.health, size: 20, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Health Overview',
                style: theme.typography.bodyStrong,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Average health score
          Row(
            children: [
              Text(
                'Avg Health Score',
                style: theme.typography.caption,
              ),
              const Spacer(),
              Text(
                '${(avgHealthScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: avgHealthScore > 0.8 
                      ? Colors.green 
                      : avgHealthScore > 0.5 
                          ? Colors.orange 
                          : Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Health distribution
          Row(
            children: [
              _buildHealthIndicator('Healthy', healthyCount, Colors.green),
              const SizedBox(width: 12),
              _buildHealthIndicator('Warning', warningCount, Colors.orange),
              const SizedBox(width: 12),
              _buildHealthIndicator('Critical', criticalCount, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedHealthCard(FluentThemeData theme, CampaignHealthIndicator indicator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicator.isCritical 
              ? Colors.red.withValues(alpha: 0.3)
              : indicator.hasWarnings
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicator.isCritical 
                      ? Colors.red
                      : indicator.hasWarnings
                          ? Colors.orange
                          : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  indicator.campaignName,
                  style: theme.typography.bodyStrong,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (indicator.isCritical 
                      ? Colors.red
                      : indicator.hasWarnings
                          ? Colors.orange
                          : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(indicator.healthScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: indicator.isCritical 
                        ? Colors.red
                        : indicator.hasWarnings
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Text(
                'Status: ${indicator.status.toUpperCase()}',
                style: theme.typography.caption,
              ),
              const Spacer(),
              Text(
                'Updated: ${_formatTimestamp(indicator.lastUpdated)}',
                style: theme.typography.caption?.copyWith(
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
          
          if (indicator.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Issues:',
              style: theme.typography.caption?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            ...indicator.issues.map((issue) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Row(
                children: [
                  Icon(FluentIcons.warning, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  void _showDateRangePicker() {
    // Implementation for date range picker
    // This would typically show a dialog with date pickers
  }

  void _exportAnalyticsReport() async {
    try {
      // Here you would implement the actual export functionality
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Export Started'),
          content: const Text('Generating analytics report...'),
          severity: InfoBarSeverity.info,
          onClose: close,
        ),
      );
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Export Failed'),
          content: Text('Failed to export report: $e'),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
    }
  }
}
