import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextBlockWidget extends ConsumerStatefulWidget {
  final TextBlock block;
  final TemplateType? templateType;

  const TextBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

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
      padding: _getPlatformPadding(),
      child: isSelected && _isEditing
          ? _buildEditingWidget()
          : _buildDisplayWidget(isSelected, editorState.isPreviewMode, editorState.previewData),
    );
  }

  EdgeInsets _getPlatformPadding() {
    // Adjust padding based on template type for better platform compatibility
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case TemplateType.email:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      default:
        return const EdgeInsets.all(16);
    }
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
          _controller.text = widget.block.text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      } : null,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: _getMinHeight(),
          maxWidth: _getMaxWidth(),
        ),
        padding: _getContentPadding(),
        decoration: BoxDecoration(
          border: isSelected && !isPreviewMode
              ? Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
          // Add subtle background for email compatibility
          color: widget.templateType == TemplateType.email && !isPreviewMode
              ? Colors.grey.withValues(alpha: 0.02)
              : null,
        ),
        child: isPreviewMode 
            ? _buildPreviewText(displayText)
            : _buildEditableText(displayText, isSelected),
      ),
    );
  }

  EdgeInsets _getContentPadding() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.all(8);
      case TemplateType.email:
        return const EdgeInsets.all(12);
      default:
        return const EdgeInsets.all(8);
    }
  }

  double _getMinHeight() {
    // Platform-specific minimum heights
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return 36; // Optimized for mobile touch targets
      case TemplateType.email:
        return 44; // Better for email client rendering
      default:
        return 40;
    }
  }

  double _getMaxWidth() {
    // Platform-specific max widths for better readability
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return 320; // Mobile screen width consideration
      case TemplateType.email:
        return 580; // Standard email width minus padding
      default:
        return double.infinity;
    }
  }

  Widget _buildPreviewText(String text) {
    return SelectableText(
      text.isEmpty ? 'Empty text block' : text,
      style: _getTextStyle(text.isEmpty),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  Widget _buildEditableText(String text, bool isSelected) {
    // Highlight placeholders in edit mode
    if (widget.block.hasPlaceholders && text.isNotEmpty) {
      return _buildTextWithHighlightedPlaceholders(text, isSelected);
    }

    return SelectableText(
      text.isEmpty ? 'Double-click to edit text' : text,
      style: _getTextStyle(text.isEmpty),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  TextStyle _getTextStyle(bool isEmpty) {
    final baseStyle = TextStyle(
      fontSize: _getResponsiveFontSize(),
      fontWeight: _parseFontWeight(widget.block.fontWeight),
      color: isEmpty 
          ? _getPlaceholderColor() 
          : _parseColor(widget.block.color),
      fontStyle: widget.block.italic ? FontStyle.italic : FontStyle.normal,
      decoration: widget.block.underline ? TextDecoration.underline : TextDecoration.none,
      height: _getResponsiveLineHeight(),
      letterSpacing: _getResponsiveLetterSpacing(),
      fontFamily: _getFontFamily(),
    );

    // Platform-specific adjustments
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return baseStyle.copyWith(
          // WhatsApp uses system fonts for better mobile compatibility
          fontFamily: _getWhatsAppFont(),
          // Ensure good readability on mobile
          fontSize: baseStyle.fontSize != null
                    ? (baseStyle.fontSize! < 14 ? 14 : (baseStyle.fontSize! > 24 ? 24 : baseStyle.fontSize!))
                    : 0,
        );
      case TemplateType.email:
        return baseStyle.copyWith(
          // Email-safe fonts with comprehensive fallbacks
          fontFamily: _getEmailSafeFont(),
          // Slightly larger for email readability
          fontSize: baseStyle.fontSize != null
                    ? (baseStyle.fontSize! < 16 ? 16 : (baseStyle.fontSize! > 28 ? 28 : baseStyle.fontSize!))
                    : 0,
        );
      default:
        return baseStyle;
    }
  }

  Color _getPlaceholderColor() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF8696A0); // WhatsApp placeholder color
      case TemplateType.email:
        return const Color(0xFF999999); // Email-safe gray
      default:
        return Colors.grey;
    }
  }

  double _getResponsiveFontSize() {
    final baseFontSize = widget.block.fontSize;
    
    // Adjust font size based on platform with accessibility considerations
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        // Ensure minimum readable size for mobile (WCAG AA compliance)
        return baseFontSize < 14 ? 14 : (baseFontSize > 24 ? 24 : baseFontSize);
      case TemplateType.email:
        // Email clients prefer 16px+ for body text
        return baseFontSize < 16 ? 16 : (baseFontSize > 28 ? 28 : baseFontSize);
      default:
        return baseFontSize;
    }
  }

  double _getResponsiveLineHeight() {
    final baseLineHeight = widget.block.lineHeight;
    
    // Platform-specific line height adjustments for readability
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        // Optimal for mobile reading
        return baseLineHeight < 1.3 ? 1.3 : (baseLineHeight > 1.6 ? 1.6 : baseLineHeight);
      case TemplateType.email:
        // Better readability in email clients
        return baseLineHeight < 1.4 ? 1.4 : (baseLineHeight > 1.8 ? 1.8 : baseLineHeight);
      default:
        return baseLineHeight;
    }
  }

  double _getResponsiveLetterSpacing() {
    final baseSpacing = widget.block.letterSpacing;
    
    // Constrain letter spacing for platform compatibility
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return baseSpacing.clamp(-0.5, 2.0);
      case TemplateType.email:
        return baseSpacing.clamp(-0.3, 1.5);
      default:
        return baseSpacing;
    }
  }

  String? _getFontFamily() {
    if (widget.block.fontFamily == 'default') return null;
    return widget.block.fontFamily;
  }

  String _getWhatsAppFont() {
    // WhatsApp-optimized font stack
    switch (widget.block.fontFamily.toLowerCase()) {
      case 'serif':
        return 'Georgia, serif';
      case 'monospace':
        return 'Monaco, Consolas, monospace';
      case 'sans-serif':
      case 'default':
      default:
        return 'system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
    }
  }

  String _getEmailSafeFont() {
    // Comprehensive email-safe font stack
    if (widget.templateType == TemplateType.email) {
      return 'Monaco, Consolas, "Lucida Console", "Courier New", monospace';
    }
    switch (widget.block.fontFamily.toLowerCase()) {
      case 'serif':
        return 'Georgia, "Times New Roman", Times, serif';
      case 'sans-serif':
      case 'default':
      default:
        return 'Arial, Helvetica, "Segoe UI", Roboto, sans-serif';
    }
  }

  FontWeight _parseFontWeight(String fontWeight) {
    switch (fontWeight.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      case 'extrabold':
        return FontWeight.w800;
      default:
        return FontWeight.normal;
    }
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
          style: _getTextStyle(false),
        ));
      }

      // Add highlighted placeholder with platform-appropriate styling
      spans.add(TextSpan(
        text: match.group(0),
        style: _getTextStyle(false).copyWith(
          fontWeight: FontWeight.bold,
          color: _getPlaceholderHighlightColor(theme),
          backgroundColor: _getPlaceholderBackgroundColor(theme),
          fontStyle: FontStyle.italic,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _getTextStyle(false),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: _parseAlignment(widget.block.alignment),
    );
  }

  Color _getPlaceholderHighlightColor(FluentThemeData theme) {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF25D366); // WhatsApp green
      case TemplateType.email:
        return const Color(0xFF007ACC); // Professional blue
      default:
        return theme.accentColor;
    }
  }

  Color _getPlaceholderBackgroundColor(FluentThemeData theme) {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF25D366).withValues(alpha: 0.1);
      case TemplateType.email:
        return const Color(0xFF007ACC).withValues(alpha: 0.1);
      default:
        return theme.accentColor.withValues(alpha: 0.1);
    }
  }

  Widget _buildEditingWidget() {
    return TextBox(
      controller: _controller,
      maxLines: null,
      autofocus: true,
      style: _getTextStyle(false),
      placeholder: 'Enter text with {{placeholders}}',
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
      // Return platform-appropriate default color
      switch (widget.templateType) {
        case TemplateType.whatsapp:
          return const Color(0xFF111B21); // WhatsApp dark text
        case TemplateType.email:
          return const Color(0xFF333333); // Email-safe dark gray
        default:
          return Colors.black;
      }
    }
  }

  TextAlign _parseAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        // Email clients have poor justify support, fallback to left
        return widget.templateType == TemplateType.email 
            ? TextAlign.left 
            : TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }
}
