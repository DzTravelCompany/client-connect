import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/campaign_providers.dart';


class CampaignMonitoringWidget extends ConsumerStatefulWidget {
  final int campaignId;
  final bool showDetailedMetrics;
  final bool showHealthIndicator;

  const CampaignMonitoringWidget({
    super.key,
    required this.campaignId,
    this.showDetailedMetrics = true,
    this.showHealthIndicator = true,
  });

  @override
  ConsumerState<CampaignMonitoringWidget> createState() => _CampaignMonitoringWidgetState();
}

class _CampaignMonitoringWidgetState extends ConsumerState<CampaignMonitoringWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringAsync = ref.watch(campaignMonitoringProvider(widget.campaignId));
    final theme = FluentTheme.of(context);

    return monitoringAsync.when(
      data: (data) => _buildMonitoringContent(context, theme, data),
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, error.toString()),
    );
  }

  Widget _buildMonitoringContent(BuildContext context, FluentThemeData theme, CampaignMonitoringData data) {
    if (data.campaign == null) {
      return _buildErrorState(theme, 'Campaign not found');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getHealthBorderColor(data.healthScore),
          width: 2,
        ),
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
          // Header with campaign name and health indicator
          _buildHeader(theme, data),
          
          const SizedBox(height: 16),
          
          // Real-time metrics
          _buildRealTimeMetrics(theme, data),
          
          if (widget.showDetailedMetrics) ...[
            const SizedBox(height: 16),
            _buildDetailedMetrics(theme, data),
          ],
          
          const SizedBox(height: 16),
          
          // Progress visualization
          _buildProgressVisualization(theme, data),
          
          const SizedBox(height: 12),
          
          // Last updated indicator
          _buildLastUpdatedIndicator(theme, data.lastUpdated),
        ],
      ),
    );
  }

  Widget _buildHeader(FluentThemeData theme, CampaignMonitoringData data) {
    return Row(
      children: [
        // Campaign status indicator with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: data.campaign!.isInProgress ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(data.campaign!.status),
                  shape: BoxShape.circle,
                  boxShadow: data.campaign!.isInProgress ? [
                    BoxShadow(
                      color: _getStatusColor(data.campaign!.status).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.campaign!.name,
                style: theme.typography.bodyStrong?.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${data.campaign!.status.toUpperCase()} • ${data.statistics.totalMessages} recipients',
                style: theme.typography.caption?.copyWith(
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        
        if (widget.showHealthIndicator)
          _buildHealthIndicator(theme, data.healthScore),
      ],
    );
  }

  Widget _buildHealthIndicator(FluentThemeData theme, double healthScore) {
    Color healthColor;
    IconData healthIcon;
    String healthText;
    
    if (healthScore > 0.8) {
      healthColor = Colors.green;
      healthIcon = FluentIcons.completed_solid;
      healthText = 'Healthy';
    } else if (healthScore > 0.5) {
      healthColor = Colors.orange;
      healthIcon = FluentIcons.warning;
      healthText = 'Warning';
    } else {
      healthColor = Colors.red;
      healthIcon = FluentIcons.error_badge;
      healthText = 'Critical';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(healthIcon, size: 12, color: healthColor),
          const SizedBox(width: 4),
          Text(
            healthText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: healthColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics(FluentThemeData theme, CampaignMonitoringData data) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            'Sent',
            '${data.statistics.sentMessages}',
            Colors.green,
            FluentIcons.completed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Failed',
            '${data.statistics.failedMessages}',
            Colors.red,
            FluentIcons.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            'Pending',
            '${data.statistics.pendingMessages}',
            Colors.orange,
            FluentIcons.clock,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(FluentThemeData theme, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildDetailedMetrics(FluentThemeData theme, CampaignMonitoringData data) {
    final retryCount = data.messageLogs.where((log) => log.retryCount > 0).length;
    final avgRetryCount = data.messageLogs.isNotEmpty 
        ? data.messageLogs.map((log) => log.retryCount).reduce((a, b) => a + b) / data.messageLogs.length
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric('Success Rate', '${(data.statistics.successRate * 100).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildDetailMetric('Retry Count', '$retryCount'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric('Avg Retries', avgRetryCount.toStringAsFixed(1)),
              ),
              Expanded(
                child: _buildDetailMetric('Health Score', '${(data.healthScore * 100).toStringAsFixed(0)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value) {
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

  Widget _buildProgressVisualization(FluentThemeData theme, CampaignMonitoringData data) {
    final total = data.statistics.totalMessages;
    if (total == 0) return const SizedBox.shrink();
    
    final sentProgress = data.statistics.sentMessages / total;
    final failedProgress = data.statistics.failedMessages / total;
    final pendingProgress = data.statistics.pendingMessages / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Overview',
          style: theme.typography.caption?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: Row(
            children: [
              if (sentProgress > 0)
                Expanded(
                  flex: (sentProgress * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              if (failedProgress > 0)
                Expanded(
                  flex: (failedProgress * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              if (pendingProgress > 0)
                Expanded(
                  flex: (pendingProgress * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${data.statistics.sentMessages + data.statistics.failedMessages}/${data.statistics.totalMessages} processed',
          style: theme.typography.caption?.copyWith(
            color: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdatedIndicator(FluentThemeData theme, DateTime lastUpdated) {
    final timeDiff = DateTime.now().difference(lastUpdated);
    String timeText;
    
    if (timeDiff.inSeconds < 60) {
      timeText = '${timeDiff.inSeconds}s ago';
    } else if (timeDiff.inMinutes < 60) {
      timeText = '${timeDiff.inMinutes}m ago';
    } else {
      timeText = '${timeDiff.inHours}h ago';
    }
    
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: timeDiff.inSeconds < 10 ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Updated $timeText',
          style: theme.typography.caption?.copyWith(
            fontSize: 10,
            color: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: const Column(
        children: [
          ProgressRing(),
          SizedBox(height: 12),
          Text('Loading campaign monitoring data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(FluentThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(FluentIcons.error, size: 32, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Monitoring Error',
            style: theme.typography.bodyStrong?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.typography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getHealthBorderColor(double healthScore) {
    if (healthScore > 0.8) return Colors.green.withValues(alpha: 0.3);
    if (healthScore > 0.5) return Colors.orange.withValues(alpha: 0.3);
    return Colors.red.withValues(alpha: 0.3);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
      case 'sending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}