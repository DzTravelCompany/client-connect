import 'dart:convert';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/core/models/database.dart' show Template, TemplatesCompanion;
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:drift/drift.dart';


class TemplateModel {
  final int id;
  final String name;
  final String? subject;
  final String body; // Keep for backward compatibility
  final TemplateType templateType;
  final List<TemplateBlock> blocks;
  final bool isEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateModel({
    required this.id,
    required this.name,
    this.subject,
    required this.body,
    required this.templateType,
    required this.blocks,
    required this.isEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from database Template to TemplateModel
  factory TemplateModel.fromDatabase(Template template) {
    List<TemplateBlock> blocks = [];
    
    // Try to parse blocks from JSON if available
    if (template.blocksJson != null && template.blocksJson!.isNotEmpty) {
      try {
        final List<dynamic> blocksJson = jsonDecode(template.blocksJson!);
        blocks = blocksJson.map((blockJson) => TemplateBlock.fromJson(blockJson)).toList();
      } catch (e) {
        // If parsing fails, create a simple text block from the body
        blocks = [
          TextBlock(
            id: 'legacy-${template.id}',
            text: template.body,
          ),
        ];
      }
    } else if (template.body.isNotEmpty) {
      // Create a text block from the legacy body field
      blocks = [
        TextBlock(
          id: 'legacy-${template.id}',
          text: template.body,
        ),
      ];
    }

    return TemplateModel(
      id: template.id,
      name: template.name,
      subject: template.subject,
      body: template.body,
      templateType: template.templateType == 'whatsapp' 
          ? TemplateType.whatsapp 
          : TemplateType.email,
      blocks: blocks,
      isEmail: template.isEmail,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
    );
  }

  // Convert to database Template for insertion/update
  TemplatesCompanion toDatabase() {
    return TemplatesCompanion.insert(
      name: name,
      subject: Value(subject),
      body: body.isNotEmpty ? body : _generateBodyFromBlocks(),
      templateType: Value(templateType == TemplateType.whatsapp ? 'whatsapp' : 'email'),
      blocksJson: Value(jsonEncode(blocks.map((block) => block.toJson()).toList())),
      isEmail: Value(templateType == TemplateType.email),
      updatedAt: Value(DateTime.now()),
    );
  }

  // Convert to database Template for update (with ID)
  TemplatesCompanion toDatabaseUpdate() {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      subject: Value(subject),
      body: Value(body.isNotEmpty ? body : _generateBodyFromBlocks()),
      templateType: Value(templateType == TemplateType.whatsapp ? 'whatsapp' : 'email'),
      blocksJson: Value(jsonEncode(blocks.map((block) => block.toJson()).toList())),
      isEmail: Value(templateType == TemplateType.email),
      updatedAt: Value(DateTime.now()),
    );
  }

  // Generate proper HTML/text body from blocks based on template type
  String _generateBodyFromBlocks({String Function(String imageUrl)? imageSrcResolver}) {
    if (blocks.isEmpty) return '';
    
    switch (templateType) {
      case TemplateType.email:
        return _generateEmailHtml(imageSrcResolver: imageSrcResolver);
      case TemplateType.whatsapp:
        return _generateWhatsAppText();
    }
  }


    String generateBodyFromBlocks(TemplateType templateType, {String Function(String imageUrl)? imageSrcResolver}) {

      switch (templateType) {
        case TemplateType.email:
          return _generateEmailHtml(imageSrcResolver: imageSrcResolver);
        case TemplateType.whatsapp:
          return _generateWhatsAppText();
      }
  }


  // Generate HTML for email templates
  String _generateEmailHtml({String Function(String imageUrl)? imageSrcResolver}) {
    final buffer = StringBuffer();
    
    // Start with email-safe HTML structure
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>${subject ?? name}</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Arial, Helvetica, sans-serif; line-height: 1.6; margin: 0; padding: 20px; }');
    buffer.writeln('.container { max-width: 600px; margin: 0 auto; }');
    buffer.writeln('.button { display: inline-block; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; text-align: center; }');
    buffer.writeln('.divider { border: none; height: 1px; margin: 20px 0; }');
    buffer.writeln('.spacer { height: 20px; }');
    buffer.writeln('img { max-width: 100%; height: auto; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<div class="container">');
    
    for (final block in blocks) {
      buffer.writeln(_generateEmailBlockHtml(block, imageSrcResolver: imageSrcResolver));
    }
    
    buffer.writeln('</div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return buffer.toString();
  }

  // Generate individual block HTML for email
  String _generateEmailBlockHtml(TemplateBlock block, {String Function(String imageUrl)? imageSrcResolver}) {
    switch (block.type) {
      case TemplateBlockType.text:
        final textBlock = block as TextBlock;
        final style = _buildEmailTextStyle(textBlock);
        final alignment = textBlock.alignment == 'center' ? 'center' : 
                         textBlock.alignment == 'right' ? 'right' : 'left';
        return '<p style="$style text-align: $alignment;">${_escapeHtml(textBlock.text)}</p>';
      
      case TemplateBlockType.richText:
        final richTextBlock = block as RichTextBlock;
        return '<div style="font-size: ${richTextBlock.fontSize}px; font-family: ${richTextBlock.fontFamily}; line-height: ${richTextBlock.lineHeight};">${richTextBlock.htmlContent}</div>';
      
      case TemplateBlockType.image:
        final imageBlock = block as ImageBlock;
        final alignment = imageBlock.alignment == 'center' ? 'center' : 
                         imageBlock.alignment == 'right' ? 'right' : 'left';
        final style = 'max-width: ${imageBlock.width}px; height: auto; border-radius: ${imageBlock.borderRadius}px;';
        final borderStyle = imageBlock.borderWidth > 0 ? 'border: ${imageBlock.borderWidth}px solid ${imageBlock.borderColor};' : '';
        final resolvedImageUrl = imageSrcResolver != null ? imageSrcResolver(imageBlock.imageUrl) : imageBlock.imageUrl;
        logger.i('Image URL (original): ${imageBlock.imageUrl}, Resolved: $resolvedImageUrl');
        return '<div style="text-align: $alignment;"><img src="$resolvedImageUrl" alt="${imageBlock.altText}" style="$style $borderStyle" /></div>';
      
      case TemplateBlockType.button:
        final buttonBlock = block as ButtonBlock;
        final alignment = buttonBlock.alignment == 'center' ? 'center' : 
                         buttonBlock.alignment == 'right' ? 'right' : 'left';
        final buttonStyle = 'background-color: ${buttonBlock.backgroundColor}; color: ${buttonBlock.textColor}; padding: 12px 24px; text-decoration: none; border-radius: ${buttonBlock.borderRadius}px; display: inline-block; font-weight: bold;';
        final actionUrl = buttonBlock.actionType == 'url' ? buttonBlock.action : '#';
        return '<div style="text-align: $alignment; margin: 20px 0;"><a href="$actionUrl" style="$buttonStyle">${_escapeHtml(buttonBlock.text)}</a></div>';
      
      case TemplateBlockType.list:
        final listBlock = block as ListBlock;
        final listTag = listBlock.listType == 'numbered' ? 'ol' : 'ul';
        final listStyle = 'font-size: ${listBlock.fontSize}px; color: ${listBlock.color}; margin: ${listBlock.spacing}px 0;';
        final buffer = StringBuffer('<$listTag style="$listStyle">');
        for (final item in listBlock.items) {
          buffer.writeln('<li>${_escapeHtml(item)}</li>');
        }
        buffer.writeln('</$listTag>');
        return buffer.toString();
      
      case TemplateBlockType.spacer:
        final spacerBlock = block as SpacerBlock;
        return '<div class="spacer" style="height: ${spacerBlock.height}px;"></div>';
      
      case TemplateBlockType.divider:
        final dividerBlock = block as DividerBlock;
        final style = 'border: none; height: ${dividerBlock.thickness}px; background-color: ${dividerBlock.color}; width: ${dividerBlock.width}%; margin: 20px auto;';
        return '<hr style="$style" />';
      
      case TemplateBlockType.social:
        final socialBlock = block as SocialBlock;
        final buffer = StringBuffer('<div style="text-align: center; margin: 20px 0;">');
        for (final link in socialBlock.socialLinks) {
          final platform = link['platform'] ?? '';
          final url = link['url'] ?? '';
          buffer.writeln('<a href="$url" style="margin: 0 10px; text-decoration: none;">${platform.toUpperCase()}</a>');
        }
        buffer.writeln('</div>');
        return buffer.toString();
      
      default:
        return '<!-- Unsupported block type: ${block.type.name} -->';
    }
  }

  // Generate formatted text for WhatsApp
  String _generateWhatsAppText() {
    final buffer = StringBuffer();
    
    for (int i = 0; i < blocks.length; i++) {
      final blockText = _generateWhatsAppBlockText(blocks[i]);
      if (blockText.isNotEmpty) {
        buffer.writeln(blockText);
        
        // Add spacing between blocks (except for spacer blocks)
        if (i < blocks.length - 1 && blocks[i].type != TemplateBlockType.spacer) {
          buffer.writeln();
        }
      }
    }
    
    return buffer.toString().trim();
  }

  // Generate individual block text for WhatsApp
  String _generateWhatsAppBlockText(TemplateBlock block) {
    switch (block.type) {
      case TemplateBlockType.text:
        final textBlock = block as TextBlock;
        String text = textBlock.text;
        
        // Apply WhatsApp formatting
        if (textBlock.fontWeight == 'bold') {
          text = '*$text*';
        }
        if (textBlock.italic) {
          text = '_${text}_';
        }
        
        return text;
      
      case TemplateBlockType.richText:
        final richTextBlock = block as RichTextBlock;
        return _stripHtmlForWhatsApp(richTextBlock.htmlContent);
      
      case TemplateBlockType.image:
        final imageBlock = block as ImageBlock;
        return imageBlock.imageUrl.isNotEmpty 
            ? '📷 Image: ${imageBlock.altText.isNotEmpty ? imageBlock.altText : 'Attached'}'
            : '📷 [Image]';
      
      case TemplateBlockType.button:
        final buttonBlock = block as ButtonBlock;
        return '🔗 ${buttonBlock.text}${buttonBlock.action.isNotEmpty ? '\n${buttonBlock.action}' : ''}';
      
      case TemplateBlockType.list:
        final listBlock = block as ListBlock;
        final buffer = StringBuffer();
        for (int i = 0; i < listBlock.items.length; i++) {
          final prefix = listBlock.listType == 'numbered' 
              ? '${i + 1}. ' 
              : '• ';
          buffer.writeln('$prefix${listBlock.items[i]}');
        }
        return buffer.toString().trim();
      
      case TemplateBlockType.spacer:
        final spacerBlock = block as SpacerBlock;
        // Create visual spacing with appropriate line breaks
        final lines = (spacerBlock.height / 20).round().clamp(1, 3);
        return '\n' * lines;
      
      case TemplateBlockType.divider:
        return '─' * 20; // WhatsApp-friendly divider
      
      case TemplateBlockType.qrCode:
        final qrBlock = block as QRCodeBlock;
        return '📱 QR Code: ${qrBlock.data}';
      
      case TemplateBlockType.social:
        final socialBlock = block as SocialBlock;
        final buffer = StringBuffer('🔗 Follow us:\n');
        for (final link in socialBlock.socialLinks) {
          final platform = link['platform'] ?? '';
          final url = link['url'] ?? '';
          buffer.writeln('${platform.toUpperCase()}: $url');
        }
        return buffer.toString().trim();
      
      default:
        return '';
    }
  }

  // Helper method to build email text styles
  String _buildEmailTextStyle(TextBlock textBlock) {
    final styles = <String>[];
    
    styles.add('font-size: ${textBlock.fontSize}px');
    styles.add('color: ${textBlock.color}');
    styles.add('line-height: ${textBlock.lineHeight}');
    styles.add('letter-spacing: ${textBlock.letterSpacing}px');
    
    if (textBlock.fontFamily != 'default') {
      styles.add('font-family: ${textBlock.fontFamily}, Arial, sans-serif');
    } else {
      styles.add('font-family: Arial, Helvetica, sans-serif');
    }
    
    switch (textBlock.fontWeight) {
      case 'bold':
        styles.add('font-weight: bold');
        break;
      case 'light':
        styles.add('font-weight: 300');
        break;
      case 'medium':
        styles.add('font-weight: 500');
        break;
      default:
        styles.add('font-weight: normal');
    }
    
    if (textBlock.italic) {
      styles.add('font-style: italic');
    }
    
    if (textBlock.underline) {
      styles.add('text-decoration: underline');
    }
    
    return '${styles.join('; ')};';
  }

  // Helper method to escape HTML
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // Helper method to strip HTML for WhatsApp
  String _stripHtmlForWhatsApp(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<strong[^>]*>|<b[^>]*>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'</strong>|</b>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'<em[^>]*>|<i[^>]*>', caseSensitive: false), '_')
        .replaceAll(RegExp(r'</em>|</i>', caseSensitive: false), '_')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  // Get template type as string
  String get type => templateType == TemplateType.whatsapp ? 'whatsapp' : 'email';

  // Create a copy with updated fields
  TemplateModel copyWith({
    int? id,
    String? name,
    String? subject,
    String? body,
    TemplateType? templateType,
    List<TemplateBlock>? blocks,
    bool? isEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      templateType: templateType ?? this.templateType,
      blocks: blocks ?? this.blocks,
      isEmail: isEmail ?? this.isEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if template has blocks
  bool get hasBlocks => blocks.isNotEmpty;

  // Get block count
  int get blockCount => blocks.length;

  // Get blocks by type
  List<TemplateBlock> getBlocksByType(TemplateBlockType type) {
    return blocks.where((block) => block.type == type).toList();
  }

  // Check if template is compatible with a specific template type
  bool isCompatibleWith(TemplateType type) {
    return blocks.every((block) => block.isCompatibleWith(type));
  }

  /// Validate the template model for saving
  /// Returns a list of validation errors, empty if valid
  List<String> validate() {
    final errors = <String>[];
    
    // Name validation
    if (name.trim().isEmpty) {
      errors.add('Template name is required');
    } else if (name.trim().length > 255) {
      errors.add('Template name must be 255 characters or less');
    }
    
    // Subject validation for email templates
    if (templateType == TemplateType.email) {
      if (subject == null || subject!.trim().isEmpty) {
        errors.add('Email templates must have a subject');
      } else if (subject!.trim().length > 500) {
        errors.add('Email subject must be 500 characters or less');
      }
    }
    
    // Blocks validation
    if (blocks.isEmpty) {
      errors.add('Template must have at least one block');
    }
    
    // Validate individual blocks
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final blockErrors = _validateBlock(block, i);
      errors.addAll(blockErrors);
    }
    
    return errors;
  }

  /// Validate an individual block
  List<String> _validateBlock(TemplateBlock block, int index) {
    final errors = <String>[];
    final blockLabel = 'Block ${index + 1} (${block.type.name})';
    
    switch (block.type) {
      case TemplateBlockType.text:
        final textBlock = block as TextBlock;
        if (textBlock.text.trim().isEmpty) {
          errors.add('$blockLabel: Text content is required');
        }
        break;
        
      case TemplateBlockType.richText:
        final richTextBlock = block as RichTextBlock;
        if (richTextBlock.htmlContent.trim().isEmpty) {
          errors.add('$blockLabel: Rich text content is required');
        }
        break;
        
      case TemplateBlockType.image:
        final imageBlock = block as ImageBlock;
        if (imageBlock.imageUrl.trim().isEmpty) {
          errors.add('$blockLabel: Image URL is required');
        }
        break;
        
      case TemplateBlockType.button:
        final buttonBlock = block as ButtonBlock;
        if (buttonBlock.text.trim().isEmpty) {
          errors.add('$blockLabel: Button text is required');
        }
        break;
        
      case TemplateBlockType.list:
        final listBlock = block as ListBlock;
        if (listBlock.items.isEmpty) {
          errors.add('$blockLabel: List must have at least one item');
        }
        break;
        
      default:
        // Other block types don't require specific validation
        break;
    }
    
    return errors;
  }

  /// Get the estimated size of the template in bytes (for performance optimization)
  int get estimatedSize {
    int size = 0;
    
    // Base template data
    size += name.length * 2; // UTF-16 encoding
    size += (subject?.length ?? 0) * 2;
    size += body.length * 2;
    
    // Blocks data
    for (final block in blocks) {
      size += _estimateBlockSize(block);
    }
    
    return size;
  }

  /// Estimate the size of a single block
  int _estimateBlockSize(TemplateBlock block) {
    int size = 50; // Base block overhead
    
    switch (block.type) {
      case TemplateBlockType.text:
        final textBlock = block as TextBlock;
        size += textBlock.text.length * 2;
        break;
        
      case TemplateBlockType.richText:
        final richTextBlock = block as RichTextBlock;
        size += richTextBlock.htmlContent.length * 2;
        break;
        
      case TemplateBlockType.image:
        final imageBlock = block as ImageBlock;
        size += imageBlock.imageUrl.length * 2;
        size += imageBlock.altText.length * 2;
        break;
        
      case TemplateBlockType.button:
        final buttonBlock = block as ButtonBlock;
        size += buttonBlock.text.length * 2;
        size += buttonBlock.action.length * 2;
        break;
        
      case TemplateBlockType.list:
        final listBlock = block as ListBlock;
        for (final item in listBlock.items) {
          size += item.length * 2;
        }
        break;
        
      default:
        size += 100; // Default estimate for other block types
        break;
    }
    
    return size;
  }

  /// Check if the template is considered "large" (for performance warnings)
  bool get isLargeTemplate => estimatedSize > 1024 * 1024; // 1MB threshold

  /// Get a summary of the template for logging/debugging
  String get summary {
    return 'TemplateModel(id: $id, name: "$name", type: $type, blocks: ${blocks.length}, size: ${(estimatedSize / 1024).toStringAsFixed(1)}KB)';
  }

  @override
  String toString() {
    return 'TemplateModel(id: $id, name: $name, type: $type, blocks: ${blocks.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateModel &&
        other.id == id &&
        other.name == name &&
        other.subject == subject &&
        other.templateType == templateType;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, subject, templateType);
  }
}

// Extension to add helper methods to Template from database
extension TemplateExtension on Template {
  TemplateModel toModel() => TemplateModel.fromDatabase(this).copyWith();
}
