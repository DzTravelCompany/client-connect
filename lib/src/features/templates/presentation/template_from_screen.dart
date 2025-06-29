import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/template_model.dart';
import '../logic/template_providers.dart';
import '../../clients/logic/client_providers.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  final int? templateId;
  
  const TemplateFormScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  Timer? _autosaveTimer;
  bool _isInitialized = false;
  bool _hasUnsavedChanges = false;
  String _selectedType = 'email';
  TemplateModel? _originalTemplate;

  @override
  void initState() {
    super.initState();
    _setupFormListeners();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _setupFormListeners() {
    final controllers = [_nameController, _subjectController, _bodyController];
    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_isInitialized) return;
    
    setState(() {
      _hasUnsavedChanges = true;
    });
    
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _hasUnsavedChanges) {
        _performAutosave();
      }
    });
  }

  Future<void> _performAutosave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final template = _buildTemplateFromForm();
    await ref.read(templateFormProvider.notifier).saveTemplate(template);
    
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  TemplateModel _buildTemplateFromForm() {
    return TemplateModel(
      id: widget.templateId ?? 0,
      name: _nameController.text.trim(),
      type: _selectedType,
      subject: _selectedType == 'email' ? _subjectController.text.trim() : null,
      body: _bodyController.text.trim(),
      createdAt: _originalTemplate?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _populateForm(TemplateModel template) {
    _nameController.text = template.name;
    _subjectController.text = template.subject ?? '';
    _bodyController.text = template.body;
    _selectedType = template.type;
    _originalTemplate = template;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(templateFormProvider);
    final isEditing = widget.templateId != null;
    final clientsAsync = ref.watch(allClientsProvider);

    // Load existing template data if editing
    if (isEditing && !_isInitialized) {
      ref.watch(templateByIdProvider(widget.templateId!)).whenData((template) {
        if (template != null && !_isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateForm(template);
          });
        }
      });
    } else if (!isEditing && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    }

    return ScaffoldPage(
      header: PageHeader(
        title: Text(isEditing ? 'Edit Template' : 'Add Template'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: formState.isLoading ? null : _saveTemplate,
            ),
          ],
        ),
      ),
      content: Row(
        children: [
          // Form Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status indicator
                  if (formState.isLoading || _hasUnsavedChanges || formState.isSaved)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(formState),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (formState.isLoading) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: ProgressRing(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            const Text('Saving...', style: TextStyle(color: Colors.white)),
                          ] else if (_hasUnsavedChanges) ...[
                            const Icon(FluentIcons.edit, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text('Unsaved changes', style: TextStyle(color: Colors.white)),
                          ] else if (formState.isSaved) ...[
                            const Icon(FluentIcons.check_mark, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text('Saved', style: TextStyle(color: Colors.white)),
                          ],
                        ],
                      ),
                    ),

                  // Error message
                  if (formState.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.error, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Save failed: ${formState.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Template Type Selection
                            Text('Template Type', style: FluentTheme.of(context).typography.body),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioButton(
                                    checked: _selectedType == 'email',
                                    onChanged: (value) {
                                      if (value == true) {
                                        setState(() {
                                          _selectedType = 'email';
                                        });
                                        _onFormChanged();
                                      }
                                    },
                                    content: const Text('Email Template'),
                                  ),
                                ),
                                Expanded(
                                  child: RadioButton(
                                    checked: _selectedType == 'whatsapp',
                                    onChanged: (value) {
                                      if (value == true) {
                                        setState(() {
                                          _selectedType = 'whatsapp';
                                        });
                                        _onFormChanged();
                                      }
                                    },
                                    content: const Text('WhatsApp Template'),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Template Name
                            _buildTextFormField(
                              controller: _nameController,
                              label: 'Template Name *',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Template name is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email Subject (only for email templates)
                            if (_selectedType == 'email') ...[
                              _buildTextFormField(
                                controller: _subjectController,
                                label: 'Email Subject',
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Template Body
                            _buildTextFormField(
                              controller: _bodyController,
                              label: 'Message Body *',
                              maxLines: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Message body is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Available Placeholders
                            _buildPlaceholdersSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Preview Section
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[60]),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: clientsAsync.when(
                        data: (clients) {
                          if (clients.isEmpty) {
                            return const Center(
                              child: Text('Add a client to see preview'),
                            );
                          }
                          
                          final sampleClient = clients.first;
                          final currentTemplate = _buildTemplateFromForm();
                          final preview = TemplatePreviewService.generatePreview(
                            currentTemplate,
                            sampleClient,
                          );
                          
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[10],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[40]),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview for: ${sampleClient.fullName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_selectedType == 'email' && _subjectController.text.isNotEmpty) ...[
                                  Text(
                                    'Subject: ${_subjectController.text}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Divider(),
                                ],
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      preview,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(child: ProgressRing()),
                        error: (error, stack) => Center(
                          child: Text('Error loading preview: $error'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        TextFormBox(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          expands: false,
        ),
      ],
    );
  }

  Widget _buildPlaceholdersSection() {
    final placeholders = TemplatePreviewService.getAvailablePlaceholders();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Placeholders',
          style: FluentTheme.of(context).typography.body,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: placeholders.map((placeholder) {
            return GestureDetector(
              onTap: () {
                final currentText = _bodyController.text;
                final selection = _bodyController.selection;
                final newText = currentText.replaceRange(
                  selection.start,
                  selection.end,
                  placeholder,
                );
                _bodyController.text = newText;
                _bodyController.selection = TextSelection.collapsed(
                  offset: selection.start + placeholder.length,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  placeholder,
                  style: TextStyle(
                    fontSize: 12,
                    color: FluentTheme.of(context).accentColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Click on a placeholder to insert it at cursor position',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[100],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TemplateFormState formState) {
    if (formState.isLoading) return Colors.blue;
    if (_hasUnsavedChanges) return Colors.orange;
    if (formState.isSaved) return Colors.green;
    return Colors.grey;
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final template = _buildTemplateFromForm();
    await ref.read(templateFormProvider.notifier).saveTemplate(template);

    final formState = ref.read(templateFormProvider);
    if (formState.error == null && mounted) {
      context.go('/templates');
    }
  }
}