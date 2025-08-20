import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';
import 'campaign_status_badge.dart';
import 'campaign_progress_indicator.dart';
import 'campaign_actions_menu.dart';

class EnhancedCampaignCard extends ConsumerStatefulWidget {
  final CampaignModel campaign;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onViewDetails;

  const EnhancedCampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.onStart,
    this.onPause,
    this.onViewDetails,
  });

  @override
  ConsumerState<EnhancedCampaignCard> createState() => _EnhancedCampaignCardState();
}

class _EnhancedCampaignCardState extends ConsumerState<EnhancedCampaignCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final campaignStatusAsync = ref.watch(campaignStatusStreamProvider(widget.campaign.id));
    final currentCampaign = campaignStatusAsync.valueOrNull ?? widget.campaign;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Card(
                backgroundColor: _isHovered 
                    ? theme.cardColor.withValues(alpha: 0.8)
                    : theme.cardColor,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: _isHovered
                        ? Border.all(color: theme.accentColor.withValues(alpha: 0.5))
                        : null,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and status
                        _buildHeader(currentCampaign),
                        const SizedBox(height: 12),
                        
                        // Campaign details
                        _buildDetails(currentCampaign),
                        const SizedBox(height: 12),
                        
                        if (currentCampaign.isInProgress || currentCampaign.isCompleted) ...[
                          _buildRealTimeProgressIndicator(currentCampaign),
                          const SizedBox(height: 12),
                        ],
                        
                        // Action buttons (visible on hover)
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: _buildActionButtons(currentCampaign),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CampaignModel campaign) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        CampaignStatusBadge(
          campaign: campaign,
          size: CampaignStatusBadgeSize.small,
        ),
      ],
    );
  }

  Widget _buildDetails(CampaignModel campaign) {
    return Row(
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
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[100]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeProgressIndicator(CampaignModel campaign) {
    final campaignMetricsAsync = ref.watch(campaignMetricsProvider(campaign.id));
    
    return campaignMetricsAsync.when(
      data: (metrics) {
        final statistics = metrics.statistics;
        final progress = statistics.totalMessages > 0 
            ? statistics.sentMessages / statistics.totalMessages 
            : 0.0;
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: campaign.isCompleted 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: campaign.isCompleted 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    campaign.isCompleted ? FluentIcons.completed : FluentIcons.send,
                    size: 12,
                    color: campaign.isCompleted ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      campaign.isCompleted ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: campaign.isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  Text(
                    '${statistics.sentMessages}/${statistics.totalMessages}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    campaign.isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildProgressStat('Success', statistics.sentMessages, Colors.green),
                  const SizedBox(width: 8),
                  _buildProgressStat('Failed', statistics.failedMessages, Colors.red),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => CampaignProgressIndicator(
        campaign: campaign,
        showStats: true,
        height: 6,
      ),
      error: (_, __) => CampaignProgressIndicator(
        campaign: campaign,
        showStats: true,
        height: 6,
      ),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CampaignModel campaign) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary action row
        Row(
          children: [
            if (widget.onStart != null && (campaign.isPending || campaign.isPaused))
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: Button(
                    onPressed: widget.onStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.play, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          campaign.isPaused ? 'Resume' : 'Start',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.onPause != null && campaign.isInProgress)
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: Button(
                    onPressed: widget.onPause,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.pause, size: 12),
                        const SizedBox(width: 4),
                        const Text('Pause', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            if ((widget.onStart != null && (campaign.isPending || campaign.isPaused)) || 
                (widget.onPause != null && campaign.isInProgress))
              const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 28,
                child: Button(
                  onPressed: widget.onViewDetails,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.view, size: 12),
                      const SizedBox(width: 4),
                      const Text('Details', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Secondary action row
        SizedBox(
          width: double.infinity,
          height: 28,
          child: Button(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
            ),
            onPressed: () => _showActionsMenu(context, campaign),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.more, size: 14),
                const SizedBox(width: 4),
                const Text('More Actions', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showActionsMenu(BuildContext context, CampaignModel campaign) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('${campaign.name} - Actions'),
        content: CampaignActionsMenu(
          campaign: campaign,
          onClose: () => Navigator.of(context).pop(),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}