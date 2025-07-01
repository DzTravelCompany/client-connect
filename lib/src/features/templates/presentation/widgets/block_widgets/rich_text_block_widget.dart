import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class RichTextBlockWidget extends StatelessWidget {
  final RichTextBlock block;

  const RichTextBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(4),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _stripHtmlTags(block.htmlContent),
              style: TextStyle(
                fontSize: block.fontSize,
                height: block.lineHeight,
                color: theme.typography.body?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlContent) {
    // Simple HTML tag removal for preview
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}