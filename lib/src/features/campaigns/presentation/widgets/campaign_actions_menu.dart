import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';
import 'campaign_scheduling_dialog.dart';
import 'campaign_duplication_dialog.dart';
import 'campaign_export_dialog.dart';

class CampaignActionsMenu extends ConsumerWidget {
  final CampaignModel campaign;
  final VoidCallback? onClose;

  const CampaignActionsMenu({
    super.key,
    required this.campaign,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(campaignActionsProvider);
    final isLoading = actionsState.isLoading;

    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Actions
          _buildActionSection(
            context,
            ref,
            'Primary Actions',
            _buildPrimaryActions(context, ref, isLoading),
          ),
          
          const Divider(),
          
          // Management Actions
          _buildActionSection(
            context,
            ref,
            'Management',
            _buildManagementActions(context, ref, isLoading),
          ),
          
          const Divider(),
          
          // Advanced Actions
          _buildActionSection(
            context,
            ref,
            'Advanced',
            _buildAdvancedActions(context, ref, isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Widget> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[100],
            ),
          ),
        ),
        ...actions,
      ],
    );
  }

  List<Widget> _buildPrimaryActions(BuildContext context, WidgetRef ref, bool isLoading) {
    final actions = <Widget>[];

    if (campaign.isPending || campaign.isScheduled) {
      actions.add(_buildActionItem(
        context,
        icon: FluentIcons.play,
        label: 'Start Campaign',
        onPressed: isLoading ? null : () => _startCampaign(context, ref),
        color: Colors.green,
      ));
    }

    if (campaign.isInProgress) {
      actions.add(_buildActionItem(
        context,
        icon: FluentIcons.pause,
        label: 'Pause Campaign',
        onPressed: isLoading ? null : () => _pauseCampaign(context, ref),
        color: Colors.orange,
      ));
    }

    if (campaign.isPaused) {
      actions.add(_buildActionItem(
        context,
        icon: FluentIcons.play,
        label: 'Resume Campaign',
        onPressed: isLoading ? null : () => _resumeCampaign(context, ref),
        color: Colors.blue,
      ));
    }

    if (campaign.isInProgress || campaign.isPaused) {
      actions.add(_buildActionItem(
        context,
        icon: FluentIcons.cancel,
        label: 'Cancel Campaign',
        onPressed: isLoading ? null : () => _cancelCampaign(context, ref),
        color: Colors.red,
      ));
    }

    return actions;
  }

  List<Widget> _buildManagementActions(BuildContext context, WidgetRef ref, bool isLoading) {
    return [
      _buildActionItem(
        context,
        icon: FluentIcons.calendar,
        label: campaign.isScheduled ? 'Reschedule' : 'Schedule',
        onPressed: isLoading ? null : () => _scheduleCampaign(context, ref),
      ),
      
      _buildActionItem(
        context,
        icon: FluentIcons.copy,
        label: 'Duplicate',
        onPressed: isLoading ? null : () => _duplicateCampaign(context, ref),
      ),
      
      if (campaign.isCompleted || campaign.isFailed)
        _buildActionItem(
          context,
          icon: FluentIcons.refresh,
          label: 'Retry Failed Messages',
          onPressed: isLoading ? null : () => _retryFailedMessages(context, ref),
        ),
    ];
  }

  List<Widget> _buildAdvancedActions(BuildContext context, WidgetRef ref, bool isLoading) {
    return [
      _buildActionItem(
        context,
        icon: FluentIcons.download,
        label: 'Export Data',
        onPressed: isLoading ? null : () => _exportCampaign(context, ref),
      ),
      
      if (campaign.isCompleted || campaign.isFailed || campaign.isCancelled)
        _buildActionItem(
          context,
          icon: FluentIcons.delete,
          label: 'Delete Campaign',
          onPressed: isLoading ? null : () => _deleteCampaign(context, ref),
          color: Colors.red,
        ),
    ];
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: HoverButton(
        onPressed: onPressed,
        builder: (context, states) {
          final isHovered = states.isHovered;
          final isDisabled = onPressed == null;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHovered && !isDisabled
                  ? (color ?? FluentTheme.of(context).accentColor).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isDisabled
                      ? Colors.grey[100]
                      : color ?? FluentTheme.of(context).typography.body?.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDisabled
                          ? Colors.grey[100]
                          : color ?? FluentTheme.of(context).typography.body?.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Action handlers
  void _startCampaign(BuildContext context, WidgetRef ref) {
    ref.read(campaignActionsProvider.notifier).startCampaign(campaign.id);
    onClose?.call();
  }

  void _pauseCampaign(BuildContext context, WidgetRef ref) {
    ref.read(campaignActionsProvider.notifier).pauseCampaign(campaign.id);
    onClose?.call();
  }

  void _resumeCampaign(BuildContext context, WidgetRef ref) {
    ref.read(campaignActionsProvider.notifier).resumeCampaign(campaign.id);
    onClose?.call();
  }

  void _cancelCampaign(BuildContext context, WidgetRef ref) {
    _showConfirmationDialog(
      context,
      title: 'Cancel Campaign',
      message: 'Are you sure you want to cancel this campaign? This action cannot be undone.',
      confirmText: 'Cancel Campaign',
      onConfirm: () {
        ref.read(campaignActionsProvider.notifier).cancelCampaign(campaign.id);
        onClose?.call();
      },
    );
  }

  void _deleteCampaign(BuildContext context, WidgetRef ref) {
    _showConfirmationDialog(
      context,
      title: 'Delete Campaign',
      message: 'Are you sure you want to delete this campaign? This action cannot be undone.',
      confirmText: 'Delete',
      onConfirm: () {
        ref.read(campaignActionsProvider.notifier).deleteCampaign(campaign.id);
        onClose?.call();
      },
    );
  }

  void _scheduleCampaign(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CampaignSchedulingDialog(campaign: campaign),
    );
    onClose?.call();
  }

  void _duplicateCampaign(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CampaignDuplicationDialog(campaign: campaign),
    );
    onClose?.call();
  }

  void _retryFailedMessages(BuildContext context, WidgetRef ref) {
    ref.read(campaignActionsProvider.notifier).retryFailedMessages(campaign.id);
    onClose?.call();
  }

  void _exportCampaign(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CampaignExportDialog(campaign: campaign),
    );
    onClose?.call();
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(confirmText),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}