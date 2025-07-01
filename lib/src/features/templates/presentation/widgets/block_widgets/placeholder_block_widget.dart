import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class PlaceholderBlockWidget extends StatelessWidget {
  final PlaceholderBlock block;

  const PlaceholderBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              FluentIcons.variable,
              size: 16,
              color: theme.accentColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.label.isEmpty ? 'Placeholder' : block.label,
                    style: TextStyle(
                      color: theme.accentColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (block.placeholderKey.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '{{${block.placeholderKey}}}',
                      style: TextStyle(
                        color: theme.accentColor.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (block.defaultValue.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Default: ${block.defaultValue}',
                      style: TextStyle(
                        color: theme.inactiveColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                block.dataType.toUpperCase(),
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}