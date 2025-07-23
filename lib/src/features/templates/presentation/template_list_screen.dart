import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isRefreshing = false;
  Key _templateListKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    // Listen to template operations to refresh list
    ref.listen<AsyncValue<void>>(templateOperationsProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          setState(() {
            _templateListKey = UniqueKey(); // Force rebuild after operations
          });
        },
      );
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.surfacePrimary,
            DesignTokens.surfacePrimary.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          SizedBox(height: DesignTokens.space4),
          _buildToolbar(context),
          SizedBox(height: DesignTokens.space4),
          Expanded(
            child: templatesAsync.when(
              data: (templates) => _buildContent(context, ref, templates),
              loading: () => DesignSystemComponents.loadingIndicator(
                message: 'Loading templates...',
              ),
              error: (error, stackTrace) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.surfaceSecondary,
            DesignTokens.surfaceSecondary.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.accentPrimary.withValues(alpha: 0.15),
                  DesignTokens.accentPrimary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: DesignTokens.accentPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              FluentIcons.text_document,
              size: DesignTokens.iconSizeLarge,
              color: DesignTokens.accentPrimary,
            ),
          ),
          SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Templates',
                  style: DesignTextStyles.titleLarge.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                SizedBox(height: DesignTokens.space1),
                Consumer(
                  builder: (context, ref, child) {
                    final templatesAsync = ref.watch(templatesProvider);
                    return templatesAsync.when(
                      data: (templates) => Text(
                        '${templates.length} templates available',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                      loading: () => Text(
                        'Loading templates...',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Error loading templates',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.semanticError,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              DesignSystemComponents.secondaryButton(
                text: 'Refresh',
                icon: FluentIcons.refresh,
                isLoading: _isRefreshing,
                onPressed: _isRefreshing ? null : _refreshTemplates,
              ),
              SizedBox(width: DesignTokens.space3),
              DesignSystemComponents.primaryButton(
                text: 'Advanced Editor',
                icon: FluentIcons.design,
                onPressed: () => context.pushNamed('editorTemplate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      child: DesignSystemComponents.standardCard(
        padding: EdgeInsets.all(DesignTokens.space4),
        child: Row(
          children: [
            // Search Box
            Expanded(
              flex: 2,
              child: DesignSystemComponents.textInput(
                controller: TextEditingController(text: _searchQuery),
                placeholder: 'Search templates...',
                prefixIcon: FluentIcons.search,
                suffixIcon: _searchQuery.isNotEmpty ? FluentIcons.clear : null,
                onSuffixIconPressed: _searchQuery.isNotEmpty ? () {
                  setState(() {
                    _searchQuery = '';
                  });
                } : null,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(width: DesignTokens.space4),
            // Filter Dropdown
            SizedBox(
              width: 140,
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
            SizedBox(width: DesignTokens.space4),
            // Quick Actions
            DesignSystemComponents.primaryButton(
              text: 'New Template',
              icon: FluentIcons.add,
              onPressed: () => context.go('/templates/editor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TemplateModel> templates,
  ) {
    final filteredTemplates = _filterTemplates(templates);

    if (filteredTemplates.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      child: GridView.builder(
        key: _templateListKey,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: DesignTokens.space4,
          mainAxisSpacing: DesignTokens.space4,
          childAspectRatio: 1.2,
        ),
        itemCount: filteredTemplates.length,
        itemBuilder: (context, index) {
          final template = filteredTemplates[index];
          return TemplateCard(
            key: ValueKey(template.id), // Add key for individual cards
            template: template,
            onTemplateChanged: () {
              // Callback to refresh list when template is modified
              setState(() {
                _templateListKey = UniqueKey();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    final hasFilter = _selectedFilter != 'all';

    return DesignSystemComponents.emptyState(
      title: hasSearchQuery || hasFilter
          ? 'No templates found'
          : 'No templates yet',
      message: hasSearchQuery || hasFilter
          ? 'Try adjusting your search or filter criteria'
          : 'Create your first template to get started',
      icon: hasSearchQuery || hasFilter
          ? FluentIcons.search
          : FluentIcons.text_document,
      iconColor: DesignTokens.accentPrimary,
      actionText: hasSearchQuery || hasFilter ? 'Clear Filters' : 'Create Your First Template',
      onAction: hasSearchQuery || hasFilter
          ? () {
              setState(() {
                _searchQuery = '';
                _selectedFilter = 'all';
              });
            }
          : () => context.pushNamed('editorTemplate'),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return DesignSystemComponents.emptyState(
      title: 'Failed to load templates',
      message: error.toString(),
      icon: FluentIcons.error,
      iconColor: DesignTokens.semanticError,
      actionText: 'Retry',
      onAction: _refreshTemplates,
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
      ref.invalidate(templatesProvider);
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _templateListKey = UniqueKey(); // Force rebuild after refresh
      });
      
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
  final VoidCallback? onTemplateChanged;

  const TemplateCard({super.key, required this.template, this.onTemplateChanged,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DesignSystemComponents.standardCard(
      onTap: () => context.pushNamed('editeditorTemplate', pathParameters: {'id': template.id.toString()}),
      isHoverable: true,
      padding: EdgeInsets.all(DesignTokens.space4),
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
                  gradient: LinearGradient(
                    colors: [
                      _getTypeColor(template.type).withValues(alpha: 0.15),
                      _getTypeColor(template.type).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  _getTemplateIcon(template.type),
                  color: _getTypeColor(template.type),
                  size: DesignTokens.iconSizeMedium,
                ),
              ),
              const Spacer(),
              DropDownButton(
                leading: Icon(
                  FluentIcons.more_vertical,
                  size: DesignTokens.iconSizeSmall,
                  color: DesignTokens.textSecondary,
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
                    leading: Icon(FluentIcons.delete, color: DesignTokens.semanticError),
                    text: Text('Delete', style: TextStyle(color: DesignTokens.semanticError)),
                    onPressed: () => _showDeleteDialog(context, ref, template),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space3),
          
          // Template name
          Text(
            template.name,
            style: DesignTextStyles.subtitle.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DesignTokens.space1),
          
          // Subject (if available)
          if (template.subject?.isNotEmpty == true) ...[
            Text(
              template.subject!,
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: DesignTokens.space2),
          ] else ...[
            SizedBox(height: DesignTokens.space3),
          ],
          
          const Spacer(),
          
          // Footer with type and date
          Row(
            children: [
              DesignSystemComponents.statusBadge(
                text: template.type.toUpperCase(),
                type: _getSemanticType(template.type),
              ),
              const Spacer(),
              Text(
                _formatDate(template.updatedAt),
                style: DesignTextStyles.caption.copyWith(
                  color: DesignTokens.textTertiary,
                ),
              ),
            ],
          ),
        ],
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
        return DesignTokens.semanticInfo;
      case 'whatsapp':
        return DesignTokens.semanticSuccess;
      default:
        return DesignTokens.textSecondary;
    }
  }

  SemanticColorType _getSemanticType(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return SemanticColorType.info;
      case 'whatsapp':
        return SemanticColorType.success;
      default:
        return SemanticColorType.info;
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
      await ref.read(templateOperationsProvider.notifier).duplicateTemplate(template.id);
      onTemplateChanged?.call();
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
            SizedBox(height: DesignTokens.space2),
            Container(
              padding: EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: DesignTokens.withOpacity(DesignTokens.semanticError, 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(
                  color: DesignTokens.withOpacity(DesignTokens.semanticError, 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.warning,
                    color: DesignTokens.semanticError,
                    size: DesignTokens.iconSizeSmall,
                  ),
                  SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.semanticError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          DesignSystemComponents.secondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          DesignSystemComponents.dangerButton(
            text: 'Delete',
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(templateOperationsProvider.notifier).deleteTemplate(template.id);
                onTemplateChanged?.call();
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