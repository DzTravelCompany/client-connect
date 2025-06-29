import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tag_model.dart';
import '../../logic/tag_providers.dart';

class TagFormDialog extends ConsumerStatefulWidget {
  final TagModel? tag;

  const TagFormDialog({super.key, this.tag});

  @override
  ConsumerState<TagFormDialog> createState() => _TagFormDialogState();
}

class _TagFormDialogState extends ConsumerState<TagFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#3B82F6'; // Default blue

  final List<String> _predefinedColors = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Yellow
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#F97316', // Orange
    '#06B6D4', // Cyan
    '#84CC16', // Lime
    '#EC4899', // Pink
    '#6B7280', // Gray
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameController.text = widget.tag!.name;
      _descriptionController.text = widget.tag!.description ?? '';
      _selectedColor = widget.tag!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(tagFormProvider);
    final isEditing = widget.tag != null;

    return ContentDialog(
      title: Text(isEditing ? 'Edit Tag' : 'Create New Tag'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          formState.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Name field
              const Text('Tag Name *'),
              const SizedBox(height: 4),
              TextFormBox(
                controller: _nameController,
                placeholder: 'Enter tag name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tag name is required';
                  }
                  if (value.trim().length > 50) {
                    return 'Tag name must be 50 characters or less';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              const Text('Description'),
              const SizedBox(height: 4),
              TextFormBox(
                controller: _descriptionController,
                placeholder: 'Enter tag description (optional)',
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Description must be 200 characters or less';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Color picker
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${color.substring(1)}')),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(int.parse('0xFF${color.substring(1)}')).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              FluentIcons.check_mark,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Preview
              const Text('Preview'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${_selectedColor.substring(1)}')).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(int.parse('0xFF${_selectedColor.substring(1)}')).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${_selectedColor.substring(1)}')),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nameController.text.isEmpty ? 'Tag Name' : _nameController.text,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () {
            ref.read(tagFormProvider.notifier).resetState();
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          onPressed: formState.isLoading ? null : _saveTag,
          child: formState.isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    final tag = TagModel(
      id: widget.tag?.id ?? 0,
      name: _nameController.text.trim(),
      color: _selectedColor,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      createdAt: widget.tag?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(tagFormProvider.notifier).saveTag(tag);

    final formState = ref.read(tagFormProvider);
    if (formState.error == null && mounted) {
      ref.read(tagFormProvider.notifier).resetState();
      Navigator.of(context).pop();
      
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(widget.tag != null ? 'Tag updated' : 'Tag created'),
          content: Text('The tag "${tag.name}" has been ${widget.tag != null ? 'updated' : 'created'} successfully.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    }
  }
}
