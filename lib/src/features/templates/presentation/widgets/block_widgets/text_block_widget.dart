import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextBlockWidget extends ConsumerStatefulWidget {
  final TextBlock block;

  const TextBlockWidget({super.key, required this.block});

  @override
  ConsumerState<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends ConsumerState<TextBlockWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  String _lastBlockText = '';

  @override
  void initState() {
    super.initState();
    _lastBlockText = widget.block.text;
    _controller = TextEditingController(text: widget.block.text);
  }

  @override
  void didUpdateWidget(TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
     // Only update controller if the block text changed externally (not from our editing)
    if (oldWidget.block.text != widget.block.text && 
        !_isEditing && 
        widget.block.text != _lastBlockText) {
      _lastBlockText = widget.block.text;
      _controller.text = widget.block.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(templateEditorProvider);
    final isSelected = editorState.selectedBlockId == widget.block.id;

    return Container(
      padding: const EdgeInsets.all(16),
      child: isSelected && _isEditing
          ? _buildEditingWidget()
          : _buildDisplayWidget(isSelected, editorState.isPreviewMode, editorState.previewData),
    );
  }

  Widget _buildDisplayWidget(bool isSelected, bool isPreviewMode, Map<String, String> previewData) {
    // Determine what text to display
    String displayText;
    if (isPreviewMode && widget.block.hasPlaceholders) {
      displayText = widget.block.renderWithData(previewData);
    } else {
      displayText = widget.block.text;
    }

    return GestureDetector(
       onDoubleTap: isSelected && !isPreviewMode ? () {
        setState(() {
          _isEditing = true;
          // Ensure controller has the current text when starting to edit
          _controller.text = widget.block.text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      } : null,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: isPreviewMode 
            ? _buildPreviewText(displayText)
            : _buildEditableText(displayText, isSelected),
      ),
    );
  }

  Widget _buildPreviewText(String text) {
    return Text(
      text.isEmpty ? 'Empty text block' : text,
      style: TextStyle(
        fontSize: widget.block.fontSize,
        fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
        color: text.isEmpty 
            ? Colors.grey 
            : _parseColor(widget.block.color),
        fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
        decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
        height: widget.block.lineHeight,
        letterSpacing: widget.block.letterSpacing,
      ),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  Widget _buildEditableText(String text, bool isSelected) {
    // Highlight placeholders in edit mode
    if (widget.block.hasPlaceholders && text.isNotEmpty) {
      return _buildTextWithHighlightedPlaceholders(text, isSelected);
    }

    return Text(
      text.isEmpty ? 'Double-click to edit text' : text,
      style: TextStyle(
        fontSize: widget.block.fontSize,
        fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
        color: text.isEmpty 
            ? Colors.grey 
            : _parseColor(widget.block.color),
        fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
        decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
        height: widget.block.lineHeight,
        letterSpacing: widget.block.letterSpacing,
      ),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  Widget _buildTextWithHighlightedPlaceholders(String text, bool isSelected) {
    final theme = FluentTheme.of(context);
    final spans = <TextSpan>[];
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before placeholder
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: widget.block.fontSize,
            fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
            color: _parseColor(widget.block.color),
            fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
            decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
            height: widget.block.lineHeight,
            letterSpacing: widget.block.letterSpacing,
          ),
        ));
      }

      // Add highlighted placeholder
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: widget.block.fontSize,
          fontWeight: FontWeight.bold,
          color: theme.accentColor,
          backgroundColor: theme.accentColor.withValues(alpha: 0.1),
          fontStyle: FontStyle.italic,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          fontSize: widget.block.fontSize,
          fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          color: _parseColor(widget.block.color),
          fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
          decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
          height: widget.block.lineHeight,
          letterSpacing: widget.block.letterSpacing,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  Widget _buildEditingWidget() {
    return TextBox(
      controller: _controller,
      maxLines: null,
      autofocus: true,
      style: TextStyle(
        fontSize: widget.block.fontSize,
        fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
        color: _parseColor(widget.block.color),
        fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
        decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
        height: widget.block.lineHeight,
        letterSpacing: widget.block.letterSpacing,
      ),
      onChanged: (value) {
        _lastBlockText = value;
        ref.read(templateEditorProvider.notifier).updateBlock(
          widget.block.id,
          {'text': value},
        );
      },
      onSubmitted: (value) {
        setState(() => _isEditing = false);
      },
      onTapOutside: (event) {
        setState(() => _isEditing = false);
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  TextAlign _parseAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }
}
