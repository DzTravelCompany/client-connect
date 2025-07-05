import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_logs_dialog.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class CampaignDetailsScreen extends ConsumerWidget {
  final int campaignId;
  
  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final messageLogsAsync = ref.watch(campaignMessageLogsProvider(campaignId));
    final progressAsync = ref.watch(campaignProgressProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: campaignAsync.when(
          data: (campaign) => Text(campaign?.name ?? 'Campaign Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Campaign Details'),
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back'),
              onPressed: () => context.go('/campaigns'),
            ),
          ],
        ),
      ),
      content: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return const Center(
              child: Text('Campaign not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign overview
                _buildCampaignOverview(context, campaign, ref),
                const SizedBox(height: 24),

                // Real-time progress (if in progress)
                if (campaign.isInProgress)
                  progressAsync.when(
                    data: (progress) {
                      if (progress.campaignId == campaignId) {
                        return Column(
                          children: [
                            _buildProgressSection(context, progress),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                // Message statistics
                messageLogsAsync.when(
                  data: (logs) => _buildMessageStatistics(context, logs),
                  loading: () => const Center(child: ProgressRing()),
                  error: (error, stack) => Text('Error loading statistics: $error'),
                ),

                const SizedBox(height: 24),

                // Template preview
                _buildTemplatePreview(context, campaign, ref),

                const SizedBox(height: 24),

                // Recipients list
                _buildRecipientsList(context, campaign, ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: ProgressRing()),
        error: (error, stack) => Center(
          child: Text('Error loading campaign: $error'),
        ),
      ),
    );
  }

  Widget _buildCampaignOverview(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Campaign Overview',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const Spacer(),
                _buildStatusBadge(campaign.status),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Created',
                    _formatDate(campaign.createdAt),
                    FluentIcons.calendar,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Recipients',
                    '${campaign.clientIds.length}',
                    FluentIcons.people,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Scheduled',
                    campaign.scheduledAt != null 
                        ? _formatDate(campaign.scheduledAt!)
                        : 'Immediate',
                    FluentIcons.clock,
                  ),
                ),
                if (campaign.completedAt != null)
                  Expanded(
                    child: _buildOverviewItem(
                      'Completed',
                      _formatDate(campaign.completedAt!),
                      FluentIcons.completed,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[100]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, CampaignProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending Progress',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ProgressBar(
                    value: progress.progressPercentage * 100,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(progress.progressPercentage * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress stats
            Row(
              children: [
                _buildProgressStat('Processed', progress.processed, Colors.blue),
                const SizedBox(width: 16),
                _buildProgressStat('Successful', progress.successful, Colors.green),
                const SizedBox(width: 16),
                _buildProgressStat('Failed', progress.failed, Colors.red),
                const Spacer(),
                Text(
                  '${progress.processed}/${progress.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (progress.currentStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                progress.currentStatus!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[100],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMessageStatistics(BuildContext context, List<MessageLogModel> logs) {
    final sent = logs.where((log) => log.isSent).length;
    final failed = logs.where((log) => log.isFailed).length;
    final pending = logs.where((log) => log.isPending).length;
    final total = logs.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Message Statistics',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const Spacer(),
                Button(
                  onPressed: () => _showMessageLogs(context),
                  child: const Text('View All Messages'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', total, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Sent', sent, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Failed', failed, Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Pending', pending, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    final templateAsync = ref.watch(templateByIdProvider(campaign.templateId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Preview',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            templateAsync.when(
              data: (template) {
                if (template == null) {
                  return const Text('Template not found');
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          template.isEmail ? FluentIcons.mail : FluentIcons.chat,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          template.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (template.subject != null) ...[
                      Text(
                        'Subject: ${template.subject}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[150],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[200]),
                      ),
                      child: Text(
                        template.body,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const ProgressRing(),
              error: (error, stack) => Text('Error loading template: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipients (${campaign.clientIds.length})',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            ...campaign.clientIds.take(5).map((clientId) {
              final clientAsync = ref.watch(clientByIdProvider(clientId));
              return clientAsync.when(
                data: (client) {
                  if (client == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.contact, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(client.fullName)),
                        if (client.email != null)
                          Text(
                            client.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[100],
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 24, child: ProgressRing()),
                error: (_, __) => const SizedBox.shrink(),
              );
            }),
            
            if (campaign.clientIds.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${campaign.clientIds.length - 5} more recipients',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[100],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = FluentIcons.clock;
        break;
      case 'in_progress':
        color = Colors.blue;
        icon = FluentIcons.send;
        break;
      case 'completed':
        color = Colors.green;
        icon = FluentIcons.completed;
        break;
      case 'failed':
        color = Colors.red;
        icon = FluentIcons.error;
        break;
      default:
        color = Colors.grey;
        icon = FluentIcons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: (0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: (0.3))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MessageLogsDialog(campaignId: campaignId),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}