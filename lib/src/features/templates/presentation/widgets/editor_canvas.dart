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
        // Enhanced Canvas Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.cardColor,
                theme.cardColor.withValues(alpha: 0.95),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: editorState.isPreviewMode
                        ? [
                            const Color(0xFF4CAF50).withValues(alpha: 0.15),
                            const Color(0xFF4CAF50).withValues(alpha: 0.08),
                          ]
                        : [
                            theme.accentColor.withValues(alpha: 0.15),
                            theme.accentColor.withValues(alpha: 0.08),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: editorState.isPreviewMode
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : theme.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  editorState.isPreviewMode 
                      ? FluentIcons.preview 
                      : FluentIcons.canvas_app_template32,
                  size: 22,
                  color: editorState.isPreviewMode
                      ? const Color(0xFF4CAF50)
                      : theme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          editorState.isPreviewMode ? 'Live Preview' : 'Design Canvas',
                          style: theme.typography.subtitle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Template type indicator with enhanced styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getTemplateTypeColor(editorState.templateType).withValues(alpha: 0.15),
                                _getTemplateTypeColor(editorState.templateType).withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTemplateTypeColor(editorState.templateType).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTemplateTypeIcon(editorState.templateType),
                                size: 12,
                                color: _getTemplateTypeColor(editorState.templateType),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                editorState.templateType.name.toUpperCase(),
                                style: TextStyle(
                                  color: _getTemplateTypeColor(editorState.templateType),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          editorState.isPreviewMode 
                              ? 'See how your template will look to recipients'
                              : 'Drag blocks from the toolbox to build your template',
                          style: theme.typography.caption?.copyWith(
                            color: theme.inactiveColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Enhanced stats and controls
              Row(
                children: [
                  if (!editorState.isPreviewMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.build_definition,
                            size: 12,
                            color: theme.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${editorState.blocks.length}',
                            style: TextStyle(
                              color: theme.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (editorState.usedPlaceholders.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.variable,
                            size: 12,
                            color: const Color(0xFF9C27B0),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${editorState.usedPlaceholders.length}',
                            style: const TextStyle(
                              color: Color(0xFF9C27B0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Enhanced preview toggle button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: editorState.isPreviewMode
                            ? [
                                theme.accentColor.withValues(alpha: 0.15),
                                theme.accentColor.withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                const Color(0xFF4CAF50).withValues(alpha: 0.08),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: editorState.isPreviewMode
                            ? theme.accentColor.withValues(alpha: 0.3)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Button(
                      onPressed: () => ref.read(templateEditorProvider.notifier).togglePreviewMode(),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.transparent),
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            editorState.isPreviewMode ? FluentIcons.edit : FluentIcons.preview,
                            size: 14,
                            color: editorState.isPreviewMode
                                ? theme.accentColor
                                : const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            editorState.isPreviewMode ? 'Edit' : 'Preview',
                            style: TextStyle(
                              color: editorState.isPreviewMode
                                  ? theme.accentColor
                                  : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Enhanced Canvas Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getCanvasBackgroundColor(editorState.templateType),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: editorState.blocks.isEmpty
                ? _buildEmptyState(context, ref, dragDropState.isDragging, editorState.templateType)
                : _buildCanvasContent(context, ref, editorState, dragDropState),
          ),
        ),
      ],
    );
  }

  Color _getTemplateTypeColor(TemplateType templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFF25D366);
      case TemplateType.email:
        return const Color(0xFF007ACC);
    }
  }

  IconData _getTemplateTypeIcon(TemplateType templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return FluentIcons.chat;
      case TemplateType.email:
        return FluentIcons.mail;
    }
  }

  Color _getCanvasBackgroundColor(TemplateType? templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const Color(0xFFF7F8FA); // WhatsApp-like background
      case TemplateType.email:
        return Colors.white; // Clean white for email
      default:
        return Colors.white;
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDragging, TemplateType? templateType) {
    final theme = FluentTheme.of(context);
    
    return DragTarget<TemplateBlockType>(
      onAcceptWithDetails: (details) {
        _addBlockFromDrag(ref, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isHovering
                ? LinearGradient(
                    colors: [
                      theme.accentColor.withValues(alpha: 0.08),
                      theme.accentColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            border: isHovering
                ? Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHovering
                          ? [
                              theme.accentColor.withValues(alpha: 0.15),
                              theme.accentColor.withValues(alpha: 0.08),
                            ]
                          : [
                              theme.accentColor.withValues(alpha: 0.08),
                              theme.accentColor.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isHovering
                          ? theme.accentColor.withValues(alpha: 0.3)
                          : theme.accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    isHovering 
                        ? FluentIcons.add 
                        : _getTemplateTypeIcon(templateType ?? TemplateType.email),
                    size: 56,
                    color: isHovering
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: theme.typography.subtitle?.copyWith(
                    color: isHovering
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ) ?? const TextStyle(),
                  child: Text(
                    isHovering
                        ? 'Drop block here to get started'
                        : 'Start building your ${templateType?.name ?? 'template'}',
                  ),
                ),
                const SizedBox(height: 12),
                if (!isHovering) ...[
                  Text(
                    _getEmptyStateMessage(templateType),
                    style: theme.typography.body?.copyWith(
                      color: theme.inactiveColor,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.cardColor.withValues(alpha: 0.8),
                          theme.cardColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.lightbulb,
                              size: 20,
                              color: theme.accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Tips',
                              style: theme.typography.bodyStrong?.copyWith(
                                color: theme.accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Drag blocks from the left panel\n• Use placeholders like {{name}} for dynamic content\n• Preview your template anytime',
                          style: theme.typography.caption?.copyWith(
                            color: theme.inactiveColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getEmptyStateMessage(TemplateType? templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 'Drag blocks to create your WhatsApp message\nOptimized for mobile viewing';
      case TemplateType.email:
        return 'Drag blocks to create your email template\nOptimized for email clients';
      default:
        return 'Drag blocks from the toolbox or click to add';
    }
  }

  Widget _buildCanvasContent(
    BuildContext context,
    WidgetRef ref,
    TemplateEditorState state,
    DragDropState dragDropState,
  ) {
    return SingleChildScrollView(
      padding: _getCanvasPadding(state.templateType),
      child: ConstrainedBox(
        constraints: _getCanvasConstraints(state.templateType),
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
                state.templateType,
              ),
              if (!state.isPreviewMode)
                _buildDropZone(context, ref, i + 1, dragDropState.isDragging),
            ],
          ],
        ),
      ),
    );
  }

  EdgeInsets _getCanvasPadding(TemplateType? templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.all(12); // Compact padding for mobile
      case TemplateType.email:
        return const EdgeInsets.all(20); // Standard email padding
      default:
        return const EdgeInsets.all(20);
    }
  }

  BoxConstraints _getCanvasConstraints(TemplateType? templateType) {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const BoxConstraints(
          maxWidth: 350, // Mobile-first width
          minHeight: 400,
        );
      case TemplateType.email:
        return const BoxConstraints(
          maxWidth: 600, // Standard email width
          minHeight: 400,
        );
      default:
        return const BoxConstraints(
          maxWidth: 600,
          minHeight: 400,
        );
    }
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
          duration: const Duration(milliseconds: 200),
          height: isHovering ? 48 : 8,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: isHovering
                ? LinearGradient(
                    colors: [
                      theme.accentColor.withValues(alpha: 0.15),
                      theme.accentColor.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            border: isHovering
                ? Border.all(
                    color: theme.accentColor,
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : Border.all(
                    color: theme.accentColor.withValues(alpha: 0.2),
                    width: 1,
                    style: BorderStyle.none,
                  ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isHovering
            ? Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        FluentIcons.add,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Drop block here',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
    TemplateType? templateType,
  ) {
    final theme = FluentTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
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
                child: _buildBlockWidget(block, templateType),
              ),
              if (isSelected && !isPreviewMode) 
                _buildBlockControls(context, ref, block),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(TemplateBlock block, TemplateType? templateType) {
    switch (block.type) {
      case TemplateBlockType.text:
        return TextBlockWidget(
          block: block as TextBlock,
          templateType: templateType,
        );
      case TemplateBlockType.richText:
        return RichTextBlockWidget(
          block: block as RichTextBlock,
          templateType: templateType,
        );
      case TemplateBlockType.image:
        return ImageBlockWidget(
          block: block as ImageBlock,
          templateType: templateType,
        );
      case TemplateBlockType.button:
        return ButtonBlockWidget(
          block: block as ButtonBlock,
          templateType: templateType,
        );
      case TemplateBlockType.spacer:
        return SpacerBlockWidget(
          block: block as SpacerBlock,
          templateType: templateType,
        );
      case TemplateBlockType.divider:
        return DividerBlockWidget(
          block: block as DividerBlock,
          templateType: templateType,
        );
      case TemplateBlockType.list:
        return ListBlockWidget(
          block: block as ListBlock,
          templateType: templateType,
        );
      case TemplateBlockType.qrCode:
        return QRCodeBlockWidget(
          block: block as QRCodeBlock,
          templateType: templateType,
        );
      case TemplateBlockType.social:
        return SocialBlockWidget(
          block: block as SocialBlock,
          templateType: templateType,
        );
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
