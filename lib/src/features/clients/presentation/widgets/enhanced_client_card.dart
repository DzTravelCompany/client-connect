import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/clients/presentation/widgets/quick_edit_client_dialog.dart';
import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_model.dart';
import '../../../tags/logic/tag_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

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
    final clientTagsAsync = ref.watch(clientTagsProvider(widget.client.id));

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.space3),
      child: DesignSystemComponents.standardCard(
        onTap: widget.onTap,
        isSelected: widget.isSelected,
        isHoverable: true,
        padding: EdgeInsets.all(DesignTokens.space4),
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
                  SizedBox(width: DesignTokens.space3),
                ],
                // Avatar with design system styling
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.accentPrimary.withValues(alpha: 0.15),
                        DesignTokens.accentPrimary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                    border: Border.all(
                      color: DesignTokens.accentPrimary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(widget.client.fullName),
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.accentPrimary,
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.space3),
                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.fullName,
                        style: DesignTextStyles.subtitle.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      if (widget.client.jobTitle != null &&
                          widget.client.company != null) ...[
                        SizedBox(height: DesignTokens.space1),
                        Text(
                          '${widget.client.jobTitle} at ${widget.client.company}',
                          style: DesignTextStyles.body.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ] else if (widget.client.company != null) ...[
                        SizedBox(height: DesignTokens.space1),
                        Text(
                          widget.client.company!,
                          style: DesignTextStyles.body.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status indicator
                DesignSystemComponents.statusDot(
                  type: _getStatusType(widget.client),
                  size: 8,
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space3),
            
            // Contact information
            Row(
              children: [
                if (widget.client.email != null) ...[
                  Expanded(
                    child: _buildContactInfo(
                      FluentIcons.mail,
                      widget.client.email!,
                    ),
                  ),
                ],
                if (widget.client.phone != null) ...[
                  if (widget.client.email != null)
                    SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: _buildContactInfo(
                      FluentIcons.phone,
                      widget.client.phone!,
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
                        SizedBox(height: DesignTokens.space3),
                        _buildTagsRow(tags),
                      ],
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            SizedBox(height: DesignTokens.space3),
            
            // Footer with last updated and quick actions
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Updated ${_formatRelativeDate(widget.client.updatedAt)}',
                    style: DesignTextStyles.caption.copyWith(
                      color: DesignTokens.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: DesignTokens.space2),
                _buildQuickActions(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.space1),
          decoration: BoxDecoration(
            color: DesignTokens.withOpacity(DesignTokens.textSecondary, 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSizeSmall,
            color: DesignTokens.textSecondary,
          ),
        ),
        SizedBox(width: DesignTokens.space2),
        Expanded(
          child: Text(
            text,
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow(List<TagModel> tags) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: DesignTokens.space1,
            runSpacing: DesignTokens.space1,
            children: tags
                .take(3)
                .map((tag) => DesignSystemComponents.statusBadge(
                      text: tag.name,
                      type: SemanticColorType.info,
                    ))
                .toList(),
          ),
        ),
        if (tags.length > 3)
          Text(
            '+${tags.length - 3}',
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            icon: Icon(
              FluentIcons.edit,
              size: 12,
              color: DesignTokens.textSecondary,
            ),
            onPressed: () => _showQuickEditDialog(context),
          ),
        ),
        SizedBox(width: DesignTokens.space1),
        SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            icon: Icon(
              FluentIcons.mail,
              size: 12,
              color: DesignTokens.textSecondary,
            ),
            onPressed: () => _launchEmail(context),
          ),
        ),
        SizedBox(width: DesignTokens.space1),
        FlyoutTarget(
          controller: _moreActionsFlyoutController,
          child: SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: Icon(
                FluentIcons.more,
                size: 12,
                color: DesignTokens.textSecondary,
              ),
              onPressed: () {
                _moreActionsFlyoutController.showFlyout(
                  builder: (context) {
                    return MenuFlyout(
                      items: [
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.edit, size: 16),
                          text: const Text('Edit Client'),
                          onPressed: () {
                            _moreActionsFlyoutController.close();
                            _editClient(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: Icon(FluentIcons.delete,
                              size: 16, color: DesignTokens.semanticError),
                          text: Text('Delete Client',
                              style: TextStyle(color: DesignTokens.semanticError)),
                          onPressed: () {
                            _moreActionsFlyoutController.close();
                            _confirmDeleteClient(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.download, size: 16),
                          text: const Text('Export Data'),
                          onPressed: () {
                            _moreActionsFlyoutController.close();
                            _exportClientData(context);
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.bullseye_target, size: 16),
                          text: const Text('View Campaigns'),
                          onPressed: () {
                            _moreActionsFlyoutController.close();
                            _viewClientCampaigns(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
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
        title: const Text('Delete Client'),
        content: Text(
            'Are you sure you want to delete ${widget.client.fullName}? This action cannot be undone.'),
        actions: [
          DesignSystemComponents.secondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          DesignSystemComponents.dangerButton(
            text: 'Delete',
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
    context.go('/campaigns', extra: {'clientId': widget.client.id});
  }

  void _showErrorMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Error'),
        content: Text(message),
        severity: InfoBarSeverity.error,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Success'),
        content: Text(message),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  void _showInfoMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Info'),
        content: Text(message),
        severity: InfoBarSeverity.info,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
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

  SemanticColorType _getStatusType(ClientModel client) {
    final daysSinceUpdate = DateTime.now().difference(client.updatedAt).inDays;

    if (daysSinceUpdate <= 7) {
      return SemanticColorType.success; // Recently active
    } else if (daysSinceUpdate <= 30) {
      return SemanticColorType.warning; // Moderately active
    } else {
      return SemanticColorType.info; // Inactive
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
