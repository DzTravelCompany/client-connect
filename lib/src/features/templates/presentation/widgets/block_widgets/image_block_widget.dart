import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class ImageBlockWidget extends ConsumerWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final editorState = ref.watch(templateEditorProvider);
    final isSelected = editorState.selectedBlockId == block.id;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildImageContent(context, theme, ref, isSelected, editorState.isPreviewMode),
    );
  }

  Widget _buildImageContent(BuildContext context, FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    final alignment = _parseAlignment(block.alignment);
    
    return Align(
      alignment: alignment,
      child: Stack(
        children: [
          block.imageUrl.isEmpty
              ? _buildPlaceholder(theme, ref, isSelected, isPreviewMode)
              : _buildImage(theme, ref, isSelected, isPreviewMode),
          if (isSelected && !isPreviewMode)
            _buildSelectionOverlay(theme, ref),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    return GestureDetector(
      onTap: isSelected && !isPreviewMode ? () => _pickImage(ref) : null,
      child: Container(
        width: block.width,
        height: block.height,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(block.borderRadius),
          border: Border.all(
            color: isSelected 
                ? theme.accentColor
                : block.borderWidth > 0 
                    ? _parseColor(block.borderColor)
                    : theme.accentColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : (block.borderWidth > 0 ? block.borderWidth : 1),
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
              isSelected && !isPreviewMode ? 'Click to upload image' : 'No image selected',
              style: TextStyle(
                color: theme.inactiveColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildImage(FluentThemeData theme, WidgetRef ref, bool isSelected, bool isPreviewMode) {
    return GestureDetector(
      onTap: isSelected && !isPreviewMode ? () => _showImageOptions(ref) : null,
      child: Container(
        decoration: block.borderWidth > 0
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(block.borderRadius),
                border: Border.all(
                  color: isSelected 
                      ? theme.accentColor
                      : _parseColor(block.borderColor),
                  width: isSelected ? 2 : block.borderWidth,
                ),
              )
            : isSelected ? BoxDecoration(
                borderRadius: BorderRadius.circular(block.borderRadius),
                border: Border.all(
                  color: theme.accentColor,
                  width: 2,
                ),
              ) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(block.borderRadius),
          child: _buildImageWidget(theme),
        ),
      ),
    );
  }

  Widget _buildImageWidget(FluentThemeData theme) {
    // Check if it's a local file path or URL
    if (block.imageUrl.startsWith('http://') || block.imageUrl.startsWith('https://')) {
      return Image.network(
        block.imageUrl,
        width: block.isResponsive ? null : block.width,
        height: block.height,
        fit: _parseFit(block.fit),
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(theme),
      );
    } else if (File(block.imageUrl).existsSync()) {
      return Image.file(
        File(block.imageUrl),
        width: block.isResponsive ? null : block.width,
        height: block.height,
        fit: _parseFit(block.fit),
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(theme),
      );
    } else {
      return _buildErrorWidget(theme);
    }
  }

  Widget _buildErrorWidget(FluentThemeData theme) {
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
      );

      if (result != null && result.files.single.path != null) {
        final imagePath = result.files.single.path!;
        ref.read(templateEditorProvider.notifier).updateBlock(
          block.id,
          {'imageUrl': imagePath},
        );
      }
    } catch (e) {
      // Handle error - could show a dialog or toast
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
    // This could show a context menu with options like:
    // - Replace image
    // - Remove image
    // - Edit alt text
    // For now, just trigger image picker
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
      default:
        return BoxFit.cover;
    }
  }
}