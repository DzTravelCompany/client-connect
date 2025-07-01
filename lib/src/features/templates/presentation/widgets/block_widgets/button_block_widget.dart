import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ButtonBlockWidget extends ConsumerWidget {
  final ButtonBlock block;

  const ButtonBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    final alignment = _parseAlignment(block.alignment);
    
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: block.fullWidth ? double.infinity : null,
        child: HoverButton(
          onPressed: () => _handleButtonPress(context),
          builder: (context, states) {
            final isHovering = states.contains(WidgetState.hovered);
            final backgroundColor = isHovering && block.hoverColor.isNotEmpty
                ? _parseColor(block.hoverColor)
                : _parseColor(block.backgroundColor);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: _getButtonPadding(block.size),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(block.borderRadius),
                border: block.borderWidth > 0
                    ? Border.all(
                        color: _parseColor(block.borderColor),
                        width: block.borderWidth,
                      )
                    : null,
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                block.text,
                style: TextStyle(
                  color: _parseColor(block.textColor),
                  fontSize: _getButtonFontSize(block.size),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleButtonPress(BuildContext context) {
    if (block.action.isNotEmpty) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Button Action'),
          content: Text('${block.actionType.toUpperCase()}: ${block.action}'),
          severity: InfoBarSeverity.info,
          onClose: close,
        ),
      );
    }
  }

  Alignment _parseAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  EdgeInsets _getButtonPadding(String size) {
    switch (size) {
      case 'small':
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case 'large':
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getButtonFontSize(String size) {
    switch (size) {
      case 'small':
        return 12.0;
      case 'large':
        return 16.0;
      default:
        return 14.0;
    }
  }
}