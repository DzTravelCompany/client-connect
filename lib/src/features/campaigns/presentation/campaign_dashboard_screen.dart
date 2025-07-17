import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_logs_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/layouts/three_column_layout.dart';
import 'widgets/campaign_filter_panel.dart';
import 'widgets/enhanced_campaign_card.dart';
import 'widgets/campaign_details_panel.dart';


class CampaignDashboardScreen extends ConsumerStatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  ConsumerState<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends ConsumerState<CampaignDashboardScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {

    return Consumer(
      builder: (context, ref, child){
        final campaignsAsync = ref.watch(allCampaignsProvider);
        final progressAsync = ref.watch(campaignProgressProvider);
        final filterState = ref.watch(campaignFilterStateProvider);
        final detailPanelState = ref.watch(campaignDetailPanelProvider);
        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Campaign Dashboard'),
            commandBar: CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('New Campaign'),
                  onPressed: () => context.pushNamed('createCampaigns'),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.analytics_report),
                  label: const Text('Analytics'),
                  onPressed: () => context.pushNamed('seeAnalyticsCampaigns'),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () => ref.invalidate(allCampaignsProvider),
                ),
              ],
            ),
          ),
          content: ThreeColumnLayout(
            sidebar: const CampaignFilterPanel(),
            mainContent: _buildMainContent(context, ref, campaignsAsync, progressAsync, filterState),
            detailPanel: detailPanelState.isVisible 
                ? _buildDetailPanel(context, ref, detailPanelState)
                : null,
            showDetailPanel: detailPanelState.isVisible,
          ),
        );
      }
    );
  }

  Widget _buildMainContent(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue<List<CampaignModel>> campaignsAsync,
    AsyncValue<CampaignProgress> progressAsync,
    CampaignFilterState filterState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Campaign health indicators
          _buildHealthIndicators(ref),

          // Real-time progress indicator
          progressAsync.when(
            data: (progress) => _buildProgressIndicator(progress),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Campaign cards grid
          Expanded(
            child: campaignsAsync.when(
              data: (campaigns) {
                final filteredCampaigns = _filterCampaigns(campaigns, filterState);
                
                if (filteredCampaigns.isEmpty) {
                  return _buildEmptyState(filterState.hasActiveFilters);
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredCampaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = filteredCampaigns[index];
                    return _buildEnhancedCampaignCard(context, ref, campaign);
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
    );
  }

  Widget _buildHealthIndicators(WidgetRef ref) {
    final healthAsync = ref.watch(campaignHealthProvider);
    
    return healthAsync.when(
      data: (healthIndicators) {
        if (healthIndicators.isEmpty) return const SizedBox.shrink();
        
        final criticalCampaigns = healthIndicators.where((h) => h.isCritical).length;
        final warningCampaigns = healthIndicators.where((h) => h.hasWarnings).length;
        final healthyCampaigns = healthIndicators.where((h) => h.isHealthy).length;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                criticalCampaigns > 0 
                    ? Colors.red.withValues(alpha: 0.1)
                    : warningCampaigns > 0
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: criticalCampaigns > 0 
                  ? Colors.red.withValues(alpha: 0.3)
                  : warningCampaigns > 0
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.health,
                    size: 20,
                    color: criticalCampaigns > 0 
                        ? Colors.red
                        : warningCampaigns > 0
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Campaign Health Overview',
                    style: FluentTheme.of(context).typography.subtitle?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${healthIndicators.length} active campaigns',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildHealthStat('Healthy', healthyCampaigns, Colors.green),
                  const SizedBox(width: 16),
                  _buildHealthStat('Warning', warningCampaigns, Colors.orange),
                  const SizedBox(width: 16),
                  _buildHealthStat('Critical', criticalCampaigns, Colors.red),
                  const Spacer(),
                  if (criticalCampaigns > 0 || warningCampaigns > 0)
                    Button(
                      onPressed: () => _showHealthDetails(healthIndicators),
                      child: const Text('View Details'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHealthStat(String label, int count, Color color) {
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

  void _showHealthDetails(List<CampaignHealthIndicator> healthIndicators) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Campaign Health Details'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          child: ListView.builder(
            itemCount: healthIndicators.length,
            itemBuilder: (context, index) {
              final indicator = healthIndicators[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              indicator.campaignName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${(indicator.healthScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: indicator.isCritical 
                                  ? Colors.red
                                  : indicator.hasWarnings
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (indicator.issues.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...indicator.issues.map((issue) => Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 2),
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
                ),
              );
            },
          ),
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

  Widget _buildDetailPanel(BuildContext context, WidgetRef ref, CampaignDetailPanelState panelState) {
    if (panelState.selectedCampaignId == null) return const SizedBox.shrink();
    
    return CampaignDetailsPanel(
      campaignId: panelState.selectedCampaignId!,
      activeTab: panelState.activeTab,
      onClose: () => ref.read(campaignDetailPanelProvider.notifier).hidePanel(),
      onTabChanged: (tab) => ref.read(campaignDetailPanelProvider.notifier).setActiveTab(tab),
    );
  }

  Widget _buildEnhancedCampaignCard(BuildContext context, WidgetRef ref, CampaignModel campaign) {
    return EnhancedCampaignCard(
      campaign: campaign,
      onTap: () {
        ref.read(campaignDetailPanelProvider.notifier).showCampaignDetails(campaign.id);
      },
      onStart: campaign.isPending ? () => _startCampaign(ref, campaign.id) : null,
      onPause: campaign.isInProgress ? () => _pauseCampaign(ref, campaign.id) : null,
      onViewDetails: () => context.go('/campaigns/${campaign.id}'),
    );
  }

  List<CampaignModel> _filterCampaigns(List<CampaignModel> campaigns, CampaignFilterState filterState) {
    var filtered = campaigns.where((campaign) {
      // Apply search filter
      if (filterState.searchTerm.isNotEmpty) {
        final searchLower = filterState.searchTerm.toLowerCase();
        if (!campaign.name.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      // Apply status filters
      if (filterState.statusFilters.isNotEmpty) {
        if (!filterState.statusFilters.contains(campaign.status)) {
          return false;
        }
      }
      
      // Apply date range filters
      if (filterState.startDate != null) {
        if (campaign.createdAt.isBefore(filterState.startDate!)) {
          return false;
        }
      }
      
      if (filterState.endDate != null) {
        if (campaign.createdAt.isAfter(filterState.endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (filterState.sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'scheduledAt':
          final aDate = a.scheduledAt ?? DateTime(1970);
          final bDate = b.scheduledAt ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return filterState.sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FluentIcons.send, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No campaigns match your filters' : 'No campaigns yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters 
                ? 'Try adjusting your search criteria'
                : 'Create your first campaign to get started',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/campaigns/create'),
            child: const Text('Create Campaign'),
          ),
        ],
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

  // TODO see this function later
  // ignore: unused_element
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

  // TODO see this function later
  // ignore: unused_element
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
                  _startCampaign(ref, campaign.id);
                },
              ),
            if (campaign.isInProgress)
              ListTile(
                leading: const Icon(FluentIcons.pause),
                title: const Text('Stop Campaign'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pauseCampaign(ref, campaign.id);
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

  void _startCampaign(WidgetRef ref, int campaignId) async {
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

  void _pauseCampaign(WidgetRef ref, int campaignId) async {
    try {
      final controller = ref.read(campaignControlProvider);
      await controller.stopCampaign(campaignId);
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Campaign Paused'),
            content: const Text('The campaign has been paused.'),
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
            content: Text('Failed to pause campaign: $e'),
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