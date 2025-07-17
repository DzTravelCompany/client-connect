import 'package:client_connect/src/features/templates/data/template_dao.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: _buildHeader(context, theme),
      content: Column(
        children: [
          _buildToolbar(context, theme),
          const SizedBox(height: 16),
          Expanded(
            child: templatesAsync.when(
              data: (templates) => _buildContent(context, ref, templates, theme),
              loading: () => _buildLoadingState(theme),
              error: (error, stackTrace) => _buildErrorState(context, theme, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FluentThemeData theme) {
    return PageHeader(
      title: Row(
        children: [
          Icon(
            FluentIcons.text_document,
            size: 24,
            color: theme.accentColor,
          ),
          const SizedBox(width: 12),
          const Text('Templates'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final templatesAsync = ref.watch(templatesProvider);
                return templatesAsync.when(
                  data: (templates) => Text(
                    '${templates.length} templates',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  loading: () => Text(
                    'Loading...',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      commandBar: CommandBar(
        primaryItems: [
          CommandBarButton(
            icon: Icon(
              FluentIcons.refresh,
              color: _isRefreshing ? theme.accentColor : null,
            ),
            label: const Text('Refresh'),
            onPressed: _isRefreshing ? null : _refreshTemplates,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.design),
            label: const Text('Advanced Editor'),
            onPressed: () => context.pushNamed('editorTemplate'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.accentColor),
              ),
              child: TextBox(
                placeholder: 'Search templates...',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    FluentIcons.search,
                    size: 16,
                    color: theme.inactiveColor,
                  ),
                ),
                suffix: _searchQuery.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Icon(
                            FluentIcons.clear,
                            size: 14,
                            color: theme.inactiveColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      )
                    : null,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter Dropdown
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.accentColor),
            ),
            child: ComboBox<String>(
              value: _selectedFilter,
              items: const [
                ComboBoxItem(value: 'all', child: Text('All Types')),
                ComboBoxItem(value: 'email', child: Text('Email')),
                ComboBoxItem(value: 'whatsapp', child: Text('WhatsApp')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // Quick Actions
          Button(
            onPressed: () => context.go('/templates/editor'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FluentIcons.add,
                  size: 16,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 6),
                const Text('New Template'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TemplateModel> templates,
    FluentThemeData theme,
  ) {
    final filteredTemplates = _filterTemplates(templates);

    if (filteredTemplates.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: filteredTemplates.length,
        itemBuilder: (context, index) {
          final template = filteredTemplates[index];
          return TemplateCard(template: template);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FluentThemeData theme) {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    final hasFilter = _selectedFilter != 'all';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                hasSearchQuery || hasFilter
                    ? FluentIcons.search
                    : FluentIcons.text_document,
                size: 48,
                color: theme.accentColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearchQuery || hasFilter
                  ? 'No templates found'
                  : 'No templates yet',
              style: theme.typography.subtitle?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery || hasFilter
                  ? 'Try adjusting your search or filter criteria'
                  : 'Create your first template to get started',
              style: theme.typography.body?.copyWith(
                color: theme.inactiveColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (hasSearchQuery || hasFilter) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Button(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'all';
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => context.pushNamed('editorTemplate'),
                    child: const Text('Create Template'),
                  ),
                ],
              ),
            ] else ...[
              FilledButton(
                onPressed: () => context.pushNamed('editorTemplate'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add, size: 16),
                    SizedBox(width: 8),
                    Text('Create Your First Template'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ProgressRing(),
          const SizedBox(height: 16),
          Text(
            'Loading templates...',
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FluentThemeData theme, Object error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                FluentIcons.error,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load templates',
              style: theme.typography.subtitle?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.typography.body?.copyWith(
                color: theme.inactiveColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onPressed: _refreshTemplates,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.refresh, size: 16),
                      SizedBox(width: 6),
                      Text('Retry'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => context.pushNamed('editorTemplate'),
                  child: const Text('Create New Template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TemplateModel> _filterTemplates(List<TemplateModel> templates) {
    var filtered = templates;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((template) {
        final query = _searchQuery.toLowerCase();
        return template.name.toLowerCase().contains(query) ||
               (template.subject?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((template) {
        return template.type.toLowerCase() == _selectedFilter;
      }).toList();
    }

    return filtered;
  }

  Future<void> _refreshTemplates() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Invalidate the provider to trigger a refresh
      ref.invalidate(templatesProvider);
      
      // Wait a moment for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Templates Refreshed'),
            content: const Text('Template list has been updated'),
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
            title: const Text('Refresh Failed'),
            content: Text('Failed to refresh templates: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}

class TemplateCard extends ConsumerWidget {
  final TemplateModel template;

  const TemplateCard({super.key, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: HoverButton(
        onPressed: () => context.pushNamed('editeditorTemplate', pathParameters: {'id': template.id.toString()}),
        builder: (context, states) {
          final isHovering = states.contains(WidgetState.hovered);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isHovering
                  ? theme.accentColor.withValues(alpha: 0.05)
                  : Colors.transparent,
              border: Border.all(
                color: isHovering
                    ? theme.accentColor.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and menu
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getTypeColor(template.type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getTemplateIcon(template.type),
                          color: _getTypeColor(template.type),
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      DropDownButton(
                        leading: Icon(
                          FluentIcons.more_vertical,
                          size: 16,
                          color: theme.inactiveColor,
                        ),
                        items: [
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.edit),
                            text: const Text('Edit'),
                            onPressed: () => context.pushNamed('editeditorTemplate', pathParameters: {'id': template.id.toString()}),
                          ),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.design),
                            text: const Text('Advanced Editor'),
                            onPressed: () => context.pushNamed('editeditorTemplate', pathParameters: {'id': template.id.toString()}),
                          ),
                          const MenuFlyoutSeparator(),
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
                  const SizedBox(height: 12),
                  
                  // Template name
                  Text(
                    template.name,
                    style: theme.typography.bodyStrong?.copyWith(
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Subject (if available)
                  if (template.subject?.isNotEmpty == true) ...[
                    Text(
                      template.subject!,
                      style: theme.typography.body?.copyWith(
                        color: theme.inactiveColor,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    const SizedBox(height: 14),
                  ],
                  
                  const Spacer(),
                  
                  // Footer with type and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(template.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
                      const Spacer(),
                      Text(
                        _formatDate(template.updatedAt),
                        style: theme.typography.caption?.copyWith(
                          color: theme.inactiveColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
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
      final dao = TemplateDao();
      await dao.duplicateTemplate(template.id);
      ref.invalidate(templatesProvider);
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Template Duplicated'),
            content: Text('${template.name} (Copy) has been created'),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, TemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${template.name}"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final dao = TemplateDao();
                await dao.deleteTemplate(template.id);
                ref.invalidate(templatesProvider);
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Template Deleted'),
                      content: Text('${template.name} has been deleted'),
                      severity: InfoBarSeverity.success,
                      onClose: close,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
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
              }
            },
          ),
        ],
      ),
    );
  }
}
