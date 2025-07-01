import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class QRCodeBlockWidget extends StatelessWidget {
  final QRCodeBlock block;

  const QRCodeBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: block.size,
          height: block.size,
          decoration: BoxDecoration(
            color: _parseColor(block.backgroundColor),
            border: Border.all(
              color: theme.accentColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: block.data.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.q_r_code,
                      size: block.size * 0.3,
                      color: theme.inactiveColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code',
                      style: TextStyle(
                        color: theme.inactiveColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'No data set',
                      style: TextStyle(
                        color: theme.inactiveColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    // QR Code pattern simulation
                    Container(
                      decoration: BoxDecoration(
                        color: _parseColor(block.foregroundColor),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: CustomPaint(
                        size: Size(block.size, block.size),
                        painter: QRCodePatternPainter(
                          foregroundColor: _parseColor(block.foregroundColor),
                          backgroundColor: _parseColor(block.backgroundColor),
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
                          block.data.length > 20 
                              ? '${block.data.substring(0, 20)}...'
                              : block.data,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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

  QRCodePatternPainter({
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = foregroundColor;
    final blockSize = size.width / 21; // 21x21 grid for simplicity
    
    // Draw a simple QR code pattern
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        // Create a checkerboard-like pattern with some QR code characteristics
        if (_shouldDrawBlock(i, j)) {
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

  bool _shouldDrawBlock(int i, int j) {
    // Simulate QR code pattern with finder patterns and data
    // Corner finder patterns
    if ((i < 7 && j < 7) || (i > 13 && j < 7) || (i < 7 && j > 13)) {
      return (i == 0 || i == 6 || j == 0 || j == 6 || 
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