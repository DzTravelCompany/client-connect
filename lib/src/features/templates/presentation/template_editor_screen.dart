import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/data/template_dao.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/editor_canvas.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/editor_inspector.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/editor_toolbox.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/template_type_selector.dart';
import 'widgets/template_preview_dialog.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final int? templateId;

  const TemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;
  final TemplateDao _templateDao = TemplateDao();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _subjectController = TextEditingController();
    
    // Load template if editing
    if (widget.templateId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTemplate();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _loadTemplate() async {

    ref.read(templateEditorProvider.notifier).setLoading(true);
    
    try {

      if (widget.templateId != null) {
        final template = await _templateDao.getTemplateById(widget.templateId!);
        if (template != null) {
          ref.read(templateEditorProvider.notifier).loadTemplate(
            blocks: template.blocks,
            templateType: template.type == "email" ? TemplateType.email : TemplateType.whatsapp,
            templateName: template.name,
            templateSubject: template.subject ?? '',
          );
          _nameController.text = template.name;
          _subjectController.text = template.subject ?? '';
        } else {
          ref.read(templateEditorProvider.notifier).setError('Template not found');
        }
      } else {
        // This case should ideally not happen if templateId is null,
        // but as a fallback, we can load empty or default.
        // For now, matching existing behavior of loading sample if no ID.
        final sampleBlocks = [
          TextBlock(
            id: 'sample-1',
            text: 'Welcome to our newsletter!',
            fontSize: 24.0,
            fontWeight: 'bold',
          ),
          ImageBlock(
            id: 'sample-2',
            imageUrl: '/placeholder.svg?height=200&width=400',
            width: 400,
            height: 200,
          ),
        ];
        
        ref.read(templateEditorProvider.notifier).loadTemplate(
          blocks: sampleBlocks,
          templateType: TemplateType.email,
          templateName: 'Sample Template',
          templateSubject: 'Sample Subject',
        );
        
        _nameController.text = 'Sample Template';
        _subjectController.text = 'Sample Subject';
      }
    } catch (e) {
      ref.read(templateEditorProvider.notifier).setError('Failed to load template: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: _buildHeader(context, theme, editorState),
      content: editorState.isLoading
          ? const Center(child: ProgressRing())
          : editorState.error != null
              ? _buildErrorState(context, editorState.error!)
              : _buildEditorContent(context, theme, editorState),
    );
  }

  Widget _buildHeader(BuildContext context, FluentThemeData theme, TemplateEditorState state) {
    return PageHeader(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => _handleBack(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.templateId == null ? 'New Template' : 'Edit Template'),
                if (state.templateName.isNotEmpty)
                  Text(
                    state.templateName,
                    style: theme.typography.caption?.copyWith(
                      color: theme.inactiveColor,
                    ),
                  ),
              ],
            ),
          ),
          if (state.isDirty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Unsaved',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      commandBar: CommandBar(
        primaryItems: [
          CommandBarButton(
            icon: const Icon(FluentIcons.undo),
            label: const Text('Undo'),
            onPressed: state.canUndo
                ? () => ref.read(templateEditorProvider.notifier).undo()
                : null,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.redo),
            label: const Text('Redo'),
            onPressed: state.canRedo
                ? () => ref.read(templateEditorProvider.notifier).redo()
                : null,
          ),
          CommandBarSeparator(),
          CommandBarButton(
            icon: const Icon(FluentIcons.save),
            label: const Text('Save'),
            onPressed: state.isDirty ? () => _saveTemplate(context) : null,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.preview),
            label: const Text('Preview'),
            onPressed: () => _showPreview(context),
          ),
          CommandBarSeparator(),
          CommandBarButton(
            icon: const Icon(FluentIcons.clear_formatting),
            label: const Text('Clear'),
            onPressed: state.blocks.isNotEmpty
                ? () => _showClearDialog(context)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = FluentTheme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Template',
            style: theme.typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: () => _loadTemplate(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent(BuildContext context, FluentThemeData theme, TemplateEditorState state) {
    return Column(
      children: [
        // Template Info Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(
                color: theme.accentColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextBox(
                  controller: _nameController,
                  placeholder: 'Template Name',
                  onChanged: (value) {
                    ref.read(templateEditorProvider.notifier).setTemplateInfo(name: value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (state.templateType == TemplateType.email) ...[
                Expanded(
                  flex: 2,
                  child: TextBox(
                    controller: _subjectController,
                    placeholder: 'Email Subject',
                    onChanged: (value) {
                      ref.read(templateEditorProvider.notifier).setTemplateInfo(subject: value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              const TemplateTypeSelector(),
            ],
          ),
        ),
        
        // Main Editor Area
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Row(
              children: [
                // Toolbox Panel
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      right: BorderSide(
                        color: theme.accentColor,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: const EditorToolbox(),
                ),
                
                // Canvas Panel
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const EditorCanvas(),
                  ),
                ),
                
                // Inspector Panel
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      left: BorderSide(
                        color: theme.accentColor,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: const EditorInspector(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    final state = ref.read(templateEditorProvider);
    
    if (state.isDirty) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save before leaving?'),
          actions: [
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Button(
              child: const Text('Discard'),
              onPressed: () {
                context.go('/templates');
                context.pop();
              },
            ),
            FilledButton(
              child: const Text('Save'),
              onPressed: () async {
                context.go('/templates');
                //Navigator.of(context).pop();
                _saveTemplate(context);
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
          ],
        ),
      );
    } else {
      context.go('/templates');
    }
  }

  void _saveTemplate(BuildContext context) async {

    final state = ref.read(templateEditorProvider);
    

    ref.read(templateEditorProvider.notifier).setLoading(true);
    
    try {

      // Create template model from current state
      final templateModel = TemplateModel(
        id: widget.templateId ?? 0, // Will be ignored for new templates
        name: state.templateName.trim(),
        subject: state.templateType == TemplateType.email ? state.templateSubject.trim() : null,
        body: '', // Will be generated from blocks
        templateType: state.templateType,
        blocks: state.blocks,
        isEmail: state.templateType == TemplateType.email,
        createdAt: state.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final validationErrors = templateModel.validate();
      if (validationErrors.isNotEmpty) {
        if (context.mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Validation Error'),
              content: Text(validationErrors.first),
              severity: InfoBarSeverity.warning,
              onClose: close,
            ),
          );
        }
        return;
      }

      // Check for duplicate names (only for new templates or when name changed)
      if (widget.templateId == null) {
        final nameExists = await _templateDao.templateNameExists(templateModel.name);
        if (nameExists) {
          if (context.mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Duplicate Name'),
                content: Text('A template with the name "${templateModel.name}" already exists.'),
                severity: InfoBarSeverity.warning,
                onClose: close,
              ),
            );
          }
          return;
        }
      }

      // Performance warning for large templates
      if (templateModel.isLargeTemplate && context.mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Large Template Warning'),
            content: Text(
              'This template is quite large (${(templateModel.estimatedSize / 1024).toStringAsFixed(1)}KB). '
              'Large templates may take longer to load and send. Do you want to continue saving?'
            ),
            actions: [
              Button(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FilledButton(
                child: const Text('Save Anyway'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          return;
        }
      }

      if (widget.templateId == null) {
        // Creating new template
        await _templateDao.createTemplate(templateModel);
        
        if (context.mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Template Created'),
              content: Text('Template "${templateModel.name}" has been created successfully.'),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
        }
      } else {
        // Updating existing template
        try {
          await _templateDao.updateTemplate(templateModel);
        } catch (e) {
          throw Exception('Failed to update template in database ${e.toString()}');
        }
        
        
        if (context.mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Template Updated'),
              content: Text('Template "${templateModel.name}" has been updated successfully.'),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
        }
      }

      ref.read(templateEditorProvider.notifier).markSaved();

    } catch (e) {
      ref.read(templateEditorProvider.notifier).setError('Failed to save template: ${e.toString()}');
      
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Save Failed'),
            content: Text('Failed to save template: ${e.toString()}'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    } finally {
      ref.read(templateEditorProvider.notifier).setLoading(false);
    }
  }

  void _showPreview(BuildContext context) {
    final state = ref.read(templateEditorProvider);
    
    showDialog(
      context: context,
      builder: (context) => TemplatePreviewDialog(
        templateName: state.templateName,
        templateSubject: state.templateSubject,
        templateType: state.templateType,
        blocks: state.blocks,
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear Template'),
        content: const Text('Are you sure you want to clear all blocks? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Clear'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(templateEditorProvider.notifier).clearTemplate();
            },
          ),
        ],
      ),
    );
  }
}
