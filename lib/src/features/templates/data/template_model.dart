import 'dart:convert';
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

  // Generate plain text body from blocks for backward compatibility
  String _generateBodyFromBlocks() {
    final buffer = StringBuffer();
    
    for (final block in blocks) {
      switch (block.type) {
        case TemplateBlockType.text:
          final textBlock = block as TextBlock;
          buffer.writeln(textBlock.text);
          break;
        case TemplateBlockType.richText:
          final richTextBlock = block as RichTextBlock;
          // Strip HTML tags for plain text
          final plainText = richTextBlock.htmlContent
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');
          buffer.writeln(plainText);
          break;
        case TemplateBlockType.button:
          final buttonBlock = block as ButtonBlock;
          buffer.writeln('[${buttonBlock.text}]');
          break;
        case TemplateBlockType.placeholder:
          final placeholderBlock = block as PlaceholderBlock;
          buffer.writeln('{{${placeholderBlock.placeholderKey}}}');
          break;
        case TemplateBlockType.list:
          final listBlock = block as ListBlock;
          for (int i = 0; i < listBlock.items.length; i++) {
            final prefix = listBlock.listType == 'numbered' 
                ? '${i + 1}. ' 
                : '${listBlock.bulletStyle} ';
            buffer.writeln('$prefix${listBlock.items[i]}');
          }
          break;
        case TemplateBlockType.spacer:
          buffer.writeln(); // Add empty line for spacer
          break;
        case TemplateBlockType.divider:
          buffer.writeln('---'); // Simple divider representation
          break;
        default:
          // For other block types, add a placeholder
          buffer.writeln('[${block.type.name.toUpperCase()} BLOCK]');
          break;
      }
    }
    
    return buffer.toString().trim();
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
  TemplateModel toModel() => TemplateModel.fromDatabase(this);
}