import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
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
                        _buildHeader(),
                        const SizedBox(height: 12),
                        
                        // Campaign details
                        _buildDetails(),
                        const SizedBox(height: 12),
                        
                        // Progress indicator (for active campaigns) - only show if there's space
                        if (widget.campaign.isInProgress || widget.campaign.isCompleted) ...[
                          CampaignProgressIndicator(
                            campaign: widget.campaign,
                            showStats: true,
                            height: 6,
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Action buttons (visible on hover) - remove Spacer and use Expanded Column
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: _buildActionButtons(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.campaign.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Created ${_formatDate(widget.campaign.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        CampaignStatusBadge(
          campaign: widget.campaign,
          size: CampaignStatusBadgeSize.small,
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            FluentIcons.people,
            'Recipients',
            '${widget.campaign.clientIds.length}',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            FluentIcons.calendar,
            'Scheduled',
            widget.campaign.scheduledAt != null 
                ? _formatDate(widget.campaign.scheduledAt!)
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

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary action row
        Row(
          children: [
            if (widget.onStart != null)
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
                        const Text('Start', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.onPause != null)
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
            if (widget.onStart != null || widget.onPause != null)
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
            onPressed: () => _showActionsMenu(ref.context),
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

  void _showActionsMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('${widget.campaign.name} - Actions'),
        content: CampaignActionsMenu(
          campaign: widget.campaign,
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