import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';


class EditorToolbox extends ConsumerWidget {
  const EditorToolbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final editorState = ref.watch(templateEditorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  FluentIcons.toolbox,
                  size: 20,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Toolbox',
                style: theme.typography.subtitle,
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
            ],
          ),
        ),
      ],
    );
  }

  List<_ToolboxItem> _getContentBlocks(TemplateType templateType) {
    return [
      _ToolboxItem(
        icon: FluentIcons.text_field,
        title: 'Text',
        description: 'Simple text content',
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
      _ToolboxItem(
        icon: FluentIcons.variable,
        title: 'Placeholder',
        description: 'Dynamic content placeholder',
        blockType: TemplateBlockType.placeholder,
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
            width: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
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
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHovering
            ? theme.accentColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHovering
              ? theme.accentColor.withValues(alpha: 0.2)
              : theme.accentColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHovering
                  ? theme.accentColor.withValues(alpha: 0.15)
                  : theme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 18,
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: theme.typography.caption?.copyWith(
                    color: theme.inactiveColor,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isHovering)
            Icon(
              FluentIcons.add,
              size: 16,
              color: theme.accentColor,
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
      case TemplateBlockType.placeholder:
        notifier.addBlock(notifier.createPlaceholderBlock());
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