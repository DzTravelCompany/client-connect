import 'package:client_connect/src/features/campaigns/presentation/retry_management_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';


class CampaignMetricsCard extends ConsumerWidget {
  final CampaignModel campaign;
  final bool compact;

  const CampaignMetricsCard({
    super.key,
    required this.campaign,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(campaignStatisticsProvider(campaign.id));
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: statisticsAsync.when(
          data: (stats) => compact 
              ? _buildCompactMetrics(context, stats)
              : _buildFullMetrics(context, stats),
          loading: () => const Center(child: ProgressRing()),
          error: (error, _) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildCompactMetrics(BuildContext context, CampaignStatistics stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem('Total', stats.totalMessages, Colors.blue),
        _buildMetricItem('Sent', stats.sentMessages, Colors.green),
        _buildMetricItem('Failed', stats.failedMessages, Colors.red),
      ],
    );
  }

  Widget _buildFullMetrics(BuildContext context, CampaignStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaign Metrics',
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 16),
        
        // Primary metrics
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Messages', stats.totalMessages, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Sent', stats.sentMessages, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Failed', stats.failedMessages, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Pending', stats.pendingMessages, Colors.orange)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Success rate
        Row(
          children: [
            Expanded(
              child: _buildRateCard(
                'Success Rate',
                stats.successRate,
                stats.successRate >= 0.9 ? Colors.green : 
                stats.successRate >= 0.7 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRateCard(
                'Failure attempts',
                stats.retryStatistics.retryFailedRate,
                stats.retryStatistics.retryFailedRate <= 0.1 ? Colors.green : 
                stats.retryStatistics.retryFailedRate <= 0.3 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
        
        // Retry statistics
        if (stats.retryStatistics.totalRetryAttempts > 0) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Retry Statistics',
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Retries', stats.retryStatistics.totalRetryAttempts, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Successful Retries', stats.retryStatistics.successfulRetries, Colors.green)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(String label, double rate, Color color) {
    final percentage = (rate * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
