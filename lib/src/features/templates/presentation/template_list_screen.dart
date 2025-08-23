import 'package:client_connect/src/features/templates/data/template_dao.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import '../../../core/design_system/layout_system.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return LayoutSystem.pageContainer(
      includeScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutSystem.pageHeader(
            title: 'Templates',
            subtitle: templatesAsync.when(
              data: (templates) => '${templates.length} templates available',
              loading: () => 'Loading templates...',
              error: (_, __) => 'Error loading templates',
            ),
            leading: Container(
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
            actions: [
              DesignSystemComponents.secondaryButton(
                text: 'Refresh',
                icon: FluentIcons.refresh,
                isLoading: _isRefreshing,
                onPressed: _isRefreshing ? null : _refreshTemplates,
                tooltip: 'Refresh template list',
              ),
            ],
          ),
          
          LayoutSystem.verticalSpace(DesignTokens.space4),
          
          _buildEnhancedToolbar(context),
          
          LayoutSystem.verticalSpace(DesignTokens.space4),
          
          Flexible(
            child: templatesAsync.when(
              data: (templates) => _buildEnhancedContent(context, ref, templates),
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

  Widget _buildEnhancedToolbar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      child: DesignSystemComponents.standardCard(
        padding: EdgeInsets.all(DesignTokens.space4),
        child: LayoutSystem.inlineFormFields(
          children: [
            DesignSystemComponents.textInput(
              controller: _searchController,
              label: null,
              placeholder: 'Search templates by name or subject...',
              prefixIcon: FluentIcons.search,
              suffixIcon: _searchQuery.isNotEmpty ? FluentIcons.clear : null,
              onSuffixIconPressed: _searchQuery.isNotEmpty ? () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              } : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              semanticLabel: 'Search templates',
            ),
            
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Type',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: 12,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space1),
                  ComboBox<String>(
                    value: _selectedFilter,
                    items: const [
                      ComboBoxItem(value: 'all', child: Text('All Types')),
                      ComboBoxItem(value: 'email', child: Text('Email Templates')),
                      ComboBoxItem(value: 'whatsapp', child: Text('WhatsApp Templates')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            
            DesignSystemComponents.primaryButton(
              text: 'New Template',
              icon: FluentIcons.add,
              onPressed: () => context.go('/templates/editor'),
              tooltip: 'Create a new template',
              semanticLabel: 'Create new template',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContent(
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            LayoutSystem.cardGrid(
              cards: filteredTemplates.map((template) => 
                EnhancedTemplateCard(template: template)
              ).toList(),
              spacing: DesignTokens.space4,
              cardAspectRatio: 1.3,
            ),
            LayoutSystem.verticalSpace(DesignTokens.space6),
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

  Widget _buildEmptyState(BuildContext context) {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    final hasFilter = _selectedFilter != 'all';

    return DesignSystemComponents.emptyState(
      title: hasSearchQuery || hasFilter
          ? 'No templates found'
          : 'No templates yet',
      message: hasSearchQuery || hasFilter
          ? 'Try adjusting your search or filter criteria to find templates'
          : 'Create your first template to get started with automated messaging',
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
                _searchController.clear();
              });
            }
          : () => context.pushNamed('editorTemplate'),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return DesignSystemComponents.emptyState(
      title: 'Failed to load templates',
      message: 'There was an error loading your templates. Please try again.',
      icon: FluentIcons.error,
      iconColor: DesignTokens.semanticError,
      actionText: 'Retry',
      onAction: _refreshTemplates,
    );
  }

  Future<void> _refreshTemplates() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      ref.invalidate(templatesProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Templates Refreshed'),
            content: const Text('Template list has been updated successfully'),
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

class EnhancedTemplateCard extends ConsumerWidget {
  final TemplateModel template;

  const EnhancedTemplateCard({super.key, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DesignSystemComponents.standardCard(
      onTap: () => context.pushNamed('editeditorTemplate', pathParameters: {'id': template.id.toString()}),
      isHoverable: true,
      semanticLabel: 'Template: ${template.name}',
      tooltip: 'Tap to edit ${template.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTypeColor(template.type).withValues(alpha: 0.2),
                      _getTypeColor(template.type).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  border: Border.all(
                    color: _getTypeColor(template.type).withValues(alpha: 0.3),
                  ),
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
                    text: const Text('Edit Template'),
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
          
          LayoutSystem.verticalSpace(DesignTokens.space4),
          
          Text(
            template.name,
            style: DesignTextStyles.subtitle.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          LayoutSystem.verticalSpace(DesignTokens.space2),
          
          if (template.subject?.isNotEmpty == true) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space2,
                vertical: DesignTokens.space1,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.neutralGray100.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: Text(
                template.subject!,
                style: DesignTextStyles.caption.copyWith(
                  color: DesignTokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            LayoutSystem.verticalSpace(DesignTokens.space3),
          ] else ...[
            LayoutSystem.verticalSpace(DesignTokens.space4),
          ],
          
          const Spacer(),
          
          Container(
            padding: EdgeInsets.only(top: DesignTokens.space3),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: DesignTokens.borderPrimary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                DesignSystemComponents.statusBadge(
                  text: template.type.toUpperCase(),
                  type: _getSemanticType(template.type),
                  icon: _getTemplateIcon(template.type),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      FluentIcons.clock,
                      size: DesignTokens.iconSizeSmall,
                      color: DesignTokens.textTertiary,
                    ),
                    SizedBox(width: DesignTokens.space1),
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
      final dao = TemplateDao();
      await dao.duplicateTemplate(template.id);
      ref.invalidate(templatesProvider);
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Template Duplicated'),
            content: Text('${template.name} (Copy) has been created successfully'),
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
        content: LayoutSystem.sectionContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${template.name}"?',
                style: DesignTextStyles.body,
              ),
              LayoutSystem.verticalSpace(DesignTokens.space3),
              Container(
                padding: EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: DesignTokens.semanticError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  border: Border.all(
                    color: DesignTokens.semanticError.withValues(alpha: 0.3),
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
                        'This action cannot be undone. The template will be permanently deleted.',
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
        ),
        actions: [
          DesignSystemComponents.secondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          DesignSystemComponents.dangerButton(
            text: 'Delete Template',
            icon: FluentIcons.delete,
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
                      content: Text('${template.name} has been deleted successfully'),
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