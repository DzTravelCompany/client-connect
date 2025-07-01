import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ImageBlockWidget extends ConsumerWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildImageContent(context, theme),
    );
  }

  Widget _buildImageContent(BuildContext context, FluentThemeData theme) {
    final alignment = _parseAlignment(block.alignment);
    
    return Align(
      alignment: alignment,
      child: block.imageUrl.isEmpty
          ? _buildPlaceholder(theme)
          : _buildImage(theme),
    );
  }

  Widget _buildPlaceholder(FluentThemeData theme) {
    return Container(
      width: block.width,
      height: block.height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(block.borderRadius),
        border: Border.all(
          color: block.borderWidth > 0 
              ? _parseColor(block.borderColor)
              : theme.accentColor,
          width: block.borderWidth > 0 ? block.borderWidth : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.file_image,
            size: 32,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(
              color: theme.inactiveColor,
              fontSize: 12,
            ),
          ),
          if (block.altText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Alt: ${block.altText}',
              style: TextStyle(
                color: theme.inactiveColor,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(FluentThemeData theme) {
    return Container(
      decoration: block.borderWidth > 0
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(block.borderRadius),
              border: Border.all(
                color: _parseColor(block.borderColor),
                width: block.borderWidth,
              ),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(block.borderRadius),
        child: Image.network(
          block.imageUrl,
          width: block.isResponsive ? null : block.width,
          height: block.height,
          fit: _parseFit(block.fit),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: block.width,
              height: block.height,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(block.borderRadius),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.error,
                    size: 32,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
      return Colors.black;
    }
  }

  BoxFit _parseFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }
}