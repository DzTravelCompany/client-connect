import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/presentation/layouts/three_column_layout.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import 'widgets/campaign_filter_panel.dart';
import 'widgets/enhanced_campaign_card.dart';
import 'widgets/campaign_details_panel.dart';
import 'widgets/bulk_campaign_actions_panel.dart';

class CampaignDashboardScreen extends ConsumerStatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  ConsumerState<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends ConsumerState<CampaignDashboardScreen> {
  bool _showBulkActions = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final campaignsAsync = ref.watch(allCampaignsProvider);
        final progressAsync = ref.watch(campaignProgressProvider);
        final filterState = ref.watch(campaignFilterStateProvider);
        final detailPanelState = ref.watch(campaignDetailPanelProvider);
        
        return Container(
          color: DesignTokens.surfacePrimary,
          child: Column(
            children: [
              _buildHeader(context, ref),
              Expanded(
                child: ThreeColumnLayout(
                  sidebar: const CampaignFilterPanel(),
                  mainContent: _buildMainContent(context, ref, campaignsAsync, progressAsync, filterState),
                  detailPanel: detailPanelState.isVisible 
                      ? _buildDetailPanel(context, ref, detailPanelState)
                      : _showBulkActions
                          ? campaignsAsync.when(
                              data: (campaigns) => BulkCampaignActionsPanel(
                                campaigns: _filterCampaigns(campaigns, filterState),
                                onClose: () => setState(() => _showBulkActions = false),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            )
                          : null,
                  showDetailPanel: detailPanelState.isVisible || _showBulkActions,
                ),
              ),
            ],
          ),
        );
      }
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
            padding: const EdgeInsets.all(DesignTokens.space2),
            decoration: BoxDecoration(
              color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.2),
              ),
            ),
            child: Icon(
              FluentIcons.send,
              size: DesignTokens.iconSizeLarge,
              color: DesignTokens.semanticInfo,
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign Dashboard',
                  style: DesignTextStyles.titleLarge.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.space1),
                Text(
                  'Manage and monitor your marketing campaigns',
                  style: DesignTextStyles.body.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              DesignSystemComponents.secondaryButton(
                text: _showBulkActions ? 'Hide Bulk Actions' : 'Bulk Actions',
                icon: FluentIcons.multi_select,
                onPressed: () => setState(() => _showBulkActions = !_showBulkActions),
              ),
              SizedBox(width: DesignTokens.space3),
              DesignSystemComponents.secondaryButton(
                text: 'Analytics',
                icon: FluentIcons.analytics_report,
                onPressed: () => context.pushNamed('seeAnalyticsCampaigns'),
              ),
              SizedBox(width: DesignTokens.space3),
              DesignSystemComponents.secondaryButton(
                text: 'Refresh',
                icon: FluentIcons.refresh,
                onPressed: () => ref.invalidate(allCampaignsProvider),
              ),
              SizedBox(width: DesignTokens.space3),
              DesignSystemComponents.primaryButton(
                text: 'New Campaign',
                icon: FluentIcons.add,
                onPressed: () => context.pushNamed('createCampaigns'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue<List<CampaignModel>> campaignsAsync,
    AsyncValue<CampaignProgress> progressAsync,
    CampaignFilterState filterState,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
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
                    crossAxisSpacing: DesignTokens.space4,
                    mainAxisSpacing: DesignTokens.space4,
                  ),
                  itemCount: filteredCampaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = filteredCampaigns[index];
                    return _buildEnhancedCampaignCard(context, ref, campaign);
                  },
                );
              },
              loading: () => DesignSystemComponents.loadingIndicator(
                message: 'Loading campaigns...',
              ),
              error: (error, stack) => DesignSystemComponents.emptyState(
                title: 'Error loading campaigns',
                message: error.toString(),
                icon: FluentIcons.error,
                iconColor: DesignTokens.semanticError,
                actionText: 'Retry',
                onAction: () => ref.invalidate(allCampaignsProvider),
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
          margin: EdgeInsets.only(bottom: DesignTokens.space4),
          child: DesignSystemComponents.standardCard(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FluentIcons.health,
                      size: DesignTokens.iconSizeMedium,
                      color: criticalCampaigns > 0 
                          ? DesignTokens.semanticError
                          : warningCampaigns > 0
                              ? DesignTokens.semanticWarning
                              : DesignTokens.semanticSuccess,
                    ),
                    SizedBox(width: DesignTokens.space2),
                    Text(
                      'Campaign Health Overview',
                      style: DesignTextStyles.subtitle.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${healthIndicators.length} active campaigns',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: DesignTokens.space3),
                
                Row(
                  children: [
                    _buildHealthStat('Healthy', healthyCampaigns, DesignTokens.semanticSuccess),
                    SizedBox(width: DesignTokens.space4),
                    _buildHealthStat('Warning', warningCampaigns, DesignTokens.semanticWarning),
                    SizedBox(width: DesignTokens.space4),
                    _buildHealthStat('Critical', criticalCampaigns, DesignTokens.semanticError),
                    const Spacer(),
                    if (criticalCampaigns > 0 || warningCampaigns > 0)
                      DesignSystemComponents.secondaryButton(
                        text: 'View Details',
                        onPressed: () => _showHealthDetails(healthIndicators),
                      ),
                  ],
                ),
              ],
            ),
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
        DesignSystemComponents.statusDot(
          type: _getSemanticTypeFromColor(color),
          size: 8.0,
        ),
        SizedBox(width: DesignTokens.space1),
        Text(
          '$label: $count',
          style: DesignTextStyles.caption,
        ),
      ],
    );
  }

  SemanticColorType _getSemanticTypeFromColor(Color color) {
    if (color == DesignTokens.semanticSuccess) return SemanticColorType.success;
    if (color == DesignTokens.semanticWarning) return SemanticColorType.warning;
    if (color == DesignTokens.semanticError) return SemanticColorType.error;
    return SemanticColorType.info;
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
              return DesignSystemComponents.standardCard(
                padding: const EdgeInsets.all(DesignTokens.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DesignSystemComponents.statusDot(
                          type: indicator.isCritical 
                              ? SemanticColorType.error
                              : indicator.hasWarnings
                                  ? SemanticColorType.warning
                                  : SemanticColorType.success,
                          size: 12.0,
                        ),
                        SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: Text(
                            indicator.campaignName,
                            style: DesignTextStyles.body.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                        ),
                        Text(
                          '${(indicator.healthScore * 100).toStringAsFixed(0)}%',
                          style: DesignTextStyles.body.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: indicator.isCritical 
                                ? DesignTokens.semanticError
                                : indicator.hasWarnings
                                    ? DesignTokens.semanticWarning
                                    : DesignTokens.semanticSuccess,
                          ),
                        ),
                      ],
                    ),
                    if (indicator.issues.isNotEmpty) ...[
                      SizedBox(height: DesignTokens.space2),
                      ...indicator.issues.map((issue) => Padding(
                        padding: EdgeInsets.only(left: DesignTokens.space5, bottom: DesignTokens.space1),
                        child: Row(
                          children: [
                            Icon(
                              FluentIcons.warning,
                              size: DesignTokens.iconSizeSmall,
                              color: DesignTokens.semanticError,
                            ),
                            SizedBox(width: DesignTokens.space1),
                            Expanded(
                              child: Text(
                                issue,
                                style: DesignTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              );
            },
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
    return DesignSystemComponents.emptyState(
      title: hasFilters ? 'No campaigns match your filters' : 'No campaigns yet',
      message: hasFilters 
          ? 'Try adjusting your search criteria'
          : 'Create your first campaign to get started',
      icon: FluentIcons.send,
      iconColor: DesignTokens.textTertiary,
      actionText: 'Create Campaign',
      onAction: () => context.go('/campaigns/create'),
    );
  }

  Widget _buildProgressIndicator(CampaignProgress progress) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: DesignTokens.space4),
      child: DesignSystemComponents.standardCard(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.send,
                  size: DesignTokens.iconSizeMedium,
                  color: DesignTokens.semanticInfo,
                ),
                SizedBox(width: DesignTokens.space2),
                Text(
                  'Campaign in Progress',
                  style: DesignTextStyles.subtitle,
                ),
                const Spacer(),
                Text(
                  '${progress.processed}/${progress.total}',
                  style: DesignTextStyles.body.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space3),
            
            // Progress bar
            ProgressBar(
              value: progress.progressPercentage * 100,
            ),
            
            SizedBox(height: DesignTokens.space2),
            
            Row(
              children: [
                _buildProgressStat('Successful', progress.successful, DesignTokens.semanticSuccess),
                SizedBox(width: DesignTokens.space4),
                _buildProgressStat('Failed', progress.failed, DesignTokens.semanticError),
                const Spacer(),
                if (progress.currentStatus != null)
                  Text(
                    progress.currentStatus!,
                    style: DesignTextStyles.caption.copyWith(
                      color: DesignTokens.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Row(
      children: [
        DesignSystemComponents.statusDot(
          type: _getSemanticTypeFromColor(color),
          size: 8.0,
        ),
        SizedBox(width: DesignTokens.space1),
        Text(
          '$label: $value',
          style: DesignTextStyles.caption,
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
}