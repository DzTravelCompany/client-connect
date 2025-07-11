import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../logic/dashboard_providers.dart';
import 'widgets/bento_grid.dart';
import 'widgets/metric_card.dart';
import 'widgets/activity_feed_widget.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/chart_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final activityAsync = ref.watch(dashboardActivityProvider);
    final clientGrowthAsync = ref.watch(clientGrowthChartProvider);
    final campaignPerformanceAsync = ref.watch(campaignPerformanceChartProvider);
    
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Center',
                      style: theme.typography.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back! Here\'s what\'s happening with your business.',
                      style: theme.typography.body?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Button(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(theme.resources.cardBackgroundFillColorSecondary),
                      ),
                      onPressed: () {
                        // Refresh data
                        ref.invalidate(dashboardMetricsProvider);
                        ref.invalidate(dashboardActivityProvider);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.refresh, size: 16),
                          SizedBox(width: 8),
                          Text('Refresh'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        // Quick action - navigate to add client
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.add, size: 16),
                          SizedBox(width: 8),
                          Text('Quick Action'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Bento Grid Dashboard
            Expanded(
              child: StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Metrics Row
                  StaggeredGridTile.count(
                    crossAxisCellCount: 4,
                    mainAxisCellCount: 1,
                    child: metricsAsync.when(
                      data: (metrics) => _buildMetricsRow(context, metrics),
                      loading: () => _buildLoadingCard(context, 'Loading metrics...'),
                      error: (error, stack) => _buildErrorCard(context, 'Failed to load metrics'),
                    ),
                  ),
                  
                  // Client Growth Chart
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: clientGrowthAsync.when(
                      data: (data) => BentoCard(
                        child: ChartWidget(
                          title: 'Client Growth',
                          data: data,
                          type: ChartType.line,
                        ),
                      ),
                      loading: () => _buildLoadingCard(context, 'Loading chart...'),
                      error: (error, stack) => _buildErrorCard(context, 'Chart error'),
                    ),
                  ),
                  
                  // Campaign Performance Chart
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: campaignPerformanceAsync.when(
                      data: (data) => BentoCard(
                        child: ChartWidget(
                          title: 'Campaign Success Rate',
                          data: data,
                          type: ChartType.bar,
                        ),
                      ),
                      loading: () => _buildLoadingCard(context, 'Loading chart...'),
                      error: (error, stack) => _buildErrorCard(context, 'Chart error'),
                    ),
                  ),
                  
                  // Activity Feed
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: activityAsync.when(
                      data: (activities) => BentoCard(
                        child: ActivityFeedWidget(activities: activities),
                      ),
                      loading: () => _buildLoadingCard(context, 'Loading activity...'),
                      error: (error, stack) => _buildErrorCard(context, 'Activity error'),
                    ),
                  ),
                  
                  // Quick Actions
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: const BentoCard(
                      child: QuickActionsWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, DashboardMetrics metrics) {
    final theme = FluentTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Total Clients',
              value: metrics.totalClients.toString(),
              subtitle: '+${metrics.newClientsThisWeek} this week',
              icon: FluentIcons.people,
              iconColor: Colors.blue,
              trend: '+12%',
              isPositiveTrend: true,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Expanded(
            child: MetricCard(
              title: 'Active Campaigns',
              value: metrics.activeCampaigns.toString(),
              subtitle: '+${metrics.campaignsThisWeek} this week',
              icon: FluentIcons.send,
              iconColor: Colors.green,
              trend: '+8%',
              isPositiveTrend: true,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Expanded(
            child: MetricCard(
              title: 'Templates',
              value: metrics.totalTemplates.toString(),
              subtitle: 'Ready to use',
              icon: FluentIcons.page,
              iconColor: Colors.purple,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Expanded(
            child: MetricCard(
              title: 'Messages Sent',
              value: _formatNumber(metrics.messagesSentThisWeek),
              subtitle: 'This week',
              icon: FluentIcons.mail,
              iconColor: Colors.orange,
              trend: '+24%',
              isPositiveTrend: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, String message) {
    final theme = FluentTheme.of(context);
    
    return BentoCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.typography.body?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    final theme = FluentTheme.of(context);
    
    return BentoCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.error,
              size: 32,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.typography.body?.copyWith(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}