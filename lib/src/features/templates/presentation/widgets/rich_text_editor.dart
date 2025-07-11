import 'package:client_connect/src/features/templates/data/rich_text_model.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/formatting_toolbar.dart';
import 'package:fluent_ui/fluent_ui.dart';


class RichTextEditor extends StatefulWidget {
  final RichTextContent content;
  final Function(RichTextContent) onChanged;
  final TextStyle? baseStyle;
  final String? placeholder;
  final bool enabled;
  final int? maxLines;
  final TextAlign textAlign;

  const RichTextEditor({
    super.key,
    required this.content,
    required this.onChanged,
    this.baseStyle,
    this.placeholder,
    this.enabled = true,
    this.maxLines,
    this.textAlign = TextAlign.start,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  TextSelection _selection = const TextSelection.collapsed(offset: 0);
  OverlayEntry? _toolbarOverlay;
  bool _showToolbar = false;
  RichTextContent _currentContent = const RichTextContent();
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
    _controller = TextEditingController(text: _currentContent.plainText);
    _focusNode = FocusNode();
    
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _currentContent = widget.content;
      final newText = _currentContent.plainText;
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _removeToolbar();
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideToolbar();
    }
  }

  void _handleTextChange() {
    final text = _controller.text;
    final plainText = _currentContent.plainText;
    
    if (text != plainText) {
      // Text has changed, update the rich text content
      if (text.length > plainText.length) {
        // Text was inserted
        final insertPos = _findInsertPosition(plainText, text);
        final insertedText = text.substring(insertPos, insertPos + (text.length - plainText.length));
        final formatting = _getFormattingAtPosition(insertPos);
        _currentContent = _currentContent.insertText(insertPos, insertedText, formatting);
      } else if (text.length < plainText.length) {
        // Text was deleted
        final deleteStart = _findDeleteStart(plainText, text);
        final deleteEnd = deleteStart + (plainText.length - text.length);
        _currentContent = _currentContent.deleteText(deleteStart, deleteEnd);
      } else {
        // Text was replaced, recreate content
        _currentContent = RichTextContent.fromPlainText(text);
      }
      
      widget.onChanged(_currentContent);
    }
  }

  int _findInsertPosition(String oldText, String newText) {
    for (int i = 0; i < oldText.length && i < newText.length; i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }
    return oldText.length;
  }

  int _findDeleteStart(String oldText, String newText) {
    for (int i = 0; i < oldText.length && i < newText.length; i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }
    return newText.length;
  }

  TextFormatting _getFormattingAtPosition(int position) {
    if (position > 0) {
      return _currentContent.getFormattingAt(position - 1);
    }
    return const TextFormatting();
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    // The logic inside the function can remain exactly the same.
    // You don't have to use the 'cause' variable if you don't need it.
    setState(() {
      _selection = selection;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _selection == selection) {
        if (selection.isCollapsed || !_focusNode.hasFocus) {
          _hideToolbar();
        } else {
          showToolbar();
        }
      }
    });
  }

  void showToolbar() {
    if (_showToolbar || _selection.isCollapsed) return;
    
    _showToolbar = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createToolbarOverlay();
    });
  }

  void _hideToolbar() {
    if (!_showToolbar) return;
    
    _showToolbar = false;
    _removeToolbar();
  }

  void _createToolbarOverlay() {
    if (!mounted || _toolbarOverlay != null || _selection.isCollapsed) return;

    final renderBox = _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    try {
      final textPainter = TextPainter(
        text: TextSpan(text: _controller.text, style: widget.baseStyle),
        textDirection: TextDirection.ltr,
        maxLines: widget.maxLines,
      );
      textPainter.layout(maxWidth: renderBox.size.width);

      final selectionRects = textPainter.getBoxesForSelection(_selection);
      if (selectionRects.isEmpty) return;

      final firstRect = selectionRects.first;
      final offset = renderBox.localToGlobal(Offset.zero);
      
      // Calculate toolbar position
      double toolbarLeft = offset.dx + firstRect.left;
      double toolbarTop = offset.dy + firstRect.top - 60; // Increased space for toolbar

      // Ensure toolbar stays within screen bounds
      final screenSize = MediaQuery.of(context).size;
      if (toolbarLeft + 300 > screenSize.width) {
        toolbarLeft = screenSize.width - 320;
      }
      if (toolbarLeft < 20) {
        toolbarLeft = 20;
      }
      if (toolbarTop < 20) {
        toolbarTop = offset.dy + firstRect.bottom + 10;
      }

      _toolbarOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: toolbarLeft,
          top: toolbarTop,
          child: FormattingToolbar(
            onFormatText: _applyFormatting,
            currentFormatting: _getCurrentFormatting(),
            onClose: _hideToolbar,
          ),
        ),
      );

      Overlay.of(context).insert(_toolbarOverlay!);
    } catch (e) {
      // Handle any errors gracefully
      _hideToolbar();
    }
  }

  void _removeToolbar() {
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  TextFormatting _getCurrentFormatting() {
    if (_selection.isCollapsed) {
      return _currentContent.getFormattingAt(_selection.baseOffset);
    }
    
    // For selections, return the formatting of the first character
    return _currentContent.getFormattingAt(_selection.start);
  }

  void _applyFormatting(TextFormatting formatting) {
    if (_selection.isCollapsed) return;

    final newContent = _currentContent.applyFormatting(
      _selection.start,
      _selection.end,
      formatting,
    );

    setState(() {
      _currentContent = newContent;
    });

    widget.onChanged(newContent);
    _hideToolbar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _editorKey,
        constraints: const BoxConstraints(minHeight: 40),
        child: widget.enabled
            ? _buildEditableText()
            : _buildReadOnlyText(),
    );
  }

  Widget _buildEditableText() {
    return SelectableText.rich(
      _buildTextSpan(),
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      onSelectionChanged: _handleSelectionChanged,
      onTap: () {
        _focusNode.requestFocus();
      },
      style: widget.baseStyle,
    );
  }

  Widget _buildReadOnlyText() {
    return SelectableText.rich(
      _buildTextSpan(),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      style: widget.baseStyle,
    );
  }

  TextSpan _buildTextSpan() {
    if (_currentContent.isEmpty) {
      return TextSpan(
        text: widget.placeholder ?? '',
        style: widget.baseStyle?.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final spans = _currentContent.segments.map((segment) {
      return TextSpan(
        text: segment.text,
        style: _buildTextStyle(segment.formatting),
      );
    }).toList();

    return TextSpan(children: spans);
  }

  TextStyle _buildTextStyle(TextFormatting formatting) {
    TextStyle style = widget.baseStyle ?? const TextStyle();

    if (formatting.bold) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }

    if (formatting.italic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    if (formatting.underline) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }

    if (formatting.strikethrough) {
      final decorations = <TextDecoration>[];
      if (formatting.underline) decorations.add(TextDecoration.underline);
      decorations.add(TextDecoration.lineThrough);
      style = style.copyWith(
        decoration: TextDecoration.combine(decorations),
      );
    }

    if (formatting.fontSize != null) {
      style = style.copyWith(fontSize: formatting.fontSize);
    }

    if (formatting.fontFamily != null) {
      style = style.copyWith(fontFamily: formatting.fontFamily);
    }

    if (formatting.color != null) {
      style = style.copyWith(color: _parseColor(formatting.color!));
    }

    if (formatting.backgroundColor != null) {
      style = style.copyWith(backgroundColor: _parseColor(formatting.backgroundColor!));
    }

    return style;
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }
}