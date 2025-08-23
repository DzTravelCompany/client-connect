import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_logs_dialog.dart';
import 'package:client_connect/src/features/campaigns/presentation/retry_management_dialog.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';

class CampaignDetailsScreen extends ConsumerWidget {
  final int campaignId;
  
  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final messageLogsAsync = ref.watch(campaignMessageLogsProvider(campaignId));
    final progressAsync = ref.watch(campaignProgressProvider);

    return ScaffoldPage(
      header: _buildEnhancedHeader(context, campaignAsync),
      content: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return DesignSystemComponents.emptyState(
              title: 'Campaign not found',
              message: 'The requested campaign could not be found',
              icon: FluentIcons.search,
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(DesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign overview
                _buildCampaignOverview(context, campaign, ref),
                SizedBox(height: DesignTokens.space6),

                // Real-time progress (if in progress)
                if (campaign.isInProgress)
                  progressAsync.when(
                    data: (progress) {
                      if (progress.campaignId == campaignId) {
                        return Column(
                          children: [
                            _buildProgressSection(context, progress),
                            SizedBox(height: DesignTokens.space6),
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
                  data: (logs) => _buildMessageStatistics(context, campaign, logs),
                  loading: () => DesignSystemComponents.loadingIndicator(message: 'Loading statistics...'),
                  error: (error, stack) => DesignSystemComponents.emptyState(
                    title: 'Error loading statistics',
                    message: error.toString(),
                    icon: FluentIcons.error,
                    iconColor: DesignTokens.semanticError,
                  ),
                ),

                SizedBox(height: DesignTokens.space6),

                // Template preview
                _buildTemplatePreview(context, campaign, ref),

                SizedBox(height: DesignTokens.space6),

                // Recipients list
                _buildRecipientsList(context, campaign, ref),
              ],
            ),
          );
        },
        loading: () => DesignSystemComponents.loadingIndicator(message: 'Loading campaign details...'),
        error: (error, stack) => DesignSystemComponents.emptyState(
          title: 'Error loading campaign',
          message: error.toString(),
          icon: FluentIcons.error,
          iconColor: DesignTokens.semanticError,
          actionText: 'Retry',
          onAction: () => ref.invalidate(campaignByIdProvider(campaignId)),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, AsyncValue<CampaignModel?> campaignAsync) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentPrimary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.accentPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          DesignSystemComponents.secondaryButton(
            text: 'Back',
            icon: FluentIcons.back,
            onPressed: () => context.go('/campaigns'),
          ),
          
          SizedBox(width: DesignTokens.space4),
          
          // Campaign info
          Expanded(
            child: campaignAsync.when(
              data: (campaign) => campaign != null ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.space2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.accentPrimary.withValues(alpha: 0.15),
                          DesignTokens.accentPrimary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      border: Border.all(
                        color: DesignTokens.accentPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      FluentIcons.campaign_template,
                      size: DesignTokens.iconSizeMedium,
                      color: DesignTokens.accentPrimary,
                    ),
                  ),
                  SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: DesignTextStyles.titleLarge.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.accentPrimary,
                          ),
                        ),
                        SizedBox(height: DesignTokens.space1),
                        Text(
                          'Campaign Details',
                          style: DesignTextStyles.body.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(campaign.status),
                ],
              ) : const SizedBox.shrink(),
              loading: () => DesignSystemComponents.skeletonLoader(height: 40),
              error: (_, __) => Text(
                'Campaign Details',
                style: DesignTextStyles.titleLarge.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignOverview(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.info,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textSecondary,
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                'Campaign Overview',
                style: DesignTextStyles.subtitle.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(campaign.status),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
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
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: DesignTokens.iconSizeSmall, color: DesignTokens.textTertiary),
            SizedBox(width: DesignTokens.space2),
            Text(
              label,
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textTertiary,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space1),
        Text(
          value,
          style: DesignTextStyles.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, CampaignProgress progress) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.progress_ring_dots,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.accentPrimary,
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                'Sending Progress',
                style: DesignTextStyles.subtitle.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress.progressPercentage * 100).toInt()}%',
                style: DesignTextStyles.bodyLarge.copyWith(
                  color: DesignTokens.accentPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: DesignTokens.neutralGray200,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.progressPercentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accentPrimary,
                      DesignTokens.accentPrimary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.space3),
          
          // Progress stats
          Row(
            children: [
              _buildProgressStat('Processed', progress.processed, DesignTokens.accentPrimary),
              SizedBox(width: DesignTokens.space4),
              _buildProgressStat('Successful', progress.successful, DesignTokens.semanticSuccess),
              SizedBox(width: DesignTokens.space4),
              _buildProgressStat('Failed', progress.failed, DesignTokens.semanticError),
              const Spacer(),
              Text(
                '${progress.processed}/${progress.total}',
                style: DesignTextStyles.bodyLarge,
              ),
            ],
          ),
          
