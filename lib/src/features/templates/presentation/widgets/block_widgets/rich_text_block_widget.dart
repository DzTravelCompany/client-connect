import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RichTextBlockWidget extends ConsumerStatefulWidget {
  final RichTextBlock block;
  final TemplateType? templateType;

  const RichTextBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

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
      padding: _getPlatformPadding(),
      child: isSelected && _isEditing
          ? _buildEditingWidget(theme)
          : _buildDisplayWidget(context, theme, isSelected, editorState.isPreviewMode, editorState.previewData),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TemplateType.email:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      default:
        return const EdgeInsets.all(16);
    }
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
        constraints: _getContentConstraints(),
        padding: _getContentPadding(),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.accentColor.withValues(alpha: 0.8)
                : _getBorderColor(theme),
          ),
          borderRadius: BorderRadius.circular(6),
          color: _getBackgroundColor(theme, isSelected),
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
                    fontFamily: _getFontFamily(),
                  ),
                ),
                if (!isPreviewMode && isSelected) ...[
                  const Spacer(),
                  Text(
                    'Double-click to edit',
                    style: TextStyle(
                      color: theme.inactiveColor,
                      fontSize: 10,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _buildRenderedContent(displayContent, theme),
          ],
        ),
      ),
    );
  }

  EdgeInsets _getContentPadding() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.all(12);
      case TemplateType.email:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(12);
    }
  }

  Color _getBorderColor(FluentThemeData theme) {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFE4E6EA);
      case TemplateType.email:
        return const Color(0xFFDDDDDD);
      default:
        return theme.accentColor.withValues(alpha: 0.5);
    }
  }

  Color _getBackgroundColor(FluentThemeData theme, bool isSelected) {
    if (isSelected) {
      return theme.accentColor.withValues(alpha: 0.05);
    }
    
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFF7F8FA);
      case TemplateType.email:
        return const Color(0xFFFAFAFA);
      default:
        return Colors.transparent;
    }
  }

  BoxConstraints _getContentConstraints() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const BoxConstraints(
          maxWidth: 320, // Mobile-friendly width
          minHeight: 80,
        );
      case TemplateType.email:
        return const BoxConstraints(
          maxWidth: 580, // Email-safe width
          minHeight: 100,
        );
      default:
        return const BoxConstraints(
          minHeight: 80,
        );
    }
  }

  Widget _buildRenderedContent(String content, FluentThemeData theme) {
    final strippedContent = _stripHtmlTags(content);
    
    return SelectableText(
      strippedContent.isEmpty ? 'Empty rich text content' : strippedContent,
      style: TextStyle(
        fontSize: _getResponsiveFontSize(),
        height: _getResponsiveLineHeight(),
        color: strippedContent.isEmpty 
            ? _getPlaceholderColor(theme)
            : _getTextColor(theme),
        fontFamily: _getFontFamily(),
      ),
    );
  }

  double _getResponsiveFontSize() {
    final baseFontSize = widget.block.fontSize;
    
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return baseFontSize < 14 ? 14 : (baseFontSize > 20 ? 20 : baseFontSize);
      case TemplateType.email:
        return baseFontSize < 16 ? 16 : (baseFontSize > 24 ? 24 : baseFontSize);
      default:
        return baseFontSize;
    }
  }

  double _getResponsiveLineHeight() {
    final baseLineHeight = widget.block.lineHeight;
    
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return baseLineHeight < 1.3 ? 1.3 : (baseLineHeight > 1.6 ? 1.6 : baseLineHeight);
      case TemplateType.email:
        return baseLineHeight < 1.5 ? 1.5 : (baseLineHeight > 1.8 ? 1.8 : baseLineHeight);
      default:
        return baseLineHeight;
    }
  }

  Color _getPlaceholderColor(FluentThemeData theme) {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF8696A0);
      case TemplateType.email:
        return const Color(0xFF999999);
      default:
        return theme.inactiveColor;
    }
  }

  Color _getTextColor(FluentThemeData theme) {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF111B21);
      case TemplateType.email:
        return const Color(0xFF333333);
      default:
        return theme.typography.body?.color ?? Colors.black;
    }
  }

  String? _getFontFamily() {
    switch (widget.templateType) {
      case TemplateType.whatsapp:
        return 'system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
      case TemplateType.email:
        return 'Arial, Helvetica, "Segoe UI", sans-serif';
      default:
        return widget.block.fontFamily == 'default' ? null : widget.block.fontFamily;
    }
  }

  Widget _buildEditingWidget(FluentThemeData theme) {
    return Container(
      padding: _getContentPadding(),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.accentColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
        color: _getBackgroundColor(theme, true),
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
                  fontFamily: _getFontFamily(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextBox(
            controller: _controller,
            maxLines: null,
            minLines: 4,
            autofocus: true,
            placeholder: 'Enter HTML content with {{placeholders}}',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(),
              height: _getResponsiveLineHeight(),
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
    // Enhanced HTML tag removal for better preview with platform-specific handling
    String stripped = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<strong[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</strong>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<b[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</b>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<em[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</em>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<i[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</i>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();

    // Platform-specific text processing
    switch (widget.templateType) {
      case TemplateType.email:
        // Remove excessive line breaks for email
        stripped = stripped.replaceAll(RegExp(r'\n{3,}'), '\n\n');
        break;
      case TemplateType.whatsapp:
        // Limit line breaks for mobile
        stripped = stripped.replaceAll(RegExp(r'\n{2,}'), '\n');
        break;
      default:
        logger.i('Unknown template type: ${widget.templateType}');
        // Handle the case where widget.templateType is null
        // You can either do nothing, or add some default behavior
        break;
    }

    return stripped;
  }
}