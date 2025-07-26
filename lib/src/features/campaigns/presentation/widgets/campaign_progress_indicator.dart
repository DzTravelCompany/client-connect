import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';

class CampaignProgressIndicator extends ConsumerWidget {
  final CampaignModel campaign;
  final bool showPercentage;
  final bool showStats;
  final double height;

  const CampaignProgressIndicator({
    super.key,
    required this.campaign,
    this.showPercentage = true,
    this.showStats = false,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!campaign.isInProgress && !campaign.isCompleted) {
      return const SizedBox.shrink();
    }

    final messageLogsAsync = ref.watch(campaignMessageLogsProvider(campaign.id));
    
    return messageLogsAsync.when(
      data: (logs) {
        final total = logs.length;
        final sent = logs.where((log) => log.isSent).length;
        final failed = logs.where((log) => log.isFailed || log.isFailedMaxRetries).length;
        final pending = logs.where((log) => log.isPending || log.isRetrying).length;
        
        final progress = total > 0 ? sent / total : 0.0;
        final percentage = (progress * 100).toInt();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(height / 2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          campaign.isCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showPercentage) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            
            // Statistics
            if (showStats) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProgressStat('Sent', sent, Colors.green),
                  const SizedBox(width: 12),
                  _buildProgressStat('Failed', failed, Colors.red),
                  const SizedBox(width: 12),
                  _buildProgressStat('Pending', pending, Colors.orange),
                  const Spacer(),
                  Text(
                    '$sent/$total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
      loading: () => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: const LinearProgressIndicator(
          backgroundColor: Colors.transparent,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}