          if (progress.currentStatus != null) ...[
            SizedBox(height: DesignTokens.space2),
            Text(
              progress.currentStatus!,
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
        SizedBox(width: DesignTokens.space1),
        Text(
          '$label: $value',
          style: DesignTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildMessageStatistics(BuildContext context, CampaignModel campaign, List<MessageLogModel> logs) {
    final sent = logs.where((log) => log.isSent).length;
    final failed = logs.where((log) => log.isFailed || log.isFailedMaxRetries).length;
    final pending = logs.where((log) => log.isPending).length;
    final retrying = logs.where((log) => log.isRetrying).length;
    final total = logs.length;
    final withRetries = logs.where((log) => log.retryCount > 0).length;

    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.analytics_logo,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textSecondary,
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                'Message Statistics',
                style: DesignTextStyles.subtitle.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const Spacer(),
              DesignSystemComponents.secondaryButton(
                text: 'View All Messages',
                onPressed: () => _showMessageLogs(context),
              ),
              SizedBox(width: DesignTokens.space2),
              // TODO : manage retry if need for future
              // DesignSystemComponents.secondaryButton(
              //   text: 'Manage Retries',
              //   onPressed: () => _showRetryManagement(context, campaign),
              // ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', total, DesignTokens.accentPrimary),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: _buildStatCard('Sent', sent, DesignTokens.semanticSuccess),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: _buildStatCard('Failed', failed, DesignTokens.semanticError),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: _buildStatCard('Pending', pending, DesignTokens.semanticWarning),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.space3),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Retrying', retrying, DesignTokens.semanticInfo),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: _buildStatCard('With Retries', withRetries, DesignTokens.neutralGray600),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(child: Container()), // Empty space
              SizedBox(width: DesignTokens.space3),
              Expanded(child: Container()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: DesignTextStyles.titleLarge.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
          SizedBox(height: DesignTokens.space1),
          Text(
            label,
            style: DesignTextStyles.caption.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    final templateAsync = ref.watch(templateByIdProvider(campaign.templateId));
    
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.preview,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textSecondary,
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                'Template Preview',
                style: DesignTextStyles.subtitle.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          templateAsync.when(
            data: (template) {
              if (template == null) {
                return DesignSystemComponents.emptyState(
                  title: 'Template not found',
                  message: 'The template used in this campaign could not be found',
                  icon: FluentIcons.search,
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(DesignTokens.space2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: template.isEmail 
                                ? [
                                    DesignTokens.accentPrimary.withValues(alpha: 0.15),
                                    DesignTokens.accentPrimary.withValues(alpha: 0.08),
                                  ]
                                : [
                                    DesignTokens.semanticSuccess.withValues(alpha: 0.15),
                                    DesignTokens.semanticSuccess.withValues(alpha: 0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                        child: Icon(
                          template.isEmail ? FluentIcons.mail : FluentIcons.chat,
                          size: DesignTokens.iconSizeSmall,
                          color: template.isEmail ? DesignTokens.accentPrimary : DesignTokens.semanticSuccess,
                        ),
                      ),
                      SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: Text(
                          template.name,
                          style: DesignTextStyles.bodyLarge,
                        ),
                      ),
                      DesignSystemComponents.statusBadge(
                        text: template.type.toUpperCase(),
                        type: template.isEmail ? SemanticColorType.info : SemanticColorType.success,
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.space2),
                  
                  if (template.subject != null) ...[
                    Text(
                      'Subject: ${template.subject}',
                      style: DesignTextStyles.bodyLarge,
                    ),
                    SizedBox(height: DesignTokens.space2),
                  ],
                  
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(DesignTokens.space3),
                    decoration: BoxDecoration(
                      color: DesignTokens.neutralGray100,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                      border: Border.all(color: DesignTokens.neutralGray200),
                    ),
                    child: Text(
                      template.body,
                      style: DesignTextStyles.body,
                    ),
                  ),
                ],
              );
            },
            loading: () => DesignSystemComponents.skeletonLoader(height: 120),
            error: (error, stack) => DesignSystemComponents.emptyState(
              title: 'Error loading template',
              message: error.toString(),
              icon: FluentIcons.error,
              iconColor: DesignTokens.semanticError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsList(BuildContext context, CampaignModel campaign, WidgetRef ref) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.people,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textSecondary,
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                'Recipients (${campaign.clientIds.length})',
                style: DesignTextStyles.subtitle.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          ...campaign.clientIds.take(5).map((clientId) {
            final clientAsync = ref.watch(clientByIdProvider(clientId));
            return clientAsync.when(
              data: (client) {
                if (client == null) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: DesignTokens.space2),
                  padding: EdgeInsets.all(DesignTokens.space3),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    border: Border.all(color: DesignTokens.neutralGray200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DesignTokens.accentPrimary.withValues(alpha: 0.15),
                              DesignTokens.accentPrimary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                        ),
                        child: Center(
                          child: Text(
                            client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                            style: DesignTextStyles.bodyLarge.copyWith(
                              color: DesignTokens.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: DesignTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: DesignTextStyles.bodyLarge,
                            ),
                            if (client.email != null)
                              Text(
                                client.email!,
                                style: DesignTextStyles.caption.copyWith(
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Container(
                margin: EdgeInsets.only(bottom: DesignTokens.space2),
                child: DesignSystemComponents.skeletonLoader(height: 60),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),
          
          if (campaign.clientIds.length > 5) ...[
            SizedBox(height: DesignTokens.space2),
            Text(
              '... and ${campaign.clientIds.length - 5} more recipients',
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    SemanticColorType type;
    IconData icon;
    
    switch (status) {
      case 'pending':
        type = SemanticColorType.warning;
        icon = FluentIcons.clock;
        break;
      case 'in_progress':
        type = SemanticColorType.info;
        icon = FluentIcons.send;
        break;
      case 'completed':
        type = SemanticColorType.success;
        icon = FluentIcons.completed;
        break;
      case 'failed':
        type = SemanticColorType.error;
        icon = FluentIcons.error;
        break;
      default:
        type = SemanticColorType.info;
        icon = FluentIcons.help;
    }

    return DesignSystemComponents.statusBadge(
      text: status.toUpperCase(),
      type: type,
      icon: icon,
    );
  }

  void _showMessageLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MessageLogsDialog(campaignId: campaignId),
    );
  }

  void _showRetryManagement(BuildContext context, CampaignModel campaign) {
    showDialog(
      context: context,
      builder: (context) => RetryManagementDialog(
        campaignId: campaign.id,
        campaignName: campaign.name,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}