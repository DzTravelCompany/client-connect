import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_logs_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class CampaignDashboardScreen extends ConsumerStatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  ConsumerState<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends ConsumerState<CampaignDashboardScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    final progressAsync = ref.watch(campaignProgressProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Campaign Dashboard'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('New Campaign'),
              onPressed: () => context.go('/campaigns/create'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () => ref.invalidate(allCampaignsProvider),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Real-time progress indicator
            progressAsync.when(
              data: (progress) => _buildProgressIndicator(progress),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Filter tabs
            Row(
              children: [
                _buildFilterTab('all', 'All Campaigns'),
                const SizedBox(width: 8),
                _buildFilterTab('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterTab('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterTab('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterTab('failed', 'Failed'),
              ],
            ),
            const SizedBox(height: 16),

            // Campaign list
            Expanded(
              child: campaignsAsync.when(
                data: (campaigns) {
                  final filteredCampaigns = _filterCampaigns(campaigns);
                  
                  if (filteredCampaigns.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = filteredCampaigns[index];
                      return _buildCampaignCard(campaign);
                    },
                  );
                },
                loading: () => const Center(child: ProgressRing()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading campaigns: $error'),
                      const SizedBox(height: 16),
                      Button(
                        onPressed: () => ref.invalidate(allCampaignsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(CampaignProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: (0.1)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: (0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.send, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Campaign in Progress',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const Spacer(),
              Text(
                '${progress.processed}/${progress.total}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          ProgressBar(
            value: progress.progressPercentage * 100,
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildProgressStat('Successful', progress.successful, Colors.green),
              const SizedBox(width: 16),
              _buildProgressStat('Failed', progress.failed, Colors.red),
              const Spacer(),
              if (progress.currentStatus != null)
                Text(
                  progress.currentStatus!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
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

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FluentTheme.of(context).accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? FluentTheme.of(context).accentColor : Colors.grey[60],
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(campaign.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(campaign.status),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () => _showCampaignMenu(campaign),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Campaign details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    FluentIcons.people,
                    'Recipients',
                    '${campaign.clientIds.length}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    FluentIcons.calendar,
                    'Scheduled',
                    campaign.scheduledAt != null 
                        ? _formatDate(campaign.scheduledAt!)
                        : 'Immediate',
                  ),
                ),
                if (campaign.completedAt != null)
                  Expanded(
                    child: _buildDetailItem(
                      FluentIcons.completed,
                      'Completed',
                      _formatDate(campaign.completedAt!),
                    ),
                  ),
              ],
            ),
            
            // Message logs summary for completed campaigns
            if (campaign.isCompleted || campaign.isInProgress)
              _buildMessageLogsSummary(campaign.id),
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
      case 'scheduled':
        color = Colors.purple;
        icon = FluentIcons.calendar;
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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[100]),
        const SizedBox(width: 8),
        Column(
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageLogsSummary(int campaignId) {
    final messageLogsAsync = ref.watch(campaignMessageLogsProvider(campaignId));
    
    return messageLogsAsync.when(
      data: (logs) {
        final sent = logs.where((log) => log.isSent).length;
        final failed = logs.where((log) => log.isFailed).length;
        final pending = logs.where((log) => log.isPending).length;
        
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              _buildMessageStat('Sent', sent, Colors.green),
              const SizedBox(width: 16),
              _buildMessageStat('Failed', failed, Colors.red),
              const SizedBox(width: 16),
              _buildMessageStat('Pending', pending, Colors.orange),
              const Spacer(),
              Button(
                onPressed: () => _showMessageLogs(campaignId),
                child: const Text('View Details'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 20, child: ProgressRing()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessageStat(String label, int count, Color color) {
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
          '$label: $count',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FluentIcons.send, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? 'No campaigns yet'
                : 'No ${_selectedFilter.replaceAll('_', ' ')} campaigns',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Create your first campaign to get started'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/campaigns/create'),
            child: const Text('Create Campaign'),
          ),
        ],
      ),
    );
  }

  List<CampaignModel> _filterCampaigns(List<CampaignModel> campaigns) {
    if (_selectedFilter == 'all') return campaigns;
    return campaigns.where((campaign) => campaign.status == _selectedFilter).toList();
  }

  void _showCampaignMenu(CampaignModel campaign) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(campaign.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (campaign.isPending)
              ListTile(
                leading: const Icon(FluentIcons.play),
                title: const Text('Start Campaign'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _startCampaign(campaign.id);
                },
              ),
            if (campaign.isInProgress)
              ListTile(
                leading: const Icon(FluentIcons.pause),
                title: const Text('Stop Campaign'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _stopCampaign(campaign.id);
                },
              ),
            ListTile(
              leading: const Icon(FluentIcons.view),
              title: const Text('View Details'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/campaigns/${campaign.id}');
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.mail),
              title: const Text('Message Logs'),
              onPressed: () {
                Navigator.of(context).pop();
                _showMessageLogs(campaign.id);
              },
            ),
            if (campaign.isCompleted || campaign.isFailed)
              ListTile(
                leading: const Icon(FluentIcons.delete),
                title: const Text('Delete Campaign'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteDialog(campaign.id);
                },
              ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _startCampaign(int campaignId) async {
    try {
      final controller = ref.read(campaignControlProvider);
      await controller.startCampaign(campaignId);
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Campaign Started'),
            content: const Text('The campaign has been started and is now sending messages.'),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text('Failed to start campaign: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _stopCampaign(int campaignId) async {
    try {
      final controller = ref.read(campaignControlProvider);
      await controller.stopCampaign(campaignId);
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Campaign Stopped'),
            content: const Text('The campaign has been stopped.'),
            severity: InfoBarSeverity.warning,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text('Failed to stop campaign: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _showMessageLogs(int campaignId) {
    showDialog(
      context: context,
      builder: (context) => MessageLogsDialog(campaignId: campaignId),
    );
  }

  void _showDeleteDialog(int campaignId) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Campaign'),
        content: const Text('Are you sure you want to delete this campaign? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Campaign Deleted'),
                  content: const Text('The campaign has been deleted.'),
                  severity: InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}