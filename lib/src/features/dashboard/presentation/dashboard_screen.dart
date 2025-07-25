import 'package:client_connect/src/features/dashboard/presentation/widgets/activity_feed_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import '../logic/dashboard_providers.dart';
import 'widgets/metric_card.dart';
import 'widgets/quick_actions_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final activityAsync = ref.watch(dashboardActivityProvider);
    
    return Container(
      color: DesignTokens.surfacePrimary,
      child: Column(
        children: [
          _buildHeader(context, ref),
          SizedBox(height: DesignTokens.space6),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.space6),
                child: StaggeredGrid.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: DesignTokens.space4,
                  crossAxisSpacing: DesignTokens.space4,
                  children: [
                    // Metrics Row - Full width
                    StaggeredGridTile.count(
                      crossAxisCellCount: 4,
                      mainAxisCellCount: 1,
                      child: metricsAsync.when(
                        data: (metrics) => _buildMetricsRow(context, metrics),
                        loading: () => DesignSystemComponents.skeletonLoader(
                          height: 120,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                        error: (error, stack) => DesignSystemComponents.emptyState(
                          title: 'Error Loading Metrics',
                          message: 'Failed to load dashboard metrics',
                          icon: FluentIcons.error,
                          iconColor: DesignTokens.semanticError,
                          actionText: 'Retry',
                          onAction: () => ref.invalidate(dashboardMetricsProvider),
                        ),
                      ),
                    ),
              
              
                    // Activity Feed - Left side
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 2,
                      child: activityAsync.when(
                        data: (activities) => DesignSystemComponents.standardCard(
                          child: ActivityFeedWidget(activities: activities),
                        ),
                        loading: () => DesignSystemComponents.skeletonLoader(
                          height: 300,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                        error: (error, stack) => DesignSystemComponents.standardCard(
                          child: DesignSystemComponents.emptyState(
                            title: 'Activity Error',
                            message: 'Unable to load recent activity',
                            icon: FluentIcons.timeline,
                            iconColor: DesignTokens.semanticError,
                          ),
                        ),
                      ),
                    ),
                    
                    // Quick Actions - Right side
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 2,
                      child: DesignSystemComponents.standardCard(
                        child: const QuickActionsWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.accentPrimary,
                  DesignTokens.accentSecondary,
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              FluentIcons.view_dashboard,
              size: DesignTokens.iconSizeLarge,
              color: DesignTokens.textInverse,
            ),
          ),
          SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Command Center',
                  style: DesignTextStyles.displayLarge.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                SizedBox(height: DesignTokens.space1),
                Text(
                  'Welcome back! Here\'s what\'s happening with your business.',
                  style: DesignTextStyles.bodyLarge.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              DesignSystemComponents.secondaryButton(
                text: 'Refresh',
                icon: FluentIcons.refresh,
                onPressed: () {
                  ref.invalidate(dashboardMetricsProvider);
                  ref.invalidate(dashboardActivityProvider);
                },
                tooltip: 'Refresh dashboard data',
              ),
              SizedBox(width: DesignTokens.space3),
              DesignSystemComponents.primaryButton(
                text: 'Quick Action',
                icon: FluentIcons.add,
                onPressed: () => _showQuickActionMenu(context, ref),
                tooltip: 'Quick actions menu',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, DashboardMetrics metrics) {
    return DesignSystemComponents.standardCard(
      padding: const EdgeInsets.all(DesignTokens.space6),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Total Clients',
              value: metrics.totalClients.toString(),
              subtitle: '+${metrics.newClientsThisWeek} this week',
              icon: FluentIcons.people,
              iconColor: DesignTokens.accentPrimary,
              trend: '+12%',
              isPositiveTrend: true,
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: DesignTokens.borderPrimary,
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          ),
          Expanded(
            child: MetricCard(
              title: 'Active Campaigns',
              value: metrics.activeCampaigns.toString(),
              subtitle: '+${metrics.campaignsThisWeek} this week',
              icon: FluentIcons.send,
              iconColor: DesignTokens.semanticSuccess,
              trend: '+8%',
              isPositiveTrend: true,
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: DesignTokens.borderPrimary,
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          ),
          Expanded(
            child: MetricCard(
              title: 'Templates',
              value: metrics.totalTemplates.toString(),
              subtitle: 'Ready to use',
              icon: FluentIcons.page,
              iconColor: DesignTokens.semanticInfo,
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: DesignTokens.borderPrimary,
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          ),
          Expanded(
            child: MetricCard(
              title: 'Messages Sent',
              value: _formatNumber(metrics.messagesSentThisWeek),
              subtitle: 'This week',
              icon: FluentIcons.mail,
              iconColor: DesignTokens.semanticWarning,
              trend: '+24%',
              isPositiveTrend: true,
            ),
          ),
        ],
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

  void _showQuickActionMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Row(
          children: [
            Icon(
              FluentIcons.lightning_bolt,
              color: DesignTokens.accentPrimary,
              size: DesignTokens.iconSizeMedium,
            ),
            SizedBox(width: DesignTokens.space2),
            const Text('Quick Actions'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuickActionItem(
                context,
                'Add New Client',
                FluentIcons.reminder_person,
                () {
                  Navigator.of(context).pop();
                  context.go('/clients/add');
                },
              ),
              SizedBox(height: DesignTokens.space2),
              _buildQuickActionItem(
                context,
                'Create Campaign',
                FluentIcons.send,
                () {
                  Navigator.of(context).pop();
                  context.go('/campaigns/create');
                },
              ),
              SizedBox(height: DesignTokens.space2),
              _buildQuickActionItem(
                context,
                'New Template',
                FluentIcons.page,
                () {
                  Navigator.of(context).pop();
                  context.go('/templates/editor');
                },
              ),
            ],
          ),
        ),
        actions: [
          DesignSystemComponents.secondaryButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return DesignSystemComponents.standardCard(
      onTap: onTap,
      isHoverable: true,
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space2),
            decoration: BoxDecoration(
              color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Icon(
              icon,
              color: DesignTokens.accentPrimary,
              size: DesignTokens.iconSizeMedium,
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(
              title,
              style: DesignTextStyles.body.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          Icon(
            FluentIcons.chevron_right,
            color: DesignTokens.textTertiary,
            size: DesignTokens.iconSizeSmall,
          ),
        ],
      ),
    );
  }
}