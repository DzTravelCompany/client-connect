import 'package:fluent_ui/fluent_ui.dart';
import '../../data/tag_model.dart';

enum TagChipSize { small, medium, large }

class TagChip extends StatelessWidget {
  final TagModel tag;
  final TagChipSize size;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.tag,
    this.size = TagChipSize.medium,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final color = Color(int.parse('0xFF${tag.color.substring(1)}'));
    
    double fontSize;
    double padding;
    double iconSize;
    
    switch (size) {
      case TagChipSize.small:
        fontSize = 10;
        padding = 4;
        iconSize = 10;
        break;
      case TagChipSize.medium:
        fontSize = 12;
        padding = 6;
        iconSize = 12;
        break;
      case TagChipSize.large:
        fontSize = 14;
        padding = 8;
        iconSize = 14;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding + 2, vertical: padding),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? color
                : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: padding),
            Text(
              tag.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? Colors.white
                    : theme.typography.body?.color,
              ),
            ),
            if (onRemove != null) ...[
              SizedBox(width: padding),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  FluentIcons.clear,
                  size: iconSize,
                  color: isSelected 
                      ? Colors.white
                      : theme.typography.body?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ActionChip extends StatelessWidget {
  final Widget? avatar;
  final Widget label;
  final VoidCallback? onPressed;

  const ActionChip({
    super.key,
    this.avatar,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 4),
            ],
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 12,
                color: theme.accentColor,
                fontWeight: FontWeight.w500,
              ),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}
