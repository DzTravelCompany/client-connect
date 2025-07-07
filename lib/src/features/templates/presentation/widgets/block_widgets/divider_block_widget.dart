import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DividerBlockWidget extends StatelessWidget {
  final DividerBlock block;
  final TemplateType? templateType;

  const DividerBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPlatformPadding(),
      child: _buildDividerContent(),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TemplateType.email:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
      default:
        return const EdgeInsets.all(16);
    }
  }

  Widget _buildDividerContent() {
    return Center(
      child: Container(
        width: _getDividerWidth(),
        height: _getAdjustedThickness(),
        decoration: BoxDecoration(
          color: _parseColor(block.color),
          borderRadius: BorderRadius.circular(_getAdjustedThickness() / 2),
        ),
      ),
    );
  }

  double _getDividerWidth() {
    final baseWidth = block.width;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        // Use percentage of mobile screen width
        return (300 * baseWidth / 100).clamp(50.0, 300.0);
      case TemplateType.email:
        // Use percentage of email width (580px max content width)
        return (580 * baseWidth / 100).clamp(100.0, 580.0);
      default:
        return double.infinity;
    }
  }

  double _getAdjustedThickness() {
    final baseThickness = block.thickness;
    
    // Ensure minimum visibility across platforms
    switch (templateType) {
      case TemplateType.whatsapp:
        return baseThickness < 1 ? 1 : (baseThickness > 4 ? 4 : baseThickness);
      case TemplateType.email:
        return baseThickness < 1 ? 1 : (baseThickness > 3 ? 3 : baseThickness);
      default:
        return baseThickness;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Return platform-appropriate default colors
      switch (templateType) {
        case TemplateType.whatsapp:
          return const Color(0xFFE4E6EA); // WhatsApp divider color
        case TemplateType.email:
          return const Color(0xFFDDDDDD); // Email-safe gray
        default:
          return Colors.grey;
      }
    }
  }
}