import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show CheckboxListTile, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/campaign_providers.dart';
import '../../data/campaigns_model.dart';

class BulkCampaignActionsPanel extends ConsumerWidget {
  final List<CampaignModel> campaigns;
  final VoidCallback? onClose;

  const BulkCampaignActionsPanel({
    super.key,
    required this.campaigns,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulkOperationsState = ref.watch(bulkCampaignOperationsProvider);
    final selectedIds = bulkOperationsState.selectedCampaignIds;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        border: Border.all(color: Colors.grey[200]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.multi_select,
                  size: 20,
                  color: FluentTheme.of(context).accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                      Text(
                        '${selectedIds.length} campaigns selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.chrome_close, size: 16),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Campaign selection
          Expanded(
            child: Column(
              children: [
                // Selection controls
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Campaigns',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Button(
                              onPressed: () => _selectAll(ref),
                              child: const Text('Select All'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Button(
                              onPressed: () => _clearSelection(ref),
                              child: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Campaign list
                Expanded(
                  child: ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      final isSelected = selectedIds.contains(campaign.id);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Material(
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) => _toggleSelection(ref, campaign.id),
                            title: Text(
                              campaign.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              campaign.statusDisplayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: campaign.statusColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (selectedIds.isNotEmpty) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulk Actions',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  _buildActionButton(
                    context,
                    ref,
                    icon: FluentIcons.play,
                    label: 'Start Selected',
                    onPressed: _canPerformAction(ref, 'start') 
                        ? () => _performBulkAction(ref, 'start')
                        : null,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildActionButton(
                    context,
                    ref,
                    icon: FluentIcons.pause,
                    label: 'Pause Selected',
                    onPressed: _canPerformAction(ref, 'pause') 
                        ? () => _performBulkAction(ref, 'pause')
                        : null,
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildActionButton(
                    context,
                    ref,
                    icon: FluentIcons.cancel,
                    label: 'Cancel Selected',
                    onPressed: _canPerformAction(ref, 'cancel') 
                        ? () => _performBulkAction(ref, 'cancel')
                        : null,
                    color: Colors.red,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildActionButton(
                    context,
                    ref,
                    icon: FluentIcons.delete,
                    label: 'Delete Selected',
                    onPressed: _canPerformAction(ref, 'delete') 
                        ? () => _performBulkAction(ref, 'delete')
                        : null,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],

          // Progress indicator
          if (bulkOperationsState.isLoading) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ProgressRing(),
                  const SizedBox(height: 8),
                  Text(
                    'Processing bulk operation...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                  if (bulkOperationsState.operationProgress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Progress: ${bulkOperationsState.operationProgress.values.first}/${selectedIds.length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final bulkOperationsState = ref.watch(bulkCampaignOperationsProvider);
    
    return SizedBox(
      width: double.infinity,
      child: Button(
        onPressed: bulkOperationsState.isLoading ? null : onPressed,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAll(WidgetRef ref) {
    final campaignIds = campaigns.map((c) => c.id).toList();
    ref.read(bulkCampaignOperationsProvider.notifier).selectAllCampaigns(campaignIds);
  }

  void _clearSelection(WidgetRef ref) {
    ref.read(bulkCampaignOperationsProvider.notifier).clearSelection();
  }

  void _toggleSelection(WidgetRef ref, int campaignId) {
    ref.read(bulkCampaignOperationsProvider.notifier).toggleCampaignSelection(campaignId);
  }

  bool _canPerformAction(WidgetRef ref, String action) {
    final bulkOperationsState = ref.read(bulkCampaignOperationsProvider);
    final selectedCampaigns = campaigns.where(
      (c) => bulkOperationsState.selectedCampaignIds.contains(c.id),
    ).toList();

    switch (action) {
      case 'start':
        return selectedCampaigns.any((c) => c.isPending || c.isScheduled);
      case 'pause':
        return selectedCampaigns.any((c) => c.isInProgress);
      case 'cancel':
        return selectedCampaigns.any((c) => c.isInProgress || c.isPaused);
      case 'delete':
        return selectedCampaigns.any((c) => c.isCompleted || c.isFailed || c.isCancelled);
      default:
        return false;
    }
  }

  void _performBulkAction(WidgetRef ref, String action) {
    final notifier = ref.read(bulkCampaignOperationsProvider.notifier);
    
    switch (action) {
      case 'start':
        notifier.bulkStart();
        break;
      case 'pause':
        notifier.bulkPause();
        break;
      case 'cancel':
        notifier.bulkCancel();
        break;
      case 'delete':
        _showDeleteConfirmation(ref, notifier);
        break;
    }
  }

  void _showDeleteConfirmation(WidgetRef ref, BulkCampaignOperationsNotifier notifier) {
    final selectedCount = ref.read(bulkCampaignOperationsProvider).selectedCampaignIds.length;
    
    showDialog(
      context: ref.context,
      builder: (context) => ContentDialog(
        title: const Text('Confirm Bulk Delete'),
        content: Text(
          'Are you sure you want to delete $selectedCount campaigns? This action cannot be undone.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              notifier.bulkDelete();
            },
          ),
        ],
      ),
    );
  }
}