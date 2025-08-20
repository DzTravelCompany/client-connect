import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/campaign_providers.dart';
import '../../data/campaigns_model.dart';
import 'campaign_status_badge.dart';
import 'campaign_metrics_card.dart';
import '../../../templates/logic/template_providers.dart';
import '../../../clients/logic/client_providers.dart';
import 'campaign_monitoring_widget.dart';
import 'real_time_message_logs.dart';


class CampaignDetailsPanel extends ConsumerWidget {
  final int campaignId;
  final String activeTab;
  final VoidCallback onClose;
  final Function(String) onTabChanged;

  const CampaignDetailsPanel({
    super.key,
    required this.campaignId,
    required this.activeTab,
    required this.onClose,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final theme = FluentTheme.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          left: BorderSide(
            color: theme.resources.dividerStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.resources.dividerStrokeColorDefault,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Campaign Details',
                    style: theme.typography.bodyStrong,
                  ),
                ),
                Button(
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                  ),
                  onPressed: onClose,
                  child: const Icon(FluentIcons.chrome_close, size: 12),
                ),
              ],
            ),
          ),

          // Tab navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab(context, 'overview', 'Overview'),
                const SizedBox(width: 8),
                _buildTab(context, 'metrics', 'Metrics'),
                const SizedBox(width: 8),
                _buildTab(context, 'logs', 'Logs'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: campaignAsync.when(
              data: (campaign) {
                if (campaign == null) {
                  return const Center(child: Text('Campaign not found'));
                }
                return _buildTabContent(context, ref, campaign);
              },
              loading: () => const Center(child: ProgressRing()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String tabId, String label) {
    final isActive = activeTab == tabId;
    
    return GestureDetector(
      onTap: () => onTabChanged(tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? FluentTheme.of(context).accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive 
                ? FluentTheme.of(context).accentColor 
                : Colors.grey[200],
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, CampaignModel campaign) {
    switch (activeTab) {
      case 'overview':
        return _buildOverviewTab(context, ref, campaign);
      case 'metrics':
        return _buildMetricsTab(context, ref, campaign);
      case 'logs':
        return _buildLogsTab(context, ref, campaign);
      default:
        return _buildOverviewTab(context, ref, campaign);
    }
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref, CampaignModel campaign) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campaign status
        Row(
          children: [
            Expanded(
              child: Text(
                campaign.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            CampaignStatusBadge(campaign: campaign),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Real-time monitoring widget for active campaigns
        if (campaign.isInProgress || campaign.isCompleted)
          CampaignMonitoringWidget(
            campaignId: campaign.id,
            showDetailedMetrics: true,
            showHealthIndicator: true,
          ),
        
        const SizedBox(height: 16),
        
        // Campaign details
        _buildDetailSection('Campaign Information', [
          _buildDetailRow('Created', _formatDate(campaign.createdAt)),
          _buildDetailRow('Recipients', '${campaign.clientIds.length}'),
          if (campaign.scheduledAt != null)
            _buildDetailRow('Scheduled', _formatDate(campaign.scheduledAt!)),
          if (campaign.completedAt != null)
            _buildDetailRow('Completed', _formatDate(campaign.completedAt!)),
        ]),
        
        const SizedBox(height: 16),
        
        // Template information
        _buildTemplateSection(ref, campaign.templateId),
        
        const SizedBox(height: 16),
        
        // Recipients preview
        _buildRecipientsSection(ref, campaign.clientIds.take(5).toList()),
      ],
    ),
  );
}

  Widget _buildMetricsTab(BuildContext context, WidgetRef ref, CampaignModel campaign) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CampaignMetricsCard(
        campaign: campaign,
        compact: false,
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context, WidgetRef ref, CampaignModel campaign) {
  return RealTimeMessageLogs(
    campaignId: campaign.id,
    showFilters: true,
    showExportButton: true,
  );
}

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(WidgetRef ref, int templateId) {
    final templateAsync = ref.watch(templateByIdProvider(templateId));
    
    return templateAsync.when(
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        
        return _buildDetailSection('Template', [
          _buildDetailRow('Name', template.name),
          _buildDetailRow('Type', template.type.toUpperCase()),
          if (template.subject != null)
            _buildDetailRow('Subject', template.subject!),
        ]);
      },
      loading: () => const SizedBox(height: 60, child: ProgressRing()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecipientsSection(WidgetRef ref, List<int> clientIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipients Preview',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...clientIds.map((clientId) {
          final clientAsync = ref.watch(clientByIdProvider(clientId));
          return clientAsync.when(
            data: (client) {
              if (client == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(FluentIcons.contact, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        client.fullName,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 16, child: ProgressRing()),
            error: (_, __) => const SizedBox.shrink(),
          );
        }),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildLogItem(WidgetRef ref, MessageLogModel log) {
    final clientAsync = ref.watch(clientByIdProvider(log.clientId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getLogStatusColor(log.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  log.type == 'email' ? FluentIcons.mail : FluentIcons.chat,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: clientAsync.when(
                    data: (client) => Text(
                      client?.fullName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unknown'),
                  ),
                ),
                Text(
                  log.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _getLogStatusColor(log.status),
                  ),
                ),
              ],
            ),
            if (log.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                log.errorMessage!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLogStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
      case 'failed_max_retries':
        return Colors.red;
      case 'pending':
      case 'retrying':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}