import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class TemplateTypeSelector extends ConsumerWidget {
  const TemplateTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.accentColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeButton(
            context,
            ref,
            TemplateType.email,
            FluentIcons.mail,
            'Email',
            editorState.templateType == TemplateType.email,
          ),
          _buildTypeButton(
            context,
            ref,
            TemplateType.whatsapp,
            FluentIcons.chat,
            'WhatsApp',
            editorState.templateType == TemplateType.whatsapp,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    WidgetRef ref,
    TemplateType type,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    final theme = FluentTheme.of(context);
    
    return HoverButton(
      onPressed: () {
        if (!isSelected) {
          _showTypeChangeDialog(context, ref, type);
        }
      },
      builder: (context, states) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor
                : states.isHovered
                    ? theme.accentColor.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : states.isHovered
                        ? theme.accentColor
                        : theme.inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : states.isHovered
                          ? theme.accentColor
                          : theme.inactiveColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTypeChangeDialog(BuildContext context, WidgetRef ref, TemplateType newType) {
    final currentState = ref.read(templateEditorProvider);
    
    if (currentState.blocks.isEmpty) {
      ref.read(templateEditorProvider.notifier).setTemplateType(newType);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Change Template Type'),
        content: const Text(
          'Changing the template type may remove some blocks that are not compatible with the new type. Do you want to continue?',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(templateEditorProvider.notifier).setTemplateType(newType);
            },
          ),
        ],
      ),
    );
  }
}
