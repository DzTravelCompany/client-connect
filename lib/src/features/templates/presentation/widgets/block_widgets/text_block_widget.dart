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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
  }

  @override
  void didUpdateWidget(TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && !_isEditing) {
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
          : _buildDisplayWidget(isSelected),
    );
  }

  Widget _buildDisplayWidget(bool isSelected) {
    return GestureDetector(
      onDoubleTap: isSelected ? () => setState(() => _isEditing = true) : null,
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
        child: Text(
          widget.block.text.isEmpty ? 'Double-click to edit text' : widget.block.text,
          style: TextStyle(
            fontSize: widget.block.fontSize,
            fontWeight: widget.block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
            color: widget.block.text.isEmpty 
                ? Colors.grey 
                : _parseColor(widget.block.color),
            fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
            decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
            height: widget.block.lineHeight,
            letterSpacing: widget.block.letterSpacing,
          ),
          textAlign: _parseAlignment(widget.block.alignment),
        ),
      ),
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
        _isEditing = true;
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