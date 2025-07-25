import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';

class QRCodeBlockWidget extends StatelessWidget {
  final QRCodeBlock block;
  final TemplateType? templateType;

  const QRCodeBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final adjustedSize = _getAdjustedSize();
    
    return Container(
      padding: _getPlatformPadding(),
      child: Center(
        child: Container(
          width: adjustedSize,
          height: adjustedSize,
          decoration: BoxDecoration(
            color: _parseColor(block.backgroundColor),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          child: block.data.isEmpty
              ? _buildEmptyState(theme, adjustedSize)
              : _buildQRCodeContent(theme, adjustedSize),
        ),
      ),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TemplateType.email:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(16);
    }
  }

  double _getAdjustedSize() {
    final baseSize = block.size;
    
    // Adjust size based on platform constraints
    switch (templateType) {
      case TemplateType.whatsapp:
        // Limit QR code size for mobile screens
        return baseSize > 200 ? 200 : (baseSize < 80 ? 80 : baseSize);
      case TemplateType.email:
        // Email clients can handle larger QR codes
        return baseSize > 300 ? 300 : (baseSize < 100 ? 100 : baseSize);
      default:
        return baseSize;
    }
  }

  double _getBorderRadius() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 8; // Rounded for mobile
      case TemplateType.email:
        return 4; // Minimal for email
      default:
        return 4;
    }
  }

  Widget _buildEmptyState(FluentThemeData theme, double size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FluentIcons.q_r_code,
          size: size * 0.3,
          color: theme.inactiveColor,
        ),
        SizedBox(height: size * 0.05),
        Text(
          'QR Code',
          style: TextStyle(
            color: theme.inactiveColor,
            fontSize: _getTextSize(size),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'No data set',
          style: TextStyle(
            color: theme.inactiveColor,
            fontSize: _getTextSize(size) - 2,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeContent(FluentThemeData theme, double size) {
    return Stack(
      children: [
        // QR Code pattern simulation
        Container(
          decoration: BoxDecoration(
            color: _parseColor(block.foregroundColor),
            borderRadius: BorderRadius.circular(_getBorderRadius() - 1),
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: QRCodePatternPainter(
              foregroundColor: _parseColor(block.foregroundColor),
              backgroundColor: _parseColor(block.backgroundColor),
              templateType: templateType,
            ),
          ),
        ),
        // Data overlay
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              _getTruncatedData(),
              style: TextStyle(
                color: Colors.white,
                fontSize: _getDataTextSize(size),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  double _getTextSize(double size) {
    final baseSize = size * 0.08;
    return baseSize.clamp(10.0, 16.0);
  }

  double _getDataTextSize(double size) {
    final baseSize = size * 0.06;
    return baseSize.clamp(8.0, 12.0);
  }

  String _getTruncatedData() {
    final maxLength = templateType == TemplateType.whatsapp ? 15 : 20;
    return block.data.length > maxLength 
        ? '${block.data.substring(0, maxLength)}...'
        : block.data;
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return colorString == '#FFFFFF' ? Colors.white : Colors.black;
    }
  }
}

class QRCodePatternPainter extends CustomPainter {
  final Color foregroundColor;
  final Color backgroundColor;
  final TemplateType? templateType;

  QRCodePatternPainter({
    required this.foregroundColor,
    required this.backgroundColor,
    this.templateType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = foregroundColor;
    final gridSize = _getGridSize();
    final blockSize = size.width / gridSize;
    
    // Draw a QR code pattern optimized for the platform
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (_shouldDrawBlock(i, j, gridSize)) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * blockSize,
              j * blockSize,
              blockSize,
              blockSize,
            ),
            paint,
          );
        }
      }
    }
  }

  int _getGridSize() {
    // Adjust grid complexity based on platform
    switch (templateType) {
      case TemplateType.whatsapp:
        return 17; // Simpler pattern for mobile
      case TemplateType.email:
        return 21; // Standard QR code grid
      default:
        return 21;
    }
  }

  bool _shouldDrawBlock(int i, int j, int gridSize) {
    // Simulate QR code pattern with finder patterns and data
    final cornerSize = 7;
    
    // Corner finder patterns
    if ((i < cornerSize && j < cornerSize) || 
        (i > gridSize - cornerSize - 1 && j < cornerSize) || 
        (i < cornerSize && j > gridSize - cornerSize - 1)) {
      return (i == 0 || i == cornerSize - 1 || j == 0 || j == cornerSize - 1 || 
              (i >= 2 && i <= 4 && j >= 2 && j <= 4));
    }
    
    // Timing patterns
    if (i == 6 || j == 6) {
      return (i + j) % 2 == 0;
    }
    
    // Data area - pseudo-random pattern
    return ((i + j * 3) % 3 == 0) || ((i * 2 + j) % 5 == 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
