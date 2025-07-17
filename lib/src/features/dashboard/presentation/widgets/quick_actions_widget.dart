import 'package:fluent_ui/fluent_ui.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.typography.bodyStrong?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _QuickActionButton(
                  icon: FluentIcons.add_friend,
                  label: 'Add Client',
                  description: 'Create a new client profile',
                  color: theme.accentColor,
                  onPressed: () {},
                ),
                
                const SizedBox(height: 12),
                
                _QuickActionButton(
                  icon: FluentIcons.send,
                  label: 'New Campaign',
                  description: 'Start a messaging campaign',
                  color: Colors.blue,
                  onPressed: () {},
                ),
                
                const SizedBox(height: 12),
                
                _QuickActionButton(
                  icon: FluentIcons.page_add,
                  label: 'Create Template',
                  description: 'Design a new message template',
                  color: Colors.purple,
                  onPressed: () {},
                ),
                
                const SizedBox(height: 12),
                
                _QuickActionButton(
                  icon: FluentIcons.import,
                  label: 'Import Data',
                  description: 'Import clients from file',
                  color: Colors.orange,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: Button(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.isHovered) {
              return color.withValues(alpha: 0.1);
            }
            return theme.resources.cardBackgroundFillColorSecondary;
          }),
          padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.typography.body?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              FluentIcons.chevron_right,
              size: 12,
              color: theme.resources.textFillColorTertiary,
            ),
          ],
        ),
      ),
    );
  }
}