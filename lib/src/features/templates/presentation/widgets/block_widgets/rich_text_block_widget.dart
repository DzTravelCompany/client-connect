import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RichTextBlockWidget extends ConsumerStatefulWidget {
  final RichTextBlock block;

  const RichTextBlockWidget({super.key, required this.block});

  @override
  ConsumerState<RichTextBlockWidget> createState() => _RichTextBlockWidgetState();
}

class _RichTextBlockWidgetState extends ConsumerState<RichTextBlockWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  String _lastBlockContent = '';

  @override
  void initState() {
    super.initState();
    _lastBlockContent = widget.block.htmlContent;
    _controller = TextEditingController(text: widget.block.htmlContent);
  }

  @override
  void didUpdateWidget(RichTextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if the block content changed externally
    if (oldWidget.block.htmlContent != widget.block.htmlContent && 
        !_isEditing && 
        widget.block.htmlContent != _lastBlockContent) {
      _lastBlockContent = widget.block.htmlContent;
      _controller.text = widget.block.htmlContent;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final editorState = ref.watch(templateEditorProvider);
    final isSelected = editorState.selectedBlockId == widget.block.id;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: isSelected && _isEditing
          ? _buildEditingWidget(theme)
          : _buildDisplayWidget(context, theme, isSelected, editorState.isPreviewMode, editorState.previewData),
    );
  }

  Widget _buildDisplayWidget(BuildContext context, FluentThemeData theme, bool isSelected, bool isPreviewMode, Map<String, String> previewData) {
    String displayContent;
    if (isPreviewMode && widget.block.hasPlaceholders) {
      displayContent = widget.block.renderWithData(previewData);
    } else {
      displayContent = widget.block.htmlContent;
    }

    return GestureDetector(
      onDoubleTap: isSelected && !isPreviewMode ? () {
        setState(() {
          _isEditing = true;
          _controller.text = widget.block.htmlContent;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      } : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.accentColor.withValues(alpha: 0.8)
                : theme.accentColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.font_color_a,
                  size: 14,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rich Text Content',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isPreviewMode && isSelected) ...[
                  const Spacer(),
                  Text(
                    'Double-click to edit',
                    style: TextStyle(
                      color: theme.inactiveColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _stripHtmlTags(displayContent),
              style: TextStyle(
                fontSize: widget.block.fontSize,
                height: widget.block.lineHeight,
                color: theme.typography.body?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingWidget(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.accentColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.font_color_a,
                size: 14,
                color: theme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Editing Rich Text Content',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextBox(
            controller: _controller,
            maxLines: null,
            minLines: 3,
            autofocus: true,
            placeholder: 'Enter HTML content with {{placeholders}}',
            style: TextStyle(
              fontSize: widget.block.fontSize,
              height: widget.block.lineHeight,
              fontFamily: 'monospace',
            ),
            onChanged: (value) {
              _lastBlockContent = value;
              ref.read(templateEditorProvider.notifier).updateBlock(
                widget.block.id,
                {'htmlContent': value},
              );
            },
            onSubmitted: (value) {
              setState(() => _isEditing = false);
            },
            onTapOutside: (event) {
              setState(() => _isEditing = false);
            },
          ),
        ],
      ),
    );
  }

  String _stripHtmlTags(String htmlContent) {
    // Simple HTML tag removal for preview
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}