import 'package:client_connect/src/features/templates/data/rich_text_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;

class FormattingToolbar extends StatefulWidget {
  final Function(TextFormatting) onFormatText;
  final TextFormatting currentFormatting;
  final VoidCallback onClose;

  const FormattingToolbar({
    super.key,
    required this.onFormatText,
    required this.currentFormatting,
    required this.onClose,
  });

  @override
  State<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends State<FormattingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48, // Fixed height to prevent overflow
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.micaBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormatButton(
                        icon: FluentIcons.bold,
                        isActive: widget.currentFormatting.bold,
                        onPressed: () => _toggleBold(),
                        tooltip: 'Bold',
                      ),
                      _buildFormatButton(
                        icon: FluentIcons.italic,
                        isActive: widget.currentFormatting.italic,
                        onPressed: () => _toggleItalic(),
                        tooltip: 'Italic',
                      ),
                      _buildFormatButton(
                        icon: FluentIcons.underline,
                        isActive: widget.currentFormatting.underline,
                        onPressed: () => _toggleUnderline(),
                        tooltip: 'Underline',
                      ),
                      _buildFormatButton(
                        icon: FluentIcons.strikethrough,
                        isActive: widget.currentFormatting.strikethrough,
                        onPressed: () => _toggleStrikethrough(),
                        tooltip: 'Strikethrough',
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 1,
                        height: 24,
                        color: theme.accentColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      _buildFontSizeSelector(),
                      const SizedBox(width: 4),
                      _buildColorPicker(),
                      const SizedBox(width: 4),
                      Container(
                        width: 1,
                        height: 24,
                        color: theme.accentColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      _buildFormatButton(
                        icon: FluentIcons.chrome_close,
                        isActive: false,
                        onPressed: widget.onClose,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final theme = FluentTheme.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            icon: Icon(
              icon,
              size: 14,
              color: isActive
                  ? theme.accentColor
                  : theme.typography.body?.color?.withValues(alpha: 0.7),
            ),
            onPressed: onPressed,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (isActive) {
                  return theme.accentColor.withValues(alpha: 0.1);
                }
                if (states.contains(WidgetState.hovered)) {
                  return theme.accentColor.withValues(alpha: 0.05);
                }
                return Colors.transparent;
              }),
              padding: WidgetStateProperty.all(
                const EdgeInsets.all(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    final currentSize = widget.currentFormatting.fontSize ?? 14.0;

    return SizedBox(
      width: 70,
      height: 32,
      child: ComboBox<double>(
        value: currentSize,
        items: [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0]
            .map((size) => ComboBoxItem<double>(
                  value: size,
                  child: Text('${size.toInt()}', style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
        onChanged: (size) {
          if (size != null) {
            _applyFormatting(widget.currentFormatting.copyWith(fontSize: size));
          }
        },
        placeholder: Text('${currentSize.toInt()}', style: const TextStyle(fontSize: 12)),
        isExpanded: false,
      ),
    );
  }

  Widget _buildColorPicker() {
    final theme = FluentTheme.of(context);
    final currentColor = _parseColor(widget.currentFormatting.color ?? '#000000');

    return Tooltip(
      message: 'Text Color',
      child: GestureDetector(
        onTap: _showColorPicker,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            FluentIcons.font_color_a,
            size: 12,
            color: _getContrastColor(currentColor),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Choose Text Color'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: _buildColorGrid(),
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = [
      '#000000', '#FFFFFF', '#FF0000', '#00FF00', '#0000FF',
      '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080',
      '#FFC0CB', '#A52A2A', '#808080', '#000080', '#008000',
      '#FFD700', '#DC143C', '#4B0082', '#FF1493', '#00CED1',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((colorHex) {
        final color = _parseColor(colorHex);
        return GestureDetector(
          onTap: () {
            _applyFormatting(widget.currentFormatting.copyWith(color: colorHex));
            Navigator.of(context).pop();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleBold() {
    _applyFormatting(
      widget.currentFormatting.copyWith(bold: !widget.currentFormatting.bold),
    );
  }

  void _toggleItalic() {
    _applyFormatting(
      widget.currentFormatting.copyWith(italic: !widget.currentFormatting.italic),
    );
  }

  void _toggleUnderline() {
    _applyFormatting(
      widget.currentFormatting.copyWith(underline: !widget.currentFormatting.underline),
    );
  }

  void _toggleStrikethrough() {
    _applyFormatting(
      widget.currentFormatting.copyWith(strikethrough: !widget.currentFormatting.strikethrough),
    );
  }

  void _applyFormatting(TextFormatting formatting) {
    widget.onFormatText(formatting);
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}