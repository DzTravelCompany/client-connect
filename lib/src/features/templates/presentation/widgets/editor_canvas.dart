import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/block_widgets/button_block_widget.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/block_widgets/divider_block_widget.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/block_widgets/image_block_widget.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/block_widgets/spacer_block_widget.dart';
import 'package:client_connect/src/features/templates/presentation/widgets/block_widgets/text_block_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'block_widgets/rich_text_block_widget.dart';
import 'block_widgets/list_block_widget.dart';
import 'block_widgets/qr_code_block_widget.dart';
import 'block_widgets/social_block_widget.dart';

class EditorCanvas extends ConsumerWidget {
  const EditorCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final dragDropState = ref.watch(dragDropStateProvider);
    final theme = FluentTheme.of(context);

    return Column(
      children: [
        // Canvas Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.accentColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  editorState.isPreviewMode 
                      ? FluentIcons.preview 
                      : FluentIcons.canvas_app_template32,
                  size: 20,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                editorState.isPreviewMode ? 'Preview' : 'Canvas',
                style: theme.typography.subtitle,
              ),
              const Spacer(),
              if (!editorState.isPreviewMode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${editorState.blocks.length} blocks',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (editorState.usedPlaceholders.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.variable,
                        size: 12,
                        color: theme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${editorState.usedPlaceholders.length}',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Button(
                onPressed: () => ref.read(templateEditorProvider.notifier).togglePreviewMode(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      editorState.isPreviewMode ? FluentIcons.edit : FluentIcons.preview,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(editorState.isPreviewMode ? 'Edit' : 'Preview'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Canvas Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.accentColor,
                width: 1,
              ),
            ),
            child: editorState.blocks.isEmpty
                ? _buildEmptyState(context, ref, dragDropState.isDragging)
                : _buildCanvasContent(context, ref, editorState, dragDropState),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDragging) {
    final theme = FluentTheme.of(context);
    
    return DragTarget<TemplateBlockType>(
      onAcceptWithDetails: (details) {
        _addBlockFromDrag(ref, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovering
                ? theme.accentColor.withValues(alpha: 0.05)
                : Colors.transparent,
            border: isHovering
                ? Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? theme.accentColor.withValues(alpha: 0.1)
                        : theme.accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    isHovering ? FluentIcons.add : FluentIcons.canvas_app_template32,
                    size: 48,
                    color: isHovering
                        ? theme.accentColor
                        : theme.inactiveColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isHovering
                      ? 'Drop block here'
                      : 'Start building your template',
                  style: theme.typography.subtitle?.copyWith(
                    color: isHovering
                        ? theme.accentColor
                        : theme.inactiveColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isHovering)
                  Text(
                    'Drag blocks from the toolbox or click to add',
                    style: theme.typography.body?.copyWith(
                      color: theme.inactiveColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanvasContent(
    BuildContext context,
    WidgetRef ref,
    TemplateEditorState state,
    DragDropState dragDropState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drop zone at the top (only in edit mode)
          if (!state.isPreviewMode)
            _buildDropZone(context, ref, 0, dragDropState.isDragging),
          
          // Blocks with drop zones between them
          for (int i = 0; i < state.blocks.length; i++) ...[
            _buildBlockWrapper(
              context,
              ref,
              state.blocks[i],
              state.selectedBlockId == state.blocks[i].id,
              i,
              state.isPreviewMode,
            ),
            if (!state.isPreviewMode)
              _buildDropZone(context, ref, i + 1, dragDropState.isDragging),
          ],
        ],
      ),
    );
  }

  Widget _buildDropZone(BuildContext context, WidgetRef ref, int index, bool isDragging) {
    final theme = FluentTheme.of(context);
    
    if (!isDragging) {
      return const SizedBox(height: 4);
    }
    
    return DragTarget<TemplateBlockType>(
      onAcceptWithDetails: (details) {
        _addBlockFromDrag(ref, details.data, index: index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovering ? 40 : 8,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isHovering
                ? theme.accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isHovering
                ? Border.all(
                    color: theme.accentColor,
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isHovering
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FluentIcons.add,
                        size: 16,
                        color: theme.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Drop here',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBlockWrapper(
    BuildContext context,
    WidgetRef ref,
    TemplateBlock block,
    bool isSelected,
    int index,
    bool isPreviewMode,
  ) {
    final theme = FluentTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: !isPreviewMode ? () {
          ref.read(templateEditorProvider.notifier).selectBlock(block.id);
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected && !isPreviewMode
                  ? theme.accentColor
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected && !isPreviewMode
                      ? theme.accentColor.withValues(alpha: 0.02)
                      : Colors.transparent,
                ),
                child: _buildBlockWidget(block),
              ),
              if (isSelected && !isPreviewMode) 
                _buildBlockControls(context, ref, block),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(TemplateBlock block) {
    switch (block.type) {
      case TemplateBlockType.text:
        return TextBlockWidget(block: block as TextBlock);
      case TemplateBlockType.richText:
        return RichTextBlockWidget(block: block as RichTextBlock);
      case TemplateBlockType.image:
        return ImageBlockWidget(block: block as ImageBlock);
      case TemplateBlockType.button:
        return ButtonBlockWidget(block: block as ButtonBlock);
      case TemplateBlockType.spacer:
        return SpacerBlockWidget(block: block as SpacerBlock);
      case TemplateBlockType.divider:
        return DividerBlockWidget(block: block as DividerBlock);
      case TemplateBlockType.list:
        return ListBlockWidget(block: block as ListBlock);
      case TemplateBlockType.qrCode:
        return QRCodeBlockWidget(block: block as QRCodeBlock);
      case TemplateBlockType.social:
        return SocialBlockWidget(block: block as SocialBlock);
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text('Unsupported block type: ${block.type}'),
        );
    }
  }

  Widget _buildBlockControls(BuildContext context, WidgetRef ref, TemplateBlock block) {
    final theme = FluentTheme.of(context);
    
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.copy, size: 14),
              onPressed: () {
                ref.read(templateEditorProvider.notifier).duplicateBlock(block.id);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
              ),
            ),
            IconButton(
              icon: const Icon(FluentIcons.delete, size: 14),
              onPressed: () {
                _showDeleteDialog(context, ref, block);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addBlockFromDrag(WidgetRef ref, TemplateBlockType blockType, {int? index}) {
    final notifier = ref.read(templateEditorProvider.notifier);
    
    TemplateBlock block;
    switch (blockType) {
      case TemplateBlockType.text:
        block = notifier.createTextBlock();
        break;
      case TemplateBlockType.richText:
        block = notifier.createRichTextBlock();
        break;
      case TemplateBlockType.image:
        block = notifier.createImageBlock();
        break;
      case TemplateBlockType.button:
        block = notifier.createButtonBlock();
        break;
      case TemplateBlockType.spacer:
        block = notifier.createSpacerBlock();
        break;
      case TemplateBlockType.divider:
        block = notifier.createDividerBlock();
        break;
      case TemplateBlockType.list:
        block = notifier.createListBlock();
        break;
      case TemplateBlockType.qrCode:
        block = notifier.createQRCodeBlock();
        break;
      case TemplateBlockType.social:
        block = notifier.createSocialBlock();
        break;
      default:
        return;
    }
    
    notifier.addBlock(block, index: index);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, TemplateBlock block) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Block'),
        content: Text('Are you sure you want to delete this ${block.type.name} block?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(templateEditorProvider.notifier).removeBlock(block.id);
            },
          ),
        ],
      ),
    );
  }
}
