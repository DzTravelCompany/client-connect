import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material, BoxDecoration, BoxShadow, Offset, BorderRadius, BoxShape;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorToolbox extends ConsumerWidget {
  const EditorToolbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final editorState = ref.watch(templateEditorProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor.withValues(alpha: 0.95),
            theme.cardColor.withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: theme.accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor.withValues(alpha: 0.15),
                        theme.accentColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    FluentIcons.toolbox,
                    size: 20,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Block Library',
                        style: theme.typography.subtitle?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Drag blocks to canvas',
                        style: theme.typography.caption?.copyWith(
                          color: theme.inactiveColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildToolboxSection(
                  context,
                  ref,
                  'Content Blocks',
                  _getContentBlocks(editorState.templateType),
                ),
                const SizedBox(height: 24),
                _buildToolboxSection(
                  context,
                  ref,
                  'Layout Elements',
                  _getLayoutBlocks(editorState.templateType),
                ),
                if (editorState.templateType == TemplateType.email) ...[
                  const SizedBox(height: 24),
                  _buildToolboxSection(
                    context,
                    ref,
                    'Interactive Elements',
                    _getInteractiveBlocks(),
                  ),
                ],
                if (editorState.templateType == TemplateType.whatsapp) ...[
                  const SizedBox(height: 24),
                  _buildToolboxSection(
                    context,
                    ref,
                    'WhatsApp Specific',
                    _getWhatsAppBlocks(),
                  ),
                ],
                const SizedBox(height: 24),
                _buildPlaceholderSection(context, ref, editorState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_ToolboxItem> _getContentBlocks(TemplateType templateType) {
    return [
      _ToolboxItem(
        icon: FluentIcons.text_field,
        title: 'Text',
        description: 'Simple text content with placeholders',
        blockType: TemplateBlockType.text,
        isCompatible: true,
      ),
      _ToolboxItem(
        icon: FluentIcons.font_color_a,
        title: 'Rich Text',
        description: 'Formatted text with HTML',
        blockType: TemplateBlockType.richText,
        isCompatible: templateType == TemplateType.email,
      ),
      _ToolboxItem(
        icon: FluentIcons.file_image,
        title: 'Image',
        description: 'Add images and graphics',
        blockType: TemplateBlockType.image,
        isCompatible: true,
      ),
    ];
  }

  List<_ToolboxItem> _getLayoutBlocks(TemplateType templateType) {
    return [
      _ToolboxItem(
        icon: FluentIcons.more,
        title: 'Spacer',
        description: 'Add vertical spacing',
        blockType: TemplateBlockType.spacer,
        isCompatible: true,
      ),
      _ToolboxItem(
        icon: FluentIcons.line,
        title: 'Divider',
        description: 'Horizontal separator line',
        blockType: TemplateBlockType.divider,
        isCompatible: true,
      ),
    ];
  }

  List<_ToolboxItem> _getInteractiveBlocks() {
    return [
      _ToolboxItem(
        icon: FluentIcons.button_control,
        title: 'Button',
        description: 'Call-to-action button',
        blockType: TemplateBlockType.button,
        isCompatible: true,
      ),
      _ToolboxItem(
        icon: FluentIcons.bulleted_list,
        title: 'List',
        description: 'Bulleted or numbered list',
        blockType: TemplateBlockType.list,
        isCompatible: true,
      ),
      _ToolboxItem(
        icon: FluentIcons.share,
        title: 'Social Links',
        description: 'Social media buttons',
        blockType: TemplateBlockType.social,
        isCompatible: true,
      ),
    ];
  }

  List<_ToolboxItem> _getWhatsAppBlocks() {
    return [
      _ToolboxItem(
        icon: FluentIcons.q_r_code,
        title: 'QR Code',
        description: 'Generate QR codes',
        blockType: TemplateBlockType.qrCode,
        isCompatible: true,
      ),
    ];
  }

  Widget _buildPlaceholderSection(BuildContext context, WidgetRef ref, TemplateEditorState state) {
    final theme = FluentTheme.of(context);
    final availablePlaceholders = PlaceholderManager.getAvailablePlaceholders();
    final usedPlaceholders = state.usedPlaceholders;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLACEHOLDERS',
          style: theme.typography.bodyStrong?.copyWith(
            color: theme.inactiveColor,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.variable,
                    size: 16,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Click to insert into selected text block',
                    style: theme.typography.caption?.copyWith(
                      color: theme.inactiveColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: availablePlaceholders.map((placeholder) {
                  final isUsed = usedPlaceholders.contains(placeholder);
                  final canInsert = state.selectedBlock is TextBlock || state.selectedBlock is RichTextBlock;
                  
                  return _buildPlaceholderChip(
                    context,
                    ref,
                    placeholder,
                    PlaceholderManager.getPlaceholderLabel(placeholder),
                    isUsed,
                    canInsert,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (usedPlaceholders.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'USED IN TEMPLATE',
            style: theme.typography.bodyStrong?.copyWith(
              color: theme.inactiveColor,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: usedPlaceholders.map((placeholder) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '{{$placeholder}}',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderChip(
    BuildContext context,
    WidgetRef ref,
    String key,
    String label,
    bool isUsed,
    bool canInsert,
  ) {
    final theme = FluentTheme.of(context);
    
    return HoverButton(
      onPressed: canInsert ? () => ref.read(templateEditorProvider.notifier).insertPlaceholder(key) : null,
      builder: (context, states) {
        final isHovering = states.contains(WidgetState.hovered);
        final isDisabled = !canInsert;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDisabled
                ? theme.accentColor.withValues(alpha: 0.05)
                : isHovering
                    ? theme.accentColor.withValues(alpha: 0.15)
                    : theme.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? theme.accentColor.withValues(alpha: 0.1)
                  : isHovering
                      ? theme.accentColor.withValues(alpha: 0.4)
                      : theme.accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FluentIcons.variable,
                size: 12,
                color: isDisabled
                    ? theme.inactiveColor
                    : theme.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled
                      ? theme.inactiveColor
                      : theme.accentColor,
                  fontSize: 11,
                  fontWeight: isUsed ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isUsed) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolboxSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<_ToolboxItem> items,
  ) {
    final theme = FluentTheme.of(context);
    final compatibleItems = items.where((item) => item.isCompatible).toList();
    
    if (compatibleItems.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.bodyStrong?.copyWith(
            color: theme.inactiveColor,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...compatibleItems.map((item) => _buildToolboxItemWidget(context, ref, item)),
      ],
    );
  }

  Widget _buildToolboxItemWidget(BuildContext context, WidgetRef ref, _ToolboxItem item) {
    final theme = FluentTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Draggable<TemplateBlockType>(
        data: item.blockType,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.95),
                  theme.accentColor.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildItemContent(context, theme, item),
        ),
        onDragStarted: () {
          ref.read(dragDropStateProvider.notifier).state = 
              ref.read(dragDropStateProvider).copyWith(
                isDragging: true,
                draggedBlockType: item.blockType,
              );
        },
        onDragEnd: (details) {
          ref.read(dragDropStateProvider.notifier).state = const DragDropState();
        },
        child: HoverButton(
          onPressed: () => _addBlock(ref, item.blockType),
          builder: (context, states) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: _buildItemContent(context, theme, item, states: states),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemContent(
    BuildContext context,
    FluentThemeData theme,
    _ToolboxItem item, {
    Set<WidgetState>? states,
  }) {
    final isHovering = states?.contains(WidgetState.hovered) ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isHovering
            ? LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.12),
                  theme.accentColor.withValues(alpha: 0.08),
                ],
              )
            : LinearGradient(
                colors: [
                  theme.cardColor.withValues(alpha: 0.8),
                  theme.cardColor.withValues(alpha: 0.6),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHovering
              ? theme.accentColor.withValues(alpha: 0.3)
              : theme.accentColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isHovering
            ? [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isHovering
                    ? [
                        theme.accentColor.withValues(alpha: 0.2),
                        theme.accentColor.withValues(alpha: 0.15),
                      ]
                    : [
                        theme.accentColor.withValues(alpha: 0.12),
                        theme.accentColor.withValues(alpha: 0.08),
                      ]
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.typography.bodyStrong?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: theme.typography.caption?.copyWith(
                    color: theme.inactiveColor,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isHovering ? FluentIcons.add : FluentIcons.drag_object,
              size: 16,
              color: isHovering 
                  ? theme.accentColor 
                  : theme.inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  void _addBlock(WidgetRef ref, TemplateBlockType blockType) {
    final notifier = ref.read(templateEditorProvider.notifier);
    
    switch (blockType) {
      case TemplateBlockType.text:
        notifier.addBlock(notifier.createTextBlock());
        break;
      case TemplateBlockType.richText:
        notifier.addBlock(notifier.createRichTextBlock());
        break;
      case TemplateBlockType.image:
        notifier.addBlock(notifier.createImageBlock());
        break;
      case TemplateBlockType.button:
        notifier.addBlock(notifier.createButtonBlock());
        break;
      case TemplateBlockType.spacer:
        notifier.addBlock(notifier.createSpacerBlock());
        break;
      case TemplateBlockType.divider:
        notifier.addBlock(notifier.createDividerBlock());
        break;
      case TemplateBlockType.list:
        notifier.addBlock(notifier.createListBlock());
        break;
      case TemplateBlockType.qrCode:
        notifier.addBlock(notifier.createQRCodeBlock());
        break;
      case TemplateBlockType.social:
        notifier.addBlock(notifier.createSocialBlock());
        break;
      default:
        // Handle other block types
        break;
    }
  }
}

class _ToolboxItem {
  final IconData icon;
  final String title;
  final String description;
  final TemplateBlockType blockType;
  final bool isCompatible;

  const _ToolboxItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.blockType,
    required this.isCompatible,
  });
}
