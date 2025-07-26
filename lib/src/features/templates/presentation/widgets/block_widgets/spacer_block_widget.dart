import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SpacerBlockWidget extends StatelessWidget {
  final SpacerBlock block;
  final TemplateType? templateType;

  const SpacerBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final adjustedHeight = _getAdjustedHeight();
    
    return Container(
      height: adjustedHeight,
      margin: _getMargin(),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(4),
        color: _getSpacerBackgroundColor(theme),
      ),
      child: Center(
        child: Text(
          'Spacer (${adjustedHeight.toInt()}px)',
          style: TextStyle(
            color: _getSpacerTextColor(theme),
            fontSize: _getTextSize(),
            fontWeight: FontWeight.w500,
            fontFamily: _getFontFamily(),
          ),
        ),
      ),
    );
  }

  double _getAdjustedHeight() {
    final baseHeight = block.height;
    
    // Adjust height based on platform constraints
    switch (templateType) {
      case TemplateType.whatsapp:
        // Limit spacer height for mobile screens
        return baseHeight > 40 ? 40 : (baseHeight < 8 ? 8 : baseHeight);
      case TemplateType.email:
        // Email clients handle spacing well, but keep reasonable limits
        return baseHeight < 10 ? 10 : (baseHeight > 80 ? 80 : baseHeight);
      default:
        return baseHeight;
    }
  }

  EdgeInsets _getMargin() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 2);
      case TemplateType.email:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 4);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 4);
    }
  }

  Color _getSpacerBackgroundColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFF7F8FA).withValues(alpha: 0.5);
      case TemplateType.email:
        return const Color(0xFFFAFAFA);
      default:
        return theme.cardColor.withValues(alpha: 0.3);
    }
  }

  Color _getSpacerTextColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF8696A0);
      case TemplateType.email:
        return const Color(0xFF999999);
      default:
        return theme.inactiveColor;
    }
  }

  double _getTextSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 9;
      case TemplateType.email:
        return 11;
      default:
        return 10;
    }
  }

  String? _getFontFamily() {
    switch (templateType) {
      case TemplateType.email:
        return 'Arial, Helvetica, sans-serif';
      default:
        return null;
    }
  }
}