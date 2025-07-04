import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import '../../../templates/data/template_model.dart';
import '../../../templates/data/template_block_model.dart';
import '../../../clients/data/client_model.dart';
import '../../../templates/presentation/widgets/block_widgets/text_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/rich_text_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/button_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/image_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/list_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/spacer_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/divider_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/qr_code_block_widget.dart';
import '../../../templates/presentation/widgets/block_widgets/social_block_widget.dart';

class TemplatePreviewWidget extends ConsumerWidget {
  final TemplateModel template;
  final ClientModel client;

  const TemplatePreviewWidget({
    super.key,
    required this.template,
    required this.client,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[60]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: template.isEmail ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[60]),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  template.isEmail ? FluentIcons.mail : FluentIcons.chat,
                  size: 20,
                  color: template.isEmail ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.isEmail ? 'Email Preview' : 'WhatsApp Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: template.isEmail ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Preview for: ${client.fullName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[120],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: template.isEmail ? Colors.blue : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Email-specific header (subject line)
          if (template.isEmail && template.subject != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[20],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[60]),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Subject: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _renderTextWithPlaceholders(template.subject!, client),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'To: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        client.email ?? client.fullName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Template content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: template.hasBlocks 
                  ? _buildBlocksPreview(context, ref)
                  : _buildLegacyPreview(context),
            ),
          ),
          
          // Preview footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[20],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey[60]),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.info,
                  size: 14,
                  color: Colors.grey[120],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This is a preview. Actual formatting may vary depending on the recipient\'s device.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[120],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksPreview(BuildContext context, WidgetRef ref) {
    if (template.blocks.isEmpty) {
      return const Center(
        child: Text(
          'No content blocks in this template',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: template.blocks.map((block) => _buildBlockWidget(block, context, ref)).toList(),
    );
  }

  Widget _buildBlockWidget(TemplateBlock block, BuildContext context, WidgetRef ref) {
    // Create a modified block with client data for preview
    final previewBlock = _createPreviewBlock(block, client);
    
    switch (previewBlock.type) {
      case TemplateBlockType.text:
        return TextBlockWidget(block: previewBlock as TextBlock);
      case TemplateBlockType.richText:
        return RichTextBlockWidget(block: previewBlock as RichTextBlock);
      case TemplateBlockType.button:
        return ButtonBlockWidget(block: previewBlock as ButtonBlock);
      case TemplateBlockType.image:
        return ImageBlockWidget(block: previewBlock as ImageBlock);
      case TemplateBlockType.list:
        return ListBlockWidget(block: previewBlock as ListBlock);
      case TemplateBlockType.spacer:
        return SpacerBlockWidget(block: previewBlock as SpacerBlock);
      case TemplateBlockType.divider:
        return DividerBlockWidget(block: previewBlock as DividerBlock);
      case TemplateBlockType.qrCode:
        return QRCodeBlockWidget(block: previewBlock as QRCodeBlock);
      case TemplateBlockType.social:
        return SocialBlockWidget(block: previewBlock as SocialBlock);
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unsupported block type: ${block.type}',
            style: TextStyle(
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  Widget _buildLegacyPreview(BuildContext context) {
    final renderedBody = _renderTextWithPlaceholders(template.body, client);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[10],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[40]),
      ),
      child: Text(
        renderedBody.isEmpty ? 'No content in this template' : renderedBody,
        style: TextStyle(
          color: renderedBody.isEmpty ? Colors.grey : null,
          fontStyle: renderedBody.isEmpty ? FontStyle.italic : null,
        ),
      ),
    );
  }

  TemplateBlock _createPreviewBlock(TemplateBlock block, ClientModel client) {
    final clientData = _getClientPlaceholderData(client);
    
    switch (block.type) {
      case TemplateBlockType.text:
        final textBlock = block as TextBlock;
        return TextBlock(
          id: textBlock.id,
          text: _renderTextWithPlaceholders(textBlock.text, client),
          fontSize: textBlock.fontSize,
          fontWeight: textBlock.fontWeight,
          color: textBlock.color,
          alignment: textBlock.alignment,
          italic: textBlock.italic,
          underline: textBlock.underline,
          lineHeight: textBlock.lineHeight,
          letterSpacing: textBlock.letterSpacing,
        );
        
      case TemplateBlockType.richText:
        final richTextBlock = block as RichTextBlock;
        return RichTextBlock(
          id: richTextBlock.id,
          htmlContent: _renderTextWithPlaceholders(richTextBlock.htmlContent, client),
          fontSize: richTextBlock.fontSize,
          lineHeight: richTextBlock.lineHeight,
        );
        
      case TemplateBlockType.button:
        final buttonBlock = block as ButtonBlock;
        return ButtonBlock(
          id: buttonBlock.id,
          text: _renderTextWithPlaceholders(buttonBlock.text, client),
          action: _renderTextWithPlaceholders(buttonBlock.action, client),
          actionType: buttonBlock.actionType,
          backgroundColor: buttonBlock.backgroundColor,
          textColor: buttonBlock.textColor,
          borderColor: buttonBlock.borderColor,
          borderWidth: buttonBlock.borderWidth,
          borderRadius: buttonBlock.borderRadius,
          size: buttonBlock.size,
          alignment: buttonBlock.alignment,
          fullWidth: buttonBlock.fullWidth,
          hoverColor: buttonBlock.hoverColor,
        );
        
      case TemplateBlockType.list:
        final listBlock = block as ListBlock;
        return ListBlock(
          id: listBlock.id,
          items: listBlock.items.map((item) => _renderTextWithPlaceholders(item, client)).toList(),
          listType: listBlock.listType,
          bulletStyle: listBlock.bulletStyle,
          fontSize: listBlock.fontSize,
          color: listBlock.color,
          spacing: listBlock.spacing,
        );
        
      default:
        return block; // Return unchanged for blocks that don't need placeholder replacement
    }
  }

  String _renderTextWithPlaceholders(String text, ClientModel client) {
    final clientData = _getClientPlaceholderData(client);
    String result = text;
    
    // Replace placeholders with client data
    clientData.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    
    return result;
  }

  Map<String, String> _getClientPlaceholderData(ClientModel client) {
    return {
      'firstName': client.firstName,
      'lastName': client.lastName,
      'fullName': client.fullName,
      'email': client.email ?? '',
      'phone': client.phone ?? '',
      'company': client.company ?? '',
      'jobTitle': client.jobTitle ?? '',
      'address': client.address ?? '',
      // Add common placeholders
      'currentDate': DateTime.now().toString().split(' ')[0],
      'currentYear': DateTime.now().year.toString(),
    };
  }
}

// Template Preview Service for backward compatibility
class TemplatePreviewService {
  static String generatePreview(TemplateModel template, ClientModel client) {
    final clientData = {
      'firstName': client.firstName,
      'lastName': client.lastName,
      'fullName': client.fullName,
      'email': client.email ?? '',
      'phone': client.phone ?? '',
      'company': client.company ?? '',
      'jobTitle': client.jobTitle ?? '',
      'address': client.address ?? '',
      'currentDate': DateTime.now().toString().split(' ')[0],
      'currentYear': DateTime.now().year.toString(),
    };
    
    String result = template.body;
    
    // Replace placeholders with client data
    clientData.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    
    return result;
  }
}