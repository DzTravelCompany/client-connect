import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListBlockWidget extends ConsumerWidget {
  final ListBlock block;
  final TemplateType? templateType;

  const ListBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final isPreviewMode = editorState.isPreviewMode;
    final previewData = editorState.previewData;

    return Container(
      padding: _getPlatformPadding(),
      constraints: _getListConstraints(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildListItems(isPreviewMode, previewData),
      ),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TemplateType.email:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      default:
        return const EdgeInsets.all(16);
    }
  }

  BoxConstraints _getListConstraints() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const BoxConstraints(
          maxWidth: 300, // Mobile-friendly width
        );
      case TemplateType.email:
        return const BoxConstraints(
          maxWidth: 580, // Email-safe width with padding
        );
      default:
        return const BoxConstraints();
    }
  }

  List<Widget> _buildListItems(bool isPreviewMode, Map<String, String> previewData) {
    return block.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      // Render item with placeholders if in preview mode
      String displayItem = item;
      if (isPreviewMode && _hasPlaceholders(item)) {
        displayItem = _renderItemWithData(item, previewData);
      }
      
      return Container(
        margin: EdgeInsets.only(bottom: _getResponsiveSpacing()),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _getBulletWidth(),
              child: Text(
                block.listType == 'numbered' 
                    ? '${index + 1}.' 
                    : _getBulletCharacter(),
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(),
                  color: _parseColor(block.color),
                  fontWeight: FontWeight.w600,
                  fontFamily: _getFontFamily(),
                ),
              ),
            ),
            SizedBox(width: _getItemSpacing()),
            Expanded(
              child: SelectableText(
                displayItem,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(),
                  color: _parseColor(block.color),
                  height: _getResponsiveLineHeight(),
                  fontFamily: _getFontFamily(),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getBulletCharacter() {
    // Use platform-appropriate bullet characters
    switch (templateType) {
      case TemplateType.whatsapp:
        return '•'; // Standard bullet for mobile
      case TemplateType.email:
        return '•'; // Email-safe bullet
      default:
        return block.bulletStyle;
    }
  }

  double _getResponsiveSpacing() {
    final baseSpacing = block.spacing;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        return baseSpacing < 6 ? 6 : (baseSpacing > 12 ? 12 : baseSpacing);
      case TemplateType.email:
        return baseSpacing < 8 ? 8 : (baseSpacing > 16 ? 16 : baseSpacing);
      default:
        return baseSpacing;
    }
  }

  double _getBulletWidth() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 24; // Compact for mobile
      case TemplateType.email:
        return 28; // Slightly wider for email
      default:
        return 24;
    }
  }

  double _getItemSpacing() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 8; // Compact spacing
      case TemplateType.email:
        return 12; // More generous spacing
      default:
        return 8;
    }
  }

  double _getResponsiveFontSize() {
    final baseFontSize = block.fontSize;
      
    switch (templateType) {
      case TemplateType.whatsapp:
        return baseFontSize < 14 ? 14 : (baseFontSize > 20 ? 20 : baseFontSize);
      case TemplateType.email:
        return baseFontSize < 16 ? 16 : (baseFontSize > 24 ? 24 : baseFontSize);
      default:
        return baseFontSize;
    }
    
  }

  double _getResponsiveLineHeight() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 1.4; // Compact line height for mobile
      case TemplateType.email:
        return 1.6; // Better readability for email
      default:
        return 1.4;
    }
  }

  String? _getFontFamily() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 'system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
      case TemplateType.email:
        return 'Arial, Helvetica, "Segoe UI", sans-serif'; // Email-safe font
      default:
        return null;
    }
  }

  bool _hasPlaceholders(String text) {
    return text.contains(RegExp(r'\{\{[^}]+\}\}'));
  }

  String _renderItemWithData(String item, Map<String, String> data) {
    String result = item;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    
    for (final match in regex.allMatches(item)) {
      final placeholder = match.group(1);
      if (placeholder != null && data.containsKey(placeholder)) {
        result = result.replaceAll(match.group(0)!, data[placeholder]!);
      }
    }
    
    return result;
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Return platform-appropriate default colors
      switch (templateType) {
        case TemplateType.whatsapp:
          return const Color(0xFF111B21); // WhatsApp dark text
        case TemplateType.email:
          return const Color(0xFF333333); // Email-safe dark gray
        default:
          return Colors.black;
      }
    }
  }
}