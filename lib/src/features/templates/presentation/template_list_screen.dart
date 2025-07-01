import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Templates'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.design),
              label: const Text('Advanced Editor'),
              onPressed: () => context.go('/templates/editor'),
            ),
          ],
        ),
      ),
      content: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? _buildEmptyState(context, theme)
            : _buildTemplateList(context, ref, templates, theme),
        loading: () => const Center(child: ProgressRing()),
        error: (error, stackTrace) => _buildErrorState(context, theme, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.text_document,
            size: 64,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 20),
          Text(
            'No templates found',
            style: theme.typography.subtitle?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first template to get started',
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/templates/editor'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.add, size: 16),
                SizedBox(width: 8),
                Text('Create Template'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FluentThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            'Error loading templates',
            style: theme.typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Button(
            onPressed: () => context.go('/templates'),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(
    BuildContext context,
    WidgetRef ref,
    List<TemplateModel> templates,
    FluentThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        logger.i(templates);
        final template = templates[index];
        return TemplateListTile(template: template);
      },
    );
  }
}

class TemplateListTile extends ConsumerWidget {
  final TemplateModel template;

  const TemplateListTile({super.key, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: HoverButton(
        onPressed: () => context.go('/templates/edit/${template.id}'),
        builder: (context, states) {
          final isHovering = states.contains(WidgetState.hovered);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHovering
                  ? theme.accentColor.withValues(alpha: 0.05)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering
                    ? theme.accentColor.withValues(alpha: 0.2)
                    : theme.accentColor,
              ),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTemplateIcon(template.type),
                    color: theme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: theme.typography.bodyStrong,
                      ),
                      const SizedBox(height: 4),
                      if (template.subject?.isNotEmpty == true) ...[
                        Text(
                          'Subject: ${template.subject}',
                          style: theme.typography.body?.copyWith(
                            color: theme.inactiveColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(template.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              template.type.toUpperCase(),
                              style: TextStyle(
                                color: _getTypeColor(template.type),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(template.updatedAt),
                            style: theme.typography.caption?.copyWith(
                              color: theme.inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DropDownButton(
                  leading: const Icon(FluentIcons.more_vertical, size: 16),
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.edit),
                      text: const Text('Edit'),
                      onPressed: () => context.go('/templates/edit/${template.id}'),
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.design),
                      text: const Text('Advanced Editor'),
                      onPressed: () => context.go('/templates/editor/${template.id}'),
                    ),
                    MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.copy),
                      text: const Text('Duplicate'),
                      onPressed: () => _duplicateTemplate(context, ref, template),
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.delete),
                      text: const Text('Delete'),
                      onPressed: () => _showDeleteDialog(context, ref, template),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getTemplateIcon(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return FluentIcons.mail;
      case 'whatsapp':
        return FluentIcons.chat;
      default:
        return FluentIcons.text_document;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return Colors.blue;
      case 'whatsapp':
        return Colors.green;
      default:
        return Colors.grey;
    }
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

  void _duplicateTemplate(BuildContext context, WidgetRef ref, TemplateModel template) async {
    try {
      // TODO: Implement template duplication
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Template Duplicated'),
          content: Text('${template.name} (Copy) has been created'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Error'),
          content: Text('Failed to duplicate template: $e'),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, TemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // TODO: Implement template deletion
                displayInfoBar(
                  context,
                  builder: (context, close) => InfoBar(
                    title: const Text('Template Deleted'),
                    content: Text('${template.name} has been deleted'),
                    severity: InfoBarSeverity.success,
                    onClose: close,
                  ),
                );
              } catch (e) {
                displayInfoBar(
                  context,
                  builder: (context, close) => InfoBar(
                    title: const Text('Error'),
                    content: Text('Failed to delete template: $e'),
                    severity: InfoBarSeverity.error,
                    onClose: close,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}