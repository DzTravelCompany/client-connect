import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_model.dart';
import '../../../tags/logic/tag_providers.dart';

class EnhancedClientCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final clientTagsAsync = ref.watch(clientTagsProvider(client.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        backgroundColor: isSelected 
            ? theme.accentColor.withValues(alpha: 0.1)
            : theme.cardColor,
        borderColor: isSelected 
            ? theme.accentColor.withValues(alpha: 0.3)
            : theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        child: GestureDetector(
          onTap: onTap,
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
                      if (showSelection) ...[
                        Checkbox(
                          checked: isSelected,
                          onChanged: (checked) => onSelectionChanged(checked ?? false),
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
                            _getInitials(client.fullName),
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
                              client.fullName,
                              style: theme.typography.bodyStrong?.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            if (client.jobTitle != null && client.company != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${client.jobTitle} at ${client.company}',
                                style: theme.typography.body?.copyWith(
                                  color: theme.resources.textFillColorSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ] else if (client.company != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                client.company!,
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
                          color: _getStatusColor(client),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Contact information
                  Row(
                    children: [
                      if (client.email != null) ...[
                        Expanded(
                          child: _buildContactInfo(
                            FluentIcons.mail,
                            client.email!,
                            theme,
                          ),
                        ),
                      ],
                      if (client.phone != null) ...[
                        if (client.email != null) const SizedBox(width: 16),
                        Expanded(
                          child: _buildContactInfo(
                            FluentIcons.phone,
                            client.phone!,
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
                      Text(
                        'Updated ${_formatRelativeDate(client.updatedAt)}',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorTertiary,
                        ),
                      ),
                      const Spacer(),
                      _buildQuickActions(theme),
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
            children: tags.take(3).map((tag) => Container(
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
            )).toList(),
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

  Widget _buildQuickActions(FluentThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
          onPressed: () {
            // TODO: Quick edit action
          },
          child: Icon(
            FluentIcons.edit,
            size: 16,
            color: theme.resources.textFillColorSecondary,
          ),
        ),
        Button(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
          onPressed: () {
            // TODO: Quick email action
          },
          child: Icon(
            FluentIcons.mail,
            size: 16,
            color: theme.resources.textFillColorSecondary,
          ),
        ),
        Button(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
          onPressed: () {
            // TODO: More actions menu
          },
          child: Icon(
            FluentIcons.more,
            size: 16,
            color: theme.resources.textFillColorSecondary,
          ),
        ),
      ],
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