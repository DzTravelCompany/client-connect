import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/template_providers.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final templatesAsync = _selectedFilter == 'all'
        ? ref.watch(allTemplatesProvider)
        : ref.watch(templatesByTypeProvider(_selectedFilter));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Templates'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Add Template'),
              onPressed: () => context.go('/templates/add'),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter tabs
            Row(
              children: [
                _buildFilterTab('all', 'All Templates'),
                const SizedBox(width: 8),
                _buildFilterTab('email', 'Email Templates'),
                const SizedBox(width: 8),
                _buildFilterTab('whatsapp', 'WhatsApp Templates'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Template list
            Expanded(
              child: templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FluentIcons.mail, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'No templates found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Create your first template to get started'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.go('/templates/add'),
                            child: const Text('Add Template'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _buildTemplateCard(template);
                    },
                  );
                },
                loading: () => const Center(child: ProgressRing()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FluentTheme.of(context).accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? FluentTheme.of(context).accentColor : Colors.grey[60],
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(template) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template.isEmail ? FluentIcons.mail : FluentIcons.chat,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () => _showTemplateMenu(template),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (template.subject != null) ...[
              Text(
                'Subject: ${template.subject}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[100],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Expanded(
              child: Text(
                template.body,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[120],
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updated ${_formatDate(template.updatedAt)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[80],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateMenu(template) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.edit),
              title: const Text('Edit Template'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/templates/edit/${template.id}');
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.view),
              title: const Text('Preview Template'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/templates/preview/${template.id}');
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.delete),
              title: const Text('Delete Template'),
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(template.id);
              },
            ),
          ],
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

  void _showDeleteDialog(int templateId) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              final dao = ref.read(templateDaoProvider);
              try {
                await dao.deleteTemplate(templateId);
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Template deleted'),
                      content: const Text('The template has been successfully deleted.'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}