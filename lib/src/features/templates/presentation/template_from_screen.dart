import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/template_model.dart';
import '../data/template_block_model.dart';
import '../logic/template_providers.dart';
import '../../clients/logic/client_providers.dart';


class TemplateFormScreen extends ConsumerStatefulWidget {
  final int? templateId;
  
  const TemplateFormScreen({
    super.key,
    this.templateId,
  });

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  TemplateType _selectedType = TemplateType.email;
  List<TemplateBlock> _blocks = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      _loadTemplate();
    } else {
      // Initialize with a default text block
      _blocks = [
        TextBlock(
          id: 'default-text',
          text: '',
        ),
      ];
    }
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      final template = await ref.read(templateDaoProvider).getTemplateById(widget.templateId!);
      if (template != null) {
        _nameController.text = template.name;
        _subjectController.text = template.subject ?? '';
        _bodyController.text = template.body;
        _selectedType = template.templateType;
        _blocks = template.blocks.isNotEmpty ? template.blocks : [
          TextBlock(
            id: 'legacy-text',
            text: template.body,
          ),
        ];
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Error'),
            content: Text('Failed to load template: $e'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  TemplateModel _buildTemplateFromForm() {
    // Update the text block with current body content
    final updatedBlocks = _blocks.map((block) {
      if (block is TextBlock && block.id == 'default-text' || block.id == 'legacy-text') {
        return TextBlock(
          id: block.id,
          text: _bodyController.text,
        );
      }
      return block;
    }).toList();

    return TemplateModel(
      id: widget.templateId ?? 0,
      name: _nameController.text.trim(),
      subject: _selectedType == TemplateType.email ? _subjectController.text.trim() : null,
      body: _bodyController.text.trim(), // Keep for backward compatibility
      templateType: _selectedType,
      blocks: updatedBlocks,
      isEmail: _selectedType == TemplateType.email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final template = _buildTemplateFromForm();
      final templateDao = ref.read(templateDaoProvider);

      if (widget.templateId != null) {
        await templateDao.updateTemplate(template);
      } else {
        await templateDao.createTemplate(template);
      }

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Success'),
            content: const Text('Template saved successfully!'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted){
          context.go('/templates');
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Error'),
            content: Text('Failed to save template: $e'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTemplateTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Type',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                RadioButton(
                  checked: _selectedType == TemplateType.email,
                  onChanged: (value) {
                    if (value == true) {
                      setState(() => _selectedType = TemplateType.email);
                      _onFieldChanged();
                    }
                  },
                  content: const Text('Email Template'),
                ),
                const SizedBox(width: 16),
                RadioButton(
                  checked: _selectedType == TemplateType.whatsapp,
                  onChanged: (value) {
                    if (value == true) {
                      setState(() => _selectedType = TemplateType.whatsapp);
                      _onFieldChanged();
                    }
                  },
                  content: const Text('WhatsApp Template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return InfoLabel(
      label: label,
      child: TextFormBox(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) => _onFieldChanged(),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final clients = ref.watch(allClientsProvider);
    
    return clients.when(
      data: (clientList) {
        if (clientList.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Preview',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  const Text('No clients available for preview. Add some clients first.'),
                ],
              ),
            ),
          );
        }

        final sampleClient = clientList.first;
        final currentTemplate = _buildTemplateFromForm();
        final preview = TemplatePreviewService.generatePreview(
          currentTemplate,
          sampleClient,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preview for: ${sampleClient.fullName}',
                  style: FluentTheme.of(context).typography.caption,
                ),
                const SizedBox(height: 8),
                if (_selectedType == TemplateType.email && _subjectController.text.isNotEmpty) ...[
                  Text(
                    'Subject: ${_subjectController.text}',
                    style: FluentTheme.of(context).typography.body?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).resources.cardBackgroundFillColorDefault,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: FluentTheme.of(context).resources.cardStrokeColorDefault,
                    ),
                  ),
                  child: Text(
                    preview.isNotEmpty ? preview : 'Enter template content to see preview...',
                    style: FluentTheme.of(context).typography.body,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ProgressRing(),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading clients: $error'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(widget.templateId != null ? 'Edit Template' : 'Create Template'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: _isLoading ? null : _saveTemplate,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.cancel),
              label: const Text('Cancel'),
              onPressed: () => context.go('/templates'),
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Form
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTemplateTypeSelector(),
                            const SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: _nameController,
                              label: 'Template Name *',
                              placeholder: 'Enter template name',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Template name is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            if (_selectedType == TemplateType.email) ...[
                              _buildFormField(
                                controller: _subjectController,
                                label: 'Email Subject',
                                placeholder: 'Enter email subject',
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            _buildFormField(
                              controller: _bodyController,
                              label: 'Message Body *',
                              placeholder: 'Enter your message here...\n\nUse placeholders like {{first_name}}, {{last_name}}, {{email}}, etc.',
                              maxLines: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Message body is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Placeholders',
                                      style: FluentTheme.of(context).typography.subtitle,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        '{{first_name}}',
                                        '{{last_name}}',
                                        '{{full_name}}',
                                        '{{email}}',
                                        '{{phone}}',
                                        '{{job_title}}',
                                        '{{company}}',
                                      ].map((placeholder) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          placeholder,
                                          style: FluentTheme.of(context).typography.caption?.copyWith(
                                            fontFamily: 'Consolas',
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Right column - Preview
                      Expanded(
                        flex: 1,
                        child: _buildPreviewSection(),
                      ),
                    ],
                  ),
                ),
              ),
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
