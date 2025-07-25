import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ButtonBlockWidget extends ConsumerWidget {
  final ButtonBlock block;
  final TemplateType? templateType;

  const ButtonBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: _getPlatformPadding(),
      child: _buildButtonContent(context),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case TemplateType.email:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(16);
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    final alignment = _parseAlignment(block.alignment);
    
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: _getButtonConstraints(),
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
                decoration: _getButtonDecoration(backgroundColor, isHovering),
                child: Text(
                  block.text,
                  style: _getButtonTextStyle(),
                  textAlign: TextAlign.center,
                  maxLines: _getMaxLines(),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BoxConstraints _getButtonConstraints() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const BoxConstraints(
          maxWidth: 280, // WhatsApp button width limit
          minWidth: 80,
          minHeight: 36,
          maxHeight: 48,
        );
      case TemplateType.email:
        return const BoxConstraints(
          maxWidth: 300, // Email-safe button width
          minWidth: 100,
          minHeight: 40,
          maxHeight: 60,
        );
      default:
        return const BoxConstraints(
          minWidth: 80,
          minHeight: 36,
        );
    }
  }

  int _getMaxLines() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 2; // Allow wrapping for longer text on mobile
      case TemplateType.email:
        return 1; // Keep single line for email buttons
      default:
        return 1;
    }
  }

  BoxDecoration _getButtonDecoration(Color backgroundColor, bool isHovering) {
    final borderRadius = _getResponsiveBorderRadius();
    
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: block.borderWidth > 0
          ? Border.all(
              color: _parseColor(block.borderColor),
              width: block.borderWidth,
            )
          : null,
      boxShadow: _getButtonShadow(backgroundColor, isHovering),
    );
  }

  double _getResponsiveBorderRadius() {
    final baseRadius = block.borderRadius;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        // WhatsApp prefers more rounded buttons
        return baseRadius < 8 ? 8 : baseRadius;
      case TemplateType.email:
        // Email clients prefer minimal border radius
        return baseRadius > 6 ? 6 : baseRadius;
      default:
        return baseRadius;
    }
  }

  List<BoxShadow>? _getButtonShadow(Color backgroundColor, bool isHovering) {
    if (!isHovering) return null;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        // Subtle shadow for WhatsApp
        return [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case TemplateType.email:
        // More pronounced shadow for email
        return [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
    }
  }

  TextStyle _getButtonTextStyle() {
    final baseFontSize = _getButtonFontSize(block.size);
    
    return TextStyle(
      color: _parseColor(block.textColor),
      fontSize: baseFontSize,
      fontWeight: FontWeight.w500,
      fontFamily: _getButtonFont(),
    );
  }

  double _getButtonFontSize(String size) {
    double baseFontSize;
    switch (size) {
      case 'small':
        baseFontSize = 12.0;
        break;
      case 'large':
        baseFontSize = 16.0;
        break;
      default:
        baseFontSize = 14.0;
    }
    
    // Platform-specific adjustments
    switch (templateType) {
      case TemplateType.whatsapp:
        // Ensure minimum readable size for mobile
        return baseFontSize < 12 ? 12 : baseFontSize;
      case TemplateType.email:
        // Email buttons prefer slightly larger text
        return baseFontSize < 14 ? 14 : baseFontSize;
      default:
        return baseFontSize;
    }
  }

  String? _getButtonFont() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return null; // Use system font
      case TemplateType.email:
        return 'Arial, Helvetica, sans-serif'; // Email-safe font
      default:
        return null;
    }
  }

  EdgeInsets _getButtonPadding(String size) {
    EdgeInsets basePadding;
    switch (size) {
      case 'small':
        basePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case 'large':
        basePadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        break;
      default:
        basePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
    
    // Platform-specific adjustments
    switch (templateType) {
      case TemplateType.whatsapp:
        // More compact padding for mobile
        return EdgeInsets.symmetric(
          horizontal: basePadding.horizontal * 0.8,
          vertical: basePadding.vertical,
        );
      case TemplateType.email:
        // More generous padding for email
        return EdgeInsets.symmetric(
          horizontal: basePadding.horizontal * 1.2,
          vertical: basePadding.vertical * 1.1,
        );
      default:
        return basePadding;
    }
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
      // Return platform-appropriate default colors
      switch (templateType) {
        case TemplateType.whatsapp:
          return colorString == block.backgroundColor 
              ? const Color(0xFF25D366) // WhatsApp green
              : Colors.white;
        case TemplateType.email:
          return colorString == block.backgroundColor 
              ? const Color(0xFF007ACC) // Professional blue
              : Colors.white;
        default:
          return Colors.blue;
      }
    }
  }
}
