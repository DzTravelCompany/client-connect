import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';



class TemplatePreviewDialog extends StatelessWidget {
  final String templateName;
  final String templateSubject;
  final TemplateType templateType;
  final List<TemplateBlock> blocks;

  const TemplatePreviewDialog({
    super.key,
    required this.templateName,
    required this.templateSubject,
    required this.templateType,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 800,
        maxHeight: 700,
      ),
      title: Row(
        children: [
          Icon(
            templateType == TemplateType.email ? FluentIcons.mail : FluentIcons.chat,
            size: 20,
            color: theme.accentColor,
          ),
          const SizedBox(width: 8),
          Text('Template Preview'),
          const Spacer(),
          Text(
            templateType == TemplateType.email ? 'Email' : 'WhatsApp',
            style: theme.typography.caption?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Info
          if (templateName.isNotEmpty || templateSubject.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (templateName.isNotEmpty) ...[
                    Text(
                      'Template: $templateName',
                      style: theme.typography.bodyStrong,
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (templateSubject.isNotEmpty && templateType == TemplateType.email)
                    Text(
                      'Subject: $templateSubject',
                      style: theme.typography.body?.copyWith(
                        color: theme.inactiveColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Preview Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.accentColor),
              ),
              child: blocks.isEmpty
                  ? _buildEmptyPreview(theme)
                  : _buildPreviewContent(),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          child: const Text('Export HTML'),
          onPressed: () => _exportHtml(context),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.preview,
            size: 48,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No content to preview',
            style: theme.typography.subtitle?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some blocks to see the preview',
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks.map((block) => _buildPreviewBlock(block)).toList(),
      ),
    );
  }

  Widget _buildPreviewBlock(TemplateBlock block) {
    // Create a non-interactive version of each block for preview
    switch (block.type) {
      case TemplateBlockType.text:
        return _buildPreviewTextBlock(block as TextBlock);
      case TemplateBlockType.richText:
        return _buildPreviewRichTextBlock(block as RichTextBlock);
      case TemplateBlockType.image:
        return _buildPreviewImageBlock(block as ImageBlock);
      case TemplateBlockType.button:
        return _buildPreviewButtonBlock(block as ButtonBlock);
      case TemplateBlockType.spacer:
        return SizedBox(height: (block as SpacerBlock).height);
      case TemplateBlockType.divider:
        return _buildPreviewDividerBlock(block as DividerBlock);
      case TemplateBlockType.placeholder:
        return _buildPreviewPlaceholderBlock(block as PlaceholderBlock);
      case TemplateBlockType.list:
        return _buildPreviewListBlock(block as ListBlock);
      case TemplateBlockType.qrCode:
        return _buildPreviewQRCodeBlock(block as QRCodeBlock);
      case TemplateBlockType.social:
        return _buildPreviewSocialBlock(block as SocialBlock);
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          child: Text('Unsupported block: ${block.type}'),
        );
    }
  }

  Widget _buildPreviewTextBlock(TextBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        block.text,
        style: TextStyle(
          fontSize: block.fontSize,
          fontWeight: block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          color: _parseColor(block.color),
          fontStyle: block.italic ? FontStyle.italic : FontStyle.normal,
          decoration: block.underline ? TextDecoration.underline : TextDecoration.none,
          height: block.lineHeight,
          letterSpacing: block.letterSpacing,
        ),
        textAlign: _parseAlignment(block.alignment),
      ),
    );
  }

  Widget _buildPreviewRichTextBlock(RichTextBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        block.htmlContent.replaceAll(RegExp(r'<[^>]*>'), ''), // Strip HTML for preview
        style: TextStyle(
          fontSize: block.fontSize,
          height: block.lineHeight,
        ),
      ),
    );
  }

  Widget _buildPreviewImageBlock(ImageBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: _parseImageAlignment(block.alignment),
      child: block.imageUrl.isEmpty
          ? Container(
              width: block.width,
              height: block.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(block.borderRadius),
                border: block.borderWidth > 0
                    ? Border.all(
                        color: _parseColor(block.borderColor),
                        width: block.borderWidth,
                      )
                    : null,
              ),
              child: const Center(
                child: Icon(FluentIcons.file_image, size: 32, color: Colors.grey),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(block.borderRadius),
              child: Container(
                decoration: block.borderWidth > 0
                    ? BoxDecoration(
                        border: Border.all(
                          color: _parseColor(block.borderColor),
                          width: block.borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(block.borderRadius),
                      )
                    : null,
                child: Image.network(
                  block.imageUrl,
                  width: block.width,
                  height: block.height,
                  fit: _parseBoxFit(block.fit),
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: block.width,
                      height: block.height,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(FluentIcons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewButtonBlock(ButtonBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: _parseButtonAlignment(block.alignment),
      child: Container(
        width: block.fullWidth ? double.infinity : null,
        child: Container(
          padding: _getButtonPadding(block.size),
          decoration: BoxDecoration(
            color: _parseColor(block.backgroundColor),
            borderRadius: BorderRadius.circular(block.borderRadius),
            border: block.borderWidth > 0
                ? Border.all(
                    color: _parseColor(block.borderColor),
                    width: block.borderWidth,
                  )
                : null,
          ),
          child: Text(
            block.text,
            style: TextStyle(
              color: _parseColor(block.textColor),
              fontSize: _getButtonFontSize(block.size),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewDividerBlock(DividerBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        height: block.thickness,
        decoration: BoxDecoration(
          color: _parseColor(block.color),
          borderRadius: BorderRadius.circular(block.thickness / 2),
        ),
      ),
    );
  }

  Widget _buildPreviewPlaceholderBlock(PlaceholderBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Text(
          '{{${block.placeholderKey.isEmpty ? block.label : block.placeholderKey}}}',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewListBlock(ListBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(bottom: block.spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    block.listType == 'numbered' 
                        ? '${index + 1}.' 
                        : block.bulletStyle,
                    style: TextStyle(
                      fontSize: block.fontSize,
                      color: _parseColor(block.color),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: block.fontSize,
                      color: _parseColor(block.color),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewQRCodeBlock(QRCodeBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Container(
        width: block.size,
        height: block.size,
        decoration: BoxDecoration(
          color: _parseColor(block.backgroundColor),
          border: Border.all(color: Colors.grey),
        ),
        child: const Center(
          child: Text(
            'QR',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSocialBlock(SocialBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: block.layout == 'horizontal'
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildSocialIcons(block),
            )
          : Column(
              children: _buildSocialIcons(block),
            ),
    );
  }

  List<Widget> _buildSocialIcons(SocialBlock block) {
    return block.socialLinks.map((link) {
      return Container(
        margin: const EdgeInsets.all(4),
        width: block.iconSize,
        height: block.iconSize,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          FluentIcons.share,
          size: block.iconSize * 0.6,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Helper methods
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

  Alignment _parseImageAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  Alignment _parseButtonAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  BoxFit _parseBoxFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  EdgeInsets _getButtonPadding(String size) {
    switch (size) {
      case 'small':
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case 'large':
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getButtonFontSize(String size) {
    switch (size) {
      case 'small':
        return 12.0;
      case 'large':
        return 16.0;
      default:
        return 14.0;
    }
  }

  void _exportHtml(BuildContext context) {
    // TODO: Implement HTML export functionality
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Export HTML'),
        content: const Text('HTML export functionality will be implemented.'),
        severity: InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }
}
