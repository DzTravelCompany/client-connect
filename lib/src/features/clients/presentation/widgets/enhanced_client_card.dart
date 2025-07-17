import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/clients/presentation/widgets/quick_edit_client_dialog.dart';
import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_model.dart';
import '../../../tags/logic/tag_providers.dart';
import 'package:go_router/go_router.dart';

// 1. Change to ConsumerStatefulWidget
class EnhancedClientCard extends ConsumerStatefulWidget {
  final ClientModel client;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(bool) onSelectionChanged;
  final bool showSelection;

  const EnhancedClientCard({
    super.key,
    required this.client,
    required this.isSelected,
    required this.onTap,
    required this.onSelectionChanged,
    this.showSelection = false,
  });

  @override
  ConsumerState<EnhancedClientCard> createState() => _EnhancedClientCardState();
}

class _EnhancedClientCardState extends ConsumerState<EnhancedClientCard> {
  // 2. Add FlyoutController
  late final FlyoutController _moreActionsFlyoutController;

  @override
  void initState() {
    super.initState();
    _moreActionsFlyoutController = FlyoutController();
  }

  @override
  void dispose() {
    _moreActionsFlyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. Access widget properties via widget.client, widget.isSelected, etc.
    final theme = FluentTheme.of(context);
    final clientTagsAsync = ref.watch(clientTagsProvider(widget.client.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        backgroundColor: widget.isSelected
            ? theme.accentColor.withValues(alpha: 0.1)
            : theme.cardColor,
        borderColor: widget.isSelected
            ? theme.accentColor.withValues(alpha: 0.3)
            : theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        child: GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with avatar and selection
                  Row(
                    children: [
                      // Selection checkbox
                      if (widget.showSelection) ...[
                        Checkbox(
                          checked: widget.isSelected,
                          onChanged: (checked) =>
                              widget.onSelectionChanged(checked ?? false),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.accentColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(widget.client.fullName),
                            style: TextStyle(
                              color: theme.accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Client info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.client.fullName,
                              style: theme.typography.bodyStrong?.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            // Typo fix: client.client.company -> client.company
                            if (widget.client.jobTitle != null &&
                                widget.client.company != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${widget.client.jobTitle} at ${widget.client.company}',
                                style: theme.typography.body?.copyWith(
                                  color: theme.resources.textFillColorSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ] else if (widget.client.company != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.client.company!,
                                style: theme.typography.body?.copyWith(
                                  color: theme.resources.textFillColorSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.client),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Contact information
                  Row(
                    children: [
                      if (widget.client.email != null) ...[
                        Expanded(
                          child: _buildContactInfo(
                            FluentIcons.mail,
                            widget.client.email!,
                            theme,
                          ),
                        ),
                      ],
                      if (widget.client.phone != null) ...[
                        if (widget.client.email != null)
                          const SizedBox(width: 16),
                        Expanded(
                          child: _buildContactInfo(
                            FluentIcons.phone,
                            widget.client.phone!,
                            theme,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Tags
                  clientTagsAsync.when(
                    data: (tags) => tags.isNotEmpty
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildTagsRow(tags, theme),
                            ],
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  // Footer with last updated and quick actions
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Updated ${_formatRelativeDate(widget.client.updatedAt)}',
                          style: theme.typography.caption?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActions(theme, context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text, FluentThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.resources.textFillColorSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.typography.body?.copyWith(
              fontSize: 13,
              color: theme.resources.textFillColorSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow(List<TagModel> tags, FluentThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .take(3)
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        if (tags.length > 3)
          Text(
            '+${tags.length - 3}',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(FluentThemeData theme, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Button(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            onPressed: () => _showQuickEditDialog(context),
            child: Icon(
              FluentIcons.edit,
              size: 12,
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 24,
          height: 24,
          child: Button(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            onPressed: () => _launchEmail(context),
            child: Icon(
              FluentIcons.mail,
              size: 12,
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        ),
        const SizedBox(width: 2),
        // 3. Wrap the button in a FlyoutTarget
        FlyoutTarget(
          controller: _moreActionsFlyoutController,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Button(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                // 4. Use showFlyout and MenuFlyout
                _moreActionsFlyoutController.showFlyout(
                  builder: (context) {
                    return MenuFlyout(
                      items: [
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.copy, size: 16),
                          text: const Text('Edit Client'),
                          onPressed: () {
                            _moreActionsFlyoutController.close(); // Close the flyout
                            _editClient(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: Icon(FluentIcons.delete,
                              size: 16, color: Colors.red),
                          text: Text('Delete Client',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            _moreActionsFlyoutController.close(); // Close the flyout
                            _confirmDeleteClient(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.download, size: 16),
                          text: const Text('Export Data'),
                          onPressed: () {
                            _moreActionsFlyoutController.close(); // Close the flyout
                            _exportClientData(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.bullseye_target, size: 16),
                          text: const Text('View Campaigns'),
                          onPressed: () {
                            _moreActionsFlyoutController.close(); // Close the flyout
                            _viewClientCampaigns(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(
                FluentIcons.more,
                size: 12,
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QuickEditClientDialog(client: widget.client),
    );
  }

  void _launchEmail(BuildContext context) async {
    if (widget.client.email == null || widget.client.email!.isEmpty) {
      _showErrorMessage(context, 'No email address available for this client');
      return;
    }
    _showInfoMessage(context, 'Export functionality coming soon');
  }

  void _editClient(BuildContext context) {

    context.pushNamed('editClient', pathParameters: {'id': widget.client.id.toString()});
  }

  void _confirmDeleteClient(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Client'), // 7. Added const
        // 6. Use widget.client
        content: Text(
            'Are you sure you want to delete ${widget.client.fullName}? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'), // 7. Added const
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'), // 7. Added const
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClient(context);
            },
          ),
        ],
      ),
    );
  }

  void _deleteClient(BuildContext context) async {
    try {
      final dao = ref.read(clientDaoProvider);
      await dao.deleteClient(widget.client.id);
      if(context.mounted){
        _showSuccessMessage(context, 'Client deleted successfully'); 
      }
    } catch (e) {
      if(context.mounted){
        _showErrorMessage(context, 'Failed to delete client');
      }
    }
  }

  void _exportClientData(BuildContext context) {
    _showInfoMessage(context, 'Export functionality coming soon');
  }

  void _viewClientCampaigns(BuildContext context) {
    // 6. Use widget.client
    context.go('/campaigns', extra: {'clientId': widget.client.id});
  }

  void _showErrorMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Error'), // 7. Added const
        content: Text(message),
        severity: InfoBarSeverity.error,
        action: IconButton(
          icon: const Icon(FluentIcons.clear), // 7. Added const
          onPressed: close,
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Success'), // 7. Added const
        content: Text(message),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear), // 7. Added const
          onPressed: close,
        ),
      ),
    );
  }

  void _showInfoMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Info'), // 7. Added const
        content: Text(message),
        severity: InfoBarSeverity.info,
        action: IconButton(
          icon: const Icon(FluentIcons.clear), // 7. Added const
          onPressed: close,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  Color _getStatusColor(ClientModel client) {
    // Simple status logic - can be enhanced based on business rules
    final daysSinceUpdate = DateTime.now().difference(client.updatedAt).inDays;

    if (daysSinceUpdate <= 7) {
      return Colors.green; // Recently active
    } else if (daysSinceUpdate <= 30) {
      return Colors.orange; // Moderately active
    } else {
      return Colors.grey; // Inactive
    }
  }

  String _formatRelativeDate(DateTime date) {
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