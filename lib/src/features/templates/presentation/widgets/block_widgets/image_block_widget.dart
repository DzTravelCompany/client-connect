import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class ImageBlockWidget extends ConsumerWidget {
  final ImageBlock block;
  final TemplateType? templateType;

  const ImageBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final editorState = ref.watch(templateEditorProvider);
    final isSelected = editorState.selectedBlockId == block.id;
    
    return Container(
      padding: _getPlatformPadding(),
      child: _buildImageContent(context, theme, ref, isSelected, editorState.isPreviewMode),
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

  Widget _buildImageContent(BuildContext context, FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    final alignment = _parseAlignment(block.alignment);
    final constraints = _getImageConstraints();
    
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: constraints,
        child: Stack(
          children: [
            block.imageUrl.isEmpty
                ? _buildPlaceholder(theme, ref, isSelected, isPreviewMode)
                : _buildImage(theme, ref, isSelected, isPreviewMode),
            if (isSelected && !isPreviewMode)
              _buildSelectionOverlay(theme, ref),
          ],
        ),
      ),
    );
  }

  BoxConstraints _getImageConstraints() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return BoxConstraints(
          maxWidth: 300, // WhatsApp image width limit
          maxHeight: 300,
          minWidth: 100,
          minHeight: 100,
        );
      case TemplateType.email:
        return BoxConstraints(
          maxWidth: 580, // Email-safe width (600px container - 20px padding)
          maxHeight: 400,
          minWidth: 50,
          minHeight: 50,
        );
      default:
        return BoxConstraints(
          maxWidth: block.width,
          maxHeight: block.height,
          minWidth: 50,
          minHeight: 50,
        );
    }
  }

  Widget _buildPlaceholder(FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    final size = _getPlaceholderSize();
    
    return GestureDetector(
      onTap: isSelected && !isPreviewMode ? () => _pickImage(ref) : null,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: _getPlaceholderBackgroundColor(theme),
          borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
          border: Border.all(
            color: isSelected 
                ? theme.accentColor
                : block.borderWidth > 0 
                    ? _parseColor(block.borderColor)
                    : _getPlaceholderBorderColor(theme),
            width: isSelected ? 2 : (block.borderWidth > 0 ? block.borderWidth : 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.file_image,
              size: _getIconSize(),
              color: _getPlaceholderIconColor(theme),
            ),
            SizedBox(height: _getSpacing()),
            Text(
              isSelected && !isPreviewMode ? 'Click to upload image' : 'Image placeholder',
              style: TextStyle(
                color: _getPlaceholderTextColor(theme),
                fontSize: _getTextSize(),
                fontFamily: _getEmailSafeFont(),
              ),
              textAlign: TextAlign.center,
            ),
            if (block.altText.isNotEmpty) ...[
              SizedBox(height: _getSpacing() / 2),
              Text(
                'Alt: ${block.altText}',
                style: TextStyle(
                  color: _getPlaceholderTextColor(theme),
                  fontSize: _getTextSize() - 2,
                  fontFamily: _getEmailSafeFont(),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Email-specific fallback text
            if (templateType == TemplateType.email && block.altText.isNotEmpty) ...[
              SizedBox(height: _getSpacing()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Fallback: ${block.altText}',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 10,
                    fontFamily: _getEmailSafeFont(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPlaceholderBackgroundColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFF0F2F5); // WhatsApp chat background
      case TemplateType.email:
        return const Color(0xFFFAFAFA); // Light gray for email
      default:
        return theme.cardColor;
    }
  }

  Color _getPlaceholderBorderColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFE4E6EA);
      case TemplateType.email:
        return const Color(0xFFDDDDDD);
      default:
        return theme.accentColor.withValues(alpha: 0.3);
    }
  }

  Color _getPlaceholderIconColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF8696A0);
      case TemplateType.email:
        return const Color(0xFF999999);
      default:
        return theme.inactiveColor;
    }
  }

  Color _getPlaceholderTextColor(FluentThemeData theme) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF667781);
      case TemplateType.email:
        return const Color(0xFF666666);
      default:
        return theme.inactiveColor;
    }
  }

  Size _getPlaceholderSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return Size(
          block.width > 300 ? 300 : block.width,
          block.height > 300 ? 300 : block.height,
        );
      case TemplateType.email:
        return Size(
          block.width > 580 ? 580 : block.width,
          block.height > 400 ? 400 : block.height,
        );
      default:
        return Size(block.width, block.height);
    }
  }

  double _getResponsiveBorderRadius() {
    final baseRadius = block.borderRadius;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        // WhatsApp prefers rounded corners but not too much
        return baseRadius < 8 ? 8 : (baseRadius > 16 ? 16 : baseRadius);
      case TemplateType.email:
        // Email clients prefer minimal border radius for compatibility
        return baseRadius > 6 ? 6 : baseRadius;
      default:
        return baseRadius;
    }
  }

  double _getIconSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 24;
      case TemplateType.email:
        return 32;
      default:
        return 32;
    }
  }

  double _getSpacing() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 4;
      case TemplateType.email:
        return 8;
      default:
        return 8;
    }
  }

  double _getTextSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 12;
      case TemplateType.email:
        return 14;
      default:
        return 12;
    }
  }

  String _getEmailSafeFont() {
    switch (templateType) {
      case TemplateType.email:
        return 'Arial, Helvetica, sans-serif';
      default:
        return 'system-ui, -apple-system, sans-serif';
    }
  }

  Widget _buildImage(FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    return GestureDetector(
      onTap: isSelected && !isPreviewMode ? () => _showImageOptions(ref) : null,
      child: Container(
        decoration: _getImageDecoration(theme, isSelected),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
          child: _buildImageWidget(theme),
        ),
      ),
    );
  }

  BoxDecoration _getImageDecoration(FluentThemeData theme, bool isSelected) {
    if (block.borderWidth > 0) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
        border: Border.all(
          color: isSelected 
              ? theme.accentColor
              : _parseColor(block.borderColor),
          width: isSelected ? 2 : block.borderWidth,
        ),
        // Add shadow for email compatibility
        boxShadow: templateType == TemplateType.email ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      );
    } else if (isSelected) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
        border: Border.all(
          color: theme.accentColor,
          width: 2,
        ),
      );
    }
    return const BoxDecoration();
  }

  Widget _buildImageWidget(FluentThemeData theme) {
    final imageSize = _getImageSize();
    
    // Check if it's a local file path or URL
    if (block.imageUrl.startsWith('http://') || block.imageUrl.startsWith('https://')) {
      return _buildNetworkImage(theme, imageSize);
    } else if (File(block.imageUrl).existsSync()) {
      return _buildFileImage(theme, imageSize);
    } else {
      return _buildErrorWidget(theme, imageSize);
    }
  }

  Widget _buildNetworkImage(FluentThemeData theme, Size imageSize) {
    return Stack(
      children: [
        Image.network(
          block.imageUrl,
          width: imageSize.width,
          height: imageSize.height,
          fit: _parseFit(block.fit),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget(theme, imageSize);
          },
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(theme, imageSize),
        ),
        // Email-specific overlay with alt text for accessibility
        if (templateType == TemplateType.email && block.altText.isNotEmpty)
          _buildEmailAccessibilityOverlay(theme),
      ],
    );
  }

  Widget _buildFileImage(FluentThemeData theme, Size imageSize) {
    return Stack(
      children: [
        Image.file(
          File(block.imageUrl),
          width: imageSize.width,
          height: imageSize.height,
          fit: _parseFit(block.fit),
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(theme, imageSize),
        ),
        // Email-specific overlay with alt text for accessibility
        if (templateType == TemplateType.email && block.altText.isNotEmpty)
          _buildEmailAccessibilityOverlay(theme),
      ],
    );
  }

  Widget _buildEmailAccessibilityOverlay(FluentThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Text(
          block.altText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: _getEmailSafeFont(),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Size _getImageSize() {
    if (block.isResponsive) {
      switch (templateType) {
        case TemplateType.whatsapp:
          return Size(
            block.width > 300 ? 300 : block.width,
            _calculateResponsiveHeight(block.width > 300 ? 300 : block.width),
          );
        case TemplateType.email:
          return Size(
            block.width > 580 ? 580 : block.width,
            _calculateResponsiveHeight(block.width > 580 ? 580 : block.width),
          );
        default:
          return Size(block.width, block.height);
      }
    }
    return Size(block.width, block.height);
  }

  double _calculateResponsiveHeight(double width) {
    // Maintain aspect ratio while respecting platform constraints
    final aspectRatio = block.width / block.height;
    final calculatedHeight = width / aspectRatio;
    
    switch (templateType) {
      case TemplateType.whatsapp:
        return calculatedHeight > 300 ? 300 : calculatedHeight;
      case TemplateType.email:
        return calculatedHeight > 400 ? 400 : calculatedHeight;
      default:
        return calculatedHeight;
    }
  }

  Widget _buildLoadingWidget(FluentThemeData theme, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: _getPlaceholderBackgroundColor(theme),
        borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ProgressRing(),
          SizedBox(height: _getSpacing()),
          Text(
            'Loading image...',
            style: TextStyle(
              color: _getPlaceholderTextColor(theme),
              fontSize: _getTextSize(),
              fontFamily: _getEmailSafeFont(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(FluentThemeData theme, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: templateType == TemplateType.email 
            ? const Color(0xFFFFF5F5) 
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_getResponsiveBorderRadius()),
        border: Border.all(
          color: templateType == TemplateType.email 
              ? const Color(0xFFE53E3E) 
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: _getIconSize(),
            color: templateType == TemplateType.email 
                ? const Color(0xFFE53E3E) 
                : Colors.red,
          ),
          SizedBox(height: _getSpacing()),
          Text(
            'Image failed to load',
            style: TextStyle(
              color: templateType == TemplateType.email 
                  ? const Color(0xFFE53E3E) 
                  : Colors.red,
              fontSize: _getTextSize(),
              fontFamily: _getEmailSafeFont(),
            ),
            textAlign: TextAlign.center,
          ),
          if (block.altText.isNotEmpty) ...[
            SizedBox(height: _getSpacing() / 2),
            Text(
              block.altText,
              style: TextStyle(
                color: templateType == TemplateType.email 
                    ? const Color(0xFF666666) 
                    : theme.inactiveColor,
                fontSize: _getTextSize() - 2,
                fontFamily: _getEmailSafeFont(),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionOverlay(FluentThemeData theme, WidgetRef ref) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                FluentIcons.edit,
                size: 16,
                color: Colors.white,
              ),
              onPressed: () => _pickImage(ref),
            ),
            if (block.imageUrl.isNotEmpty)
              IconButton(
                icon: Icon(
                  FluentIcons.delete,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: () => _removeImage(ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowedExtensions: templateType == TemplateType.email 
            ? ['jpg', 'jpeg', 'png', 'gif'] // Email-safe formats
            : ['jpg', 'jpeg', 'png', 'gif', 'webp'], // WhatsApp supports more formats
      );

      if (result != null && result.files.single.path != null) {
        final imagePath = result.files.single.path!;
        
        // Validate image size for email compatibility
        if (templateType == TemplateType.email) {
          final file = File(imagePath);
          final fileSize = await file.length();
          
          // Warn if image is too large for email (>1MB)
          if (fileSize > 1024 * 1024) {
            logger.i('Warning: Image size (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB) may be too large for email clients');
          }
        }
        
        ref.read(templateEditorProvider.notifier).updateBlock(
          block.id,
          {'imageUrl': imagePath},
        );
      }
    } catch (e) {
      logger.i('Error picking image: $e');
    }
  }

  void _removeImage(WidgetRef ref) {
    ref.read(templateEditorProvider.notifier).updateBlock(
      block.id,
      {'imageUrl': ''},
    );
  }

  void _showImageOptions(WidgetRef ref) {
    _pickImage(ref);
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
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }
}