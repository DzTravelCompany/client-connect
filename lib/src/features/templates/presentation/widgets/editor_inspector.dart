import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class EditorInspector extends ConsumerWidget {
  const EditorInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

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
                  FluentIcons.settings,
                  size: 20,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Inspector',
                style: theme.typography.subtitle,
              ),
            ],
          ),
        ),
        Expanded(
          child: editorState.selectedBlock == null
              ? _buildNoSelectionState(context, theme)
              : _buildInspectorContent(context, ref, editorState.selectedBlock!, theme),
        ),
      ],
    );
  }

  Widget _buildNoSelectionState(BuildContext context, FluentThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                FluentIcons.drag_object,
                size: 48,
                color: theme.inactiveColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No block selected',
              style: theme.typography.subtitle?.copyWith(
                color: theme.inactiveColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a block from the canvas to edit its properties',
              style: theme.typography.body?.copyWith(
                color: theme.inactiveColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorContent(
    BuildContext context,
    WidgetRef ref,
    TemplateBlock block,
    FluentThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildBlockInfo(context, block, theme),
        const SizedBox(height: 20),
        _buildBlockProperties(context, ref, block, theme),
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
      case TemplateBlockType.placeholder:
        return _buildPlaceholderProperties(context, ref, block as PlaceholderBlock, theme);
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
              block.text,
              (value) => _updateBlock(ref, block.id, {'text': value}),
              maxLines: 3,
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
            _buildColorPicker(
              'Text Color',
              block.color,
              (value) => _updateBlock(ref, block.id, {'color': value}),
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
              block.imageUrl,
              (value) => _updateBlock(ref, block.id, {'imageUrl': value}),
            ),
            _buildTextInput(
              'Alt Text',
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
            _buildColorPicker(
              'Border Color',
              block.borderColor,
              (value) => _updateBlock(ref, block.id, {'borderColor': value}),
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
              block.text,
              (value) => _updateBlock(ref, block.id, {'text': value}),
            ),
            _buildTextInput(
              'Action URL',
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
            _buildColorPicker(
              'Background Color',
              block.backgroundColor,
              (value) => _updateBlock(ref, block.id, {'backgroundColor': value}),
            ),
            _buildColorPicker(
              'Text Color',
              block.textColor,
              (value) => _updateBlock(ref, block.id, {'textColor': value}),
            ),
            _buildColorPicker(
              'Hover Color',
              block.hoverColor,
              (value) => _updateBlock(ref, block.id, {'hoverColor': value}),
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
        _buildColorPicker(
          'Color',
          block.color,
          (value) => _updateBlock(ref, block.id, {'color': value}),
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

  Widget _buildPlaceholderProperties(
    BuildContext context,
    WidgetRef ref,
    PlaceholderBlock block,
    FluentThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertySection(
          theme,
          'Placeholder Settings',
          [
            _buildTextInput(
              'Label',
              block.label,
              (value) => _updateBlock(ref, block.id, {'label': value}),
            ),
            _buildTextInput(
              'Placeholder Key',
              block.placeholderKey,
              (value) => _updateBlock(ref, block.id, {'placeholderKey': value}),
            ),
            _buildTextInput(
              'Default Value',
              block.defaultValue,
              (value) => _updateBlock(ref, block.id, {'defaultValue': value}),
            ),
            _buildDropdown(
              'Data Type',
              block.dataType,
              ['text', 'number', 'date', 'boolean', 'email', 'url'],
              (value) => _updateBlock(ref, block.id, {'dataType': value}),
            ),
          ],
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
            _buildColorPicker(
              'Text Color',
              block.color,
              (value) => _updateBlock(ref, block.id, {'color': value}),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        placeholder: 'Item ${index + 1}',
                        controller: TextEditingController(text: item),
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
            _buildColorPicker(
              'Foreground Color',
              block.foregroundColor,
              (value) => _updateBlock(ref, block.id, {'foregroundColor': value}),
            ),
            _buildColorPicker(
              'Background Color',
              block.backgroundColor,
              (value) => _updateBlock(ref, block.id, {'backgroundColor': value}),
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
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextBox(
                      placeholder: 'Platform (e.g., facebook)',
                      controller: TextEditingController(text: link['platform'] ?? ''),
                      onChanged: (value) {
                        final newLinks = [...block.socialLinks];
                        newLinks[index] = {...link, 'platform': value};
                        _updateBlock(ref, block.id, {'socialLinks': newLinks});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextBox(
                      placeholder: 'URL',
                      controller: TextEditingController(text: link['url'] ?? ''),
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
          'Rich Text Content',
          [
            _buildTextInput(
              'HTML Content',
              block.htmlContent,
              (value) => _updateBlock(ref, block.id, {'htmlContent': value}),
              maxLines: 5,
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            FluentIcons.warning,
            size: 32,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Unsupported Block Type',
            style: theme.typography.subtitle?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Properties for this block type are not yet implemented.',
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildPropertySection(
    FluentThemeData theme,
    String title,
    List<Widget> children,
  ) {
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
        ...children,
      ],
    );
  }

  Widget _buildTextInput(
    String label,
    String value,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextBox(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          maxLines: maxLines,
        ),
        const SizedBox(height: 12),
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
            Text(label),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        ComboBox<String>(
          value: value,
          items: options.map((option) => ComboBoxItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Checkbox(
        checked: value,
        onChanged: onChanged,
        content: Text(label),
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    String colorValue,
    Function(String) onChanged,
  ) {
    final color = _parseColor(colorValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextBox(
                controller: TextEditingController(text: colorValue),
                onChanged: onChanged,
                placeholder: '#000000',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Helper methods
  void _updateBlock(WidgetRef ref, String blockId, Map<String, dynamic> properties) {
    ref.read(templateEditorProvider.notifier).updateBlock(blockId, properties);
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
      case TemplateBlockType.placeholder:
        return FluentIcons.variable;
      case TemplateBlockType.list:
        return FluentIcons.bulleted_list;
      case TemplateBlockType.table:
        return FluentIcons.table;
      case TemplateBlockType.social:
        return FluentIcons.share;
      case TemplateBlockType.qrCode:
        return FluentIcons.q_r_code;
      case TemplateBlockType.countdown:
        return FluentIcons.timer;
      case TemplateBlockType.rating:
        return FluentIcons.favorite_star;
      case TemplateBlockType.progress:
        return FluentIcons.progress_ring_dots;
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
      case TemplateBlockType.placeholder:
        return 'Placeholder Block';
      case TemplateBlockType.list:
        return 'List Block';
      case TemplateBlockType.table:
        return 'Table Block';
      case TemplateBlockType.social:
        return 'Social Block';
      case TemplateBlockType.qrCode:
        return 'QR Code Block';
      case TemplateBlockType.countdown:
        return 'Countdown Block';
      case TemplateBlockType.rating:
        return 'Rating Block';
      case TemplateBlockType.progress:
        return 'Progress Block';
    }
  }
}