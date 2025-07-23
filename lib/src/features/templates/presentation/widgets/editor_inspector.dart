import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auto_save_indicator.dart';

class EditorInspector extends ConsumerStatefulWidget {
  const EditorInspector({super.key});

  @override
  ConsumerState<EditorInspector> createState() => _EditorInspectorState();
}

class _EditorInspectorState extends ConsumerState<EditorInspector> {
  // Text controllers for different input fields
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key, String initialValue) {
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController(text: initialValue);
    } else if (_textControllers[key]!.text != initialValue) {
      // Only update if the value has changed externally
      final controller = _textControllers[key]!;
      final selection = controller.selection;
      controller.text = initialValue;
      // Restore cursor position if it's still valid
      if (selection.start <= initialValue.length) {
        controller.selection = selection;
      }
    }
    return _textControllers[key]!;
  }

  FocusNode _getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.cardColor.withValues(alpha: 0.95),
            theme.cardColor.withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          left: BorderSide(
            color: theme.accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(-2, 0),
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
                    FluentIcons.settings,
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
                        'Properties',
                        style: theme.typography.subtitle?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        editorState.selectedBlock != null 
                            ? _getBlockTypeName(editorState.selectedBlock!.type)
                            : 'Select a block to edit',
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
            child: editorState.selectedBlock == null
                ? _buildNoSelectionState(context, theme, editorState)
                : _buildInspectorContent(context, ref, editorState.selectedBlock!, theme, editorState),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionState(BuildContext context, FluentThemeData theme, TemplateEditorState state) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.accentColor.withValues(alpha: 0.08),
                      theme.accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  state.isPreviewMode ? FluentIcons.preview : FluentIcons.touch,
                  size: 48,
                  color: theme.accentColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.isPreviewMode ? 'Preview Mode Active' : 'No Block Selected',
                style: theme.typography.subtitle?.copyWith(
                  color: theme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.isPreviewMode 
                    ? 'Switch to edit mode to modify block properties'
                    : 'Click on a block in the canvas to edit its properties',
                style: theme.typography.body?.copyWith(
                  color: theme.inactiveColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Auto-save status panel
        const AutoSaveStatusPanel(),
        if (state.usedPlaceholders.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildPreviewDataSection(context, theme, state),
        ],
        if (!state.isPreviewMode && state.blocks.isEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  FluentIcons.lightbulb,
                  size: 24,
                  color: theme.accentColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick Start',
                  style: theme.typography.bodyStrong?.copyWith(
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag blocks from the toolbox to start building your template',
                  style: theme.typography.caption?.copyWith(
                    color: theme.inactiveColor,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewDataSection(BuildContext context, FluentThemeData theme, TemplateEditorState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                'Preview Data',
                style: theme.typography.bodyStrong?.copyWith(
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.usedPlaceholders.map((placeholder) {
            final sampleValue = PlaceholderManager.getSampleValue(placeholder);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '{{$placeholder}}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      sampleValue,
                      style: theme.typography.caption?.copyWith(
                        color: theme.inactiveColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInspectorContent(
    BuildContext context,
    WidgetRef ref,
    TemplateBlock block,
    FluentThemeData theme,
    TemplateEditorState state,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildBlockInfo(context, block, theme),
        const SizedBox(height: 20),
        _buildBlockProperties(context, ref, block, theme),
        if ((block is TextBlock && block.hasPlaceholders) || 
            (block is RichTextBlock && block.hasPlaceholders)) ...[
          const SizedBox(height: 20),
          _buildPlaceholderInfo(context, block, theme, state),
        ],
      ],
    );
  }

  Widget _buildBlockInfo(BuildContext context, TemplateBlock block, FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getBlockIcon(block.type),
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
                  _getBlockTypeName(block.type),
                  style: theme.typography.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${block.id.substring(0, 8)}...',
                  style: theme.typography.caption?.copyWith(
                    color: theme.inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderInfo(
    BuildContext context, 
    TemplateBlock block, 
    FluentThemeData theme,
    TemplateEditorState state,
  ) {
    List<String> placeholders = [];
    if (block is TextBlock) {
      placeholders = block.placeholders;
    } else if (block is RichTextBlock) {
      placeholders = block.placeholders;
    }

    if (placeholders.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
                'Placeholders in this block',
                style: theme.typography.bodyStrong?.copyWith(
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...placeholders.map((placeholder) {
            final sampleValue = state.isPreviewMode 
                ? state.previewData[placeholder] ?? '[MISSING]'
                : PlaceholderManager.getSampleValue(placeholder);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '{{$placeholder}}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: theme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Preview: $sampleValue',
                          style: theme.typography.caption?.copyWith(
                            color: theme.inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBlockProperties(
    BuildContext context,
    WidgetRef ref,
    TemplateBlock block,
    FluentThemeData theme,
  ) {
    switch (block.type) {
      case TemplateBlockType.text:
        return _buildTextProperties(context, ref, block as TextBlock, theme);
      case TemplateBlockType.richText:
        return _buildRichTextProperties(context, ref, block as RichTextBlock, theme);
      case TemplateBlockType.image:
        return _buildImageProperties(context, ref, block as ImageBlock, theme);
      case TemplateBlockType.button:
        return _buildButtonProperties(context, ref, block as ButtonBlock, theme);
      case TemplateBlockType.spacer:
        return _buildSpacerProperties(context, ref, block as SpacerBlock, theme);
      case TemplateBlockType.divider:
        return _buildDividerProperties(context, ref, block as DividerBlock, theme);
      case TemplateBlockType.list:
        return _buildListProperties(context, ref, block as ListBlock, theme);
      case TemplateBlockType.qrCode:
        return _buildQRCodeProperties(context, ref, block as QRCodeBlock, theme);
      case TemplateBlockType.social:
        return _buildSocialProperties(context, ref, block as SocialBlock, theme);
      default:
        return _buildUnsupportedProperties(theme);
    }
  }

  Widget _buildTextProperties(
    BuildContext context,
    WidgetRef ref,
    TextBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Content',
          [
            _buildTextInput(
              'Text Content',
              '${block.id}_text',
              block.text,
              (value) => _updateBlock(ref, block.id, {'text': value}),
              maxLines: 3,
              hint: 'Use {{placeholder_name}} for dynamic content',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Typography',
          [
            _buildSlider(
              'Font Size',
              block.fontSize,
              8.0,
              72.0,
              (value) => _updateBlock(ref, block.id, {'fontSize': value}),
            ),
            _buildDropdown(
              'Font Weight',
              block.fontWeight,
              ['normal', 'bold'],
              (value) => _updateBlock(ref, block.id, {'fontWeight': value}),
            ),
            _buildDropdown(
              'Alignment',
              block.alignment,
              ['left', 'center', 'right'],
              (value) => _updateBlock(ref, block.id, {'alignment': value}),
            ),
            _buildSlider(
              'Line Height',
              block.lineHeight,
              1.0,
              3.0,
              (value) => _updateBlock(ref, block.id, {'lineHeight': value}),
            ),
            _buildSlider(
              'Letter Spacing',
              block.letterSpacing,
              -2.0,
              5.0,
              (value) => _updateBlock(ref, block.id, {'letterSpacing': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Style',
          [
            _buildCheckbox(
              'Italic',
              block.italic,
              (value) => _updateBlock(ref, block.id, {'italic': value}),
            ),
            _buildCheckbox(
              'Underline',
              block.underline,
              (value) => _updateBlock(ref, block.id, {'underline': value}),
            ),
            _buildEnhancedColorPicker(
              'Text Color',
              block.color,
              (value) => _updateBlock(ref, block.id, {'color': value}),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageProperties(
    BuildContext context,
    WidgetRef ref,
    ImageBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Image Source',
          [
            _buildTextInput(
              'Image URL',
              '${block.id}_imageUrl',
              block.imageUrl,
              (value) => _updateBlock(ref, block.id, {'imageUrl': value}),
            ),
            _buildTextInput(
              'Alt Text',
              '${block.id}_altText',
              block.altText,
              (value) => _updateBlock(ref, block.id, {'altText': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Dimensions',
          [
            _buildSlider(
              'Width',
              block.width,
              50.0,
              800.0,
              (value) => _updateBlock(ref, block.id, {'width': value}),
            ),
            _buildSlider(
              'Height',
              block.height,
              50.0,
              600.0,
              (value) => _updateBlock(ref, block.id, {'height': value}),
            ),
            _buildDropdown(
              'Fit',
              block.fit,
              ['cover', 'contain', 'fill', 'fitWidth', 'fitHeight'],
              (value) => _updateBlock(ref, block.id, {'fit': value}),
            ),
            _buildDropdown(
              'Alignment',
              block.alignment,
              ['left', 'center', 'right'],
              (value) => _updateBlock(ref, block.id, {'alignment': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Border & Style',
          [
            _buildSlider(
              'Border Radius',
              block.borderRadius,
              0.0,
              50.0,
              (value) => _updateBlock(ref, block.id, {'borderRadius': value}),
            ),
            _buildSlider(
              'Border Width',
              block.borderWidth,
              0.0,
              10.0,
              (value) => _updateBlock(ref, block.id, {'borderWidth': value}),
            ),
            _buildEnhancedColorPicker(
              'Border Color',
              block.borderColor,
              (value) => _updateBlock(ref, block.id, {'borderColor': value}),
              theme,
            ),
            _buildCheckbox(
              'Responsive',
              block.isResponsive,
              (value) => _updateBlock(ref, block.id, {'isResponsive': value}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonProperties(
    BuildContext context,
    WidgetRef ref,
    ButtonBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Content',
          [
            _buildTextInput(
              'Button Text',
              '${block.id}_text',
              block.text,
              (value) => _updateBlock(ref, block.id, {'text': value}),
            ),
            _buildTextInput(
              'Action URL',
              '${block.id}_action',
              block.action,
              (value) => _updateBlock(ref, block.id, {'action': value}),
            ),
            _buildDropdown(
              'Action Type',
              block.actionType,
              ['url', 'email', 'phone'],
              (value) => _updateBlock(ref, block.id, {'actionType': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Appearance',
          [
            _buildDropdown(
              'Size',
              block.size,
              ['small', 'medium', 'large'],
              (value) => _updateBlock(ref, block.id, {'size': value}),
            ),
            _buildDropdown(
              'Alignment',
              block.alignment,
              ['left', 'center', 'right'],
              (value) => _updateBlock(ref, block.id, {'alignment': value}),
            ),
            _buildCheckbox(
              'Full Width',
              block.fullWidth,
              (value) => _updateBlock(ref, block.id, {'fullWidth': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Colors & Style',
          [
            _buildEnhancedColorPicker(
              'Background Color',
              block.backgroundColor,
              (value) => _updateBlock(ref, block.id, {'backgroundColor': value}),
              theme,
            ),
            _buildEnhancedColorPicker(
              'Text Color',
              block.textColor,
              (value) => _updateBlock(ref, block.id, {'textColor': value}),
              theme,
            ),
            _buildEnhancedColorPicker(
              'Hover Color',
              block.hoverColor,
              (value) => _updateBlock(ref, block.id, {'hoverColor': value}),
              theme,
            ),
            _buildSlider(
              'Border Radius',
              block.borderRadius,
              0.0,
              25.0,
              (value) => _updateBlock(ref, block.id, {'borderRadius': value}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacerProperties(
    BuildContext context,
    WidgetRef ref,
    SpacerBlock block,
    FluentThemeData theme,
  ) {
    return _buildPropertySection(
      theme,
      'Size',
      [
        _buildSlider(
          'Height',
          block.height,
          5.0,
          200.0,
          (value) => _updateBlock(ref, block.id, {'height': value}),
        ),
      ],
    );
  }

  Widget _buildDividerProperties(
    BuildContext context,
    WidgetRef ref,
    DividerBlock block,
    FluentThemeData theme,
  ) {
    return _buildPropertySection(
      theme,
      'Appearance',
      [
        _buildSlider(
          'Thickness',
          block.thickness,
          0.5,
          10.0,
          (value) => _updateBlock(ref, block.id, {'thickness': value}),
        ),
        _buildSlider(
          'Width (%)',
          block.width,
          10.0,
          100.0,
          (value) => _updateBlock(ref, block.id, {'width': value}),
        ),
        _buildEnhancedColorPicker(
          'Color',
          block.color,
          (value) => _updateBlock(ref, block.id, {'color': value}),
          theme,
        ),
        _buildDropdown(
          'Style',
          block.style,
          ['solid', 'dashed', 'dotted'],
          (value) => _updateBlock(ref, block.id, {'style': value}),
        ),
      ],
    );
  }

  Widget _buildListProperties(
    BuildContext context,
    WidgetRef ref,
    ListBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'List Settings',
          [
            _buildDropdown(
              'List Type',
              block.listType,
              ['bullet', 'numbered'],
              (value) => _updateBlock(ref, block.id, {'listType': value}),
            ),
            if (block.listType == 'bullet')
              _buildTextInput(
                'Bullet Style',
                '${block.id}_bulletStyle',
                block.bulletStyle,
                (value) => _updateBlock(ref, block.id, {'bulletStyle': value}),
              ),
            _buildSlider(
              'Font Size',
              block.fontSize,
              8.0,
              24.0,
              (value) => _updateBlock(ref, block.id, {'fontSize': value}),
            ),
            _buildSlider(
              'Item Spacing',
              block.spacing,
              0.0,
              20.0,
              (value) => _updateBlock(ref, block.id, {'spacing': value}),
            ),
            _buildEnhancedColorPicker(
              'Text Color',
              block.color,
              (value) => _updateBlock(ref, block.id, {'color': value}),
              theme,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'List Items',
          [
            ...block.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final controllerKey = '${block.id}_item_$index';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        placeholder: 'Item ${index + 1}',
                        controller: _getController(controllerKey, item),
                        focusNode: _getFocusNode(controllerKey),
                        onChanged: (value) {
                          final newItems = [...block.items];
                          newItems[index] = value;
                          _updateBlock(ref, block.id, {'items': newItems});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(FluentIcons.delete, size: 16),
                      onPressed: () {
                        final newItems = [...block.items];
                        newItems.removeAt(index);
                        _updateBlock(ref, block.id, {'items': newItems});
                        // Clean up controller for removed item
                        final controllerKey = '${block.id}_item_$index';
                        _textControllers[controllerKey]?.dispose();
                        _textControllers.remove(controllerKey);
                        _focusNodes[controllerKey]?.dispose();
                        _focusNodes.remove(controllerKey);
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Button(
              onPressed: () {
                final newItems = [...block.items, 'New item'];
                _updateBlock(ref, block.id, {'items': newItems});
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.add, size: 16),
                  SizedBox(width: 4),
                  Text('Add Item'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRCodeProperties(
    BuildContext context,
    WidgetRef ref,
    QRCodeBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'QR Code Data',
          [
            _buildTextInput(
              'Data/URL',
              '${block.id}_data',
              block.data,
              (value) => _updateBlock(ref, block.id, {'data': value}),
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Appearance',
          [
            _buildSlider(
              'Size',
              block.size,
              50.0,
              300.0,
              (value) => _updateBlock(ref, block.id, {'size': value}),
            ),
            _buildDropdown(
              'Error Correction',
              block.errorCorrectionLevel,
              ['L', 'M', 'Q', 'H'],
              (value) => _updateBlock(ref, block.id, {'errorCorrectionLevel': value}),
            ),
            _buildEnhancedColorPicker(
              'Foreground Color',
              block.foregroundColor,
              (value) => _updateBlock(ref, block.id, {'foregroundColor': value}),
              theme,
            ),
            _buildEnhancedColorPicker(
              'Background Color',
              block.backgroundColor,
              (value) => _updateBlock(ref, block.id, {'backgroundColor': value}),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialProperties(
    BuildContext context,
    WidgetRef ref,
    SocialBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Layout',
          [
            _buildDropdown(
              'Layout',
              block.layout,
              ['horizontal', 'vertical'],
              (value) => _updateBlock(ref, block.id, {'layout': value}),
            ),
            _buildDropdown(
              'Style',
              block.style,
              ['icons', 'buttons'],
              (value) => _updateBlock(ref, block.id, {'style': value}),
            ),
            _buildSlider(
              'Icon Size',
              block.iconSize,
              16.0,
              64.0,
              (value) => _updateBlock(ref, block.id, {'iconSize': value}),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Social Links',
          [
            ...block.socialLinks.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              final platformKey = '${block.id}_platform_$index';
              final urlKey = '${block.id}_url_$index';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.accentColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Link ${index + 1}',
                            style: theme.typography.bodyStrong,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.delete, size: 16),
                          onPressed: () {
                            final newLinks = [...block.socialLinks];
                            newLinks.removeAt(index);
                            _updateBlock(ref, block.id, {'socialLinks': newLinks});
                            // Clean up controllers for removed link
                            _textControllers[platformKey]?.dispose();
                            _textControllers.remove(platformKey);
                            _focusNodes[platformKey]?.dispose();
                            _focusNodes.remove(platformKey);
                            _textControllers[urlKey]?.dispose();
                            _textControllers.remove(urlKey);
                            _focusNodes[urlKey]?.dispose();
                            _focusNodes.remove(urlKey);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextBox(
                      placeholder: 'Platform (e.g., facebook)',
                      controller: _getController(platformKey, link['platform'] ?? ''),
                      focusNode: _getFocusNode(platformKey),
                      onChanged: (value) {
                        final newLinks = [...block.socialLinks];
                        newLinks[index] = {...link, 'platform': value};
                        _updateBlock(ref, block.id, {'socialLinks': newLinks});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextBox(
                      placeholder: 'URL',
                      controller: _getController(urlKey, link['url'] ?? ''),
                      focusNode: _getFocusNode(urlKey),
                      onChanged: (value) {
                        final newLinks = [...block.socialLinks];
                        newLinks[index] = {...link, 'url': value};
                        _updateBlock(ref, block.id, {'socialLinks': newLinks});
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Button(
              onPressed: () {
                final newLinks = [...block.socialLinks, {'platform': '', 'url': ''}];
                _updateBlock(ref, block.id, {'socialLinks': newLinks});
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.add, size: 16),
                  SizedBox(width: 4),
                  Text('Add Social Link'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRichTextProperties(
    BuildContext context,
    WidgetRef ref,
    RichTextBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Content',
          [
            _buildTextInput(
              'HTML Content',
              '${block.id}_htmlContent',
              block.htmlContent,
              (value) => _updateBlock(ref, block.id, {'htmlContent': value}),
              maxLines: 5,
              hint: 'Use HTML tags and {{placeholder_name}} for dynamic content',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPropertySection(
          theme,
          'Typography',
          [
            _buildSlider(
              'Font Size',
              block.fontSize,
              8.0,
              72.0,
              (value) => _updateBlock(ref, block.id, {'fontSize': value}),
            ),
            _buildSlider(
              'Line Height',
              block.lineHeight,
              1.0,
              3.0,
              (value) => _updateBlock(ref, block.id, {'lineHeight': value}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnsupportedProperties(FluentThemeData theme) {
    return Center(
      child: Text(
        'Properties for this block type are not yet supported',
        style: theme.typography.body?.copyWith(
          color: theme.inactiveColor,
        ),
      ),
    );
  }

  // Helper methods for building property controls
  Widget _buildPropertySection(
    FluentThemeData theme,
    String title,
    List<Widget> children,
  ) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.cardColor.withValues(alpha: 0.8),
          theme.cardColor.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.accentColor.withValues(alpha: 0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accentColor.withValues(alpha: 0.08),
                theme.accentColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getSectionIcon(title),
                size: 16,
                color: theme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.typography.bodyStrong?.copyWith(
                  color: theme.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            )).toList(),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTextInput(
    String label,
    String controllerKey,
    String value,
    Function(String) onChanged, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        TextBox(
          controller: _getController(controllerKey, value),
          focusNode: _getFocusNode(controllerKey),
          onChanged: onChanged,
          maxLines: maxLines,
          placeholder: hint,
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> options,
    Function(T) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        ComboBox<T>(
          value: value,
          items: options.map((option) => ComboBoxItem<T>(
            value: option,
            child: Text(option.toString()),
          )).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          checked: value,
          onChanged: (newValue) => onChanged(newValue ?? false),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEnhancedColorPicker(
    String label,
    String colorValue,
    Function(String) onChanged,
    FluentThemeData theme,
  ) {
    final currentColor = _parseColor(colorValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        // Color preview and input row
        Row(
          children: [
            // Color preview with live update
            GestureDetector(
              onTap: () => _showColorPickerDialog(colorValue, onChanged, theme),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentColor,
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.color,
                    size: 16,
                    color: _getContrastColor(currentColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Color input field with validation
            Expanded(
              child: TextBox(
                controller: _getController('color_$label', colorValue),
                focusNode: _getFocusNode('color_$label'),
                onChanged: (value) {
                  // Validate hex color format
                  if (_isValidHexColor(value)) {
                    onChanged(value);
                  }
                },
                placeholder: '#000000',
                prefix: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: theme.inactiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Preset color swatches
        _buildColorSwatches(onChanged, theme),
      ],
    );
  }

  Widget _buildColorSwatches(Function(String) onChanged, FluentThemeData theme) {
    final presetColors = [
      '#000000', '#FFFFFF', '#FF0000', '#00FF00', '#0000FF',
      '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080',
      '#FFC0CB', '#A52A2A', '#808080', '#000080', '#008000',
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presetColors.map((colorHex) {
        final color = _parseColor(colorHex);
        return GestureDetector(
          onTap: () => onChanged(colorHex),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showColorPickerDialog(String currentColor, Function(String) onChanged, FluentThemeData theme) {
    // This would show a more advanced color picker dialog
    // For now, we'll keep the existing functionality
  }

  bool _isValidHexColor(String color) {
    if (!color.startsWith('#')) return false;
    if (color.length != 7) return false;
    try {
      int.parse(color.substring(1), radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use black or white text
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  IconData _getBlockIcon(TemplateBlockType type) {
    switch (type) {
      case TemplateBlockType.text:
        return FluentIcons.text_field;
      case TemplateBlockType.richText:
        return FluentIcons.font_color_a;
      case TemplateBlockType.image:
        return FluentIcons.file_image;
      case TemplateBlockType.button:
        return FluentIcons.button_control;
      case TemplateBlockType.spacer:
        return FluentIcons.more;
      case TemplateBlockType.divider:
        return FluentIcons.line;
      case TemplateBlockType.list:
        return FluentIcons.bulleted_list;
      case TemplateBlockType.qrCode:
        return FluentIcons.q_r_code;
      case TemplateBlockType.social:
        return FluentIcons.share;
      default:
        return FluentIcons.unknown;
    }
  }

  String _getBlockTypeName(TemplateBlockType type) {
    switch (type) {
      case TemplateBlockType.text:
        return 'Text Block';
      case TemplateBlockType.richText:
        return 'Rich Text Block';
      case TemplateBlockType.image:
        return 'Image Block';
      case TemplateBlockType.button:
        return 'Button Block';
      case TemplateBlockType.spacer:
        return 'Spacer Block';
      case TemplateBlockType.divider:
        return 'Divider Block';
      case TemplateBlockType.list:
        return 'List Block';
      case TemplateBlockType.qrCode:
        return 'QR Code Block';
      case TemplateBlockType.social:
        return 'Social Block';
      default:
        return 'Unknown Block';
    }
  }

  void _updateBlock(WidgetRef ref, String blockId, Map<String, dynamic> properties) {
    ref.read(templateEditorProvider.notifier).updateBlock(blockId, properties);
  }

  IconData _getSectionIcon(String title) {
    switch (title.toLowerCase()) {
      case 'content':
        return FluentIcons.edit;
      case 'typography':
        return FluentIcons.font_color_a;
      case 'style':
        return FluentIcons.color;
      case 'appearance':
        return FluentIcons.design;
      case 'dimensions':
        return FluentIcons.font_size;
      case 'border & style':
        return FluentIcons.border_dash;
      case 'colors & style':
        return FluentIcons.color_solid;
      case 'size':
        return FluentIcons.full_screen;
      case 'list settings':
        return FluentIcons.bulleted_list;
      case 'list items':
        return FluentIcons.list;
      case 'qr code data':
        return FluentIcons.q_r_code;
      case 'layout':
        return FluentIcons.p_b_i_home_layout_default;
      case 'social links':
        return FluentIcons.share;
      default:
        return FluentIcons.settings;
    }
  }
}