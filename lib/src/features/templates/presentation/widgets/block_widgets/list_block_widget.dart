import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListBlockWidget extends ConsumerWidget {
  final ListBlock block;

  const ListBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final isPreviewMode = editorState.isPreviewMode;
    final previewData = editorState.previewData;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildListItems(isPreviewMode, previewData),
      ),
    );
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
        margin: EdgeInsets.only(bottom: block.spacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                block.listType == 'numbered' 
                    ? '${index + 1}.' 
                    : block.bulletStyle,
                style: TextStyle(
                  fontSize: block.fontSize,
                  color: _parseColor(block.color),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayItem,
                style: TextStyle(
                  fontSize: block.fontSize,
                  color: _parseColor(block.color),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
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
      return Colors.black;
    }
  }
}
